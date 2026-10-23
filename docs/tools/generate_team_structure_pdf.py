# -*- coding: utf-8 -*-
"""Generate the detailed CareElder team structure and work plan PDF."""

from __future__ import annotations

import os
import subprocess
from pathlib import Path

import pypdf


BASE_DIR = Path(__file__).resolve().parents[1]
OUTPUT_DIR = BASE_DIR / "original"
HTML_FILE = OUTPUT_DIR / "CareElder_Team_Roles_and_Workplan.html"
PDF_FILE = OUTPUT_DIR / "CareElder_Team_Roles_and_Workplan.pdf"

CHROME_CANDIDATES = (
    Path(r"C:\Program Files\Google\Chrome\Application\chrome.exe"),
    Path(r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"),
)


def build_html() -> str:
    return r"""<!doctype html>
<html lang="ar" dir="rtl">
<head>
<meta charset="utf-8">
<title>توزيع فريق مشروع CareElder</title>
<style>
@page { size: A4; margin: 14mm 13mm; }
* { box-sizing: border-box; }
body {
  margin: 0;
  color: #17212b;
  background: #fff;
  font-family: Tahoma, Arial, sans-serif;
  font-size: 10pt;
  line-height: 1.65;
}
.page { page-break-after: always; min-height: 267mm; }
.page:last-child { page-break-after: auto; }
.cover {
  min-height: 267mm;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  padding: 24mm 15mm;
  border: 2px solid #0f766e;
  background: linear-gradient(145deg, #f0fdfa 0%, #ffffff 58%, #eff6ff 100%);
}
.cover h1 { font-size: 30pt; color: #115e59; margin: 35mm 0 8mm; line-height: 1.25; }
.cover h2 { font-size: 15pt; color: #334155; margin: 0; font-weight: 500; }
.cover .subtitle { margin-top: 18mm; font-size: 13pt; color: #475569; }
.cover .date { color: #64748b; font-size: 9pt; }
h1, h2, h3 { color: #115e59; margin-top: 0; }
h1 { font-size: 20pt; border-bottom: 3px solid #14b8a6; padding-bottom: 5px; }
h2 { font-size: 14pt; margin-top: 16px; }
h3 { font-size: 11.5pt; margin: 12px 0 4px; }
.section-label { color: #2563eb; font-size: 8.5pt; font-weight: 700; letter-spacing: .4px; }
.intro { background: #f8fafc; border-right: 5px solid #14b8a6; padding: 10px 14px; margin: 12px 0; }
.grid { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; }
.card { border: 1px solid #cbd5e1; border-radius: 8px; padding: 10px 12px; margin: 8px 0; background: #fff; }
.card h3 { margin: 0 0 5px; }
.card .role { color: #2563eb; font-weight: 700; font-size: 9pt; }
.card p { margin: 4px 0; }
.tag { display: inline-block; background: #ccfbf1; color: #115e59; border-radius: 12px; padding: 1px 8px; font-size: 8pt; margin: 2px; }
table { width: 100%; border-collapse: collapse; margin: 9px 0 14px; font-size: 8.8pt; }
th { background: #115e59; color: white; font-weight: 700; }
th, td { border: 1px solid #cbd5e1; padding: 6px 7px; vertical-align: top; }
tr:nth-child(even) td { background: #f8fafc; }
ul { margin: 4px 0 6px; padding-right: 20px; }
li { margin: 2px 0; }
.code { direction: ltr; text-align: left; font-family: Consolas, monospace; background: #0f172a; color: #e2e8f0; padding: 10px; border-radius: 6px; font-size: 8pt; white-space: pre-wrap; }
.flow { display: flex; align-items: center; justify-content: space-between; gap: 5px; margin: 14px 0; }
.flow div { flex: 1; text-align: center; padding: 9px 5px; border: 1px solid #5eead4; background: #f0fdfa; border-radius: 7px; font-size: 8.5pt; }
.flow b { color: #0f766e; font-size: 15pt; }
.priority-high { color: #b91c1c; font-weight: 700; }
.priority-med { color: #a16207; font-weight: 700; }
.footer { margin-top: 18px; border-top: 1px solid #cbd5e1; color: #64748b; font-size: 8pt; padding-top: 5px; }
.avoid-break { page-break-inside: avoid; }
</style>
</head>
<body>

<section class="page cover">
  <div>
    <div class="section-label">CAREELDER · TEAM ORGANIZATION DOCUMENT</div>
    <h1>توزيع فريق مشروع<br>CareElder</h1>
    <h2>خطة المسؤوليات، ملكية الملفات، المخرجات، والسبرنتات</h2>
    <p class="subtitle">وثيقة تنفيذية لتنسيق فريق مكوّن من خمسة أفراد وبناء تطبيق رعاية كبار السن بطريقة منظمة وقابلة للتسليم.</p>
  </div>
  <div>
    <p><span class="tag">Flutter</span><span class="tag">FastAPI</span><span class="tag">PostgreSQL</span><span class="tag">Next.js</span><span class="tag">AI</span></p>
    <p class="date">الإصدار: 1.0 · 7 أكتوبر 2026</p>
  </div>
</section>

<section class="page">
  <div class="section-label">01 · EXECUTIVE SUMMARY</div>
  <h1>الملخص التنفيذي</h1>
  <div class="intro">
    تم تقسيم المشروع على أساس ملكية واضحة لكل جزء من النظام. الهدف أن يكون لكل فرد مسؤولية قابلة للقياس، مع تقليل التداخل في الملفات، وربط كل feature بالتصميم والـ API والاختبارات قبل اعتبارها مكتملة.
  </div>
  <h2>الفريق في سطر واحد</h2>
  <table>
    <tr><th>العضو</th><th>الدور</th><th>الملكية الأساسية</th><th>مقياس النجاح</th></tr>
    <tr><td><b>حمزة</b></td><td>Backend Core & Technical Lead</td><td>Auth، Database، RBAC، API foundation</td><td>API مستقر وDatabase سليمة</td></tr>
    <tr><td><b>سليمان</b></td><td>Backend Services & AI</td><td>Business features، AI، Notifications، Reports</td><td>Features تعمل مع اختبارات</td></tr>
    <tr><td><b>يوسف</b></td><td>Mobile Developer</td><td>Flutter، Offline، Alarms، Patient/Caregiver UI</td><td>APK يعمل Offline وبدون أخطاء</td></tr>
    <tr><td><b>خضر</b></td><td>UI/UX Designer</td><td>Figma، User Flows، Accessibility، Usability</td><td>تصميم معتمد وقابل للتنفيذ</td></tr>
    <tr><td><b>زياد</b></td><td>Doctor Portal + QA/DevOps</td><td>Next.js، CI، E2E، Deployment، Release</td><td>نسخة قابلة للاختبار والتسليم</td></tr>
  </table>
  <h2>المبدأ التنظيمي</h2>
  <div class="flow">
    <div>خضر<br><b>Design</b></div><b>←</b><div>حمزة<br><b>API Contract</b></div><b>←</b><div>سليمان/يوسف<br><b>Implementation</b></div><b>←</b><div>زياد<br><b>Test & Release</b></div>
  </div>
  <div class="intro"><b>قاعدة مهمة:</b> لا يبدأ تنفيذ الشاشة قبل اعتماد الـ user flow، ولا يبدأ ربطها قبل تثبيت الـ API contract، ولا تغلق المهمة قبل وجود test وتوثيق مختصر.</div>
</section>

<section class="page">
  <div class="section-label">02 · ROLE OWNERSHIP</div>
  <h1>تفاصيل المسؤوليات</h1>
  <div class="card avoid-break">
    <h3>حمزة — Backend Core & Technical Lead</h3><div class="role">مالك الأساس المشترك للنظام</div>
    <p><b>المهام:</b></p><ul><li>FastAPI foundation وAPI versioning.</li><li>OTP، JWT، Refresh Sessions، Logout.</li><li>Users، RBAC، permissions، ownership checks.</li><li>SQLAlchemy، Alembic، PostgreSQL schema.</li><li>Caregiver Pairing وMedications/Schedules APIs.</li><li>مراجعة قرارات الـ API والـ Database وPull Requests.</li></ul>
    <p><b>الملكية:</b> <span class="tag">services/api/app/core</span><span class="tag">db</span><span class="tag">models</span><span class="tag">schemas</span><span class="tag">alembic</span></p>
    <p><b>المخرجات:</b> Database migrations، Swagger contract، Auth tests، وصحة تشغيل الـ API.</p>
  </div>
  <div class="card avoid-break">
    <h3>سليمان — Backend Services & AI</h3><div class="role">مالك منطق الأعمال والخدمات الذكية</div>
    <p><b>المهام:</b></p><ul><li>Adherence وتسجيل الجرعات مع idempotency.</li><li>Offline Sync API وConflict handling.</li><li>WebSocket، FCM، Escalation عبر Supabase Cron.</li><li>Inventory، Forecast، Expiry Alerts.</li><li>Prescription OCR وVoice Vitals وDeterministic Triage.</li><li>Reports، Storage، SOS والتكاملات الخارجية.</li></ul>
    <p><b>الملكية:</b> <span class="tag">features</span><span class="tag">services</span><span class="tag">AI endpoints</span><span class="tag">notifications</span></p>
    <p><b>المخرجات:</b> Business services، AI evaluation results، Notification flows، واختبارات التكامل.</p>
  </div>
  <div class="card avoid-break">
    <h3>يوسف — Mobile Developer</h3><div class="role">مالك تطبيق Flutter للمريض والمرافق</div>
    <p><b>المهام:</b></p><ul><li>Flutter architecture، Riverpod، go_router، localization.</li><li>Drift SQLite وSync Queue وOffline-first.</li><li>Local exact alarms وBoot Recovery وTTS.</li><li>Patient flow، Caregiver flow، Medication screens.</li><li>FCM، Camera، Voice، Location، SOS.</li></ul>
    <p><b>الملكية:</b> <span class="tag">apps/mobile/**</span></p>
    <p><b>المخرجات:</b> APK تجريبي، Mobile tests، Offline demo، Alarm demo.</p>
  </div>
</section>

<section class="page">
  <div class="section-label">03 · ROLE OWNERSHIP</div>
  <h1>تفاصيل المسؤوليات — التصميم والويب والجودة</h1>
  <div class="card avoid-break">
    <h3>خضر — UI/UX Designer</h3><div class="role">مالك تجربة المستخدم والتصميم</div>
    <p><b>المهام:</b></p><ul><li>Personas للمريض والمرافق والطبيب.</li><li>User flows وWireframes لكل feature أساسية.</li><li>Figma Design System: ألوان، Typography، Buttons، Forms، States.</li><li>RTL، تباين عالٍ، أزرار كبيرة، وتقليل الكتابة.</li><li>Usability tests مع كبار السن وتوثيق النتائج.</li><li>تسليم design specs قبل بداية التنفيذ.</li></ul>
    <p><b>الملكية:</b> <span class="tag">docs/design</span><span class="tag">docs/user-flows</span><span class="tag">Figma</span></p>
    <p><b>المخرجات:</b> Figma file معتمد، component states، accessibility checklist، وملاحظات الاختبار.</p>
  </div>
  <div class="card avoid-break">
    <h3>زياد — Doctor Portal + QA/DevOps</h3><div class="role">مالك بوابة الطبيب وخط الجودة والإصدار</div>
    <p><b>المهام:</b></p><ul><li>Next.js Doctor Portal وصفحة التقرير `/r/[token]`.</li><li>Charts للالتزام والضغط والسكر والجرعات الفائتة.</li><li>CI/CD، environments، build checks، وrelease checklist.</li><li>Integration/E2E tests بين Mobile وAPI وPortal.</li><li>Deployment ومتابعة logs وhealth checks.</li><li>تجميع التوثيق وتجهيز Demo ونسخة التسليم.</li></ul>
    <p><b>الملكية:</b> <span class="tag">apps/doctor-portal</span><span class="tag">.github</span><span class="tag">integration tests</span><span class="tag">deployment</span></p>
    <p><b>المخرجات:</b> Portal منشور، CI أخضر، E2E scenarios، Release candidate، وQA report.</p>
  </div>
  <h2>توزيع الاختبارات</h2>
  <table>
    <tr><th>نوع الاختبار</th><th>المالك الأساسي</th><th>المشاركون</th></tr>
    <tr><td>Unit API / Domain</td><td>حمزة، سليمان</td><td>كل Backend developer يختبر كوده</td></tr>
    <tr><td>Flutter Unit / Widget</td><td>يوسف</td><td>خضر يراجع الحالات المرئية</td></tr>
    <tr><td>Integration / E2E</td><td>زياد</td><td>يوسف + حمزة + سليمان</td></tr>
    <tr><td>Usability</td><td>خضر</td><td>الفريق كله أثناء جلسات الاختبار</td></tr>
    <tr><td>Release Acceptance</td><td>زياد</td><td>حمزة يعتمد الـ API ويوسف يعتمد الـ APK</td></tr>
  </table>
</section>

<section class="page">
  <div class="section-label">04 · FILE OWNERSHIP & API CONTRACT</div>
  <h1>ملكية الملفات والتكامل بين الأجزاء</h1>
  <table>
    <tr><th>المساحة</th><th>المالك</th><th>قاعدة التعديل</th></tr>
    <tr><td><code>services/api/app/core/**</code></td><td>حمزة</td><td>لا تعديل بدون مراجعة Technical Lead</td></tr>
    <tr><td><code>services/api/app/models/**</code></td><td>حمزة</td><td>كل تغيير يحتاج Alembic migration واختبار</td></tr>
    <tr><td><code>services/api/app/features/**</code></td><td>سليمان</td><td>يرتبط بعقد API موثق</td></tr>
    <tr><td><code>apps/mobile/**</code></td><td>يوسف</td><td>لا endpoint غير موثق أو غير مختبر</td></tr>
    <tr><td><code>apps/doctor-portal/**</code></td><td>زياد</td><td>قراءة التقرير فقط في النسخة الأولى</td></tr>
    <tr><td><code>docs/design/**</code></td><td>خضر</td><td>التصميم المعتمد هو مصدر الحقيقة للواجهة</td></tr>
    <tr><td><code>.github/**</code></td><td>زياد</td><td>أي تغيير في CI يجب التحقق منه محلياً</td></tr>
  </table>
  <h2>طريقة تسليم أي Feature</h2>
  <div class="flow"><div>1<br><b>Design</b></div><b>→</b><div>2<br><b>API Contract</b></div><b>→</b><div>3<br><b>Backend</b></div><b>→</b><div>4<br><b>Mobile/Web</b></div><b>→</b><div>5<br><b>Test</b></div></div>
  <h2>قواعد الـ API Contract</h2>
  <ul><li>حمزة يثبت أسماء الـ endpoints والـ request/response schemas.</li><li>سليمان يضيف business rules والأخطاء المتوقعة.</li><li>يوسف وزياد لا يعتمدان على fields غير موثقة في OpenAPI.</li><li>أي breaking change يحتاج issue واضح وموافقة حمزة.</li><li>كل endpoint حساس يجب أن يحتوي على authorization وownership check.</li></ul>
  <div class="code">Feature branch → Pull Request → Automated CI → Review → Merge to develop → Integration test → Release candidate</div>
</section>

<section class="page">
  <div class="section-label">05 · SPRINT PLAN</div>
  <h1>خطة التنفيذ على 8 سبرنتات</h1>
  <table>
    <tr><th>السبرنت</th><th>الهدف</th><th>حمزة</th><th>سليمان</th><th>يوسف</th><th>خضر</th><th>زياد</th></tr>
    <tr><td>S1</td><td>التحليل والتصميم</td><td>API boundaries</td><td>Feature map</td><td>Mobile flows</td><td>Personas/Figma</td><td>QA plan</td></tr>
    <tr><td>S2</td><td>Foundation</td><td>Auth/DB/CI contract</td><td>Service structure</td><td>Flutter auth</td><td>Design system</td><td>Portal skeleton</td></tr>
    <tr><td>S3</td><td>الأدوية والمنبه</td><td>Medication APIs</td><td>Adherence rules</td><td>Drift/Alarm</td><td>Patient UI</td><td>Alarm test plan</td></tr>
    <tr><td>S4</td><td>المرافق والتصعيد</td><td>Pairing/RBAC</td><td>FCM/WebSocket/Cron</td><td>Caregiver UI</td><td>Dashboard UX</td><td>Integration tests</td></tr>
    <tr><td>S5</td><td>Prescription AI</td><td>Storage permissions</td><td>OCR pipeline</td><td>Camera/confirmation</td><td>Review card UX</td><td>Evaluation dataset</td></tr>
    <tr><td>S6</td><td>Voice + Inventory</td><td>Data constraints</td><td>STT/Triage/Forecast</td><td>Voice screens</td><td>Voice accessibility</td><td>Accuracy tests</td></tr>
    <tr><td>S7</td><td>Reports + SOS</td><td>Share permissions</td><td>Reports/SOS services</td><td>Charts/SOS</td><td>Doctor report UX</td><td>Doctor Portal</td></tr>
    <tr><td>S8</td><td>الاختبار والتسليم</td><td>Security review</td><td>Bug fixes</td><td>APK release</td><td>Pilot feedback</td><td>CI/E2E/deploy</td></tr>
  </table>
  <h2>معايير نهاية كل سبرنت</h2>
  <ul><li>Feature تعمل على بيئة اختبار فعلية.</li><li>اختبارات ناجحة وCI أخضر.</li><li>التصميم النهائي مطابق للتنفيذ.</li><li>لا توجد أسرار أو بيانات حقيقية داخل Git.</li><li>التوثيق وAPI examples محدثة.</li></ul>
</section>

<section class="page">
  <div class="section-label">06 · DEFINITION OF DONE</div>
  <h1>معايير التسليم والحوكمة</h1>
  <div class="grid">
    <div class="card"><h3>قبل بدء المهمة</h3><ul><li>Issue مكتوبة بوضوح.</li><li>المستخدم المستهدف معروف.</li><li>UI flow معتمد إن كانت المهمة مرئية.</li><li>API contract محدد إن كانت تحتاج Backend.</li></ul></div>
    <div class="card"><h3>أثناء التنفيذ</h3><ul><li>Branch باسم واضح.</li><li>Commits صغيرة وConventional.</li><li>عدم تعديل ملفات شخص آخر بدون تنسيق.</li><li>عدم إضافة dependency بدون سبب.</li></ul></div>
    <div class="card"><h3>قبل Pull Request</h3><ul><li>Unit/Widget tests مضافة.</li><li>Lint وformat ناجحان.</li><li>صور أو فيديو للواجهات.</li><li>تحديث README أو API docs.</li></ul></div>
    <div class="card"><h3>قبل الإغلاق</h3><ul><li>مراجعة شخص واحد على الأقل.</li><li>CI أخضر.</li><li>اختبار على بيئة staging.</li><li>تحديث الـ changelog والـ demo notes.</li></ul></div>
  </div>
  <h2>اجتماعات الفريق</h2>
  <table>
    <tr><th>الاجتماع</th><th>المدة</th><th>المشاركون</th><th>النتيجة المطلوبة</th></tr>
    <tr><td>Daily sync</td><td>10 دقائق</td><td>الفريق كله</td><td>ما تم، ما سيتم، blockers</td></tr>
    <tr><td>API/Architecture review</td><td>مرتين أسبوعياً</td><td>حمزة، سليمان، يوسف، زياد</td><td>حل تعارضات التكامل</td></tr>
    <tr><td>Design review</td><td>مرة أسبوعياً</td><td>خضر + صاحب feature</td><td>اعتماد الشاشات والحالات</td></tr>
    <tr><td>Sprint review</td><td>نهاية السبرنت</td><td>الفريق والمشرف</td><td>Demo وقرار الانتقال</td></tr>
  </table>
  <h2>المخاطر وخطة البديل</h2>
  <table>
    <tr><th>الخطر</th><th>المالك</th><th>خطة التخفيف</th></tr>
    <tr><td class="priority-high">تأخر المنبه Offline</td><td>يوسف + سليمان</td><td>تقديم alarm MVP قبل AI والتقارير.</td></tr>
    <tr><td class="priority-high">تعارض Database/API</td><td>حمزة</td><td>Migration إلزامية وAPI review.</td></tr>
    <tr><td class="priority-med">ضعف دقة AI</td><td>سليمان + خضر</td><td>Human confirmation وmanual fallback.</td></tr>
    <tr><td class="priority-med">تأخر Portal أو CI</td><td>زياد</td><td>بناء skeleton مبكراً واختبار كل Sprint.</td></tr>
  </table>
  <div class="intro"><b>النتيجة المطلوبة:</b> فريق يعرف بالضبط من يملك كل جزء، وما الذي يجب تسليمه، وكيف يتم اكتشاف المشكلة قبل نهاية المشروع.</div>
  <div class="footer">CareElder · Team Roles & Workplan · حمزة · سليمان · يوسف · خضر · زياد</div>
</section>

</body>
</html>"""


def find_browser() -> Path:
    for candidate in CHROME_CANDIDATES:
        if candidate.exists():
            return candidate
    raise FileNotFoundError("Chrome or Edge was not found")


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    HTML_FILE.write_text(build_html(), encoding="utf-8")
    browser = find_browser()
    html_uri = HTML_FILE.resolve().as_uri()
    command = [
        str(browser),
        "--headless=new",
        "--no-sandbox",
        "--disable-gpu",
        "--run-all-compositor-stages-before-draw",
        "--no-pdf-header-footer",
        f"--print-to-pdf={PDF_FILE}",
        html_uri,
    ]
    result = subprocess.run(command, capture_output=True, text=True, check=False)
    if result.returncode != 0 or not PDF_FILE.exists():
        raise RuntimeError(result.stderr or "PDF generation failed")

    pages = len(pypdf.PdfReader(str(PDF_FILE)).pages)
    print(f"HTML: {HTML_FILE}")
    print(f"PDF: {PDF_FILE}")
    print(f"Pages: {pages}")
    print(f"Size: {os.path.getsize(PDF_FILE)} bytes")


if __name__ == "__main__":
    main()
