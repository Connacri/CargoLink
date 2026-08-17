// Edge Function: request-account-deletion
//
// Called from the public web page (GitHub Pages) after the user signs in with
// Firebase (email/password OR Google). It:
//   1. Verifies the Firebase ID token (proves the account belongs to the user).
//   2. Maps the Firebase UID to the deterministic Supabase UUID (UUID v5).
//   3. Ensures a profile exists in public.users.
//   4. Inserts a row in account_deletion_requests (status 'pending') for the
//      super admin to review.
//
// JWT verification is disabled: this function does its own authn via the
// Firebase token.

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

async function verifyFirebaseToken(idToken: string): Promise<{
  uid: string;
  email?: string;
}> {
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
  const user = data.users[0];
  return {
    uid: user.localId as string,
    email: user.email as string | undefined,
  };
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return json({ ok: true });

  try {
    if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);
    if ((Number(req.headers.get("content-length")) ?? 0) > MAX_BODY_BYTES) {
      return json({ error: "Payload too large" }, 413);
    }

    const body = await req.json().catch(() => null);
    const idToken: string | undefined = body?.idToken;
    if (!idToken || typeof idToken !== "string") {
      return json({ error: "idToken is required" }, 400);
    }

    // Verify the Firebase token (proves account ownership).
    const { uid, email } = await verifyFirebaseToken(idToken);
    const userUuid = await firebaseUidToUuid(uid);

    // Ensure a profile exists.
    const { data: profile } = await supabase
      .from("users")
      .select("id, full_name, role, email")
      .eq("id", userUuid)
      .maybeSingle();

    if (!profile) {
      return json({ error: "Aucun compte CargoLink associé" }, 404);
    }

    // Reject duplicate pending requests for the same user.
    const { data: existing } = await supabase
      .from("account_deletion_requests")
      .select("id, status")
      .eq("user_id", userUuid)
      .eq("status", "pending")
      .maybeSingle();

    if (existing) {
      return json({ error: "Une demande est déjà en attente de validation" }, 409);
    }

    const { data: inserted, error: insertError } = await supabase
      .from("account_deletion_requests")
      .insert({
        user_id: userUuid,
        email: profile.email ?? email ?? "",
        full_name: profile.full_name,
        role: profile.role,
        status: "pending",
      })
      .select()
      .single();

    if (insertError) {
      console.error("insert request error", insertError);
      return json({ error: insertError.message }, 500);
    }

    return json({
      ok: true,
      requestId: inserted.id,
      message: "Demande enregistrée, en attente de validation",
    });
  } catch (e) {
    console.error("request-account-deletion error", e);
    return json(
      { error: e instanceof Error ? e.message : "Unexpected error" },
      500,
    );
  }
});