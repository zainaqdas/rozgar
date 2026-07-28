import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

interface PushPayload {
  profile_id: string;
  title_en: string;
  title_ur: string;
  body_en: string;
  body_ur: string;
  payload?: Record<string, unknown>;
  type?: string;
}

serve(async (req) => {
  try {
    const body: PushPayload = await req.json();
    const { profile_id, title_en, body_en, payload, type } = body;

    if (!profile_id) {
      return new Response(JSON.stringify({ error: "profile_id required" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: tokens, error } = await supabase
      .from("device_tokens")
      .select("token, platform")
      .eq("profile_id", profile_id);

    if (error || !tokens || tokens.length === 0) {
      return new Response(
        JSON.stringify({ message: "No device tokens", count: 0 }),
        { status: 200, headers: { "Content-Type": "application/json" } },
      );
    }

    const fcmKey = Deno.env.get("FCM_SERVER_KEY");
    if (!fcmKey) {
      return new Response(
        JSON.stringify({ error: "FCM_SERVER_KEY not configured" }),
        { status: 500, headers: { "Content-Type": "application/json" } },
      );
    }

    const results: { token: string; success: boolean }[] = [];

    for (const device of tokens) {
      const fcmPayload = {
        to: device.token,
        notification: {
          title: title_en,
          body: body_en,
        },
        data: {
          type: type ?? "general",
          payload: JSON.stringify(payload ?? {}),
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
      };

      const fcmResponse = await fetch("https://fcm.googleapis.com/fcm/send", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `key=${fcmKey}`,
        },
        body: JSON.stringify(fcmPayload),
      });

      results.push({ token: device.token, success: fcmResponse.ok });
    }

    return new Response(
      JSON.stringify({ sent: results.filter((r) => r.success).length, total: results.length }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    );
  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
