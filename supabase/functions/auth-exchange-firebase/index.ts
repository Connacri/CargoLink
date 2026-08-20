// Edge Function: auth-exchange-firebase
//
// Exchanges a Firebase ID token for a Supabase access token so the Flutter app
// can talk to Supabase (DB + Storage) as the authenticated Firebase user.
//
// How it works:
//   1. Verifies the Firebase ID token with Firebase Auth's REST API
//      (accounts:lookup). NOTE: google's oauth2 tokeninfo endpoint does NOT
//      validate Firebase ID tokens (iss=securetoken.google.com) and returns
//      "Invalid Value" for them, so it cannot be used here.
//   2. Maps the Firebase UID to a deterministic UUID (UUID v5) using the exact
//      same derivation as lib/auth_service.dart (`cargolink:<uid>` in namespace
//      `6ba7b810-9dad-11d1-80b4-00c04fd430c8`).
//   3. Ensures a matching Supabase auth user exists (id == that UUID) with a
//      deterministic password derived from the secret key. If the Firebase
//      email is already claimed by another Supabase auth user (e.g. a manually
//      created account), the mirror is created under a collision-free
//      `uid@cargolink.app` auth email instead — the real email is preserved in
//      user_metadata and in the public.users profile written by the app.
//   4. Signs that user in to obtain a real Supabase access token whose `sub`
//      equals the UUID, so every RLS policy on `auth.uid()` matches the rows
//      the client reads/writes. If the deterministic sign-in fails (stale
//      password from an older derivation), the password is reset server-side
//      and the sign-in retried once.
//
// JWT verification is disabled for this function: it does its own authn.

import { createClient } from "supabase-js";

const UUID_NAMESPACE = "6ba7b810-9dad-11d1-80b4-00c04fd430c8";
const NAME_PREFIX = "cargolink:";
const MAX_BODY_BYTES = 64 * 1024;

// Firebase Web API key for the cargolink-23dd3 project. It is a publishable
// key (also embedded in lib/firebase_options.dart) so it can live here.
const FIREBASE_API_KEY =
  Deno.env.get("FIREBASE_WEB_API_KEY") ??
  "AIzaSyBwB45_WiSmsUVO04cg8IuHBoK53wRBYo4";

// Secret key: prefer the new `SUPABASE_SECRET_KEYS` dictionary, fall back to
// the legacy `SUPABASE_SERVICE_ROLE_KEY`. Never exposed to the client.
function getSecretKey(): string {
  const legacy = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (legacy) return legacy;
  const secretKeys = Deno.env.get("SUPABASE_SECRET_KEYS");
  if (secretKeys) {
    try {
      const parsed = JSON.parse(secretKeys) as Record<string, string>;
      return parsed["default"] ?? Object.values(parsed)[0] ?? "";
    } catch {
      // malformed env var — fall through to empty key
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
  const key = getSecretKey();
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
  // accounts:lookup is the official way to verify a Firebase ID token server
  // side. tokeninfo would NOT work here (it rejects Firebase tokens).
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
    console.error(`lookup failed: HTTP ${res.status} ${msg}`);
    throw new Error(msg);
  }
  const user = data.users[0];
  console.error(`lookup ok: uid=${user.localId} email=${user.email}`);
  return {
    uid: user.localId as string,
    email: user.email as string | undefined,
  };
}

// Ensure a Supabase auth user exists whose id == the deterministic uuid. If the
// real email is already claimed by a non-deterministic user, use the
// collision-free `uid@cargolink.app` auth email (real email stays in metadata).
async function ensureSupabaseUser(
  uid: string,
  email: string | undefined,
  password: string,
  userUuid: string,
): Promise<{ email: string }> {
  const { data: existing } = await supabase.auth.admin.getUserById(userUuid);
  if (existing?.user) {
    return { email: existing.user.email ?? email ?? `${uid}@cargolink.app` };
  }

  const createEmail = email ?? `${uid}@cargolink.app`;
  const { error: createError } = await supabase.auth.admin.createUser({
    id: userUuid,
    email: createEmail,
    email_confirm: true,
    password,
    user_metadata: { firebase_uid: uid },
  });

  if (createError) {
    const msg = createError.message ?? "";
    // Race-safe: two concurrent exchanges (startup restore + idTokenChanges)
    // can both pass the getUserById check above and then both call createUser
    // with the SAME deterministic id. The loser gets a primary-key conflict
    // which GoTrue surfaces as the generic "Database error creating new user"
    // (not the email-specific "already registered" message). Before giving up,
    // re-check: if the mirror now exists the other request won the race and we
    // can proceed as if WE had created it.
    const { data: raced } = await supabase.auth.admin.getUserById(userUuid);
    if (raced?.user) {
      return { email: raced.user.email ?? createEmail };
    }
    if (!/already/i.test(msg)) {
      console.error("createUser error", createError);
      throw createError;
    }
    // Email taken by a user whose id is NOT our deterministic uuid (e.g. a
    // manually created admin account). Don't hijack it: mirror the Firebase
    // user under a deterministic, collision-free auth email. Users never log
    // into Supabase directly, so the real email is kept in metadata and in the
    // public.users profile (written by the app with the Firebase email).
    const altEmail = `${uid}@cargolink.app`;
    const { error: altError } = await supabase.auth.admin.createUser({
      id: userUuid,
      email: altEmail,
      email_confirm: true,
      password,
      user_metadata: { firebase_uid: uid, real_email: email },
    });
    if (altError) {
      console.error("alt createUser error", altError);
      throw altError;
    }
    return { email: altEmail };
  }
  return { email: createEmail };
}

// Sign the mirror user in. If the deterministic password no longer matches
// (e.g. the user was created with an older password derivation), reset the
// password server-side and retry once. Returns the session.
async function signInOrRepair(
  userUuid: string,
  email: string,
  password: string,
): Promise<{ access_token: string; refresh_token: string }> {
  const attempt = await supabase.auth.signInWithPassword({ email, password });
  if (attempt.data?.session) {
    return {
      access_token: attempt.data.session.access_token,
      refresh_token: attempt.data.session.refresh_token,
    };
  }
  if (attempt.error) {
    console.error("signIn failed, repairing password", attempt.error);
  }

  const { error: resetError } = await supabase.auth.admin.updateUserById(
    userUuid,
    { password },
  );
  if (resetError) {
    console.error("password reset error", resetError);
    throw resetError;
  }

  const retry = await supabase.auth.signInWithPassword({ email, password });
  if (retry.error || !retry.data?.session) {
    console.error("signIn retry error", retry.error);
    throw retry.error ?? new Error("Sign in failed");
  }
  return {
    access_token: retry.data.session.access_token,
    refresh_token: retry.data.session.refresh_token,
  };
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return json({ ok: true });

  try {
    if (req.method !== "POST") {
      return json({ error: "Method not allowed" }, 405);
    }
    if ((Number(req.headers.get("content-length")) ?? 0) > MAX_BODY_BYTES) {
      return json({ error: "Payload too large" }, 413);
    }

    const body = await req.json().catch(() => null);
    const idToken: string | undefined = body?.idToken;
    if (!idToken || typeof idToken !== "string") {
      return json({ error: "idToken is required" }, 400);
    }

    const { uid, email } = await verifyFirebaseToken(idToken);
    const userUuid = await firebaseUidToUuid(uid);
    const password = await derivePassword(uid);

    // Ensure the Supabase auth user exists with the deterministic id, then
    // sign in to obtain a real access token (sub == userUuid).
    const { email: emailForSignIn } = await ensureSupabaseUser(
      uid,
      email,
      password,
      userUuid,
    );
    const session = await signInOrRepair(userUuid, emailForSignIn, password);

    return json({
      accessToken: session.access_token,
      refreshToken: session.refresh_token,
      userUuid,
      email: emailForSignIn,
    });
  } catch (e) {
    console.error("auth-exchange-firebase error", e);
    return json({ error: e instanceof Error ? e.message : "Unexpected error" }, 500);
  }
});
