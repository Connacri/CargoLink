// Edge Function: admin-reset
//
// Factory reset tools for the founder (super_admin).
//
// Body: { adminToken, mode }
//   adminToken : fresh Firebase ID token of the caller (verified as super_admin)
//   mode       : 'tables'   -> wipe all public tables + uploaded files (auth kept)
//                'accounts' -> delete EVERY auth account (Firebase + Supabase Auth)
//                'full'     -> accounts first, then tables + storage
//
// Deletion is server-side (service role) and only reachable by a super_admin.

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
  { auth: { autoRefreshToken: false, persistSession: false } },
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
  for (let i = 0; i < out.length; i++) out[i] = parseInt(hex.substring(i * 2, i * 2 + 2), 16);
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
  return [hex.slice(0, 8), hex.slice(8, 12), hex.slice(12, 16), hex.slice(16, 20), hex.slice(20, 32)].join("-");
}

async function verifyFirebaseToken(idToken: string): Promise<{ uid: string }> {
  const res = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=${FIREBASE_API_KEY}`,
    { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ idToken }) },
  );
  const data = await res.json().catch(() => ({}));
  if (!res.ok || !data.users?.[0]) {
    throw new Error((data.error?.message as string) ?? "Invalid Firebase ID token");
  }
  return { uid: data.users[0].localId as string };
}

// ---------------------------------------------------------------------------
// Storage purge — recursive folder walk across ALL buckets.
// ---------------------------------------------------------------------------

async function listFolderRecursive(
  bucket: string,
  folder: string,
): Promise<string[]> {
  const files: string[] = [];
  const queue: string[] = [folder];
  while (queue.length > 0) {
    const current = queue.shift()!;
    let offset = 0;
    for (;;) {
      const { data, error } = await supabase.storage
        .from(bucket)
        .list(current, { limit: 1000, offset, sortBy: { column: "name", order: "asc" } });
      if (error) {
        console.error(`list ${bucket}/${current} error`, error.message);
        break;
      }
      const items = data ?? [];
      for (const item of items) {
        const path = current ? `${current}/${item.name}` : item.name;
        if (item.id === null) {
          queue.push(path);
        } else {
          files.push(path);
        }
      }
      if (items.length < 1000) break;
      offset += 1000;
    }
  }
  return files;
}

async function purgeFolder(bucket: string, folder: string): Promise<number> {
  try {
    const files = await listFolderRecursive(bucket, folder);
    let removed = 0;
    for (let i = 0; i < files.length; i += 400) {
      const chunk = files.slice(i, i + 400);
      const { error } = await supabase.storage.from(bucket).remove(chunk);
      if (error) {
        console.error(`remove ${bucket}/${folder} error`, error.message);
      } else {
        removed += chunk.length;
      }
    }
    return removed;
  } catch (e) {
    console.error(`purgeFolder ${bucket}/${folder} error`, e);
    return 0;
  }
}

// Removes every uploaded file across all buckets (recursive).
async function purgeAllStorage(): Promise<number> {
  let removed = 0;
  const { data: buckets, error } = await supabase.storage.listBuckets();
  if (error) throw new Error(error.message);
  for (const bucket of buckets ?? []) {
    removed += await purgeFolder(bucket.name, "");
  }
  return removed;
}

// ---------------------------------------------------------------------------
// Firebase Auth (Identity Toolkit REST, no extra SDK needed)
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

function pemToDer(pem: string): ArrayBuffer {
  const body = pem
    .replace(/-----BEGIN [^-]+-----/g, "")
    .replace(/-----END [^-]+-----/g, "")
    .replace(/\s+/g, "");
  return b64UrlToBytes(body).buffer;
}

interface ServiceAccount {
  client_email?: string;
  private_key?: string;
  project_id?: string;
  token_uri?: string;
}

function getServiceAccount(): ServiceAccount {
  const raw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
  if (!raw) throw new Error("FIREBASE_SERVICE_ACCOUNT secret is not configured");
  const sa = JSON.parse(raw) as ServiceAccount;
  if (!sa.private_key || !sa.client_email) throw new Error("FIREBASE_SERVICE_ACCOUNT missing private_key/client_email");
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
  const signature = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, te.encode(signingInput));
  return `${signingInput}.${base64UrlEncode(new Uint8Array(signature))}`;
}

async function getOAuthToken(sa: ServiceAccount): Promise<string> {
  const jwt = await createSignedJwt(sa);
  const res = await fetch(sa.token_uri ?? "https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({ grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer", assertion: jwt }).toString(),
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok || !data.access_token) {
    throw new Error((data.error_description as string) ?? (data.error as string) ?? `OAuth failed (HTTP ${res.status})`);
  }
  return data.access_token as string;
}

// ---------------------------------------------------------------------------
// Complete enumeration of Firebase users via accounts:query.
//
// Prefers the accounts:query (search users) endpoint over the legacy
// accounts:batchGet: the latter's nextPageToken is unreliable and can silently
// MISS pages, so accounts would be left behind. accounts:query paginates
// correctly and is what the Admin SDK uses under the hood.
// ---------------------------------------------------------------------------
async function listFirebaseUsers(token: string, sa: ServiceAccount): Promise<string[]> {
  const projectId = sa.project_id ?? "cargolink-23dd3";
  const out: string[] = [];
  let pageToken: string | undefined;
  for (;;) {
    const body: Record<string, unknown> = { maxResults: 500 };
    if (pageToken) body.pageToken = pageToken;
    const res = await fetch(
      `https://identitytoolkit.googleapis.com/v1/projects/${projectId}/accounts:query`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` },
        body: JSON.stringify(body),
      },
    );
    const data = await res.json().catch(() => ({}));
    if (!res.ok) throw new Error((data.error?.message as string) ?? `List users failed (HTTP ${res.status})`);
    for (const u of (data.users ?? [])) {
      if (u?.localId) out.push(u.localId as string);
    }
    pageToken = data.nextPageToken as string | undefined;
    if (!pageToken) break;
  }
  return out;
}

async function batchDeleteFirebaseUsers(token: string, sa: ServiceAccount, localIds: string[]): Promise<number> {
  const projectId = sa.project_id ?? "cargolink-23dd3";
  let deleted = 0;
  for (let i = 0; i < localIds.length; i += 500) {
    const chunk = localIds.slice(i, i + 500);
    const res = await fetch(
      `https://identitytoolkit.googleapis.com/v1/projects/${projectId}/accounts:batchDelete`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` },
        body: JSON.stringify({ localIds: chunk }),
      },
    );
    const data = await res.json().catch(() => ({}));
    if (res.ok) {
      deleted += chunk.length;
    } else if (data.error?.message !== "USER_NOT_FOUND") {
      console.error("batchDelete failed", res.status, data.error?.message);
    }
  }
  return deleted;
}

// ---------------------------------------------------------------------------
// Supabase Auth: delete every mirror account one by one, then verify empties.
// ---------------------------------------------------------------------------
async function deleteSupabaseAuthUsers(): Promise<{ deleted: number; remaining: number }> {
  let deleted = 0;
  for (let page = 1; ; page++) {
    const { data, error } = await supabase.auth.admin.listUsers({ page, perPage: 1000 });
    if (error) throw new Error(error.message);
    const users = data?.users ?? [];
    if (users.length === 0) break;
    for (const u of users) {
      const { error: delErr } = await supabase.auth.admin.deleteUser(u.id);
      if (delErr) console.error("delete supabase auth user failed", u.id, delErr.message);
      else deleted++;
    }
    if (users.length < 1000) break;
  }
  let remaining = 0;
  for (let page = 1; ; page++) {
    const { data } = await supabase.auth.admin.listUsers({ page, perPage: 1000 });
    const users = data?.users ?? [];
    remaining += users.length;
    if (users.length < 1000) break;
  }
  return { deleted, remaining };
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return json({ ok: true });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);
  if ((Number(req.headers.get("content-length")) ?? 0) > MAX_BODY_BYTES) {
    return json({ error: "Payload too large" }, 413);
  }

  try {
    const body = await req.json().catch(() => null);
    if (!body) return json({ error: "Invalid body" }, 400);

    const adminToken: string | undefined = body?.adminToken;
    const mode: string | undefined = body?.mode;
    if (!adminToken || typeof adminToken !== "string") {
      return json({ error: "adminToken is required" }, 400);
    }
    if (!["tables", "accounts", "full"].includes(mode ?? "")) {
      return json({ error: "mode must be tables | accounts | full" }, 400);
    }

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

    let accountsDeleted = 0;
    let firebaseUsersRemaining = -1;
    let supabaseUsersRemaining = -1;
    let tablesWiped = false;
    let filesRemoved = 0;

    if (mode === "accounts" || mode === "full") {
      const sa = getServiceAccount();
      const token = await getOAuthToken(sa);

      const firebaseUids = await listFirebaseUsers(token, sa);
      accountsDeleted = await batchDeleteFirebaseUsers(token, sa, firebaseUids);

      // Confirm Firebase Authentication is empty afterwards (nothing forgotten).
      const remainingFirebase = await listFirebaseUsers(token, sa);
      firebaseUsersRemaining = remainingFirebase.length;

      const supabaseResult = await deleteSupabaseAuthUsers();
      accountsDeleted += supabaseResult.deleted;
      supabaseUsersRemaining = supabaseResult.remaining;
    }

    if (mode === "tables" || mode === "full") {
      const { error } = await supabase.rpc("admin_reset_tables");
      if (error) throw new Error(`admin_reset_tables failed: ${error.message}`);
      tablesWiped = true;
      filesRemoved = await purgeAllStorage();
    }

    return json({
      ok: true,
      mode,
      accountsDeleted,
      firebaseUsersRemaining,
      supabaseUsersRemaining,
      firebaseAuthEmptied: firebaseUsersRemaining === 0,
      supabaseAuthEmptied: supabaseUsersRemaining === 0,
      tablesWiped,
      filesRemoved,
    });
  } catch (e) {
    console.error("admin-reset error", e);
    return json({ error: e instanceof Error ? e.message : "Unexpected error" }, 500);
  }
});