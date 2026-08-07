// Edge Function: send-push
//
// Sends an FCM push notification to all devices of a target user.
//
// The client (Flutter app) calls this with `verify_jwt = true` (it only runs
// from the authenticated app). Using the service role, the function reads the
// recipient's registered device tokens from `device_tokens`, then pushes each
// via the FCM (legacy HTTP) API using the `FCM_SERVER_KEY` secret you must set
// on the Supabase project (`supabase secrets set FCM_SERVER_KEY=...`).

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

    const serverKey = Deno.env.get("FCM_SERVER_KEY") ?? "";
    if (!serverKey) {
      console.error("FCM_SERVER_KEY secret is not configured");
      return json(
        { error: "FCM_SERVER_KEY secret is not configured" },
        500,
      );
    }

    let delivered = 0;
    for (const row of tokens ?? []) {
      const res = await fetch("https://fcm.googleapis.com/fcm/send", {
        method: "POST",
        headers: {
          Authorization: "key=" + serverKey,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          to: row.token,
          notification: { title, body: message, sound: "default" },
          data: { ...dataPayload, click_action: "FLUTTER_NOTIFICATION_CLICK" },
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