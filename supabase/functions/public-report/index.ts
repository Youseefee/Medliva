import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "content-type",
  "Access-Control-Allow-Methods": "GET, OPTIONS",
  "Cache-Control": "no-store",
  "X-Content-Type-Options": "nosniff",
};

Deno.serve(async (request: Request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "GET") {
    return Response.json({ error: "Method not allowed" }, {
      status: 405,
      headers: corsHeaders,
    });
  }

  const token = new URL(request.url).searchParams.get("token");
  if (!token || !/^[A-Za-z0-9_-]{40,100}$/.test(token)) {
    return Response.json({ error: "Report link is invalid or expired" }, {
      status: 404,
      headers: corsHeaders,
    });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceRoleKey) {
    return Response.json({ error: "Report service unavailable" }, {
      status: 503,
      headers: corsHeaders,
    });
  }

  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const { data, error } = await admin.rpc("get_public_report", {
    p_token: token,
  });

  if (error || !data) {
    return Response.json({ error: "Report link is invalid or expired" }, {
      status: 404,
      headers: corsHeaders,
    });
  }

  return Response.json(data, { headers: corsHeaders });
});
