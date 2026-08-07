// Edge Function: broadcast
//
// Sends an announcement to EVERY user's device (FCM push) and records the
// announcement in the `broadcasts` table for the in-app feed.
//
// Restricted to `admin` / `super_admin` (founder) roles: the caller's Supabase
// JWT is verified and its role is checked server-side using the service role.
//
// Requires the `FCM_SERVER_KEY` secret on the project:
//   supabase secrets set FCM_SERVER_KEY=...

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

    const callerUserId = await callerOf(req);
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

    const serverKey = Deno.env.get("FCM_SERVER_KEY") ?? "";
    if (serverKey) {
      const { data: tokens } = await supabase
        .from("device_tokens")
        .select("token");

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
            data: {
              type: "broadcast",
              broadcastId: broadcast?.id,
              click_action: "FLUTTER_NOTIFICATION_CLICK",
            },
          }),
        });
        if (!res.ok) console.error("FCM send failed", await res.text());
      }
    } else {
      console.warn("FCM_SERVER_KEY is not configured; no push sent.");
    }

    return json({ ok: true, id: broadcast.id });
  } catch (e) {
    console.error("broadcast error", e);
    return json({ error: e instanceof Error ? e.message : "Unexpected error" }, 500);
  }
});