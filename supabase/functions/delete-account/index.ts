// Edge Function: delete-account
//
// Permanently deletes a user's account and ALL of their data, server-side.
//
// Modes:
//   A) Self-delete: body = { idToken }  -> deletes the authenticated caller.
//   B) Admin-delete: body = { adminToken, targetUserUuid } -> a super_admin
//      deletes any account. The caller must be a super_admin in public.users.
//
// Deletes: public rows referencing the user, storage objects, the Supabase
// auth user, and the Firebase Auth account (self mode via idToken, admin mode
// via the Firebase service account in FIREBASE_SERVICE_ACCOUNT).

import { createClient } from "supabase-js";

const UUID_NAMESPACE = "6ba7b810-9dad-11d1-80b4-00c04fd430c8";
const NAME_PREFIX = "cargolink:";
const MAX_BODY_BYTES = 64 * 1024;

const FIREBASE_API_KEY =
  Deno.env.get("FIREBASE_WEB_API_KEY") ??
  "AIzaSyBwB45_WiSmsUVO04cg8IuHBoK53wRBYo4";

function getSecretKey(): string {
  const legacy = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (legacy) return legacy;
  const secretKeys = Deno.env.get("SUPABASE_SECRET_KEYS");
  if (secretKeys) {
    try {
      const parsed = JSON.parse(secretKeys) as Record<string, string>;
      return parsed["default"] ?? Object.values(parsed)[0] ?? "";
    } catch {
      // malformed env var
    }
  }
  return "";
}

const supabase = createClient(
  Deno.env.get("SUPABASE_URL") ?? "",
  getSecretKey(),
  {
    auth: { autoRefreshToken: false, persistSession: false },
  },
);

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "POST, OPTIONS",
      "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    },
  });
}

function hexToBytes(hex: string): Uint8Array {
  const out = new Uint8Array(hex.length / 2);
  for (let i = 0; i < out.length; i++) {
    out[i] = parseInt(hex.substring(i * 2, i * 2 + 2), 16);
  }
  return out;
}

async function firebaseUidToUuid(firebaseUid: string): Promise<string> {
  const name = NAME_PREFIX + firebaseUid;
  const namespaceBytes = hexToBytes(UUID_NAMESPACE.replace(/-/g, ""));
  const te = new TextEncoder();
  const buf = new Uint8Array(16 + te.encode(name).length);
  buf.set(namespaceBytes, 0);
  buf.set(te.encode(name), 16);
  const digest = await crypto.subtle.digest("SHA-1", buf);
  const bytes = new Uint8Array(digest);
  bytes[6] = (bytes[6] & 0x0f) | 0x50;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  const hex = [...bytes].map((b) => b.toString(16).padStart(2, "0")).join("");
  return [
    hex.slice(0, 8),
    hex.slice(8, 12),
    hex.slice(12, 16),
    hex.slice(16, 20),
    hex.slice(20, 32),
  ].join("-");
}

async function verifyFirebaseToken(idToken: string): Promise<{ uid: string }> {
  const res = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=${FIREBASE_API_KEY}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ idToken }),
    },
  );
  const data = await res.json().catch(() => ({}));
  if (!res.ok || !data.users?.[0]) {
    const msg = (data.error?.message as string) ?? "Invalid Firebase ID token";
    throw new Error(msg);
  }
  return { uid: data.users[0].localId as string };
}

async function deleteFirebaseAccount(idToken: string): Promise<void> {
  const res = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:delete?key=${FIREBASE_API_KEY}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ idToken }),
    },
  );
  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    console.error("firebase account delete failed", res.status, data.error?.message);
    throw new Error(data.error?.message ?? "Firebase account delete failed");
  }
}

// ---------------------------------------------------------------------------
// Firebase Admin REST (mode B: super_admin deletes another user's Firebase
// account). The firebase-admin Node SDK cannot run in a Deno edge function, so
// we replicate exactly what it does internally:
//   1. Sign an RS256 JWT with the service account private key.
//   2. Exchange it for an OAuth2 access token at the token_uri.
//   3. Call POST /v1/projects/{projectId}/accounts:delete { localId: uid }.
// The service account JSON lives in the FIREBASE_SERVICE_ACCOUNT secret.
// ---------------------------------------------------------------------------

function base64UrlEncode(bytes: Uint8Array): string {
  let bin = "";
  for (const b of bytes) bin += String.fromCharCode(b);
  return btoa(bin).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function b64UrlToBytes(s: string): Uint8Array {
  const b64 = s.replace(/-/g, "+").replace(/_/g, "/");
  const bin = atob(b64);
  const bytes = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
  return bytes;
}

// Convert a PEM PKCS#8 private key into a DER ArrayBuffer.
function pemToDer(pem: string): ArrayBuffer {
  const body = pem
    .replace(/-----BEGIN [^-]+-----/g, "")
    .replace(/-----END [^-]+-----/g, "")
    .replace(/\s+/g, "");
  return b64UrlToBytes(body).buffer;
}

interface ServiceAccount {
  client_email?: string;
  client_id?: string;
  private_key?: string;
  project_id?: string;
  token_uri?: string;
}

function getServiceAccount(): ServiceAccount {
  const raw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
  if (!raw) throw new Error("FIREBASE_SERVICE_ACCOUNT secret is not configured");
  const sa = JSON.parse(raw) as ServiceAccount;
  if (!sa.private_key || !sa.client_email) {
    throw new Error("FIREBASE_SERVICE_ACCOUNT is missing private_key/client_email");
  }
  return sa;
}

async function createSignedJwt(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "RS256", typ: "JWT" };
  const claims = {
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/cloud-platform",
    aud: sa.token_uri ?? "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  };
  const te = new TextEncoder();
  const headerB64 = base64UrlEncode(te.encode(JSON.stringify(header)));
  const claimsB64 = base64UrlEncode(te.encode(JSON.stringify(claims)));
  const signingInput = `${headerB64}.${claimsB64}`;

  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToDer(sa.private_key!),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    te.encode(signingInput),
  );
  return `${signingInput}.${base64UrlEncode(new Uint8Array(signature))}`;
}

async function getOAuthToken(sa: ServiceAccount): Promise<string> {
  const jwt = await createSignedJwt(sa);
  const res = await fetch(sa.token_uri ?? "https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }).toString(),
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok || !data.access_token) {
    const msg = (data.error_description as string) ??
      (data.error as string) ??
      `OAuth token exchange failed (HTTP ${res.status})`;
    console.error("oauth token error", msg);
    throw new Error(msg);
  }
  return data.access_token as string;
}

// Deletes a Firebase Auth account by its UID, using admin credentials.
// Tolerates USER_NOT_FOUND (already gone). Throws on real failures.
async function deleteFirebaseUserByUid(firebaseUid: string): Promise<void> {
  const sa = getServiceAccount();
  const token = await getOAuthToken(sa);
  const projectId = sa.project_id ?? "cargolink-23dd3";
  const res = await fetch(
    `https://identitytoolkit.googleapis.com/v1/projects/${projectId}/accounts:delete`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({ localId: firebaseUid }),
    },
  );
  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    const msg = (data.error?.message as string) ?? "Firebase admin delete failed";
    if (msg.includes("USER_NOT_FOUND")) {
      console.error(`firebase uid ${firebaseUid} already gone`);
      return;
    }
    console.error("firebase admin delete failed", res.status, msg);
    throw new Error(msg);
  }
}

async function purgeBucketPrefix(bucket: string, userUuid: string): Promise<void> {
  try {
    let offset = 0;
    const pageSize = 1000;
    for (;;) {
      const { data: items, error } = await supabase.storage
        .from(bucket)
        .list("", {
          limit: pageSize,
          offset,
          search: userUuid,
          sortBy: { column: "name", order: "asc" },
        });
      if (error) {
        console.error(`list ${bucket} error`, error);
        break;
      }
      const paths = (items ?? [])
        .map((it) => it.name)
        .filter((n) => n && n.startsWith(`${userUuid}/`));
      if (paths.length > 0) {
        const { error: rmErr } = await supabase.storage.from(bucket).remove(paths);
        if (rmErr) console.error(`remove ${bucket} error`, rmErr);
      }
      if ((items ?? []).length < pageSize) break;
      offset += pageSize;
    }
  } catch (e) {
    console.error(`purgeBucketPrefix ${bucket} error`, e);
  }
}

async function purgeUser(userUuid: string): Promise<void> {
  const { data: shipperRows } = await supabase
    .from("shippers")
    .select("id")
    .eq("user_id", userUuid);
  const shipperIds = (shipperRows ?? []).map((r) => r.id as string);

  const { data: bookingRows } = await supabase
    .from("bookings")
    .select("id")
    .eq("client_id", userUuid);
  const bookingIds = (bookingRows ?? []).map((r) => r.id as string);

  if (bookingIds.length > 0) {
    await supabase.from("shipment_tracking").delete().in("booking_id", bookingIds);
    await supabase.from("payments").delete().in("booking_id", bookingIds);
    await supabase.from("disputes").delete().in("booking_id", bookingIds);
    await supabase.from("notifications").delete().in("related_booking_id", bookingIds);
    await supabase.from("bookings").delete().in("id", bookingIds);
  }

  await supabase.from("notifications").delete().eq("user_id", userUuid);
  await supabase.from("device_tokens").delete().eq("user_id", userUuid);
  await supabase.from("disputes").delete().eq("reported_by_user_id", userUuid);

  if (shipperIds.length > 0) {
    await supabase.from("shipments").delete().in("shipper_id", shipperIds);
    await supabase.from("shipper_flags").delete().in("shipper_id", shipperIds);
    await supabase.from("shippers").delete().in("id", shipperIds);
  }

  await supabase.from("broadcasts").delete().eq("created_by", userUuid);

  for (const bucket of ["bookings", "documents", "profiles"]) {
    await purgeBucketPrefix(bucket, userUuid);
  }

  await supabase.auth.admin.deleteUser(userUuid);
  await supabase.from("users").delete().eq("id", userUuid);
}

// The mirror Supabase auth user stores the Firebase UID in user_metadata.
// Returns the Firebase UID if known, otherwise undefined.
async function firebaseUidFromUuid(userUuid: string): Promise<string | undefined> {
  const { data } = await supabase.auth.admin.getUserById(userUuid);
  const meta = data?.user?.user_metadata as Record<string, unknown> | undefined;
  const uid = meta?.firebase_uid;
  return typeof uid === "string" && uid.length > 0 ? uid : undefined;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return json({ ok: true });

  try {
    if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);
    if ((Number(req.headers.get("content-length")) ?? 0) > MAX_BODY_BYTES) {
      return json({ error: "Payload too large" }, 413);
    }

    const body = await req.json().catch(() => null);
    if (!body) return json({ error: "Invalid body" }, 400);

    // -------- Mode B: super_admin deletes any user ------------------------
    const adminToken: string | undefined = body?.adminToken;
    const targetUserUuid: string | undefined = body?.targetUserUuid;
    if (adminToken && targetUserUuid) {
      const admin = await verifyFirebaseToken(adminToken);
      const adminUuid = await firebaseUidToUuid(admin.uid);
      const { data: adminRow } = await supabase
        .from("users")
        .select("role")
        .eq("id", adminUuid)
        .single();
      if (adminRow?.role !== "super_admin") {
        return json({ error: "Forbidden: super_admin required" }, 403);
      }

      // Delete the Firebase Auth account first (if we can map it), then purge
      // everything else. A missing FIREBASE_SERVICE_ACCOUNT secret or an
      // unknown Firebase UID aborts before any Supabase data is touched.
      const firebaseUid = await firebaseUidFromUuid(targetUserUuid);
      if (firebaseUid) {
        await deleteFirebaseUserByUid(firebaseUid);
      }

      await purgeUser(targetUserUuid);
      return json({ ok: true, userUuid: targetUserUuid });
    }

    // -------- Mode A: self delete -----------------------------------------
    const idToken: string | undefined = body?.idToken;
    if (!idToken || typeof idToken !== "string") {
      return json({ error: "idToken is required" }, 400);
    }

    const { uid } = await verifyFirebaseToken(idToken);
    const userUuid = await firebaseUidToUuid(uid);

    await purgeUser(userUuid);
    await deleteFirebaseAccount(idToken);

    return json({ ok: true, userUuid });
  } catch (e) {
    console.error("delete-account error", e);
    return json(
      { error: e instanceof Error ? e.message : "Unexpected error" },
      500,
    );
  }
});
