import { createClient } from "jsr:@supabase/supabase-js@2";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL") ?? "",
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
);

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }
  // Trigger-based auth: the cron (through the DB shim) sends a Bearer token
  // that must match the FCM_CRON_TRIGGER vault secret (checked in the DB RPC).
  const bearer = (req.headers.get("Authorization") ?? "")
    .replace(/^Bearer\s+/i, "")
    .trim();
  if (!bearer) return json({ error: "Unauthorized" }, 401);

  const { data: creds, error: rerr } = await supabase.rpc(
    "fcm_edge_refresh_credentials",
    { p_trigger: bearer },
  );
  if (rerr || !creds?.client_id || !creds?.client_secret || !creds?.refresh_token) {
    return json({ error: "Forbidden" }, 403);
  }

  const body = new URLSearchParams({
    grant_type: "refresh_token",
    client_id: creds.client_id,
    client_secret: creds.client_secret,
    refresh_token: creds.refresh_token,
  });

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body,
  });
  if (!res.ok) {
    const text = await res.text();
    return json({ error: "oauth HTTP " + res.status, detail: text }, 502);
  }
  const tok = await res.json();
  const access: string | undefined = tok.access_token;
  const expires = Number(tok.expires_in ?? 3600);
  if (!access) return json({ error: "missing access_token" }, 502);

  const { error: upErr } = await supabase
    .from("fcm_token_cache")
    .upsert(
      {
        singleton: true,
        access_token: access,
        expires_at: new Date(
          Date.now() + Math.max(expires - 60, 60) * 1000,
        ).toISOString(),
      },
      { onConflict: "singleton" },
    );
  if (upErr) {
    return json({ error: upErr.message }, 500);
  }

  return json({ ok: true });
});