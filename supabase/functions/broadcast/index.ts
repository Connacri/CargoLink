// Edge Function: broadcast
//
// Sends an announcement to EVERY user's device (FCM push) and records the
// announcement in the `broadcasts` table for the in-app feed.
//
// Restricted to `admin` / `super_admin` (founder) roles: the caller's Supabase
// JWT is verified and its role is checked server-side using the service role.
//
// Pushes via the FCM HTTP v1 API, authenticated with the Firebase service
// account in the `FIREBASE_SERVICE_ACCOUNT` secret (the legacy FCM_SERVER_KEY
// is deprecated and no longer exists on new projects).

import { createClient } from "supabase-js";

const ALLOWED_ROLES = ["admin", "super_admin"];

const supabase = createClient(
  Deno.env.get("SUPABASE_URL") ?? "",
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
  { auth: { autoRefreshToken: false, persistSession: false } },
);

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "POST, OPTIONS",
      "Access-Control-Allow-Headers":
        "authorization, x-client-info, apikey, content-type",
    },
  });
}

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
    scope: "https://www.googleapis.com/auth/firebase.messaging",
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

async function callerId(req: Request): Promise<string | null> {
  const authHeader = req.headers.get("Authorization") ?? "";
  const token = authHeader.replace(/^Bearer\s+/i, "").trim();
  if (!token) return null;
  const { data, error } = await supabase.auth.getUser(token);
  if (error || !data.user) return null;
  return data.user.id;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return json({ ok: true });

  try {
    if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

    const callerUserId = await callerId(req);
    if (!callerUserId) return json({ error: "Unauthorized" }, 401);

    const { data: profile } = await supabase
      .from("users")
      .select("role")
      .eq("id", callerUserId)
      .maybeSingle();
    if (!profile || !ALLOWED_ROLES.includes(profile.role)) {
      return json({ error: "Forbidden: admins only" }, 403);
    }

    const body = await req.json().catch(() => null);
    const title: string | undefined = body?.title;
    const message: string | undefined = body?.message;
    const audience: string = body?.audience ?? "all";

    if (!title || !message) {
      return json({ error: "title and message are required" }, 400);
    }

    // Record the announcement.
    const { data: broadcast, error: insertError } = await supabase
      .from("broadcasts")
      .insert({ title, message, audience, created_by: callerUserId })
      .select("id")
      .single();
    if (insertError) {
      return json({ error: insertError.message }, 500);
    }

    try {
      const sa = getServiceAccount();
      const accessToken = await getOAuthToken(sa);
      const projectId = sa.project_id ?? "cargolink-23dd3";
      const fcmUrl =
        `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;

      const { data: tokens } = await supabase
        .from("device_tokens")
        .select("token");

      for (const row of tokens ?? []) {
        const res = await fetch(fcmUrl, {
          method: "POST",
          headers: {
            Authorization: `Bearer ${accessToken}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            message: {
              token: row.token,
              notification: { title, body: message },
              data: {
                type: "broadcast",
                broadcastId: broadcast?.id,
                click_action: "FLUTTER_NOTIFICATION_CLICK",
              },
            },
          }),
        });
        if (!res.ok) console.error("FCM send failed", await res.text());
      }
    } catch (e) {
      console.error("FCM push skipped", e);
    }

    return json({ ok: true, id: broadcast.id });
  } catch (e) {
    console.error("broadcast error", e);
    return json({ error: e instanceof Error ? e.message : "Unexpected error" }, 500);
  }
});