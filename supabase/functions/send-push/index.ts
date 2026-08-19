// Edge Function: send-push
//
// Sends an FCM push notification to all devices of a target user.
//
// The client (Flutter app) calls this with `verify_jwt = true` (it only runs
// from the authenticated app). Using the service role, the function reads the
// recipient's registered device tokens from `device_tokens`, then pushes each
// via the FCM HTTP v1 API, authenticated with the Firebase service account in
// the `FIREBASE_SERVICE_ACCOUNT` secret (the legacy FCM_SERVER_KEY is
// deprecated and no longer exists on new projects).

import { createClient } from "supabase-js";

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

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return json({ ok: true });

  try {
    if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

    const body = await req.json().catch(() => null);
    const userId: string | undefined = body?.userId;
    const title: string | undefined = body?.title;
    const message: string | undefined = body?.message;
    const dataPayload: Record<string, string> = body?.data ?? {};

    if (!userId || typeof userId !== "string") {
      return json({ error: "userId is required" }, 400);
    }
    if (!title || !message) {
      return json({ error: "title and message are required" }, 400);
    }

    const { data: tokens, error } = await supabase
      .from("device_tokens")
      .select("token")
      .eq("user_id", userId);

    if (error) {
      console.error("read tokens error", error);
      return json({ error: error.message }, 500);
    }

    const sa = getServiceAccount();
    const accessToken = await getOAuthToken(sa);
    const projectId = sa.project_id ?? "cargolink-23dd3";
    const fcmUrl =
      `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;

    let delivered = 0;
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
              ...dataPayload,
              click_action: "FLUTTER_NOTIFICATION_CLICK",
            },
          },
        }),
      });
      delivered++;
      if (!res.ok) {
        const text = await res.text();
        console.error("FCM send failed", res.status, text);
      }
    }

    return json({ ok: true, delivered });
  } catch (e) {
    console.error("send-push error", e);
    return json({ error: e instanceof Error ? e.message : "Unexpected error" }, 500);
  }
});