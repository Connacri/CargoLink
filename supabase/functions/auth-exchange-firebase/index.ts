// Edge Function: auth-exchange-firebase
//
// Exchanges a Firebase ID token for a Supabase access token so the Flutter app
// can talk to Supabase (DB + Storage) as the authenticated Firebase user.
//
// How it works:
//   1. Verifies the Firebase ID token with Google's tokeninfo endpoint.
//   2. Maps the Firebase UID to a deterministic UUID (UUID v5) using the exact
//      same derivation as lib/auth_service.dart (`cargolink:<uid>` in namespace
//      `6ba7b810-9dad-11d1-80b4-00c04fd430c8`).
//   3. Ensures a matching Supabase auth user exists (id == that UUID) with a
//      deterministic password derived from the service-role key.
//   4. Signs that user in to obtain a real Supabase access token whose `sub`
//      equals the UUID, so every RLS policy on `auth.uid()` matches the rows
//      the client reads/writes.
//
// JWT verification is disabled for this function: it does its own authn.

import { createClient } from "supabase-js";

const UUID_NAMESPACE = "6ba7b810-9dad-11d1-80b4-00c04fd430c8";
const NAME_PREFIX = "cargolink:";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL") ?? "",
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
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

// Deterministic UUID v5 — MUST match lib/auth_service.dart
// (supabaseUserIdFromFirebase). Fallback implementation below avoids an extra
// dependency by reimplementing RFC 4122 UUIDv5 with WebCrypto.
async function firebaseUidToUuid(firebaseUid: string): Promise<string> {
  const name = NAME_PREFIX + firebaseUid;
  const namespaceBytes = hexToBytes(UUID_NAMESPACE.replace(/-/g, ""));
  const te = new TextEncoder();
  const buf = new Uint8Array(16 + te.encode(name).length);
  buf.set(namespaceBytes, 0);
  buf.set(te.encode(name), 16);
  const digest = await crypto.subtle.digest("SHA-1", buf);
  const bytes = new Uint8Array(digest);
  bytes[6] = (bytes[6] & 0x0f) | 0x50; // version 5
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // RFC 4122 variant
  const hex = [...bytes].map((b) => b.toString(16).padStart(2, "0")).join("");
  return [
    hex.slice(0, 8),
    hex.slice(8, 12),
    hex.slice(12, 16),
    hex.slice(16, 20),
    hex.slice(20, 32),
  ].join("-");
}

function hexToBytes(hex: string): Uint8Array {
  const out = new Uint8Array(hex.length / 2);
  for (let i = 0; i < out.length; i++) {
    out[i] = parseInt(hex.substring(i * 2, i * 2 + 2), 16);
  }
  return out;
}

// Deterministic, server-only password for the mirrored Supabase auth user.
async function derivePassword(firebaseUid: string): Promise<string> {
  const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  const te = new TextEncoder();
  const hmacKey = await crypto.subtle.importKey(
    "raw",
    te.encode("cargolink-pw:" + key),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign("HMAC", hmacKey, te.encode(firebaseUid));
  return [...new Uint8Array(sig)]
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("")
    .slice(0, 32);
}

async function verifyFirebaseToken(idToken: string): Promise<{
  uid: string;
  email?: string;
}> {
  const res = await fetch(
    `https://oauth2.googleapis.com/tokeninfo?id_token=${encodeURIComponent(idToken)}`,
  );
  const data = await res.json();
  if (!res.ok || !data.sub) {
    throw new Error(data.error_description ?? data.error ?? "Invalid Firebase ID token");
  }
  return { uid: data.sub as string, email: data.email };
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return json({ ok: true });

  try {
    if (req.method !== "POST") {
      return json({ error: "Method not allowed" }, 405);
    }

    const body = await req.json().catch(() => null);
    const idToken: string | undefined = body?.idToken;
    if (!idToken || typeof idToken !== "string") {
      return json({ error: "idToken is required" }, 400);
    }

    const { uid, email } = await verifyFirebaseToken(idToken);
    const userUuid = await firebaseUidToUuid(uid);
    const password = await derivePassword(uid);

    // Ensure the Supabase auth user exists with the deterministic id.
    const { data: existing } = await supabase.auth.admin.getUserById(userUuid);
    if (!existing?.user) {
      const { error: createError } = await supabase.auth.admin.createUser({
        id: userUuid,
        email: email ?? `${uid}@cargolink.app`,
        email_confirm: true,
        password,
        user_metadata: { firebase_uid: uid },
      });
      if (createError) {
        console.error("createUser error", createError);
        return json({ error: createError.message }, 500);
      }
    }

    // Sign in to obtain a real access token (sub == userUuid).
    const { data: signIn, error: signInError } = await supabase.auth.signInWithPassword(
      {
        email: email ?? `${uid}@cargolink.app`,
        password,
      },
    );
    if (signInError || !signIn.session) {
      console.error("signIn error", signInError);
      return json({ error: signInError?.message ?? "Sign in failed" }, 500);
    }

    return json({
      accessToken: signIn.session.access_token,
      refreshToken: signIn.session.refresh_token,
      userUuid,
      email: email ?? `${uid}@cargolink.app`,
    });
  } catch (e) {
    console.error("auth-exchange-firebase error", e);
    return json({ error: e instanceof Error ? e.message : "Unexpected error" }, 500);
  }
});
