import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, x-client-info, content-type",
  "Access-Control-Allow-Methods": "GET, OPTIONS",
  "Cache-Control": "no-store",
  "X-Content-Type-Options": "nosniff",
};

const htmlHeaders = {
  ...corsHeaders,
  "Content-Type": "text/html; charset=utf-8",
  "Content-Security-Policy":
    "default-src 'none'; style-src 'unsafe-inline'; script-src 'unsafe-inline'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'",
  "Referrer-Policy": "no-referrer",
};

type PublicMedication = {
  name?: string | null;
  dose_form?: string | null;
  strength?: string | null;
  stock_count?: number | null;
  times?: string[] | null;
};

type PublicVital = {
  type?: string | null;
  value_primary?: number | null;
  value_secondary?: number | null;
  meal_context?: string | null;
  band?: string | null;
  recorded_at?: string | null;
};

type PublicIntakeLog = {
  scheduled_time?: string | null;
  actual_time?: string | null;
  status?: string | null;
  reason?: string | null;
};

type PublicReportData = {
  patient_name?: string | null;
  patient_phone?: string | null;
  adherence_rate_pct?: number | null;
  total_doses?: number | null;
  taken_doses?: number | null;
  missed_doses_count?: number | null;
  active_medications?: PublicMedication[] | null;
  recent_vitals?: PublicVital[] | null;
  recent_intake_logs?: PublicIntakeLog[] | null;
};

function escapeHtml(value: unknown): string {
  const str = value === null || value === undefined ? "" : String(value);
  return str
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

function formatDateTime(iso: string | null | undefined): string {
  if (!iso) return "—";
  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) return escapeHtml(iso);
  const y = date.getUTCFullYear();
  const m = String(date.getUTCMonth() + 1).padStart(2, "0");
  const d = String(date.getUTCDate()).padStart(2, "0");
  const hh = String(date.getUTCHours()).padStart(2, "0");
  const mm = String(date.getUTCMinutes()).padStart(2, "0");
  return `${y}-${m}-${d} ${hh}:${mm} UTC`;
}

function vitalTypeLabel(type: string | null | undefined): string {
  switch ((type ?? "").toLowerCase()) {
    case "bp":
      return "ضغط الدم / Blood Pressure";
    case "glucose":
      return "سكر الدم / Blood Glucose";
    case "pulse":
      return "النبض / Pulse";
    default:
      return escapeHtml(type || "—");
  }
}

function bandBadge(band: string | null | undefined): string {
  switch ((band ?? "").toLowerCase()) {
    case "critical":
      return '<span class="badge badge-critical">حرج • CRITICAL</span>';
    case "borderline":
      return '<span class="badge badge-borderline">حدّي • BORDERLINE</span>';
    default:
      return '<span class="badge badge-normal">طبيعي • NORMAL</span>';
  }
}

function intakeStatusBadge(status: string | null | undefined): string {
  switch ((status ?? "").toLowerCase()) {
    case "taken":
      return '<span class="badge badge-normal">تم التناول • TAKEN</span>';
    case "missed":
      return '<span class="badge badge-critical">فائتة • MISSED</span>';
    case "skipped":
      return '<span class="badge badge-borderline">متخطاة • SKIPPED</span>';
    case "snoozed":
      return '<span class="badge badge-borderline">مؤجلة • SNOOZED</span>';
    default:
      return `<span class="badge">${escapeHtml(status || "—")}</span>`;
  }
}

function renderErrorHtml(titleAr: string, titleEn: string, messageAr: string, messageEn: string): string {
  return `<!doctype html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Medliva — ${escapeHtml(titleEn)}</title>
  <style>
    body { font-family: system-ui, -apple-system, "Segoe UI", Tahoma, Arial, sans-serif; background: #f4f7f6; color: #16302b; margin: 0; padding: 24px; display: flex; align-items: center; justify-content: center; min-height: 100vh; box-sizing: border-box; }
    .card { background: #fff; border: 1px solid #d9e6e2; border-radius: 16px; padding: 32px; max-width: 520px; width: 100%; text-align: center; box-shadow: 0 4px 16px rgba(0,0,0,0.06); }
    .brand { color: #00695c; font-weight: 700; font-size: 18px; margin-bottom: 12px; }
    h1 { margin: 0 0 8px; font-size: 22px; color: #b71c1c; }
    h2 { margin: 0 0 16px; font-size: 16px; color: #546e7a; font-weight: 600; direction: ltr; }
    p { margin: 6px 0; line-height: 1.6; font-size: 15px; }
    .en { direction: ltr; color: #455a64; }
  </style>
</head>
<body>
  <main class="card">
    <div class="brand">Medliva • ميدليفا</div>
    <h1>${escapeHtml(titleAr)}</h1>
    <h2>${escapeHtml(titleEn)}</h2>
    <p>${escapeHtml(messageAr)}</p>
    <p class="en">${escapeHtml(messageEn)}</p>
  </main>
</body>
</html>`;
}

function renderReportHtml(report: PublicReportData): string {
  const patientName = escapeHtml(report.patient_name || "مريض Medliva");
  const patientPhone = report.patient_phone ? escapeHtml(report.patient_phone) : "غير مسجل / Not provided";
  const adherencePct = typeof report.adherence_rate_pct === "number"
    ? report.adherence_rate_pct.toFixed(1)
    : "100.0";
  const totalDoses = Number(report.total_doses ?? 0);
  const takenDoses = Number(report.taken_doses ?? 0);
  const missedDoses = Number(report.missed_doses_count ?? 0);

  const medications = Array.isArray(report.active_medications) ? report.active_medications : [];
  const vitals = Array.isArray(report.recent_vitals) ? report.recent_vitals : [];
  const logs = Array.isArray(report.recent_intake_logs) ? report.recent_intake_logs : [];

  const medsRows = medications.length > 0
    ? medications.map((med) => {
      const times = Array.isArray(med.times) && med.times.length > 0
        ? med.times.map((t) => escapeHtml(t)).join(", ")
        : "—";
      return `<tr>
        <td><strong>${escapeHtml(med.name || "—")}</strong></td>
        <td>${escapeHtml(med.strength || "—")}</td>
        <td>${escapeHtml(med.dose_form || "—")}</td>
        <td dir="ltr">${times}</td>
        <td>${escapeHtml(med.stock_count ?? "—")}</td>
      </tr>`;
    }).join("")
    : `<tr><td colspan="5" class="empty">لا توجد أدوية نشطة • No active medications</td></tr>`;

  const vitalsRows = vitals.length > 0
    ? vitals.map((vital) => {
      const val = vital.value_secondary !== null && vital.value_secondary !== undefined
        ? `${escapeHtml(vital.value_primary)} / ${escapeHtml(vital.value_secondary)}`
        : escapeHtml(vital.value_primary ?? "—");
      return `<tr>
        <td>${vitalTypeLabel(vital.type)}</td>
        <td dir="ltr"><strong>${val}</strong></td>
        <td>${escapeHtml(vital.meal_context || "—")}</td>
        <td>${bandBadge(vital.band)}</td>
        <td dir="ltr">${formatDateTime(vital.recorded_at)}</td>
      </tr>`;
    }).join("")
    : `<tr><td colspan="5" class="empty">لا توجد قياسات مسجلة • No recorded vitals</td></tr>`;

  const logsRows = logs.length > 0
    ? logs.map((log) => `<tr>
      <td dir="ltr">${formatDateTime(log.scheduled_time)}</td>
      <td dir="ltr">${formatDateTime(log.actual_time)}</td>
      <td>${intakeStatusBadge(log.status)}</td>
      <td>${escapeHtml(log.reason || "—")}</td>
    </tr>`).join("")
    : `<tr><td colspan="4" class="empty">لا توجد سجلات جرعات خلال آخر 30 يوماً • No intake logs in last 30 days</td></tr>`;

  return `<!doctype html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Medliva — التقرير الطبي للطبيب | Doctor Clinical Report</title>
  <style>
    :root {
      --primary: #00695c;
      --primary-soft: #e0f2f1;
      --bg: #f4f7f6;
      --surface: #ffffff;
      --text: #16302b;
      --muted: #546e7a;
      --border: #d9e6e2;
    }
    * { box-sizing: border-box; }
    body { font-family: system-ui, -apple-system, "Segoe UI", Tahoma, Arial, sans-serif; background: var(--bg); color: var(--text); margin: 0; padding: 20px; line-height: 1.55; }
    .container { max-width: 960px; margin: 0 auto; }
    .header { background: var(--surface); border: 1px solid var(--border); border-radius: 16px; padding: 24px; display: flex; flex-wrap: wrap; justify-content: space-between; align-items: center; gap: 16px; margin-bottom: 20px; }
    .brand { color: var(--primary); font-weight: 800; font-size: 20px; }
    .subtitle { color: var(--muted); font-size: 14px; margin-top: 2px; }
    .patient-meta { margin-top: 12px; display: flex; flex-wrap: wrap; gap: 16px; font-size: 16px; }
    .print-btn { background: var(--primary); color: #fff; border: 0; border-radius: 12px; padding: 12px 20px; font-size: 15px; font-weight: 700; cursor: pointer; min-height: 48px; }
    .print-btn:hover { background: #004d40; }
    .kpis { display: grid; grid-template-columns: repeat(auto-fit, minmax(190px, 1fr)); gap: 14px; margin-bottom: 20px; }
    .kpi { background: var(--surface); border: 1px solid var(--border); border-radius: 14px; padding: 18px; }
    .kpi-label { font-size: 13px; color: var(--muted); }
    .kpi-value { font-size: 28px; font-weight: 800; color: var(--primary); margin-top: 6px; }
    .kpi-value.danger { color: #c62828; }
    .section { background: var(--surface); border: 1px solid var(--border); border-radius: 16px; padding: 20px; margin-bottom: 20px; }
    .section h2 { margin: 0 0 14px; font-size: 18px; color: var(--primary); display: flex; justify-content: space-between; flex-wrap: wrap; gap: 8px; }
    .section h2 span.en { font-size: 14px; color: var(--muted); font-weight: 600; direction: ltr; }
    .table-wrap { overflow-x: auto; }
    table { width: 100%; border-collapse: collapse; font-size: 15px; }
    th, td { text-align: start; padding: 10px 12px; border-bottom: 1px solid var(--border); }
    th { background: #f8fbfa; color: var(--muted); font-size: 13px; font-weight: 700; }
    tr:last-child td { border-bottom: 0; }
    .empty { text-align: center; color: var(--muted); padding: 18px; }
    .badge { display: inline-block; padding: 4px 10px; border-radius: 999px; font-size: 12px; font-weight: 700; white-space: nowrap; }
    .badge-normal { background: #e8f5e9; color: #1b5e20; }
    .badge-borderline { background: #fff8e1; color: #e65100; }
    .badge-critical { background: #ffebee; color: #b71c1c; }
    footer { text-align: center; color: var(--muted); font-size: 13px; padding: 12px 8px 24px; }
    @media print {
      body { background: #fff; padding: 0; }
      .print-btn { display: none; }
      .header, .kpi, .section { box-shadow: none; break-inside: avoid; }
    }
  </style>
</head>
<body>
  <div class="container">
    <header class="header">
      <div>
        <div class="brand">Medliva • ميدليفا — التقرير الطبي للمريض</div>
        <div class="subtitle">Doctor Clinical Summary (Last 30 Days • آخر 30 يوماً)</div>
        <div class="patient-meta">
          <div><strong>المريض / Patient:</strong> ${patientName}</div>
          <div><strong>الهاتف / Phone:</strong> <span dir="ltr">${patientPhone}</span></div>
        </div>
      </div>
      <button type="button" class="print-btn" onclick="window.print()">طباعة التقرير • Print</button>
    </header>

    <section class="kpis" aria-label="Adherence Summary">
      <div class="kpi">
        <div class="kpi-label">نسبة الالتزام • Adherence Rate</div>
        <div class="kpi-value" dir="ltr">${adherencePct}%</div>
      </div>
      <div class="kpi">
        <div class="kpi-label">الجرعات المأخوذة • Taken / Total</div>
        <div class="kpi-value" dir="ltr">${takenDoses} / ${totalDoses}</div>
      </div>
      <div class="kpi">
        <div class="kpi-label">الجرعات الفائتة • Missed Doses</div>
        <div class="kpi-value${missedDoses > 0 ? " danger" : ""}" dir="ltr">${missedDoses}</div>
      </div>
      <div class="kpi">
        <div class="kpi-label">الأدوية النشطة • Active Medications</div>
        <div class="kpi-value" dir="ltr">${medications.length}</div>
      </div>
    </section>

    <section class="section">
      <h2><span>الأدوية النشطة</span><span class="en">Active Medications</span></h2>
      <div class="table-wrap">
        <table>
          <thead>
            <tr>
              <th>الدواء / Medication</th>
              <th>التركيز / Strength</th>
              <th>الشكل / Form</th>
              <th>المواعيد / Times</th>
              <th>المخزون / Stock</th>
            </tr>
          </thead>
          <tbody>${medsRows}</tbody>
        </table>
      </div>
    </section>

    <section class="section">
      <h2><span>آخر القياسات الحيوية</span><span class="en">Recent Vitals</span></h2>
      <div class="table-wrap">
        <table>
          <thead>
            <tr>
              <th>القياس / Type</th>
              <th>القيمة / Value</th>
              <th>السياق / Context</th>
              <th>التقييم / Triage</th>
              <th>التاريخ / Recorded At</th>
            </tr>
          </thead>
          <tbody>${vitalsRows}</tbody>
        </table>
      </div>
    </section>

    <section class="section">
      <h2><span>سجل الجرعات الأخير</span><span class="en">Recent Intake Logs</span></h2>
      <div class="table-wrap">
        <table>
          <thead>
            <tr>
              <th>الموعد المحدد / Scheduled</th>
              <th>وقت التناول / Actual</th>
              <th>الحالة / Status</th>
              <th>السبب / Reason</th>
            </tr>
          </thead>
          <tbody>${logsRows}</tbody>
        </table>
      </div>
    </section>

    <footer>
      <div>هذا التقرير مُنشأ بواسطة تطبيق Medliva للمتابعة الطبية ولا يُغني عن الفحص السريري المباشر.</div>
      <div dir="ltr">Generated by Medliva for clinical follow-up. Does not replace direct medical evaluation.</div>
    </footer>
  </div>
</body>
</html>`;
}

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

  const url = new URL(request.url);
  const token = url.searchParams.get("token");
  const format = url.searchParams.get("format")?.toLowerCase();
  const accept = request.headers.get("Accept") ?? "";
  const wantsHtml = format === "html" || (format !== "json" && accept.includes("text/html"));

  if (!token || !/^[A-Za-z0-9_-]{40,100}$/.test(token)) {
    if (wantsHtml) {
      return new Response(
        renderErrorHtml(
          "رابط التقرير غير صالح أو منتهي الصلاحية",
          "Report link is invalid or expired",
          "يرجى طلب رابط مشاركة جديد من المريض أو المرافق عبر تطبيق Medliva.",
          "Please ask the patient or caregiver to generate a new report link in Medliva.",
        ),
        { status: 404, headers: htmlHeaders },
      );
    }
    return Response.json({ error: "Report link is invalid or expired" }, {
      status: 404,
      headers: corsHeaders,
    });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceRoleKey) {
    console.error("public-report: missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY");
    if (wantsHtml) {
      return new Response(
        renderErrorHtml(
          "خدمة التقارير غير متاحة حالياً",
          "Report service unavailable",
          "حدث خلل مؤقت في الخدمة. يرجى المحاولة مرة أخرى لاحقاً.",
          "The report service is temporarily unavailable. Please try again later.",
        ),
        { status: 503, headers: htmlHeaders },
      );
    }
    return Response.json({ error: "Report service unavailable" }, {
      status: 503,
      headers: corsHeaders,
    });
  }

  try {
    const admin = createClient(supabaseUrl, serviceRoleKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });
    const { data, error } = await admin.rpc("get_public_report", {
      p_token: token,
    });

    if (error || !data) {
      if (error) console.error("public-report RPC error:", error);
      if (wantsHtml) {
        return new Response(
          renderErrorHtml(
            "رابط التقرير غير صالح أو منتهي الصلاحية",
            "Report link is invalid or expired",
            "انتهت صلاحية هذا الرابط أو تم إلغاؤه. يرجى طلب رابط جديد من تطبيق Medliva.",
            "This report link has expired or been revoked. Please request a new link.",
          ),
          { status: 404, headers: htmlHeaders },
        );
      }
      return Response.json({ error: "Report link is invalid or expired" }, {
        status: 404,
        headers: corsHeaders,
      });
    }

    if (wantsHtml) {
      return new Response(
        renderReportHtml(data as PublicReportData),
        { status: 200, headers: htmlHeaders },
      );
    }

    return Response.json(data, { headers: corsHeaders });
  } catch (err) {
    console.error("public-report unhandled error:", err);
    if (wantsHtml) {
      return new Response(
        renderErrorHtml(
          "حدث خطأ غير متوقع",
          "Internal server error",
          "تعذر تحميل التقرير في الوقت الحالي. يرجى المحاولة لاحقاً.",
          "Unable to load the report right now. Please try again later.",
        ),
        { status: 500, headers: htmlHeaders },
      );
    }
    return Response.json({ error: "Internal server error" }, {
      status: 500,
      headers: corsHeaders,
    });
  }
});
