# -*- coding: utf-8 -*-
"""
Medliva - 5-Page Concise, Dense, Minimalist Engineering Specifications (Arabic)
Design Specifications:
- No large empty spaces: Each page is fully and evenly populated.
- Concise, sharp, direct text without repetition.
- Deleted the JSON schema box entirely.
- Font: Alexandria (Clean Geometric Kufi).
- Minimalist Black & White / Grayscale.
- No headers or footers.
Output: Medliva_UseCases_and_Features_AR.pdf (Exactly 5 full pages)
"""

import os
import subprocess
import pypdf

WORKSPACE = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "original"))
HTML_FILE = os.path.join(WORKSPACE, "Medliva_UseCases_and_Features_AR.html")
PDF_FILE = os.path.join(WORKSPACE, "Medliva_UseCases_and_Features_AR.pdf")

CHROME_PATH = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
if not os.path.exists(CHROME_PATH):
    CHROME_PATH = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

def build_arabic_html():
    return """<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
<meta charset="UTF-8">
<title>وثيقة المواصفات الهندسية وحالات الاستخدام - رفيق العافية (Medliva)</title>
<style>
@import url('https://fonts.googleapis.com/css2?family=Alexandria:wght@300;400;500;600;700;800;900&display=swap');

:root {
  --black: #000000;
  --text-primary: #111111;
  --text-secondary: #333333;
  --border-dark: #000000;
  --border-light: #cccccc;
  --border-subtle: #e5e5e5;
  --bg-white: #ffffff;
}

* {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
}

body {
  font-family: 'Alexandria', 'Segoe UI', Tahoma, sans-serif;
  color: var(--text-primary);
  background-color: #ffffff;
  line-height: 1.5;
  font-size: 9.3pt;
  direction: rtl;
  text-align: right;
  -webkit-print-color-adjust: exact !important;
  print-color-adjust: exact !important;
}

@page {
  size: A4 portrait;
  margin: 0;
}

.pdf-page {
  width: 210mm;
  height: 297mm;
  max-height: 297mm;
  box-sizing: border-box;
  padding: 13mm 15mm 13mm 15mm;
  page-break-after: always;
  break-after: page;
  background: var(--bg-white);
  display: flex;
  flex-direction: column;
  justify-content: flex-start;
  gap: 10px;
  overflow: hidden;
  position: relative;
  margin: 0 auto;
}

.pdf-page:last-child {
  page-break-after: avoid;
  break-after: avoid;
}

/* Page Titles */
.page-title-row {
  margin-bottom: 8px;
  border-bottom: 2px solid var(--black);
  padding-bottom: 5px;
}

.page-title {
  font-size: 13.5pt;
  font-weight: 900;
  color: var(--black);
  line-height: 1.2;
}

.page-subtitle {
  font-size: 8.6pt;
  color: var(--text-secondary);
  font-weight: 500;
  margin-top: 2px;
}

/* Minimalist Clean Box */
.box {
  background: var(--bg-white);
  border: 1px solid var(--border-light);
  padding: 9px 12px;
}

.box-dark-border {
  border: 1.5px solid var(--black);
}

.box-header {
  font-size: 9.8pt;
  font-weight: 800;
  color: var(--black);
  margin-bottom: 6px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-bottom: 1px solid var(--border-subtle);
  padding-bottom: 4px;
}

.tag-clean {
  display: inline-block;
  font-size: 7.4pt;
  font-weight: 700;
  padding: 2px 6px;
  border: 1px solid var(--black);
  background: var(--bg-white);
  color: var(--black);
}

.grid-2 {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 8px;
}

.grid-3 {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr;
  gap: 8px;
}

.grid-4 {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr 1fr;
  gap: 8px;
}

/* Tables */
.table-clean {
  width: 100%;
  border-collapse: collapse;
  font-size: 8.6pt;
  margin-top: 4px;
}

.table-clean th {
  background: #f2f2f2;
  color: var(--black);
  font-weight: 800;
  text-align: right;
  padding: 6px 8px;
  border: 1px solid var(--black);
}

.table-clean td {
  padding: 5px 8px;
  border: 1px solid var(--border-light);
  vertical-align: top;
  color: var(--text-primary);
}

.table-clean tr:nth-child(even) td {
  background: #fafafa;
}

/* Lists */
ul.bullet-list {
  padding-right: 18px;
  font-size: 8.8pt;
  line-height: 1.5;
}

ul.bullet-list li {
  margin-bottom: 4px;
}

/* Flow Step Items */
.step-item {
  display: flex;
  gap: 8px;
  align-items: flex-start;
  margin-bottom: 6px;
  font-size: 8.8pt;
}

.step-num {
  font-weight: 900;
  font-size: 9pt;
  color: var(--black);
  min-width: 18px;
}

.step-body {
  flex: 1;
}

.step-body strong {
  color: var(--black);
  font-weight: 800;
}

/* Spec Meta Line */
.spec-meta-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 6px;
  font-size: 8.2pt;
  border: 1.5px solid var(--black);
  padding: 6px 10px;
  background: #fafafa;
  margin-bottom: 8px;
}

.spec-meta-grid .item-title {
  font-weight: 800;
  color: var(--black);
}

.mono {
  font-family: 'JetBrains Mono', monospace;
  font-size: 7.8pt;
}
</style>
</head>
<body>

<!-- ============================================================== -->
<!-- PAGE 1: OVERVIEW, ARCHITECTURE & TABLE OF CONTENTS -->
<!-- ============================================================== -->
<div class="pdf-page">
  <div class="box box-dark-border" style="padding: 14px 16px;">
    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px;">
      <span class="tag-clean" style="font-size: 8pt; padding: 3px 8px;">وثيقة المواصفات الهندسية وحالات الاستخدام</span>
      <span style="font-size: 8.2pt; font-weight: 700; color: #444;">نظام رعاية كبار السن المتقدم | 2026</span>
    </div>
    <h1 style="font-size: 23pt; font-weight: 900; color: #000; line-height: 1.15; margin-bottom: 4px;">رفيق العافية (Medliva)</h1>
    <h2 style="font-size: 11pt; font-weight: 700; color: #333; margin-bottom: 8px;">منظومة الرعاية الصحية الذكية ومتابعة الالتزام الدوائي والرصد السريري لكبار السن</h2>
    <p style="font-size: 9.1pt; color: #222; line-height: 1.55;">
      منظومة رقمية وقائية متكاملة تربط المريض المسن، المرافق العائلي، والطبيب المعالج. تعتمد معمارية <strong>"العمل المستقل دون اتصال" (Offline-First)</strong> لضمان انطلاق التنبيهات الدوائية بدقة عتادية صارمة، مع واجهات مصممة خصيصاً للخصائص البصرية والحركية لكبار السن بدون كتابة نهائياً (Zero Typing)، ومسح الروشتات بالرؤية الحاسوبية، وتتبع استهلاك الأدوية وإصدار التقارير السريرية.
    </p>
  </div>

  <div class="box">
    <div class="box-header">
      <span>المعمارية التقنية ومواصفات التشغيل الأساسية</span>
    </div>
    <div class="grid-4" style="font-size: 8.6pt;">
      <div style="border: 1px solid var(--border-light); padding: 7px;">
        <strong>معمارية النظام:</strong><br>Offline-First & Local Delta Sync
      </div>
      <div style="border: 1px solid var(--border-light); padding: 7px;">
        <strong>البيئة البرمجية:</strong><br>Flutter + FastAPI + Vision OCR
      </div>
      <div style="border: 1px solid var(--border-light); padding: 7px;">
        <strong>الفئة المستهدفة:</strong><br>مرضى الأمراض المزمنة ورعاة الأسر
      </div>
      <div style="border: 1px solid var(--border-light); padding: 7px;">
        <strong>معايير النفاذية:</strong><br>Geriatric AAA (Zero Typing)
      </div>
    </div>
  </div>

  <div class="box">
    <div class="box-header">
      <span>فهرس أقسام ومحتويات الوثيقة المعتمدة (5 صفحات مركزة)</span>
    </div>
    <table class="table-clean" style="margin-top: 0;">
      <thead>
        <tr>
          <th style="width: 14%;">الصفحة</th>
          <th style="width: 46%;">القسم والمحتوى الهندسي</th>
          <th style="width: 40%;">المخرجات والهدف التطبيقي</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td><strong>صفحة 01</strong></td>
          <td>هوية المنصة، المعمارية الهندسية، وفهرس المحتويات</td>
          <td>الملخص التنفيذي وهوية المنصة</td>
        </tr>
        <tr>
          <td><strong>صفحة 02</strong></td>
          <td>بيان المشكلة السريرية، ركائز الحل، ومسار الرعاية اليومية</td>
          <td>إحصائيات WHO والجدول المقارن وأعمدة النظام</td>
        </tr>
        <tr>
          <td><strong>صفحة 03</strong></td>
          <td>منظومة المستخدمين وحالات الاستخدام UC-01 و UC-02</td>
          <td>التنبيه الدوائي المستقل ومسح الروشتة بـ AI OCR</td>
        </tr>
        <tr>
          <td><strong>صفحة 04</strong></td>
          <td>حالات الاستخدام التفاعلية والمتابعة UC-03 و UC-04</td>
          <td>تسجيل القياسات بالصوت والإشراف العائلي والتصعيد</td>
        </tr>
        <tr>
          <td><strong>صفحة 05</strong></td>
          <td>إدارة المخزون والتقارير السريرية UC-05 و UC-06</td>
          <td>الطلب بواتساب وتنبؤ النفاد والتقارير الطبية ورمز QR</td>
        </tr>
      </tbody>
    </table>
  </div>
</div>

<!-- ============================================================== -->
<!-- PAGE 2: CLINICAL PROBLEMS, SYSTEM PILLARS & CARE PIPELINE -->
<!-- ============================================================== -->
<div class="pdf-page">
  <div class="page-title-row">
    <h2 class="page-title">01. بيان المشكلة السريرية، ركائز الحل، ومسار الرعاية</h2>
    <p class="page-subtitle">التحديات الميدانية لإهمال أدوية كبار السن، المقارنة مع الوضع الراهن، ودورة الرعاية اليومية</p>
  </div>

  <div class="box box-dark-border">
    <div class="box-header">
      <span>الأزمة السريرية والميدانية (بيانات منظمة الصحة العالمية WHO)</span>
    </div>
    <p style="font-size: 8.9pt; line-height: 1.55;">
      تؤكد <strong>منظمة الصحة العالمية (WHO)</strong> أن أكثر من <strong>50%</strong> من مرضى الأمراض المزمنة يفشلون في تناول أدويتهم بانتظام. يؤدي هذا الإخفاق إلى <strong>33% إلى 45% من حالات الدخول الإسعافي للمستشفيات</strong>، وحدوث مضاعفات خطيرة كالسكتات الدماغية والفشل الكلوي.
    </p>
    <div class="grid-2" style="margin-top: 6px;">
      <div style="border: 1px solid var(--border-light); padding: 7px; background: #fafafa;">
        <strong style="color: #000; font-size: 8.8pt;">معاناة المريض المسن:</strong>
        <ul class="bullet-list" style="margin-top: 3px;">
          <li>تعدد الأدوية (5-9 أقراص يومياً بمواعيد متباينة).</li>
          <li>صعوبة قراءة الخط الصغير وارتعاش اليدين.</li>
          <li>النسيان والخلط بين جرعة اليوم وجرعة الأمس.</li>
        </ul>
      </div>
      <div style="border: 1px solid var(--border-light); padding: 7px; background: #fafafa;">
        <strong style="color: #000; font-size: 8.8pt;">إجهاد المرافق العائلي:</strong>
        <ul class="bullet-list" style="margin-top: 3px;">
          <li>القلق الدائم وتشتت العمل لصعوبة التأكد هاتفياً.</li>
          <li>حرج المسن وادعاء تناول الدواء لتفادي الإحراج.</li>
          <li>مفاجأة نفاد الأدوية المزمنة في أوقات متأخرة.</li>
        </ul>
      </div>
    </div>
  </div>

  <div class="box">
    <div class="box-header">
      <span>المقارنة التحليلية: الوضع التقليدي مقابل ابتكار Medliva</span>
    </div>
    <table class="table-clean">
      <thead>
        <tr>
          <th style="width: 22%;">المحور الهندسي</th>
          <th style="width: 39%;">التطبيقات التجارية والوضع الراهن</th>
          <th style="width: 39%;">منظومة Medliva المتكاملة</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td><strong>التنبيه الدوائي</strong></td>
          <td>إشعارات عادية تُفوت بسهولة وتتوقف بدون إنترنت.</td>
          <td><strong>شاشة استيقاظ كاملة وتنبيه عتادي صارم</strong> يعمل أوفلاين.</td>
        </tr>
        <tr>
          <td><strong>إدخال الجداول</strong></td>
          <td>كتابة يدوية معقدة بالإنجليزية تستغرق وقتاً طويلاً.</td>
          <td><strong>مسح ضوئي ذكي بالـ AI OCR</strong> يحول الروشتة لجدول بلحظات.</td>
        </tr>
        <tr>
          <td><strong>تسجيل القياسات</strong></td>
          <td>أرقام يدوية عبر لوحة المفاتيح معرضة لأخطاء الإدخال.</td>
          <td><strong>تسجيل صوتي 100% بالعامية</strong> مع تصنيف سريري فوري.</td>
        </tr>
        <tr>
          <td><strong>إدارة المخزون</strong></td>
          <td>تخمين يدوي يسبب انقطاع العلاج فجأة.</td>
          <td><strong>خصم تلقائي مع كل جرعة</strong> وتوليد رسالة طلب صيدلية بواتساب.</td>
        </tr>
      </tbody>
    </table>
  </div>

  <div class="box">
    <div class="box-header">
      <span>ركائز الحل الخمسة لمنصة Medliva</span>
    </div>
    <div class="grid-3" style="font-size: 8.4pt;">
      <div style="border: 1px solid var(--border-light); padding: 6px;">
        <strong>1. تنبيه عتادي مستقل:</strong> تشغيل شاشة الهاتف وإصدار صوت ناطق حتى لو كان الهاتف صامتاً ودون اتصال.
      </div>
      <div style="border: 1px solid var(--border-light); padding: 6px;">
        <strong>2. رقمنة الروشتة بالذكاء الاصطناعي:</strong> استخراج أسماء الأدوية وتراكيزها وأوقاتها بدقة مع مراجعة سريعة.
      </div>
      <div style="border: 1px solid var(--border-light); padding: 6px;">
        <strong>3. واجهة صوتية بدون كتابة:</strong> التقاط أرقام الضغط والسكر صوتياً وتصنيفها فورياً وفق المعايير الطبية.
      </div>
    </div>
    <div class="grid-2" style="font-size: 8.4pt; margin-top: 6px;">
      <div style="border: 1px solid var(--border-light); padding: 6px;">
        <strong>4. إشراف عائلي ومزامنة دلتا:</strong> متابعة حية لجرعات الوالد مع سلم تصعيد آلي يبلغ الأسرة في حال تفويت الجرعة.
      </div>
      <div style="border: 1px solid var(--border-light); padding: 6px;">
        <strong>5. تقارير سريرية ومخزون تنبؤي:</strong> خصم تلقائي للحبوب ورسم منحنيات الضغط والسكر وتصديرها للطبيب بـ QR.
      </div>
    </div>
  </div>

  <div class="box">
    <div class="box-header">
      <span>التدفق التشغيلي لدورة حياة الرعاية في Medliva</span>
    </div>
    <table class="table-clean" style="text-align: center;">
      <thead>
        <tr>
          <th>1. مسح الروشتة</th>
          <th>2. الجدولة المحلية</th>
          <th>3. التنبيه والإقرار</th>
          <th>4. المزامنة والمخزون</th>
          <th>5. التقرير الطبي</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td>التقاط صورة الروشتة واستخراج الأدوية بـ AI</td>
          <td>برمجة منبهات دقيقة مستقلة داخل الجهاز</td>
          <td>شاشة استيقاظ كاملة مع صوت ناطق وإقرار بلمسة</td>
          <td>تحديث لوحة المرافق وخصم رصيد العلبة</td>
          <td>توليد منحنيات بيانية سريرية للطبيب</td>
        </tr>
      </tbody>
    </table>
  </div>
</div>

<!-- ============================================================== -->
<!-- PAGE 3: PERSONAS & USE CASES 01 & 02 -->
<!-- ============================================================== -->
<div class="pdf-page">
  <div class="page-title-row">
    <h2 class="page-title">02. منظومة المستخدمين وحالات الاستخدام الأساسية (UC-01 & UC-02)</h2>
    <p class="page-subtitle">توصيف أطراف النظام، التنبيه الدوائي العتادي المستقل، ومسح الروشتات بالرؤية الحاسوبية</p>
  </div>

  <div class="box">
    <div class="box-header">
      <span>منظومة شخصيات النظام التفاعلية (User Personas Matrix)</span>
    </div>
    <div class="grid-3" style="font-size: 8.3pt;">
      <div style="border: 1px solid var(--border-light); padding: 6px;">
        <strong style="color: #000; font-size: 8.8pt;">حاج إبراهيم (73 سنة) - المريض المسن</strong><br>
        <strong>الحالة:</strong> ضغط وسكري ويتناول 6 أدوية يومياً.<br>
        <strong>الاحتياج:</strong> أزرار عملاقة، صوت عربي ناطق وواضح، وعدم الحاجة لأي كتابة أو إدخال معقد.
      </div>
      <div style="border: 1px solid var(--border-light); padding: 6px;">
        <strong style="color: #000; font-size: 8.8pt;">منى (39 سنة) - المرافقة العائلية</strong><br>
        <strong>الحالة:</strong> موظفة وأم تقيم بعيداً عن والدها بـ 35 كم.<br>
        <strong>الاحتياج:</strong> لوحة تحكم تظهر التناول لحظياً، تنبيه تصعيدي عند النسيان، وإعادة طلب الأدوية بنقرة.
      </div>
      <div style="border: 1px solid var(--border-light); padding: 6px;">
        <strong style="color: #000; font-size: 8.8pt;">د. طارق (52 سنة) - الطبيب المعالج</strong><br>
        <strong>الحالة:</strong> يفحص المسن دورياً لمعايرة الجرعات.<br>
        <strong>الاحتياج:</strong> بيانات التزام موثقة ونسب التزام حقيقية ومنحنيات ضغط تراكمية بدلاً من تخمين المريض.
      </div>
    </div>
  </div>

  <div class="box box-dark-border">
    <div class="spec-meta-grid">
      <div><span class="item-title">حالة الاستخدام:</span> <span class="mono">UC-01</span></div>
      <div><span class="item-title">الفاعل:</span> المريض المسن</div>
      <div><span class="item-title">الأولوية:</span> متطلب أساسي (Must Have)</div>
      <div><span class="item-title">التنفيذ:</span> أوفلاين 100% دون إنترنت</div>
    </div>
    <div class="box-header">
      <span>UC-01: التنبيه الدوائي الذكي وتأكيد التناول المستقل</span>
    </div>
    <p style="font-size: 8.7pt; margin-bottom: 6px;">
      <strong>الهدف التشغيلي:</strong> إيقاظ وتنبيه كبير السن بموعد الدواء بالثانية بدقة متجاوزاً صامت النظام وقفل الشاشة، بصوت ناطق وإقرار بلمسة واحدة.
    </p>
    <div class="step-item">
      <div class="step-num">1.</div>
      <div class="step-body"><strong>انطلاق المنبه العتادي:</strong> تطلق خدمة AlarmManager النظامية تنبيهاً بالثانية المحددة دون تأثر بوضع توفير البطارية أو انقطاع النت.</div>
    </div>
    <div class="step-item">
      <div class="step-num">2.</div>
      <div class="step-body"><strong>شاشة الاستيقاظ الكاملة (Full-Screen Intent):</strong> تضيء الشاشة المقفلة بواجهة عالية التباين، صورة الدواء بلون مميز، ونغمة تتصاعد تدريجياً.</div>
    </div>
    <div class="step-item">
      <div class="step-num">3.</div>
      <div class="step-body"><strong>النطق التوجيهي (TTS):</strong> ينطق الهاتف: <em>"حان موعد حبة الضغط كونكور 5 ملغ بعد الغداء يا حاج إبراهيم"</em>.</div>
    </div>
    <div class="step-item">
      <div class="step-num">4.</div>
      <div class="step-body"><strong>إقرار بلمسة واحدة:</strong> يلمس المريض الزر الأخضر الضخم <strong>[أخذت الدواء الآن]</strong>، فيتوقف الصوت فوراً وتُسجل الجرعة محلياً بتوقيت دقيق.</div>
    </div>
    <div class="grid-2" style="font-size: 8.2pt; margin-top: 4px;">
      <div style="background: #fafafa; border: 1px solid var(--border-light); padding: 5px;">
        <strong>مسار الغفوة (10 دقائق):</strong> يؤجل التنبيه بنقرة مع سقف 3 مرات قبل بدء تصعيد الأسرة.
      </div>
      <div style="background: #fafafa; border: 1px solid var(--border-light); padding: 5px;">
        <strong>مسار التجاهل:</strong> إن لم يُؤكد خلال 30 دقيقة، يُرسل إشعار تحذيري تلقائي لهاتف المرافق العائلي.
      </div>
    </div>
  </div>

  <div class="box box-dark-border">
    <div class="spec-meta-grid">
      <div><span class="item-title">حالة الاستخدام:</span> <span class="mono">UC-02</span></div>
      <div><span class="item-title">الفاعل:</span> المرافق / المريض</div>
      <div><span class="item-title">الأولوية:</span> متطلب أساسي (Must Have)</div>
      <div><span class="item-title">الزمن:</span> أقل من 3.5 ثوانٍ</div>
    </div>
    <div class="box-header">
      <span>UC-02: مسح الروشتة بالذكاء الاصطناعي واستخراج الجداول (AI OCR)</span>
    </div>
    <p style="font-size: 8.7pt; margin-bottom: 6px;">
      <strong>الهدف التشغيلي:</strong> تصوير الروشتات الورقية المكتوبة بخط الطبيب وتحويلها آلياً إلى جدول منبهات ومواعيد ومخزون أدوية بدون إدخال يدوي.
    </p>
    <div class="step-item">
      <div class="step-num">1.</div>
      <div class="step-body"><strong>الالتقاط الموجه بالكاميرا:</strong> إطار إرشادي ذكي يرصد استواء الورقة وثبات اليد والإضاءة لمنع تشوه الصورة.</div>
    </div>
    <div class="step-item">
      <div class="step-num">2.</div>
      <div class="step-body"><strong>المعالجة وتحسين الخط:</strong> تصحيح المنظور وإزالة الظلال وزيادة التباين لعزل خط يد الطبيب بوضوح.</div>
    </div>
    <div class="step-item">
      <div class="step-num">3.</div>
      <div class="step-body"><strong>التعرف البصري واستخراج الكيانات (NER):</strong> نموذج رؤية حاسوبية يستخرج: [اسم الدواء، التركيز، التكرار، الموعد بالنسبة للأكل، المدة].</div>
    </div>
    <div class="step-item">
      <div class="step-num">4.</div>
      <div class="step-body"><strong>بطاقة المراجعة الآمنة والاعتماد:</strong> تُعرض بطاقة للمرافق لمراجعة الأدوية وتأكيدها بنقرة واحدة، فتتولد المنبهات في هاتف المسن تلقائياً.</div>
    </div>
  </div>
</div>

<!-- ============================================================== -->
<!-- PAGE 4: USE CASES 03 & 04 -->
<!-- ============================================================== -->
<div class="pdf-page">
  <div class="page-title-row">
    <h2 class="page-title">03. حالات الاستخدام التفاعلية والمتابعة العائلية (UC-03 & UC-04)</h2>
    <p class="page-subtitle">تسجيل القياسات بالصوت والتصنيف السريري الفوري، ونظام الإشراف والتصعيد العائلي المباشر</p>
  </div>

  <div class="box box-dark-border">
    <div class="spec-meta-grid">
      <div><span class="item-title">حالة الاستخدام:</span> <span class="mono">UC-03</span></div>
      <div><span class="item-title">الفاعل:</span> المريض المسن</div>
      <div><span class="item-title">الأولوية:</span> متطلب أساسي (Must Have)</div>
      <div><span class="item-title">اللغة:</span> اللهجة العامية والعربية</div>
    </div>
    <div class="box-header">
      <span>UC-03: تسجيل المؤشرات الحيوية بالصوت والتصنيف السريري الفوري</span>
    </div>
    <p style="font-size: 8.7pt; margin-bottom: 6px;">
      <strong>الهدف التشغيلي:</strong> تمكين المسن من تسجيل قراءات ضغط الدم وسكر الدم ونبض القلب بنطق الأرقام بالعامية دون لمس لوحة المفاتيح نهائياً.
    </p>
    <div class="step-item">
      <div class="step-num">1.</div>
      <div class="step-body"><strong>بدء الاستماع بنقرة واحدة:</strong> يضغط المسن على أيقونة الميكروفون المركزية الضخمة، فيصدر رنين يوضح بدء الاستماع.</div>
    </div>
    <div class="step-item">
      <div class="step-num">2.</div>
      <div class="step-body"><strong>النطق العفوي التلقائي:</strong> ينطق المسن ببساطة: <em>"الضغط النهاردة 135 على 85"</em> أو <em>"السكر صايم 120"</em>.</div>
    </div>
    <div class="step-item">
      <div class="step-num">3.</div>
      <div class="step-body"><strong>تحويل الصوت واستخراج الأرقام:</strong> يعالج المحرك الذكي الجملة، يستخرج الأرقام ويؤكدها للمريض بصوت واضح.</div>
    </div>
    <div class="step-item">
      <div class="step-num">4.</div>
      <div class="step-body"><strong>التصنيف السريري الفوري:</strong> يُصنف القياس فورياً حسب المعايير الطبية المعتمدة ويُعرض بلون وإرشاد واضح:</div>
    </div>
    <div class="grid-3" style="text-align: center; margin-top: 6px;">
      <div style="border: 1px solid var(--border-light); padding: 5px; background: #fafafa;">
        <strong style="font-size: 8.5pt;">1. النطاق المثالي المستقر</strong>
        <p style="font-size: 7.7pt; margin-top: 2px;">ضغط &lt; 120/80 | سكر 70-110<br><span style="font-weight: 700;">"قراءة ممتازة ومستقرة"</span></p>
      </div>
      <div style="border: 1px solid var(--border-light); padding: 5px; background: #fafafa;">
        <strong style="font-size: 8.5pt;">2. النطاق الحذر (حدودي)</strong>
        <p style="font-size: 7.7pt; margin-top: 2px;">ضغط 130-139 / 80-89<br><span style="font-weight: 700;">"مرتفع قليلاً، قلل الأملاح"</span></p>
      </div>
      <div style="border: 1.5px solid #000; padding: 5px; background: #fff;">
        <strong style="font-size: 8.5pt;">3. النطاق الحرج (خطر)</strong>
        <p style="font-size: 7.7pt; margin-top: 2px;">ضغط &ge; 180 أو سكر &lt; 70<br><span style="font-weight: 900;">"إنذار وتنبيه المرافق فوراً!"</span></p>
      </div>
    </div>
    <div style="border-top: 1px solid var(--border-subtle); padding-top: 5px; margin-top: 6px; font-size: 8.2pt;">
      <strong>بروتوكول التدخل السريع:</strong> عند رصد هبوط سكر حاد (&lt; 60) ينطق الهاتف إرشاداً مهدئاً: <em>"يا حاج إبراهيم اجلس واشرب عصير حالاً"</em> مع إشعار عاجل للأسرة.
    </div>
  </div>

  <div class="box box-dark-border">
    <div class="spec-meta-grid">
      <div><span class="item-title">حالة الاستخدام:</span> <span class="mono">UC-04</span></div>
      <div><span class="item-title">الفاعل:</span> المرافق العائلي</div>
      <div><span class="item-title">الأولوية:</span> متطلب أساسي (Must Have)</div>
      <div><span class="item-title">بروتوكول المزامنة:</span> WebSocket & Delta Sync</div>
    </div>
    <div class="box-header">
      <span>UC-04: الإشراف والمتابعة العائلية عن بُعد والتصعيد التلقائي</span>
    </div>
    <p style="font-size: 8.7pt; margin-bottom: 6px;">
      <strong>الهدف التشغيلي:</strong> منح الأسرة الاطمئنان التام عبر خط زمني مباشر يوضح تناول الدواء، مع نظام تصعيد آلي يتدخل عند النسيان.
    </p>
    <div class="grid-2">
      <div style="border: 1px solid var(--border-light); padding: 7px;">
        <strong style="font-size: 8.8pt; color: #000;">مكونات لوحة المرافق العائلي:</strong>
        <ul class="bullet-list" style="margin-top: 4px;">
          <li><strong>الخط الزمني المباشر:</strong> عرض أدوية اليوم (أُخذت في 08:14، مؤجلة، قادمة).</li>
          <li><strong>رصد المؤشرات الحيوية:</strong> بطاقات فورية لآخر قياسات الضغط والسكر.</li>
          <li><strong>رسائل صوتية مخصصة:</strong> تسجيل صوت الأحفاد لتشجيعه مع التنبيه.</li>
          <li><strong>تعديل الجداول عن بُعد:</strong> إضافة الأدوية من هاتف المرافق مباشرة.</li>
        </ul>
      </div>
      <div style="border: 1.5px solid var(--black); padding: 7px; background: #fafafa;">
        <strong style="font-size: 8.8pt; color: #000;">هرم التصعيد التلقائي للجرعات المنسية:</strong>
        <div style="font-size: 8.2pt; display: flex; flex-direction: column; gap: 4px; margin-top: 4px;">
          <div><strong>دقيقة 0:</strong> رنين المنبه الصارم ونطق اسم الدواء بهاتف المسن.</div>
          <div><strong>دقيقة +15:</strong> رنين تذكيري هادئ ثانٍ بهاتف المسن عند عدم الإقرار.</div>
          <div><strong>دقيقة +30:</strong> إشعار تصعيدي لهاتف المرافق: <em>"تنبيه: والدك لم يؤكد جرعة الضغط"</em>.</div>
          <div><strong>دقيقة +60:</strong> إنذار طارئ مرتفع للمرافق مع زر اتصال هاتفي بضغطة واحدة.</div>
        </div>
      </div>
    </div>
  </div>
</div>

<!-- ============================================================== -->
<!-- PAGE 5: USE CASES 05 & 06 -->
<!-- ============================================================== -->
<div class="pdf-page">
  <div class="page-title-row">
    <h2 class="page-title">04. إدارة المخزون التنبؤية وإصدار التقارير السريرية (UC-05 & UC-06)</h2>
    <p class="page-subtitle">حساب معدل استهلاك الأدوية والطلب بواتساب، وتوليد تقارير الالتزام السريرية للطبيب بـ QR</p>
  </div>

  <div class="box box-dark-border">
    <div class="spec-meta-grid">
      <div><span class="item-title">حالة الاستخدام:</span> <span class="mono">UC-05</span></div>
      <div><span class="item-title">الفاعل:</span> المرافق / محرك المخزون</div>
      <div><span class="item-title">الأولوية:</span> متطلب هام (Should Have)</div>
      <div><span class="item-title">الهدف:</span> منع نفاد الأدوية المزمنة</div>
    </div>
    <div class="box-header">
      <span>UC-05: إدارة المخزون وتنبيهات النفاد وإعادة الطلب بواتساب</span>
    </div>
    <p style="font-size: 8.7pt; margin-bottom: 6px;">
      <strong>الهدف التشغيلي:</strong> القضاء التام على الانقطاع المفاجئ للأدوية عبر تتبع رصيد الأقراص وتوقع تاريخ النفاد وتنبيه الأسرة قبل 5 أيام بطلب جاهز.
    </p>
    <div class="step-item">
      <div class="step-num">1.</div>
      <div class="step-body"><strong>تسجيل رصيد العبوة:</strong> يُدخل المرافق عدد الحبوب عند مسح الروشتة (مثال: شريطان = 20 قرصاً من كونكور 5).</div>
    </div>
    <div class="step-item">
      <div class="step-num">2.</div>
      <div class="step-body"><strong>الخصم التلقائي التزامني:</strong> مع كل جرعة يؤكدها المسن، يخصم النظام قرصاً واحداً تلقائياً من الرصيد المحلي والسحابي.</div>
    </div>
    <div class="step-item">
      <div class="step-num">3.</div>
      <div class="step-body"><strong>التنبؤ بموعد النفاد:</strong> خوارزمية رياضية تحسب تاريخ النفاد: <span class="mono">تاريخ_النفاد = اليوم + (الأقراص_المتبقية / الجرعات_اليومية)</span>.</div>
    </div>
    <div class="step-item">
      <div class="step-num">4.</div>
      <div class="step-body"><strong>تنبيه استباقي قبل 5 أيام:</strong> إشعار للمرافق: <em>"تنبيه: متبقي 5 أيام فقط على نفاد دواء الضغط للوالد"</em>.</div>
    </div>
    <div class="step-item">
      <div class="step-num">5.</div>
      <div class="step-body"><strong>طلب صيدلية بضغطة واحدة بواتساب:</strong> يضغط المرافق [إنشاء الطلب]، فيجهز رسالة رسمية بأسماء الأدوية لإرسالها لصيدلية الحي فوراً.</div>
    </div>
    <div class="grid-2" style="font-size: 8.2pt; margin-top: 5px;">
      <div style="background: #fafafa; border: 1px solid var(--border-light); padding: 5px;">
        <strong>صيغة رسالة الواتساب المولدة:</strong><br>
        <em>"السلام عليكم صيدلية العناية، يرجى تحضير أدوية المريض إبراهيم: 1. علبة كونكور 5 ملغ | 2. علبة جلوكوفاج 500 ملغ. العنوان: 12 شارع التحرير."</em>
      </div>
      <div style="background: #fafafa; border: 1px solid var(--border-light); padding: 5px;">
        <strong>حارس تواريخ الصلاحية:</strong> يرصد النظام تاريخ انتهاء شريط الدواء وينبه المرافق قبل 30 يوماً لمنع تناول أدوية فاسدة.
      </div>
    </div>
  </div>

  <div class="box box-dark-border">
    <div class="spec-meta-grid">
      <div><span class="item-title">حالة الاستخدام:</span> <span class="mono">UC-06</span></div>
      <div><span class="item-title">الفاعل:</span> الطبيب / المرافق / المريض</div>
      <div><span class="item-title">الأولوية:</span> متطلب أساسي (Must Have)</div>
      <div><span class="item-title">الصيغة:</span> PDF سريري ورمز QR مشفر</div>
    </div>
    <div class="box-header">
      <span>UC-06: إصدار التقارير السريرية التراكمية للطبيب وبوابة QR</span>
    </div>
    <p style="font-size: 8.7pt; margin-bottom: 6px;">
      <strong>الهدف التشغيلي:</strong> تحويل زيارة الطبيب من التخمين ونسيان المريض إلى استشارة دقيقة مبنية على بيانات موثقة لـ 30 أو 90 يوماً سابقة.
    </p>
    <div class="grid-2">
      <div style="border: 1px solid var(--border-light); padding: 6px;">
        <strong style="font-size: 8.6pt; color: #000;">1. نسبة الالتزام التراكمية %:</strong>
        <p style="font-size: 7.9pt; color: #333; margin-top: 2px;">حساب دقيق لنسبة الجرعات المتناولة في موعدها (مثال: 94.5% خلال الربع الأخير).</p>
      </div>
      <div style="border: 1px solid var(--border-light); padding: 6px;">
        <strong style="font-size: 8.6pt; color: #000;">2. منحنيات المؤشرات البيانية:</strong>
        <p style="font-size: 7.9pt; color: #333; margin-top: 2px;">رسم بياني مستمر يوضح تقلبات الضغط الانقباضي والانبساطي وسكر الدم الصائم.</p>
      </div>
      <div style="border: 1px solid var(--border-light); padding: 6px;">
        <strong style="font-size: 8.6pt; color: #000;">3. سجل الجرعات المفقودة وأسبابها:</strong>
        <p style="font-size: 7.9pt; color: #333; margin-top: 2px;">توثيق تفصيلي للجرعات غير المؤكدة وأسباب تفويتها (نسيان، نفاد، تأجيل).</p>
      </div>
      <div style="border: 1px solid var(--border-light); padding: 6px;">
        <strong style="font-size: 8.6pt; color: #000;">4. قائمة الأدوية النشطة والتعارضات:</strong>
        <p style="font-size: 7.9pt; color: #333; margin-top: 2px;">بيان كامل بالأسماء التجارية والمواد العلمية لتفادي تكرار وصف نفس العقار.</p>
      </div>
    </div>
    <div style="margin-top: 6px; border: 1.5px dashed var(--black); padding: 6px; background: #fafafa;">
      <strong style="font-size: 8.6pt; color: #000;">فحص سريري فوري عبر رمز QR مشفر دون تثبيت برامج:</strong>
      <p style="font-size: 8pt; color: #333; margin-top: 2px;">
        يُبرز المرافق رمز <strong>QR مشفراً</strong> من هاتفه، ليمسحه الطبيب بكاميرا هاتفه أو حاسوب العيادة، فتفتح فوراً لوحة سريرية تفاعلية للبيانات بدون أي برامج إضافية.
      </p>
    </div>
    <div style="border-top: 1px solid var(--border-subtle); padding-top: 4px; margin-top: 6px; font-size: 8.1pt;">
      <strong>الأثر السريري:</strong> يقلص التقرير وقت التشخيص 40%، ويمنع الطبيب من زيادة جرعات الدواء بالخطأ ظناً منه أن الدواء لم يُجدِ بينما كان السبب نسيان المريض لأخذه.
    </div>
  </div>
</div>

</body>
</html>
"""

def main():
    print("Building Arabic HTML and rendering PDF (performance box removed, compact layout)...")
    html_content = build_arabic_html()
    with open(HTML_FILE, "w", encoding="utf-8") as f:
        f.write(html_content)
    print(f"Arabic HTML written: {HTML_FILE} ({len(html_content)} bytes)")

    html_uri = "file:///" + os.path.abspath(HTML_FILE).replace("\\", "/")
    print(f"Rendering PDF to: {PDF_FILE} using {CHROME_PATH}")

    cmd = [
        CHROME_PATH,
        "--headless=new",
        "--no-sandbox",
        "--disable-gpu",
        "--run-all-compositor-stages-before-draw",
        "--no-pdf-header-footer",
        f"--print-to-pdf={PDF_FILE}",
        html_uri
    ]

    res = subprocess.run(cmd, capture_output=True, text=True)
    if res.returncode != 0:
        print("Chrome error:", res.stderr)
        return False

    if os.path.exists(PDF_FILE):
        size = os.path.getsize(PDF_FILE)
        print(f"Arabic PDF successfully generated! Size: {size} bytes")
        reader = pypdf.PdfReader(PDF_FILE)
        total_pages = len(reader.pages)
        print(f"TOTAL PAGES IN UPDATED ARABIC PDF: {total_pages}")
        return total_pages
    else:
        print("Error: PDF file was not created.")
        return 0

if __name__ == "__main__":
    main()
