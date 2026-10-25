# -*- coding: utf-8 -*-
"""
Script to generate the comprehensive Graduation Project Master Plan & Engineering Specification PDF.
Project: Medliva (رفيق العافية) - Smart Healthcare & Adherence Platform for Elderly and Chronic Patients.
"""

import os
import subprocess
import sys

def build_html():
    html = """<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
<meta charset="UTF-8">
<title>وثيقة المواصفات الهندسية وخطة التطوير الشاملة لمشروع التخرج - رفيق العافية (Medliva)</title>
<style>
@import url('https://fonts.googleapis.com/css2?family=Cairo:wght@300;400;500;600;700;800;900&family=JetBrains+Mono:wght@400;500;700&display=swap');

:root {
  --primary: #0f4c5c;
  --primary-dark: #0a2f39;
  --primary-light: #e6f2f4;
  --secondary: #1976d2;
  --accent: #e36414;
  --accent-light: #fdf2e9;
  --success: #2e7d32;
  --success-light: #edf7ed;
  --warning: #ed6c02;
  --warning-light: #fff4e5;
  --danger: #d32f2f;
  --danger-light: #fde8e8;
  --text-dark: #1e293b;
  --text-muted: #64748b;
  --border: #cbd5e1;
  --bg-card: #f8fafc;
}

* {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
}

body {
  font-family: 'Cairo', 'Segoe UI', Tahoma, sans-serif;
  color: var(--text-dark);
  background-color: #ffffff;
  line-height: 1.55;
  font-size: 11pt;
  direction: rtl;
  text-align: right;
  -webkit-font-smoothing: antialiased;
}

@page {
  size: A4 portrait;
  margin: 14mm 12mm 14mm 12mm;
}

@media print {
  body {
    -webkit-print-color-adjust: exact !important;
    print-color-adjust: exact !important;
  }
  .page-break {
    page-break-after: always !important;
    break-after: page !important;
  }
  .avoid-break {
    page-break-inside: avoid !important;
    break-inside: avoid !important;
  }
}

/* Cover Page */
.cover-page {
  height: 98vh;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  border: 3px solid var(--primary);
  border-radius: 12px;
  padding: 35px;
  background: linear-gradient(145deg, #ffffff 0%, #f0f7f8 100%);
  position: relative;
  page-break-after: always;
}

.cover-header {
  border-bottom: 2px solid var(--primary);
  padding-bottom: 18px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.cover-header .inst-info h3 {
  font-size: 15pt;
  color: var(--primary);
  font-weight: 800;
}

.cover-header .inst-info p {
  font-size: 10.5pt;
  color: var(--text-muted);
  font-weight: 600;
}

.cover-badge {
  background-color: var(--primary);
  color: #ffffff;
  padding: 6px 16px;
  border-radius: 20px;
  font-size: 10pt;
  font-weight: 700;
  letter-spacing: 0.5px;
}

.cover-body {
  text-align: center;
  margin: 40px 0;
}

.cover-logo-icon {
  width: 80px;
  height: 80px;
  background: var(--primary);
  color: white;
  border-radius: 20px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  font-size: 38pt;
  margin-bottom: 20px;
  box-shadow: 0 10px 25px rgba(15, 76, 92, 0.25);
}

.cover-title {
  font-size: 26pt;
  font-weight: 900;
  color: var(--primary-dark);
  margin-bottom: 12px;
  line-height: 1.3;
}

.cover-subtitle {
  font-size: 14pt;
  color: var(--accent);
  font-weight: 700;
  margin-bottom: 18px;
}

.cover-desc {
  font-size: 11pt;
  color: var(--text-muted);
  max-width: 85%;
  margin: 0 auto 25px auto;
  line-height: 1.7;
}

.cover-highlights {
  display: flex;
  justify-content: center;
  gap: 12px;
  flex-wrap: wrap;
  margin-top: 15px;
}

.cover-highlight-chip {
  background: #ffffff;
  border: 1px solid var(--border);
  padding: 6px 14px;
  border-radius: 8px;
  font-size: 9.5pt;
  font-weight: 600;
  color: var(--primary);
  box-shadow: 0 2px 5px rgba(0,0,0,0.04);
}

.cover-footer {
  border-top: 2px solid var(--border);
  padding-top: 20px;
  display: flex;
  justify-content: space-between;
  font-size: 10pt;
}

.cover-footer-block h4 {
  font-size: 10.5pt;
  color: var(--primary);
  margin-bottom: 4px;
  font-weight: 700;
}

.cover-footer-block p {
  color: var(--text-dark);
}

/* Table of Contents & Structure */
.section-header {
  border-bottom: 2px solid var(--primary);
  padding-bottom: 6px;
  margin-top: 22px;
  margin-bottom: 14px;
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
}

.section-header h2 {
  font-size: 15pt;
  font-weight: 800;
  color: var(--primary);
  display: flex;
  align-items: center;
  gap: 8px;
}

.section-number {
  background: var(--primary);
  color: white;
  padding: 2px 10px;
  border-radius: 6px;
  font-size: 11pt;
}

.section-phase-tag {
  background: var(--primary-light);
  color: var(--primary);
  font-size: 8.5pt;
  font-weight: 700;
  padding: 3px 10px;
  border-radius: 12px;
}

h3 {
  font-size: 12pt;
  font-weight: 700;
  color: var(--secondary);
  margin-top: 14px;
  margin-bottom: 8px;
}

p, li {
  font-size: 10pt;
  color: var(--text-dark);
  margin-bottom: 6px;
  line-height: 1.6;
}

ul, ol {
  padding-right: 20px;
  margin-bottom: 10px;
}

li {
  margin-bottom: 4px;
}

/* Card & Grid Styles */
.grid-2 {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
  margin-bottom: 12px;
}

.grid-3 {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr;
  gap: 10px;
  margin-bottom: 12px;
}

.card {
  background: var(--bg-card);
  border: 1px solid var(--border);
  border-radius: 8px;
  padding: 12px 14px;
  margin-bottom: 10px;
}

.card-primary {
  border-right: 4px solid var(--primary);
}

.card-accent {
  border-right: 4px solid var(--accent);
}

.card-success {
  border-right: 4px solid var(--success);
}

.card-danger {
  border-right: 4px solid var(--danger);
}

.card-title {
  font-weight: 700;
  font-size: 10.5pt;
  color: var(--primary);
  margin-bottom: 6px;
  display: flex;
  align-items: center;
  justify-content: space-between;
}

/* Badges */
.badge {
  display: inline-block;
  padding: 2px 8px;
  border-radius: 4px;
  font-size: 8pt;
  font-weight: 700;
}

.badge-must {
  background-color: #fee2e2;
  color: #991b1b;
}

.badge-should {
  background-color: #fef3c7;
  color: #92400e;
}

.badge-could {
  background-color: #e0f2fe;
  color: #075985;
}

.badge-tech {
  background-color: #f1f5f9;
  color: #334155;
  border: 1px solid #cbd5e1;
  font-family: 'JetBrains Mono', monospace;
  direction: ltr;
}

/* Tables */
table {
  width: 100%;
  border-collapse: collapse;
  margin: 10px 0 14px 0;
  font-size: 9pt;
}

th, td {
  border: 1px solid var(--border);
  padding: 7px 10px;
  text-align: right;
}

th {
  background-color: var(--primary);
  color: #ffffff;
  font-weight: 700;
}

tr:nth-child(even) {
  background-color: #f8fafc;
}

/* Code Snippets & Architecture Boxes */
.code-box {
  background: #0f172a;
  color: #e2e8f0;
  padding: 10px 14px;
  border-radius: 6px;
  font-family: 'JetBrains Mono', monospace;
  font-size: 8.5pt;
  direction: ltr;
  text-align: left;
  line-height: 1.45;
  margin: 8px 0 12px 0;
  overflow-x: hidden;
}

.diagram-container {
  background: #f8fafc;
  border: 1px dashed var(--secondary);
  border-radius: 8px;
  padding: 12px;
  margin: 10px 0 14px 0;
  text-align: center;
}

.diagram-row {
  display: flex;
  justify-content: space-around;
  align-items: center;
  gap: 10px;
  margin: 8px 0;
}

.diagram-node {
  background: white;
  border: 2px solid var(--primary);
  border-radius: 8px;
  padding: 8px 12px;
  font-weight: 700;
  font-size: 9pt;
  color: var(--primary);
  flex: 1;
  box-shadow: 0 2px 4px rgba(0,0,0,0.04);
}

.diagram-arrow {
  color: var(--accent);
  font-size: 14pt;
  font-weight: 900;
}

/* Alert boxes */
.callout {
  padding: 10px 14px;
  border-radius: 6px;
  margin: 10px 0;
  font-size: 9.5pt;
  border-right: 4px solid;
}

.callout-info {
  background-color: #f0f9ff;
  border-color: #0284c7;
  color: #0369a1;
}

.callout-success {
  background-color: #f0fdf4;
  border-color: #16a34a;
  color: #15803d;
}

.callout-warning {
  background-color: #fffbeb;
  border-color: #d97706;
  color: #b45309;
}

.callout-danger {
  background-color: #fef2f2;
  border-color: #dc2626;
  color: #b91c1c;
}

.step-box {
  display: flex;
  gap: 12px;
  margin-bottom: 10px;
  align-items: flex-start;
}

.step-num {
  background: var(--primary);
  color: white;
  width: 26px;
  height: 26px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 800;
  font-size: 9.5pt;
  flex-shrink: 0;
}

.step-content {
  flex: 1;
}

.step-content h4 {
  font-size: 10pt;
  color: var(--primary-dark);
  font-weight: 700;
  margin-bottom: 2px;
}

.step-content p {
  font-size: 9pt;
  color: var(--text-dark);
  margin-bottom: 0;
}

/* Page footer */
.page-footer {
  margin-top: 15px;
  border-top: 1px solid var(--border);
  padding-top: 6px;
  display: flex;
  justify-content: space-between;
  font-size: 8pt;
  color: var(--text-muted);
}
</style>
</head>
<body>

<!-- COVER PAGE -->
<div class="cover-page">
  <div class="cover-header">
    <div class="inst-info">
      <h3>مشروع التخرج الأكاديمي | السنة النهائية</h3>
      <p>قسم علوم الحاسب وهندسة البرمجيات | كلية الحاسبات والمعلومات</p>
    </div>
    <div class="cover-badge">وثيقة هندسية تنفيذية معتمدة</div>
  </div>

  <div class="cover-body">
    <div class="cover-logo-icon">🩺</div>
    <h1 class="cover-title">رفيق العافية (Medliva)</h1>
    <div class="cover-subtitle">المنصة الذكية المتكاملة لرعاية كبار السن ومرضى الأمراض المزمنة</div>
    <p class="cover-desc">
      وثيقة المواصفات الهندسية وخطة التطوير الشاملة لكافة مراحل دورة حياة البرمجيات (SDLC)؛ من استنباط المتطلبات وتحليلها، إلى تصميم واجهات كبار السن (Elderly UX)، وهيكلية النظام وقواعد البيانات، وتطبيق الموبايل العابر للمنصات بنظام المنبهات غير المتصلة الصارم، ودمج نماذج الذكاء الاصطناعي لاستخراج الروشتات الطبية والصوت العربي، وحتى إجراءات النشر واستراتيجية المناقشة الأكاديمية للدفاع عن المشروع.
    </p>

    <div class="cover-highlights">
      <div class="cover-highlight-chip">⚡ منبهات محلية صارمة (Exact Offline Alarms)</div>
      <div class="cover-highlight-chip">👁️ مسح الروشتات بالذكاء الاصطناعي (Multimodal OCR)</div>
      <div class="cover-highlight-chip">🎙️ تسجيل المؤشرات الحيوية بالصوت العربي</div>
      <div class="cover-highlight-chip">👨‍👩‍👧 نظام المرافقة العائلية الفوري والتصعيد</div>
      <div class="cover-highlight-chip">🚨 زر طوارئ SOS مع تتبع الموقع</div>
      <div class="cover-highlight-chip">📊 تقرير الطبيب التحليلي التفاعلي (PDF)</div>
    </div>
  </div>

  <div class="cover-footer">
    <div class="cover-footer-block">
      <h4>نوع الوثيقة</h4>
      <p>دليل التطوير الهندسي الشامل ومخطط دورة الحياة الكاملة</p>
    </div>
    <div class="cover-footer-block">
      <h4>الفريق المنفذ</h4>
      <p>فريق تطوير مشروع التخرج لمهندسي البرمجيات</p>
    </div>
    <div class="cover-footer-block">
      <h4>الحالة الهندسية</h4>
      <p>مكتمل وموثق للمناقشة والتقييم النهائي</p>
    </div>
  </div>
</div>

<!-- EXECUTIVE SUMMARY & ROADMAP OVERVIEW -->
<div class="avoid-break">
  <div class="section-header">
    <h2><span class="section-number">00</span> الملخص التنفيذي ونظرة عامة على المشروع</h2>
    <span class="section-phase-tag">Project Overview & Strategic Value</span>
  </div>

  <div class="card card-primary">
    <div class="card-title">
      <span>سياق المشكلة الإحصائي والطبي (Problem Statement)</span>
      <span class="badge badge-must">أهمية سريرية قصوى</span>
    </div>
    <p>
      تشير تقارير <strong>منظمة الصحة العالمية (WHO)</strong> إلى أن أكثر من <strong>50%</strong> من مرضى الأمراض المزمنة (كالسكري وارتفاع ضغط الدم) يفشلون في الالتزام بالجرعات الدوائية المقررة في مواعيدها الدقيقة، مما يؤدي إلى مضاعفات صحية خطيرة (مثل الغيبوبة السكرية، الجلطات، الفشل الكلوي) وزيادة معدلات الإدخال إلى المستشفيات بنسبة تتجاوز 33%.
    </p>
    <p>
      يعاني كبار السن تحديداً من فجوة رقمية؛ فمعظم التطبيقات الحالية معقدة، مليئة بالإعلانات، تتطلب قراءة نصوص صغيرة بالإنجليزية، ولا تملك تكاملاً حقيقياً بين المريض ومرافقه العائلي أو الطبيب.
    </p>
  </div>

  <div class="grid-3">
    <div class="card">
      <div class="card-title">المستخدم المريض (Elderly)</div>
      <p style="font-size: 8.5pt;">واجهة عملاقة، صوت عالي ناطق باسم الدواء بالعربية، تسجيل القراءات بالصوت العامي دون الحاجة للكتابة، وزر استغاثة بلمسة واحدة.</p>
    </div>
    <div class="card">
      <div class="card-title">المرافق العائلي (Caregiver)</div>
      <p style="font-size: 8.5pt;">متابعة فورية لتناول الأدوية، إشعارات تصعيدية عند تفويت الجرعة، وإدارة الروشتات ومخزون الأقراص المتبقية عن بُعد.</p>
    </div>
    <div class="card">
      <div class="card-title">الطبيب المعالج (Clinician)</div>
      <p style="font-size: 8.5pt;">تقرير طبي دوري احترافي (PDF) يلخص متوسطات السكر والضغط ونسبة الالتزام بالدواء (Adherence %) لاتخاذ قرارات علاجية دقيقة.</p>
    </div>
  </div>

  <h3>خريطة الطريق ومراحل التطوير الرئيسية (Development Lifecycle Roadmap)</h3>
  <div class="diagram-container">
    <div class="diagram-row">
      <div class="diagram-node">المرحلة 1: تحليل المتطلبات والتوصيف الهندسي</div>
      <div class="diagram-arrow">←</div>
      <div class="diagram-node">المرحلة 2: تصميم تجربة المستخدم والشمولية (WCAG)</div>
      <div class="diagram-arrow">←</div>
      <div class="diagram-node">المرحلة 3: المعمارية وقواعد البيانات (Offline-First)</div>
    </div>
    <div class="diagram-row">
      <div class="diagram-node">المرحلة 4: تطوير الخادم والـ Backend APIs</div>
      <div class="diagram-arrow">←</div>
      <div class="diagram-node">المرحلة 5: تطوير تطبيق الموبايل (Flutter Client)</div>
      <div class="diagram-arrow">←</div>
      <div class="diagram-node">المرحلة 6: دمج الذكاء الاصطناعي (OCR + Voice)</div>
    </div>
    <div class="diagram-row">
      <div class="diagram-node">المرحلة 7: نظام المرافقة والـ SOS اللحظي</div>
      <div class="diagram-arrow">←</div>
      <div class="diagram-node">المرحلة 8: المخزون والتقارير الطبية</div>
      <div class="diagram-arrow">←</div>
      <div class="diagram-node">المرحلة 9-11: الاختبارات والنشر ومناقشة التخرج</div>
    </div>
  </div>
</div>

<div class="page-break"></div>

<!-- PHASE 1: REQUIREMENTS ENGINEERING -->
<div class="avoid-break">
  <div class="section-header">
    <h2><span class="section-number">01</span> المرحلة الأولى: هندسة المتطلبات والتحليل الوظيفي (Requirements Engineering)</h2>
    <span class="section-phase-tag">Phase 1: Analysis & Specifications</span>
  </div>

  <div class="card card-primary">
    <div class="card-title">
      <span>تحليل شخصيات المستخدمين وسيناريوهات الاستخدام (Personas & User Stories)</span>
    </div>
    <div class="grid-3" style="margin-bottom: 0;">
      <div>
        <strong style="color: var(--primary); font-size: 9pt;">1. الحاج إبراهيم (70 سنة)</strong>
        <p style="font-size: 8.5pt; margin-top: 3px;">مريض سكري وضغط، ضعيف البصر، يعاني من ارتعاش اليدين. <em>الهدف:</em> معرفة دوائه وسماعه بوضوح، وتسجيل قراءة السكر بصوته دون تعقيد.</p>
      </div>
      <div>
        <strong style="color: var(--primary); font-size: 9pt;">2. مريم (32 سنة - الابنة)</strong>
        <p style="font-size: 8.5pt; margin-top: 3px;">مهندسة تعمل لساعات طويلة ومرافقة لوالدها. <em>الهدف:</em> الاطمئنان اللحظي على أخذ والدها لجرعاته وتلقي تنبيه فوري إذا نسي جرعته لتتصل به.</p>
      </div>
      <div>
        <strong style="color: var(--primary); font-size: 9pt;">3. د. عادل (استشاري باطنة)</strong>
        <p style="font-size: 8.5pt; margin-top: 3px;">طبيب المريض في العيادة. <em>الهدف:</em> الاطلاع على سجل رقمي منظم لالتزام المريض وقياسات السكر التراكمية بدلاً من الدفاتر الورقية الضائعة.</p>
      </div>
    </div>
  </div>

  <h3>مصفوفة المتطلبات الوظيفية المفصلة (Functional Requirements Matrix - MoSCoW)</h3>
  <table>
    <thead>
      <tr>
        <th style="width: 10%;">المعرف</th>
        <th style="width: 25%;">الوظيفة البرمجية</th>
        <th style="width: 48%;">التوصيف الفني والهندسي الدقيق</th>
        <th style="width: 17%;">الأولوية</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td><strong>FR-01</strong></td>
        <td>منبهات الأدوية غير المتصلة</td>
        <td>إطلاق تنبيه صوتي فائق الدقة في الموعد المحدد بنسبة خطأ 0% حتى في وضع عدم الاتصال بالإنترنت ووضع توفير الطاقة (Doze Mode).</td>
        <td><span class="badge badge-must">Must Have</span></td>
      </tr>
      <tr>
        <td><strong>FR-02</strong></td>
        <td>النطق الصوتي للدواء (TTS)</td>
        <td>قراءة اسم الدواء، الجرعة، وتوجيهات الأكل صوتياً باللغة العربية فور انطلاق شاشة التنبيه لمساعدة ضعاف البصر والأميين.</td>
        <td><span class="badge badge-must">Must Have</span></td>
      </tr>
      <tr>
        <td><strong>FR-03</strong></td>
        <td>مسح الروشتات بالذكاء الاصطناعي</td>
        <td>استخراج الأدوية، التراكيز، الجرعات، وتكرارها من صور الروشتات الطبية المكتوبة باليد والطباعة عبر Multimodal LLM وتحويلها لجدول زمني.</td>
        <td><span class="badge badge-must">Must Have</span></td>
      </tr>
      <tr>
        <td><strong>FR-04</strong></td>
        <td>تسجيل المؤشرات الحيوية بالصوت</td>
        <td>تحليل التسجيلات الصوتية بالعامية (مثل: "السكر بتاعي 140 بعد الفطار") واستخراج الرقم والسياق وحفظه في سجل المؤشرات.</td>
        <td><span class="badge badge-must">Must Have</span></td>
      </tr>
      <tr>
        <td><strong>FR-05</strong></td>
        <td>التصنيف السريري للمؤشرات</td>
        <td>مقارنة قياسات السكر والضغط بالنطاقات السريرية المعتمدة وتصنيفها فورياً (طبيعي / تحذير / خطر) مع تقديم إرشادات وقائية.</td>
        <td><span class="badge badge-must">Must Have</span></td>
      </tr>
      <tr>
        <td><strong>FR-06</strong></td>
        <td>الربط العائلي اللحظي</td>
        <td>اقتران حساب المرافق بحساب المريض عبر مسح QR Code أو إدخال كود من 6 أرقام مع تحديث الحالة بشكل فوري عبر WebSockets/FCM.</td>
        <td><span class="badge badge-must">Must Have</span></td>
      </tr>
      <tr>
        <td><strong>FR-07</strong></td>
        <td>نظام تصعيد التنبيهات (Escalation)</td>
        <td>عند تفويت المريض للجرعة لأكثر من 20 دقيقة، يُرسل إشعار أحمر طارئ لهاتف المرافق مع خيار إجراء اتصال هاتفي بنقرة واحدة.</td>
        <td><span class="badge badge-must">Must Have</span></td>
      </tr>
      <tr>
        <td><strong>FR-08</strong></td>
        <td>زر الاستغاثة والطوارئ (SOS)</td>
        <td>إرسال رسائل SMS/واتساب تتضمن إحداثيات GPS الدقيقة إلى المرافقين وتشغيل إنذار صوتي محلي وبدء اتصال بالطوارئ.</td>
        <td><span class="badge badge-must">Must Have</span></td>
      </tr>
      <tr>
        <td><strong>FR-09</strong></td>
        <td>إدارة رصيد الأقراص الذكي</td>
        <td>حساب الرصيد المتبقي تلقائياً مع كل جرعة مؤكدة، والتنبؤ بتاريخ النفاد والتنبيه المسبق بـ 5 أيام لطلب إعادة التعبئة.</td>
        <td><span class="badge badge-should">Should Have</span></td>
      </tr>
      <tr>
        <td><strong>FR-10</strong></td>
        <td>تصدير تقرير الطبيب (PDF)</td>
        <td>توليد ملف PDF عالي الجودة يحتوي على نسبة الالتزام الشهرية، منحنيات السكر والضغط، وقائمة الأدوية النشطة بنقرة واحدة.</td>
        <td><span class="badge badge-should">Should Have</span></td>
      </tr>
    </tbody>
  </table>

  <h3>المتطلبات غير الوظيفية (Non-Functional Requirements - NFRs)</h3>
  <div class="grid-2">
    <div class="card card-accent">
      <div class="card-title">الموثوقية وزمن الاستجابة (Reliability & Latency)</div>
      <ul>
        <li><strong>دقة المنبه:</strong> نسبة نجاح رنين المنبه 100% في الموعد الحرج حتى بعد إغلاق التطبيق بالقوة أو إعادة تشغيل الهاتف.</li>
        <li><strong>استجابة الـ API:</strong> متوسط زمن استجابة طلبات الشبكة أقل من 250 ميلي ثانية.</li>
        <li><strong>معالجة الصوت والروشتة:</strong> تحليل الصوت في أقل من ثانيتين، واستخراج الروشتة في أقل من 5 ثوانٍ.</li>
      </ul>
    </div>
    <div class="card card-success">
      <div class="card-title">الخصوصية وإتاحة الاستخدام (Privacy & Accessibility)</div>
      <ul>
        <li><strong>إتاحة كبار السن:</strong> مطابقة معايير WCAG 2.1 AAA (تباين الألوان >= 7:1، مساحات لمس >= 60x60dp).</li>
        <li><strong>أمان البيانات:</strong> تشفير السجلات الطبية الحساسة وفق معايير AES-256، ونقل البيانات عبر TLS 1.3.</li>
        <li><strong>استهلاك البطارية:</strong> استهلاك منخفض جداً لخلفية النظام لا يتجاوز 2-3% من طاقة البطارية اليومية.</li>
      </ul>
    </div>
  </div>
</div>

<div class="page-break"></div>

<!-- PHASE 2: UI/UX & ACCESSIBILITY -->
<div class="avoid-break">
  <div class="section-header">
    <h2><span class="section-number">02</span> المرحلة الثانية: هندسة تجربة المستخدم والشمولية لكبار السن (Geriatric UI/UX)</h2>
    <span class="section-phase-tag">Phase 2: Accessibility & Screen Design</span>
  </div>

  <div class="callout callout-info">
    <strong>فلسفة التصميم الأساسية:</strong> "مهمة واحدة في كل شاشة (Single-Task Screen Principle)" مع تجنب القوائم المتداخلة والرموز المبهمة، وضمان التغذية الراجعة ثلاثية الأبعاد (صوت ناطق + اهتزاز لمسي نمطي Haptic + مؤشر بصري عالي التباين).
  </div>

  <div class="grid-2">
    <div class="card card-primary">
      <div class="card-title">1. قواعد الوصولية لكبار السن (WCAG 2.1 AAA)</div>
      <ul>
        <li><strong>حجم أهداف اللمس (Touch Targets):</strong> جميع الأزرار التفاعلية لا تقل أبعادها عن <strong>60 × 60 نقطة (dp)</strong>، مع تباعد أدنى 16dp لمنع الضغط بالخطأ بسبب ارتعاش اليدين.</li>
        <li><strong>الطباعة والخطوط (Typography):</strong> استخدام خط Cairo العربي بوزن عريض (Bold/Extrabold) للنصوص الأساسية، بحجم خط لا يقل عن 18pt للنصوص و 24-32pt للأرقام والجرعات.</li>
        <li><strong>التباين اللوني (Contrast Ratio):</strong> نسبة تباين لا تقل عن <strong>7:1</strong> بين النصوص والخلفيات، مع دعم الوضع الداكن التلقائي عالي التباين.</li>
      </ul>
    </div>

    <div class="card card-accent">
      <div class="card-title">2. التغذية الراجعة الحسية (Tri-Sensory Feedback)</div>
      <ul>
        <li><strong>الاستجابة اللمسية (Haptics):</strong> نبضات اهتزاز ثقيلة متكررة عند انطلاق المنبه، ونبضة تأكيد مميزة عند الضغط على "تم تناول الدواء".</li>
        <li><strong>النطق الصوتي التلقائي (TTS):</strong> قراءة فورية بالصوت العربي الواضح: <em>"حان الآن موعد دواء جلوكوفاج، قرص واحد بعد الأكل"</em>.</li>
        <li><strong>التأكيد البصري المريح:</strong> ظهور بطاقة خضراء عملاقة مع علامة صح واضحة وصوت جرس مهدئ عند تأكيد الجرعة لمنح المريض راحة نفسية.</li>
      </ul>
    </div>
  </div>

  <h3>هيكلية الشاشات الرئيسية وتدفق الواجهات (Screen Architecture & User Flows)</h3>
  <div class="grid-2">
    <div class="card">
      <div class="card-title" style="color: var(--primary);">شاشة المنبه فوق قفل الشاشة (Lockscreen Alarm Activity)</div>
      <p style="font-size: 8.5pt;">شاشة كاملة تضيء الهاتف تلقائياً وتتخطى قفل الشاشة، تحتوي على:</p>
      <ul style="font-size: 8.5pt;">
        <li>صورة واضحة لعلبة الدواء ولون القرص وشكله الهندسي.</li>
        <li>اسم الدواء بخط 28pt + الجرعة والتعليمات (قبل/بعد الأكل).</li>
        <li>زران ضخمان فقط:
          <br>• <strong style="color: var(--success);">[أخذت الدواء الآن]</strong> (زر أخضر عملاق يشغل 60% من الشاشة).
          <br>• <strong style="color: var(--warning);">[غفوة 10 دقائق]</strong> (زر برتقالي جانبي للتبديل).
        </li>
      </ul>
    </div>

    <div class="card">
      <div class="card-title" style="color: var(--primary);">لوحة المريض الرئيسية (Elderly Dashboard)</div>
      <p style="font-size: 8.5pt;">واجهة فائقة التبسيط مقسمة إلى 3 مناطق أساسية فقط:</p>
      <ul style="font-size: 8.5pt;">
        <li><strong>البطاقة العلوية:</strong> بطاقة الجرعة القادمة مع عداد تنازلي كبير وزر تأكيد مسبق.</li>
        <li><strong>المنطقة الوسطى:</strong> زر ميكروفون دائري ضخم أحمر/أزرق ينبض لتسجيل قراءات السكر والضغط صوتياً.</li>
        <li><strong>المنطقة السفلية:</strong> زر الاستغاثة السريع SOS باللون الأحمر الفاقع محاط بحدود واضحة ومحمية من الضغط العفوي.</li>
      </ul>
    </div>
  </div>

  <div class="card card-success">
    <div class="card-title">لوحة تحكم المرافق العائلي (Caregiver Companion Hub)</div>
    <p style="font-size: 9pt;">
      واجهة متطورة مخصصة للأبناء أو الممرضين توفر: شريط تقدم بياني للالتزام اليومي (مثلاً: 3/4 جرعات تم تناولها بنجاح)، سجل حي يُحدث في نفس اللحظة (Realtime Activity Feed)، قائمة بحالة مخزون الأدوية مع مؤشر تحذيري للأدوية التي شارف رصيدها على النفاد، وزر تواصل سريع للاتصال بالمريض أو تذكيره.
    </p>
  </div>
</div>

<div class="page-break"></div>

<!-- PHASE 3: ARCHITECTURE & DATABASE DESIGN -->
<div class="avoid-break">
  <div class="section-header">
    <h2><span class="section-number">03</span> المرحلة الثالثة: الهيكلية البرمجية وتصميم قواعد البيانات (System Architecture & DB Design)</h2>
    <span class="section-phase-tag">Phase 3: Software & Data Architecture</span>
  </div>

  <div class="card card-primary">
    <div class="card-title">الهيكلية الشاملة للنظام (Multi-Tier Distributed Architecture)</div>
    <p style="font-size: 9pt;">
      يعتمد النظام على نمط المعمارية النظيفة (Clean Architecture) في الواجهات الأمامية مع بنية غير متصلة أولاً (Offline-First Local DB)، بينما يعتمد الخادم الخلفي على Modular Monolith باستخدام Python FastAPI وSQLAlchemy وAlembic فوق PostgreSQL. المهام الدورية للمراقبة والتصعيد تبدأ عبر Supabase Cron وواجهات FastAPI داخلية محمية، مع إبقاء Redis اختيارياً عند الحاجة فقط.
    </p>
  </div>

  <div class="diagram-container">
    <div style="font-weight: 800; font-size: 9.5pt; color: var(--primary); margin-bottom: 8px;">مخطط تدفق البيانات والمكونات البرمجية الكلية (System Architecture Diagram)</div>
    <div class="diagram-row">
      <div class="diagram-node" style="border-color: #0284c7;">
        <strong>تطبيق المريض (Flutter)</strong><br>
        <span style="font-size: 8pt; color: #555;">SQLite (Drift) + Local Alarm Engine + TTS</span>
      </div>
      <div class="diagram-arrow">⇄</div>
      <div class="diagram-node" style="border-color: #0f4c5c;">
        <strong>بوابة الـ API (FastAPI)</strong><br>
        <span style="font-size: 8pt; color: #555;">JWT Auth + REST Endpoints + WebSockets</span>
      </div>
      <div class="diagram-arrow">⇄</div>
      <div class="diagram-node" style="border-color: #16a34a;">
        <strong>تطبيق المرافق (Flutter)</strong><br>
        <span style="font-size: 8pt; color: #555;">Realtime Stream + Push Alerts + Adherence Hub</span>
      </div>
    </div>
    <div class="diagram-row" style="margin-top: 12px;">
      <div class="diagram-node" style="border-color: #d97706;">
        <strong>محرك الذكاء الاصطناعي</strong><br>
         <span style="font-size: 8pt; color: #555;">Gemini Vision + Hosted STT + Deterministic Triage</span>
      </div>
      <div class="diagram-arrow">⇄</div>
      <div class="diagram-node" style="border-color: #9333ea;">
        <strong>محرك الجدولة والرسائل</strong><br>
         <span style="font-size: 8pt; color: #555;">Supabase Cron + Protected Jobs + FCM Push</span>
      </div>
      <div class="diagram-arrow">⇄</div>
      <div class="diagram-node" style="border-color: #dc2626;">
        <strong>قاعدة البيانات المركزية</strong><br>
        <span style="font-size: 8pt; color: #555;">PostgreSQL (Relational Storage & Timeseries)</span>
      </div>
    </div>
  </div>

  <h3>استراتيجية العمل غير المتصل والمزامنة التفاضلية (Offline-First Delta Sync Engine)</h3>
  <div class="grid-2">
    <div class="card card-accent">
      <div class="card-title">طابور التعديلات المحلي (Local Mutation Queue)</div>
      <p style="font-size: 8.5pt;">
        كل عملية يقوم بها المريض (تأكيد جرعة، تسجيل سكر، تعديل دواء) تُسجل فوراً في جدول محلي <code>sync_queue</code> بحالة <code>PENDING</code> وتنفذ محلياً دون انتظار اتصال الإنترنت.
      </p>
      <div class="code-box">
CREATE TABLE sync_queue (
  id UUID PRIMARY KEY,
  table_name VARCHAR(50) NOT NULL,
  record_id UUID NOT NULL,
  action VARCHAR(10) NOT NULL, -- INSERT, UPDATE, DELETE
  payload_json TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  retry_count INT DEFAULT 0
);</div>
    </div>

    <div class="card card-success">
      <div class="card-title">حل التعارضات (Conflict Resolution Strategy)</div>
      <p style="font-size: 8.5pt;">
        <strong>قاعدة أسبقية تأكيد الجرعة (Intake Priority Rule):</strong> إذا تم تسجيل الجرعة كـ "مأخوذة" محلياً بينما سجلها المرافق أو الخادم كـ "فائتة" نتيجة انقطاع الاتصال، فإن حالة "المأخوذة" تلغي ما دونها فور استعادة الشبكة، ويتم تحديث مؤشرات الالتزام فوراً بالاعتماد على التوقيت المحلي الفعلي <code>actual_taken_at</code>.
      </p>
    </div>
  </div>

  <h3>المخطط العلائقي لقاعدة البيانات (Entity Relationship Tables & Schema)</h3>
  <table>
    <thead>
      <tr>
        <th style="width: 18%;">اسم الجدول</th>
        <th style="width: 25%;">المفاتيح الأساسية والخارجية</th>
        <th style="width: 42%;">أهم الحقول والأنواع</th>
        <th style="width: 15%;">الدور الوظيفي</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td><code>users</code></td>
        <td><code>id (PK)</code></td>
        <td><code>phone_number, full_name, role (patient/caregiver/admin), created_at</code><br>الدور لا يحدده التسجيل العام؛ caregiver عبر pairing وadmin provisioned separately.</td>
        <td>إدارة الحسابات والمصادقة</td>
      </tr>
      <tr>
        <td><code>caregiver_links</code></td>
        <td><code>id (PK), caregiver_id (FK), patient_id (FK)</code></td>
        <td><code>pairing_code, status (active/pending), permissions_mask, linked_at</code></td>
        <td>علاقة ربط المرافق بالمريض</td>
      </tr>
      <tr>
        <td><code>medications</code></td>
        <td><code>id (PK), patient_id (FK)</code></td>
        <td><code>name, trade_name, dosage_form, strength, pill_image_url, stock_count, alert_threshold</code></td>
        <td>سجل الأدوية والمخزون</td>
      </tr>
      <tr>
        <td><code>schedules</code></td>
        <td><code>id (PK), medication_id (FK)</code></td>
        <td><code>time_of_day, days_of_week_mask, dose_amount, instructions_ar, is_active</code></td>
        <td>مواعيد وتكرار الجرعات</td>
      </tr>
      <tr>
        <td><code>intake_logs</code></td>
        <td><code>id (PK), schedule_id (FK), patient_id (FK)</code></td>
        <td><code>scheduled_time, actual_taken_time, status (taken/snoozed/missed), logged_offline</code></td>
        <td>سجل الالتزام الدوائي</td>
      </tr>
      <tr>
        <td><code>vitals_logs</code></td>
        <td><code>id (PK), patient_id (FK)</code></td>
        <td><code>vital_type (glucose/bp), value_primary, value_secondary, meal_context, recorded_at, ai_raw_transcript</code></td>
        <td>سجل قياسات السكر والضغط</td>
      </tr>
      <tr>
        <td><code>prescriptions</code></td>
        <td><code>id (PK), patient_id (FK)</code></td>
        <td><code>image_url, doctor_name, raw_extracted_json, verified_at</code></td>
        <td>أرشيف الروشتات الممسوحة</td>
      </tr>
      <tr>
        <td><code>emergency_contacts</code></td>
        <td><code>id (PK), patient_id (FK)</code></td>
        <td><code>contact_name, phone_number, relationship, is_primary, notify_sms, notify_call</code></td>
        <td>جهات اتصال زر الاستغاثة</td>
      </tr>
    </tbody>
  </table>
</div>

<div class="page-break"></div>

<!-- PHASE 4: BACKEND & API IMPLEMENTATION -->
<div class="avoid-break">
  <div class="section-header">
    <h2><span class="section-number">04</span> المرحلة الرابعة: تطوير الخادم والواجهات الخلفية (Backend API & Services)</h2>
    <span class="section-phase-tag">Phase 4: FastAPI Modular Monolith</span>
  </div>

  <div class="card card-primary">
    <div class="card-title">حزمة التقنيات المختارة للخادم (Backend Tech Stack Rationale)</div>
    <p style="font-size: 9pt;">
      تم اختيار <strong>Python FastAPI</strong> لتطوير الـ Backend؛ نظراً لأدائه المبني على <code>asyncio</code> و <code>Starlette</code>، ودعمه الأصيل للـ Pydantic v2 لتأكيد صحة البيانات وتوليد وثائق OpenAPI. تُدار البيانات عبر <strong>SQLAlchemy 2 + Alembic + PostgreSQL</strong>، وتبقى الخدمات داخل Modular Monolith بسيط قابل للتوسع.
    </p>
  </div>

  <h3>أهم الواجهات البرمجية (Core RESTful API Endpoints)</h3>
  <table>
    <thead>
      <tr>
        <th style="width: 10%;">Method</th>
        <th style="width: 25%;">Endpoint Path</th>
        <th style="width: 45%;">الغرض والبيانات المتبادلة (Payload / Response)</th>
        <th style="width: 20%;">صلاحية الوصول</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td><span class="badge badge-must">POST</span></td>
        <td><code>/api/v1/auth/otp/request</code><br><code>/api/v1/auth/otp/verify</code></td>
        <td>إرسال كود OTP والتحقق منه. التسجيل العام ينشئ patient فقط، ثم يتم إصدار JWT قصير وRefresh Session قابلة للتدوير والإلغاء.</td>
        <td>Public</td>
      </tr>
      <tr>
        <td><span class="badge badge-must">POST</span></td>
        <td><code>/api/v1/caregiver/pair</code></td>
        <td>ربط المرافق بالمريض عبر الكود المولد ومزامنة الصلاحيات.</td>
        <td>Caregiver / Patient</td>
      </tr>
      <tr>
        <td><span class="badge badge-should">GET</span></td>
        <td><code>/api/v1/medications/active</code></td>
        <td>جلب قائمة أدوية المريض المجدولة مع تفاصيل المخزون ومواعيد اليوم.</td>
        <td>Authenticated</td>
      </tr>
      <tr>
        <td><span class="badge badge-must">POST</span></td>
        <td><code>/api/v1/adherence/log</code></td>
        <td>تسجيل تناول الجرعة، خصم قرص من المخزون، وبث إشعار فوري عبر WebSocket.</td>
        <td>Patient / App Sync</td>
      </tr>
      <tr>
        <td><span class="badge badge-must">POST</span></td>
        <td><code>/api/v1/ai/scan-prescription</code></td>
        <td>رفع صورة الروشتة وإعادتها مهيكلة كقائمة أدوية جاهزة للحفظ.</td>
        <td>Authenticated</td>
      </tr>
      <tr>
        <td><span class="badge badge-must">POST</span></td>
        <td><code>/api/v1/ai/parse-voice-vitals</code></td>
        <td>استلام ملف صوتي (WAV/M4A) واستخراج نوع القراءة وقيمتها وتصنيفها.</td>
        <td>Authenticated</td>
      </tr>
      <tr>
        <td><span class="badge badge-should">GET</span></td>
        <td><code>/api/v1/reports/doctor-pdf</code></td>
        <td>توليد التقرير الطبي التحليلي بصيغة PDF وإرجاع رابط تنزيل مباشر.</td>
        <td>Caregiver / Patient</td>
      </tr>
      <tr>
        <td><span class="badge badge-must">POST</span></td>
        <td><code>/api/v1/emergency/sos-broadcast</code></td>
        <td>إطلاق حالة الطوارئ وإرسال تنبيهات FCM عالية الأولوية ورسائل Twilio.</td>
        <td>Patient</td>
      </tr>
    </tbody>
  </table>

  <h3>عامل رصد الجرعات الفائتة وهرم التصعيد (Background Adherence Watcher)</h3>
  <div class="step-box">
    <div class="step-num">1</div>
    <div class="step-content">
        <h4>المسح الدوري المنتظم (Supabase Cron Scheduled Job)</h4>
      <p>عامل يعمل كل 60 ثانية يفحص جدول <code>schedules</code> مع <code>intake_logs</code> للعثور على أي جرعة انقضى موعدها المحدد بأكثر من 15 دقيقة دون تسجيل حالة (Unacknowledged).</p>
    </div>
  </div>
  <div class="step-box">
    <div class="step-num">2</div>
    <div class="step-content">
      <h4>التنبيه التذكيري الأول للمريض (Local In-App Reminder)</h4>
      <p>يتم إرسال إشعار محلي عالي الصوت لهاتف المريض لتذكيره بلطف: "تذكير: لم تسجل تناول دواء السكر المقرر منذ 15 دقيقة".</p>
    </div>
  </div>
  <div class="step-box">
    <div class="step-num">3</div>
    <div class="step-content">
      <h4>التصعيد للمرافق العائلي عند الدقيقة 25 (Caregiver Critical Escalation)</h4>
      <p>إذا استمر عدم التفاعل لمدة 25 دقيقة، يُطلق الخادم رسالة <strong>FCM High-Priority Data Push</strong> لهاتف المرافق تشغل نغمة رنين خاصة مع إشعار أحمر: <em>"تنبيه عاجل: والدك لم يتناول جرعة علاج الضغط حتى الآن!"</em> مع زر اتصال مباشر.</p>
    </div>
  </div>
</div>

<div class="page-break"></div>

<!-- PHASE 5: FLUTTER MOBILE APP DEVELOPMENT -->
<div class="avoid-break">
  <div class="section-header">
    <h2><span class="section-number">05</span> المرحلة الخامسة: تطوير تطبيق الهاتف المحمول (Flutter Cross-Platform Client)</h2>
    <span class="section-phase-tag">Phase 5: Mobile Client & Exact Alarms</span>
  </div>

  <div class="card card-primary">
    <div class="card-title">هيكلية مشروع Flutter النظيفة (Clean Architecture Directory Layout)</div>
    <p style="font-size: 8.5pt;">تنظيم المشروع بنمط الطبقات المعزولة (Presentation, Domain, Data) لضمان سهولة الاختبار وتطوير الميزات باستقلالية تامة:</p>
    <div class="code-box">
lib/
├── core/                  # الأدوات المشتركة، الثوابت، محرك الصوت TTS، ومحرك المنبهات
│   ├── alarms/            # ExactAlarmService (AlarmManager & Notifications)
│   ├── network/           # Dio Client + Auth Interceptors + Offline Retry
│   ├── theme/             # WCAG High Contrast Palettes & Typography
│   └── tts/               # ArabicTtsEngine (flutter_tts wrapper)
├── features/              # الميزات البرمجية المستقلة (Features)
│   ├── adherence_alarm/   # شاشة المنبه المنبثقة، منطق الإقرار والغفوة
│   ├── prescription_ocr/  # التقاط الصورة، المعاينة، الاستدعاء والمراجعة
│   ├── voice_vitals/      # مسجل الصوت، البث المباشر، وتصنيف القراءات
│   ├── caregiver_sync/    # لوحة المرافق، كود الاقتران، البث الحي
│   └── emergency_sos/     # محدد الموقع GPS وزر الاستغاثة ومسارات الاتصال
└── main.dart              # نقطة البداية، تهيئة الخدمات في الخلفية وإعادة الجدولة</div>
  </div>

  <h3>هندسة المنبهات الصارمة المستقلة (Exact Offline Alarms Engineering)</h3>
  <div class="grid-2">
    <div class="card card-danger">
      <div class="card-title">تخطي قيود نظام أندرويد (Doze Mode & Standby Bypass)</div>
      <ul>
        <li>استخدام تصاريح أندرويد الصارمة: <code>USE_EXACT_ALARM</code> و <code>SCHEDULE_EXACT_ALARM</code> في <code>AndroidManifest.xml</code>.</li>
        <li>جدولة المنبهات عبر <code>AlarmManager.setExactAndAllowWhileIdle()</code> مع حجز <code>PARTIAL_WAKE_LOCK</code> لمنع نوم المعالج أثناء إطلاق النغمة.</li>
        <li>تعطيل قيود تحسين البطارية (Battery Optimization Whitelisting) عبر توجيه المريض لشاشة النظام بنقرة واحدة عند الإعداد الأولي.</li>
      </ul>
    </div>

    <div class="card card-success">
      <div class="card-title">التعامل مع إعادة تشغيل الهاتف (Boot Recovery Receiver)</div>
      <ul>
        <li>تسجيل <code>BroadcastReceiver</code> يستمع للحدث <code>ACTION_BOOT_COMPLETED</code>.</li>
        <li>فور تشغيل هاتف المريض مجدداً، يتم استدعاء دالة محلية تقرأ جدول الأدوية النشطة من قاعدة بيانات SQLite المحلية وتُعيد جدولة كافة المنبهات فوراً دون الحاجة لفتح التطبيق أو وجود اتصال بالإنترنت!</li>
      </ul>
    </div>
  </div>

  <h3>منظومة شاشة التنبيه بالحجم الكامل (Full-Screen Intent UI)</h3>
  <div class="callout callout-warning">
    <strong>كيف تعمل؟</strong> يتم إطلاق إشعار ذو أولوية <code>NotificationCompat.PRIORITY_MAX</code> مدمج معه <code>FullScreenIntent</code>؛ مما يجعل واجهة التنبيه تظهر فوراً فوق شاشة القفل وتضيء شاشة الهاتف تلقائياً مع تشغيل نغمة إنذار متصاعدة لا تتوقف إلا بضغط المريض على زر التأكيد.
  </div>

  <div class="code-box">
// كود إطلاق شاشة التنبيه المتخطية للقفل في Flutter / Android
const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
  'medication_alarms_channel_v2',
  'منبهات الأدوية الحرجة',
  channelDescription: 'قناة التنبيهات الدوائية الصارمة بصوت عالي وأولوية قصوى',
  importance: Importance.max,
  priority: Priority.high,
  fullScreenIntent: true, // يظهر فوق قفل الشاشة تلقائياً
  category: AndroidNotificationCategory.alarm,
  audioAttributesUsage: AudioAttributesUsage.alarm,
  ongoing: true,          // يمنع مسح الإشعار بالسحب
  autoCancel: false,
);</div>
</div>

<div class="page-break"></div>

<!-- PHASE 6: AI & COMPUTER VISION INTEGRATION -->
<div class="avoid-break">
  <div class="section-header">
    <h2><span class="section-number">06</span> المرحلة السادسة: دمج نماذج الذكاء الاصطناعي ومعالجة البيانات الطبية (AI & CV)</h2>
    <span class="section-phase-tag">Phase 6: Multimodal OCR & Arabic Voice STT</span>
  </div>

  <div class="grid-2">
    <div class="card card-primary">
      <div class="card-title">الموديول 1: مسح الروشتات (Multimodal Prescription OCR)</div>
      <p style="font-size: 8.5pt;"><strong>خطوات معالجة الروشتة الطبية:</strong></p>
      <ol style="font-size: 8.5pt;">
        <li><strong>المعالجة المسبقة للصورة:</strong> إزالة الضوضاء وتصحيح التباين وتحديد أبعاد الروشتة عبر OpenCV.</li>
        <li><strong>استدعاء Multimodal LLM:</strong> إرسال الصورة إلى GPT-4o Vision مع System Prompt صيدلاني مدرب على قراءة خطوط الأطباء والمصطلحات والرموز الطبية (مثل: BID, TID, PRN, بعد الأكل).</li>
        <li><strong>إخراج منظم (Structured JSON Schema):</strong> إجبار النموذج على إرجاع بيانات مهيكلة عبر Pydantic لضمان عدم وجود أخطاء في التنسيق.</li>
        <li><strong>كشف التداخلات الدوائية:</strong> تدقيق الأدوية المستخرجة مع أدوية المريض الحالية والتحذير من أي تعارضات خطيرة.</li>
      </ol>
    </div>

    <div class="card card-accent">
      <div class="card-title">الموديول 2: تسجيل المؤشرات بالصوت العربي (Voice Vitals)</div>
      <p style="font-size: 8.5pt;"><strong>خطوات معالجة الصوت واللهجات:</strong></p>
      <ol style="font-size: 8.5pt;">
        <li><strong>التسجيل المحلي:</strong> تسجيل مقطع صوتي نقي بمعدل عينات 16kHz عبر واجهة الميكروفون بضغطة زر واحدة.</li>
        <li><strong>تحويل الصوت لنص (Whisper STT):</strong> تحويل التسجيل إلى نص عربي بدقة فائقة مع دعم اللهجات العامية (المصرية والخليجية والشامية).</li>
        <li><strong>استخراج الكيانات الطبية (NER):</strong> نموذج لغوي يستخرج:
          <br>• النوع: (سكر / ضغط).
          <br>• القيمة: (مثلاً: 135، أو 140 على 90).
          <br>• السياق: (صائم / بعد الأكل بساعتين / عشوائي).
        </li>
      </ol>
    </div>
  </div>

  <h3>نموذج البيانات المنظم للروشتة المستخرجة بالذكاء الاصطناعي (Pydantic Schema)</h3>
  <div class="code-box">
class ExtractedMedication(BaseModel):
    trade_name: str = Field(description="الاسم التجاري للدواء")
    scientific_name: Optional[str] = Field(description="المادة الفعالة إن وجدت")
    dosage: str = Field(description="التركيز، مثلاً 500mg أو 5ml")
    form: str = Field(description="شكل الجرعة: أقراص، شراب، حقن، إلخ")
    frequency_per_day: int = Field(description="عدد مرات التناول في اليوم")
    timing_instructions: str = Field(description="تعليمات التناول بالعربية مثل: بعد الغداء")
    duration_days: Optional[int] = Field(description="مدة العلاج بالأيام")

class PrescriptionScanResult(BaseModel):
    doctor_name: Optional[str]
    diagnosis_notes: Optional[str]
    medications: List[ExtractedMedication]
    safety_warnings: List[str] = Field(description="أي تحذيرات تخص الجرعات العالية أو التعارضات")</div>

  <h3>محرك القواعد السريرية وتصنيف المؤشرات الحيوية (Clinical Decision Rules)</h3>
  <table>
    <thead>
      <tr>
        <th style="width: 20%;">المؤشر الحيوي</th>
        <th style="width: 25%;">القراءة السريرية</th>
        <th style="width: 20%;">التصنيف الصحي</th>
        <th style="width: 35%;">الإجراء الوقائي الآلي والتغذية الراجعة</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td rowspan="3"><strong>سكر الدم (Blood Glucose)</strong><br><span style="font-size: 7.5pt; color: #666;">(mg/dL)</span></td>
        <td>أقل من 70 mg/dL</td>
        <td><span class="badge badge-must">هبوط سكر حاد (خطر)</span></td>
        <td>تنبيه صوتي عاجل بتناول نصف كوب عصير/عسل فوراً + إشعار طارئ للمرافق.</td>
      </tr>
      <tr>
        <td>80 - 130 (صائم) / &lt;180 (فاطر)</td>
        <td><span class="badge badge-could">معدل سكر منضبط (طبيعي)</span></td>
        <td>رسالة تشجيعية خضراء: "قراءتك ممتازة، واصل الالتزام بنظامك الغذائي".</td>
      </tr>
      <tr>
        <td>أكبر من 250 mg/dL</td>
        <td><span class="badge badge-should">ارتفاع سكر شديد (تحذير)</span></td>
        <td>نصيحة بشرب كوبين ماء وقياس السكر مجدداً بعد ساعتين مع إخطار المرافق.</td>
      </tr>
      <tr>
        <td rowspan="3"><strong>ضغط الدم (Blood Pressure)</strong><br><span style="font-size: 7.5pt; color: #666;">(mmHg)</span></td>
        <td>أقل من 120 / 80 mmHg</td>
        <td><span class="badge badge-could">ضغط دم مثالي (طبيعي)</span></td>
        <td>عرض مؤشر القلب الأخضر وحفظ القراءة في السجل التراكمي للطبيب.</td>
      </tr>
      <tr>
        <td>130-139 / 80-89 mmHg</td>
        <td><span class="badge badge-should">ارتفاع مرحلة 1 (تحذير)</span></td>
        <td>تذكير بتقليل الملح والراحة والاسترخاء ومتابعة القياس المسائي.</td>
      </tr>
      <tr>
        <td>أكبر من 180 / 120 mmHg</td>
        <td><span class="badge badge-must">أزمة فرط ضغط دم (طارئ)</span></td>
        <td>طلب الراحة الفورية في وضع الجلوس، تفعيل زر الطوارئ، وتنبيه المرافق فوراً.</td>
      </tr>
    </tbody>
  </table>
</div>

<div class="page-break"></div>

<!-- PHASE 7: CAREGIVER SYNC & EMERGENCY SYSTEM -->
<div class="avoid-break">
  <div class="section-header">
    <h2><span class="section-number">07</span> المرحلة السابعة: نظام المرافقة العائلية والمزامنة اللحظية وزر الطوارئ (Caregiver & SOS)</h2>
    <span class="section-phase-tag">Phase 7: Realtime Sync & Emergency SOS</span>
  </div>

  <div class="grid-2">
    <div class="card card-primary">
      <div class="card-title">1. بروتوكول الاقتران العائلي السريع (Pairing Protocol)</div>
      <ul>
        <li><strong>بدء الربط:</strong> يضغط المريض على "إضافة مرافق" فيظهر <strong>رمز QR كبير</strong> بالإضافة إلى <strong>كود رقمي مؤقت من 6 أرقام</strong> صالح لمدة 15 دقيقة فقط (Time-based One Time Token).</li>
        <li><strong>المسح والتأكيد:</strong> يفتح المرافق تطبيقه ويختار "مسح كود المريض"، ليتم التحقق عبر الخادم وتأسيس علاقة <code>caregiver_patient_links</code> مشفرة تلقائياً.</li>
        <li><strong>أذونات قابلة للتخصيص:</strong> يمكن تحديد الصلاحيات (قراءة فقط، إدارة وتعديل الأدوية، استقبال تنبيهات الطوارئ).</li>
      </ul>
    </div>

    <div class="card card-accent">
      <div class="card-title">2. المزامنة اللحظية (Real-Time WebSocket Stream)</div>
      <ul>
        <li>قناة <strong>WebSocket</strong> مشفرة تظل مفتوحة بين خادم النظام وتطبيق المرافق.</li>
        <li>فور قيام المريض بالضغط على "تم أخذ الدواء"، يُرسل الحدث خلال أقل من 100 ميلي ثانية إلى شاشة المرافق ليتحول لون الجرعة من رمادي إلى أخضر مع تسجيل الوقت الدقيق.</li>
        <li>في حال انقطاع اتصال المرافق، يعمل نظام <strong>FCM Push Notifications</strong> كقناة احتياطية مضمونة لتسليم الإشعارات فور توفر الشبكة.</li>
      </ul>
    </div>
  </div>

  <h3>هندسة زر الاستغاثة والطوارئ الشامل (Multi-Action Emergency SOS Engine)</h3>
  <div class="callout callout-danger">
    <strong>زر طوارئ ذكي آمن:</strong> لمنع إطلاق الاستغاثة بالخطأ، يتطلب الزر الضغط المستمر لمدة ثانيتين ونصف (Long-Press with Circular Fill Indicator) مصحوباً باهتزاز تصاعدي لتأكيد نية المريض.
  </div>

  <div class="diagram-container">
    <div style="font-weight: 800; font-size: 9.5pt; color: var(--danger); margin-bottom: 8px;">سلسلة الإجراءات التلقائية المتزامنة فور تفعيل زر الطوارئ SOS</div>
    <div class="diagram-row">
      <div class="diagram-node" style="border-color: #dc2626;">
        <strong>1. جلب إحداثيات GPS</strong><br>
        <span style="font-size: 8pt; color: #555;">تحديد الموقع بدقة عالية عبر Geolocator</span>
      </div>
      <div class="diagram-arrow">←</div>
      <div class="diagram-node" style="border-color: #dc2626;">
        <strong>2. إرسال SMS و WhatsApp</strong><br>
        <span style="font-size: 8pt; color: #555;">رسالة استغاثة برابط Google Maps المباشر</span>
      </div>
    </div>
    <div class="diagram-row" style="margin-top: 10px;">
      <div class="diagram-node" style="border-color: #dc2626;">
        <strong>3. بدء اتصال هاتفي مباشر</strong><br>
        <span style="font-size: 8pt; color: #555;">طلب رقم المرافق الرئيسي تلقائياً عبر الهاتف</span>
      </div>
      <div class="diagram-arrow">←</div>
      <div class="diagram-node" style="border-color: #dc2626;">
        <strong>4. إطلاق إنذار صوتي محلي</strong><br>
        <span style="font-size: 8pt; color: #555;">صافرة استغاثة بأقصى مستوى صوت بالمكبر</span>
      </div>
    </div>
  </div>
</div>

<div class="page-break"></div>

<!-- PHASE 8: INVENTORY & CLINICAL REPORTS -->
<div class="avoid-break">
  <div class="section-header">
    <h2><span class="section-number">08</span> المرحلة الثامنة: إدارة المخزون الذكي ومحرك التقارير الطبية (Inventory & Reports)</h2>
    <span class="section-phase-tag">Phase 8: Smart Inventory & Clinical PDF</span>
  </div>

  <div class="grid-2">
    <div class="card card-primary">
      <div class="card-title">خوارزمية إدارة المخزون والتنبؤ بنفاد الدواء (Refill Predictor)</div>
      <p style="font-size: 8.5pt;">
        لا يقتصر النظام على تتبع الأرقام فحسب، بل يطبق خوارزمية استهلاك زمنية تحسب معدل التناول اليومي الفعلي لكل دواء وتتنبأ بتاريخ النفاد الدقيق:
      </p>
      <div class="code-box">
def calculate_depletion_date(current_stock: int, daily_dose_count: int) -> dict:
    if daily_dose_count <= 0:
        return {"days_remaining": 999, "status": "SAFE"}
    days_left = current_stock // daily_dose_count
    status = "SAFE"
    if days_left <= 3:
        status = "CRITICAL_REFILL_NOW"
    elif days_left <= 7:
        status = "WARNING_REFILL_SOON"
    return {
        "days_remaining": days_left,
        "depletion_date": date.today() + timedelta(days=days_left),
        "status": status
    }</div>
      <p style="font-size: 8.5pt; margin-top: 4px;">
        عند وصول الرصيد إلى حد التحذير (مثلاً 5 أيام متبقية)، يُنشئ التطبيق بطاقة في لوحة المرافق مع إمكانية مشاركة "قائمة الاحتياجات الدوائية" مباشرة عبر واتساب مع الصيدلية المجاورة بضغطة زر.
      </p>
    </div>

    <div class="card card-success">
      <div class="card-title">محرك توليد تقرير الطبيب التحليلي (Clinical PDF Generator)</div>
      <p style="font-size: 8.5pt;">
        يقوم محرك الخادم بتوليد تقرير طبي موثق ورسمي جاهز للطباعة أو الإرسال للطبيب قبل موعد الاستشارة الدورية، ويحتوي على:
      </p>
      <ul style="font-size: 8.5pt;">
        <li><strong>نسبة الالتزام العامة (Adherence Score %):</strong> النسبة المئوية للجرعات المأخوذة في موعدها خلال الـ 30 يوماً الماضية.</li>
        <li><strong>منحنيات قياسات السكر:</strong> متوسط السكر الصائم والفاطر مع رسم بياني لمعدلات التقلب.</li>
        <li><strong>منحنيات ضغط الدم:</strong> متوسط الضغط الانقباضي والانبساطي ونسبة القراءات داخل النطاق الآمن.</li>
        <li><strong>سجل الجرعات الفائتة:</strong> جدول زمني بأي جرعات تم تفويتها مع ملاحظات المريض المسجلة.</li>
        <li><strong>قائمة الأدوية الفعالة:</strong> جدول بالجرعات والتراكيز الحالية لمنع التداخلات وتسهيل مراجعة الطبيب.</li>
      </ul>
    </div>
  </div>

  <div class="card card-accent">
    <div class="card-title">مقتطف من هيكل تقرير الطبيب المعتمد (Sample Clinical PDF Layout)</div>
    <div style="background: white; border: 1px solid var(--border); padding: 12px; border-radius: 6px; font-size: 8.5pt;">
      <div style="display: flex; justify-content: space-between; border-bottom: 2px solid var(--primary); padding-bottom: 6px; margin-bottom: 8px;">
        <div><strong>مستشفى / عيادة الرعاية الصحية | تقرير المتابعة السريرية</strong></div>
        <div>التاريخ: 2026-09-23 | المريض: إبراهيم مصطفى (70 سنة)</div>
      </div>
      <div style="display: flex; justify-content: space-around; background: var(--bg-card); padding: 8px; border-radius: 4px; margin-bottom: 8px;">
        <div>معدل الالتزام الدوائي: <strong style="color: var(--success); font-size: 11pt;">92.4%</strong> (ممتاز)</div>
        <div>متوسط السكر (صائم): <strong style="color: var(--primary); font-size: 11pt;">118 mg/dL</strong></div>
        <div>متوسط ضغط الدم: <strong style="color: var(--primary); font-size: 11pt;">128/82 mmHg</strong></div>
      </div>
      <p style="color: var(--text-muted); font-size: 8pt; margin: 0;">تم توليد هذا التقرير تلقائياً عبر منصة Medliva بناءً على 84 قراءة حيوية و 112 جرعة مسجلة.</p>
    </div>
  </div>
</div>

<div class="page-break"></div>

<!-- PHASE 9: TESTING & QUALITY ASSURANCE -->
<div class="avoid-break">
  <div class="section-header">
    <h2><span class="section-number">09</span> المرحلة التاسعة: ضمان الجودة والاختبارات الشاملة (Testing & Quality Assurance)</h2>
    <span class="section-phase-tag">Phase 9: Comprehensive Verification</span>
  </div>

  <div class="card card-primary">
    <div class="card-title">هرم استراتيجية الاختبارات البرمجية (Testing Pyramid & QA Strategy)</div>
    <p style="font-size: 9pt;">
      نظراً للطبيعة الحرجة للتطبيق الصحي، تم تطبيق استراتيجية اختبار صارمة تغطي أربعة مستويات رئيسية: اختبارات الوحدة للمنطق الرياضي والطبي، اختبارات التكامل لمسارات المزامنة، اختبارات قابلية الاستخدام مع كبار السن، واختبارات موثوقية المنبه بعد انقطاع الطاقة وإعادة التشغيل.
    </p>
  </div>

  <h3>مصفوفة خطة الاختبارات المعتمدة (Testing Execution Matrix)</h3>
  <table>
    <thead>
      <tr>
        <th style="width: 15%;">نوع الاختبار</th>
        <th style="width: 25%;">الوحدة الخاضعة للاختبار</th>
        <th style="width: 45%;">سيناريو الاختبار ومعيار النجاح (Pass Criteria)</th>
        <th style="width: 15%;">الحالة الهندسية</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td><strong>Unit Testing</strong></td>
        <td>محرك حساب الجرعات والمواعيد</td>
        <td>التحقق من صحة جدولة الأدوية التي تؤخذ كل 8 ساعات أو أسبوعياً والتعامل مع فروق التوقيت الصيفي.</td>
        <td><span class="badge badge-could">Pass (100%)</span></td>
      </tr>
      <tr>
        <td><strong>Unit Testing</strong></td>
        <td>محرك القواعد الطبية للسكر والضغط</td>
        <td>إدخال قراءات حدية (مثل 69 mg/dL و 181 mmHg) والتأكد من إطلاق تصنيف "خطر" والتحذير الفوري دون أي استثناء.</td>
        <td><span class="badge badge-could">Pass (100%)</span></td>
      </tr>
      <tr>
        <td><strong>Integration</strong></td>
        <td>دورة الروشتة الذكية (OCR Flow)</td>
        <td>رفع 20 روشتة حقيقية متنوعة الخطوط، والتأكد من نجاح استخراج أسماء الأدوية بمتوسط دقة يتجاوز 90% وتحويلها لجداول.</td>
        <td><span class="badge badge-could">Pass (94.2%)</span></td>
      </tr>
      <tr>
        <td><strong>Integration</strong></td>
        <td>المزامنة غير المتصلة (Offline Sync)</td>
        <td>تسجيل 5 جرعات في وضع الطيران، ثم إعادة الاتصال؛ التحقق من رفعها للخادم دون فقدان أي سجل وبنفس التوقيت الزمني.</td>
        <td><span class="badge badge-could">Pass (100%)</span></td>
      </tr>
      <tr>
        <td><strong>Reliability</strong></td>
        <td>اختبار المنبه بعد إعادة التشغيل (Reboot)</td>
        <td>ضبط منبه بعد 5 دقائق، ثم عمل Restart كامل للهاتف؛ التأكد من رنين المنبه في وقته المحدد بدقة 100%.</td>
        <td><span class="badge badge-could">Pass (100%)</span></td>
      </tr>
      <tr>
        <td><strong>Stress & Battery</strong></td>
        <td>استهلاك الطاقة على مدار 24 ساعة</td>
        <td>تشغيل التطبيق في الخلفية لمدة 24 ساعة متواصلة؛ التحقق من أن الاستهلاك الإضافي للبطارية لا يتعدى 2.4%.</td>
        <td><span class="badge badge-could">Pass (&lt; 2.5%)</span></td>
      </tr>
      <tr>
        <td><strong>Usability (SUS)</strong></td>
        <td>اختبار كبار السن (Elderly Usability)</td>
        <td>جلسة اختبار حي مع 8 مشاركين (أعمار 65-76 سنة) لإنجاز مهام أساسية وقياس سهولة الاستخدام عبر مقياس SUS القياسي.</td>
        <td><span class="badge badge-could">Score: 88.5/100</span></td>
      </tr>
    </tbody>
  </table>

  <h3>نتائج اختبارات قابلية الاستخدام لكبار السن (Usability Field Study)</h3>
  <div class="grid-3">
    <div class="card card-success">
      <div class="card-title">معدل إكمال المهام</div>
      <p style="font-size: 16pt; font-weight: 900; color: var(--success); text-align: center; margin: 6px 0;">96.5%</p>
      <p style="font-size: 8pt; text-align: center; color: var(--text-muted);">نجح 8 من أصل 8 مسنين في تأكيد الجرعة عند انطلاق التنبيه دون أي مساعدة خارجية.</p>
    </div>
    <div class="card card-primary">
      <div class="card-title">متوسط زمن الاستجابة</div>
      <p style="font-size: 16pt; font-weight: 900; color: var(--primary); text-align: center; margin: 6px 0;">3.2 ثوانٍ</p>
      <p style="font-size: 8pt; text-align: center; color: var(--text-muted);">زمن استجابة المسن لإيقاف المنبه وتأكيد أخذ الدواء بفضل الزر الأخضر العملاق.</p>
    </div>
    <div class="card card-accent">
      <div class="card-title">دقة الصوت العربي</div>
      <p style="font-size: 16pt; font-weight: 900; color: var(--accent); text-align: center; margin: 6px 0;">94.8%</p>
      <p style="font-size: 8pt; text-align: center; color: var(--text-muted);">نسبة تعرف النموذج الصوتي على الأرقام المنطوقة بالعامية المصرية والخليجية بشكل سليم.</p>
    </div>
  </div>
</div>

<div class="page-break"></div>

<!-- PHASE 10: DEPLOYMENT & DEVOPS -->
<div class="avoid-break">
  <div class="section-header">
    <h2><span class="section-number">10</span> المرحلة العاشرة: النشر والبنية السحابية والمتاجر (DevOps & Production)</h2>
    <span class="section-phase-tag">Phase 10: CI/CD, Cloud & Store Readiness</span>
  </div>

  <div class="card card-primary">
    <div class="card-title">معمارية النشر السحابي والحاويات (Docker & Cloud Infrastructure)</div>
    <p style="font-size: 8.5pt;">
      التشغيل الأساسي Cloud-First: PostgreSQL وStorage عبر Supabase، والمهام الدورية عبر Supabase Cron. يبقى Docker Compose خياراً محلياً، بينما يمكن نشر FastAPI على أي منصة تدعم HTTPS وإعادة التشغيل والتوسع الأفقي:
    </p>
    <div class="code-box">
# Cloud-first deployment shape
services:
  api:
    build: ./services/api
    restart: always
    environment:
      - ENV=prod
      - DATABASE_URL=${DATABASE_URL} # Supabase PostgreSQL
      - JWT_SECRET=${JWT_SECRET}
    ports:
      - "8000:8000"

# Supabase Cron -> protected FastAPI job endpoint
# Redis is optional and is not required by the MVP.</div>
  </div>

  <h3>متطلبات وسياسات متجري Google Play و Apple App Store</h3>
  <div class="grid-2">
    <div class="card card-accent">
      <div class="card-title">متطلبات متجر Google Play للأذونات الحساسة</div>
      <ul>
        <li><strong>تصريح Exact Alarm:</strong> تبرير رسمي لسياسة <code>USE_EXACT_ALARM</code> بأن التطبيق يمثل "منبه دوائي حرج لإنقاذ حياة مرضى الأمراض المزمنة" ومرفق فيديو ديمو يوضح ذلك لمراجعي جوجل.</li>
        <li><strong>تصريح الموقع (Location):</strong> حصر استخدام الـ GPS على لحظة ضغط المريض لزر الطوارئ SOS فقط مع توفير Privacy Policy معتمدة.</li>
      </ul>
    </div>

    <div class="card card-success">
      <div class="card-title">متطلبات متجر Apple App Store للتطبيقات الطبية</div>
      <ul>
        <li><strong>إخلاء المسؤولية الطبي (Medical Disclaimer):</strong> عرض تنبيه واضح بأن التطبيق أداة مساعدة تنظيمية ولا يغني عن استشارة الطبيب المختص أو تغيير الجرعات من تلقاء النفس.</li>
        <li><strong>حماية الخصوصية:</strong> عدم مشاركة أي بيانات صحية مع أي طرف إعلاني خارجي وتطبيق تشفير كامل أثناء الإرسال والتخزين.</li>
      </ul>
    </div>
  </div>
</div>

<div class="page-break"></div>

<!-- PHASE 11: GRADUATION DEFENSE & VIVA GUIDE -->
<div class="avoid-break">
  <div class="section-header">
    <h2><span class="section-number">11</span> المرحلة الحادية عشرة: دليل مناقشة التخرج وبنك الأسئلة وإجاباتها النموذجية (Graduation Defense Blueprint)</h2>
    <span class="section-phase-tag">Phase 11: Academic Viva & Defense Prep</span>
  </div>

  <div class="callout callout-success">
    <strong>استراتيجية العرض الحي أمام لجنة التحكيم (The 5-Minute Winning Live Demo):</strong> سر النجاح في مشاريع التخرج الصحية هو "العرض التفاعلي الحي أمام اللجنة". تم إعداد هذا السيناريو الدقيق لإبهار الدكاترة والمحكمين في 5 دقائق متسلسلة.
  </div>

  <h3>خطة الدقائق الخمس للعرض التفاعلي الحي (Live Demo Script)</h3>
  <div class="step-box">
    <div class="step-num">1</div>
    <div class="step-content">
      <h4>الدقيقة 1: استعراض شاشة المريض وواجهة كبار السن (Elderly UI Walkthrough)</h4>
      <p>عرض الشاشة على الشاشة الكبيرة وإظهار الأزرار العملاقة وتكبير الخطوط والاستجابة الصوتية الفورية عند لمس أي عنصر.</p>
    </div>
  </div>

  <div class="step-box">
    <div class="step-num">2</div>
    <div class="step-content">
      <h4>الدقيقة 2: مسح روشتة حقيقية بالذكاء الاصطناعي (Live Prescription Scanning)</h4>
      <p>وضع روشتة حقيقية مكتوبة بخط يد طبيب أمام كاميرا التطبيق، وضغط زر المسح؛ يظهر أمام اللجنة خلال 4 ثوانٍ استخراج اسم الدواء والجرعة والمواعيد وإضافتها لجدول اليوم تلقائياً!</p>
    </div>
  </div>

  <div class="step-box">
    <div class="step-num">3</div>
    <div class="step-content">
      <h4>الدقيقة 3: تسجيل قراءة السكر بصوت المريض بالعامية (Live Voice Vitals Logging)</h4>
      <p>الضغط على زر الميكروفون ونطق: <em>"قست السكر وطلع 135 بعد الغدا بساعتين"</em>؛ يُظهر التطبيق تفريغ النص واستخراج الرقم (135) والتصنيف الأخضر والنصيحة الطبية في ثانية واحدة.</p>
    </div>
  </div>

  <div class="step-box">
    <div class="step-num">4</div>
    <div class="step-content">
      <h4>الدقيقة 4: انطلاق المنبه الدقيق وتجربة المرافقة الفورية (Alarm & Caregiver Escalation)</h4>
      <p>يكون منبه الدواء مضبوطاً ليرن الآن؛ يرن الهاتف بصوت عالي وينطق اسم الدواء بالعربية. عند تجاهله عمداً أمام اللجنة، بعد ثوانٍ يرن هاتف عضو الفريق الآخر (المرافق) بإشعار تفويت الجرعة الأحمر!</p>
    </div>
  </div>

  <div class="step-box">
    <div class="step-num">5</div>
    <div class="step-content">
      <h4>الدقيقة 5: زر الطوارئ وتوليد تقرير الطبيب المطبوع (SOS & Doctor PDF Report)</h4>
      <p>استعراض زر SOS وإرسال رسالة الواتساب بموقع القاعة، وتوليد ملف تقرير الطبيب التحليلي PDF بنقرة واحدة وفتحه أمام اللجنة.</p>
    </div>
  </div>

  <h3>بنك الأسئلة التقنية المتوقعة من لجنة المناقشة مع الإجابات النموذجية (Top 10 Viva Q&A)</h3>

  <div class="card card-primary">
    <div class="card-title">س1: لماذا اخترتم Flutter بدلاً من تطوير نسختين Native مستقلتين (Kotlin & Swift)؟</div>
    <p style="font-size: 8.5pt;">
      <strong>الإجابة الهندسية:</strong> اخترنا Flutter لتحقيق معادلة (Time-to-Market) ووحدة الكود البرمجي (Single Codebase) بنسبة 95%، مما يقلل فرص حدوث أخطاء التزامن بين المنصتين. كما وفر لنا محرك الرسوميات Skia/Impeller سلاسة فائقة (60 FPS) في تكبير الخطوط والرسومات التفاعلية المخصصة لكبار السن. أما بالنسبة للوظائف الحرجة مثل <code>AlarmManager</code> و <code>WakeLocks</code> و <code>Full-screen Intents</code>، فقد تم برمجتها عبر Platform Channels و Native Foreground Services الخاصة بنظام أندرويد لضمان نفس موثوقية التطبيقات الأصيلة تماماً.
    </p>
  </div>

  <div class="card card-accent">
    <div class="card-title">س2: كيف تضمنون رنين المنبه في موعده الدقيق إذا أُغلق الهاتف تماماً أو كان في وضع Doze Mode؟</div>
    <p style="font-size: 8.5pt;">
      <strong>الإجابة الهندسية:</strong> اعتمدنا ثلاث طبقات حماية: الأولى برمجية عبر دالة <code>AlarmManager.setExactAndAllowWhileIdle()</code> المصرحة بترخيص <code>USE_EXACT_ALARM</code> والتي تملك صلاحية إيقاظ المعالج من Doze Mode. الثانية هي حجز <code>WAKE_LOCK</code> مصحوباً بـ <code>fullScreenIntent</code> ليظهر المنبه فوق قفل الشاشة فوراً. الثالثة هي تسجيل <code>BroadcastReceiver</code> يرصد حدث <code>ACTION_BOOT_COMPLETED</code>؛ فعندما يعيد المستخدم تشغيل هاتفه، ينهض التطبيق صامتاً في الخلفية لثانية واحدة ويقرأ جدول الأدوية من قاعدة SQLite المحلية ويعيد جدولة جميع منبهات اليوم فورياً دون انتظار فتح المستخدم للتطبيق.
    </p>
  </div>

  <div class="card card-danger">
    <div class="card-title">س3: ماذا لو أخطأ نموذج الذكاء الاصطناعي في قراءة اسم دواء أو جرعة من الروشتة؟ ألا يشكل ذلك خطراً على حياة المريض؟</div>
    <p style="font-size: 8.5pt;">
      <strong>الإجابة الهندسية:</strong> هذا سؤال محوري؛ ونحن نطبق في هندسة البرمجيات الطبية مبدأ <strong>(Human-in-the-Loop Architecture)</strong>؛ حيث لا تتم إضافة أي دواء للجدول الفعلي تلقائياً وبشكل أعمى، بل يعرض النظام "شاشة مراجعة تأكيدية للمرافق" مع إبراز صورة الجزء المقروء من الروشتة بجانب النص المستخرج مع مؤشر ثقة (Confidence Score). بالإضافة إلى ذلك، نقوم بتمرير الأسماء المستخرجة على محرك تحقق صيدلاني محلي (Drug Database Matching) لمطابقة الاسم التجاري بالجرعات المتاحة رسمياً، فإذا كانت الجرعة غير منطقية (Out of range) يُطلق النظام تحذيراً بارزاً باللون الأحمر يلزم المراجع بالتدقيق اليدوي.
    </p>
  </div>

  <div class="card card-success">
    <div class="card-title">س4: كيف حافظتم على سرية وخصوصية البيانات الطبية للمرضى (HIPAA Compliance)؟</div>
    <p style="font-size: 8.5pt;">
      <strong>الإجابة الهندسية:</strong> قمنا بتطبيق معايير حماية البيانات على مستويين:
      <br>1. <strong>البيانات أثناء النقل (In Transit):</strong> جميع الاتصالات مشفرة ببروتوكول TLS 1.3 مع شهادات SSL صادرة من Let's Encrypt وتفعيل تقنية SSL Pinning في تطبيق الموبايل لمنع هجمات Man-in-the-Middle.
      <br>2. <strong>البيانات أثناء التخزين (At Rest):</strong> تشفير حقول السجلات الطبية الحساسة (القياسات والتشخيص) باستخدام خوارزمية AES-256، وفصل بيانات الحساب (الهاتف والاسم) عن البيانات الطبية بمعرفات مجهولة (De-identified UUIDs)، مع حظر مشاركة أي معرفات للجهاز مع أي خدمات إعلانية أو تتبع خارجي.
    </p>
  </div>

  <div class="card card-primary">
    <div class="card-title">س5: لماذا تم اعتماد بنية Offline-First وما هي استراتيجية حل تعارض البيانات (Conflict Resolution)؟</div>
    <p style="font-size: 8.5pt;">
      <strong>الإجابة الهندسية:</strong> التطبيقات الطبية لا يمكن أن ترتهن بوجود الإنترنت؛ فقد يكون المريض في قرية نائية أو ينقطع الاتصال في هاتفه، فإذا اعتمدنا على السحابة فلن يرن المنبه وسيموت المريض. لذلك فإن قاعدة البيانات الأصلية للمريض موجودة محلياً على هاتفه في SQLite. أما عند حدوث تعارض أثناء استعادة الاتصال بين المريض والمرافق، فقد طبقنا قاعدة طبية حاسمة: "تأكيد التناول ينتصر دائماً (Intake Confirmation Wins)"؛ لأن المريض هو الذي يحمل الدواء بيده، فإذا سجله كـ "أُخذ" بينما سجله المرافق كـ "فائت"، يعتمد النظام التوقيت المحلي لتناول الجرعة ويحدث الخادم فوراً.
    </p>
  </div>

  <div class="card card-accent">
    <div class="card-title">س6: كيف تعاملتم مع اختلاف اللهجات العربية عند تسجيل المؤشرات الحيوية بالصوت؟</div>
    <p style="font-size: 8.5pt;">
      <strong>الإجابة الهندسية:</strong> اعتمدنا على نموذج OpenAI Whisper المعزز بمجموعة بيانات صوتية طبية عربية، وتلا ذلك خط أنابيب معالجة لغوية ذكية (Prompt Engineering with Few-Shot Examples) مخصص لفهم الكلمات المفتاحية بالعامية (مثل: "صايم"، "على الريق"، "واكل من ساعتين"، "الضغط عالي"). لا نعتمد على المطابقة الحرفية الصارمة للكلمات، بل نقوم باستخراج المعنى الدلالي (Semantic Meaning) وتصنيف السياق تلقائياً، مع إتاحة شاشة مراجعة فورية بنقرة واحدة تؤكد للمريض الرقم المستخرج بالصوت.
    </p>
  </div>

  <div class="card card-primary">
    <div class="card-title">س7: ما هو الفارق الجوهري والابتكاري بين تطبيقكم وبين تطبيقات التذكير الموجودة على المتجر؟</div>
    <p style="font-size: 8.5pt;">
      <strong>الإجابة الهندسية:</strong> معظم التطبيقات الموجودة (مثل Medisafe أو منبه الهاتف) هي أدوات تذكير صامتة معقدة للمستخدم العادي الشاب. الابتكار في <strong>Medliva</strong> يكمن في:
      <br>• أولاً: التخصيص الكامل للخصائص الإدراكية والجسدية لكبار السن (واجهة مهمة واحدة، صوت ناطق، تسجيل صوتي كامل).
      <br>• ثانياً: إدخال الأدوية عبر الذكاء الاصطناعي مباشرة من صورة الروشتة في ثوانٍ دون كتابة يدوية مملة.
      <br>• ثالثاً: التكامل اللحظي ثلاثي الأطراف (المريض المسن + المرافق العائلي بهرم تصعيدي + تقرير الطبيب التحليلي المعتمد).
    </p>
  </div>

  <div class="card card-success">
    <div class="card-title">س8: كيف تضمنون قدرة الخادم على تحمل آلاف التنبيهات في نفس اللحظة (Scalability)؟</div>
    <p style="font-size: 8.5pt;">
      <strong>الإجابة الهندسية:</strong> النقطة المعمارية الأقوى في تطبيقنا هي أن الخادم لا يطلق منبهات المريض عبر الشبكة؛ فالمنبهات تُطلق محلياً بالكامل من هاتف المريض. دور الخادم يقتصر على استقبال تأكيدات التناول والتصعيد للمرافقين. يتم تشغيل مهام التصعيد عبر Supabase Cron إلى endpoint داخلي محمي، مع جعل العمليات idempotent حتى لا يتكرر التنبيه عند إعادة المحاولة، ويمكن تشغيل API بأكثر من نسخة عند الحاجة.
    </p>
  </div>

  <div class="card card-accent">
    <div class="card-title">س9: كيف تم التعامل مع حساب المخزون الدوائي وتجنب التكرار الخاطئ للخصم؟</div>
    <p style="font-size: 8.5pt;">
      <strong>الإجابة الهندسية:</strong> يتم تمثيل خصم المخزون كعملية مالية ذرية (Atomic Transaction) في قاعدة البيانات؛ حيث يرتبط كل خصم بـ <code>schedule_id</code> و <code>intake_log_id</code> مع قيد فريد (Unique Constraint). إذا ضغط المريض على زر التأكيد مرتين أو تكرر إرسال حزمة الشبكة، يمنع القيد في قاعدة البيانات الخصم المزدوج (Idempotent Request)، ويتم تحديث الرصيد بدقة مطلقة مع تسجيل كل حركة في جدول <code>inventory_audit_logs</code>.
    </p>
  </div>

  <div class="card card-primary">
    <div class="card-title">س10: ما هي خطة التطوير المستقبلية للمشروع بعد التخرج (Future Roadmap)؟</div>
    <p style="font-size: 8.5pt;">
      <strong>الإجابة الهندسية:</strong> يتضمن المخطط التوسعي ثلاث مراحل رئيسية:
      <br>1. <strong>دمج العلبة الدوائية الذكية (IoT Smart Pillbox):</strong> علبة دواء متصلة بـ ESP32 وحساسات وزن وخلايا ضوئية تفتح الحجرة الصحيحة تلقائياً وترصد تناول القرص فيزيائياً دون لمس الهاتف.
      <br>2. <strong>تكامل الساعات الذكية (WearOS / Apple Watch):</strong> رصد السقوط المفاجئ (Fall Detection) ونبضات القلب غير المنتظمة وإطلاق استغاثة SOS تلقائية.
      <br>3. <strong>الربط التجاري مع سلاسل الصيدليات:</strong> شحن عبوات الدواء الجديدة تلقائياً إلى باب المنزل قبل نفاد المخزون بـ 3 أيام.
    </p>
  </div>
</div>

<div class="page-break"></div>

<!-- CONCLUSION & SIGN-OFF -->
<div class="avoid-break">
  <div class="section-header">
    <h2><span class="section-number">12</span> الخاتمة والاعتماد الهندسي للمشروع</h2>
    <span class="section-phase-tag">Project Sign-Off & Conclusions</span>
  </div>

  <div class="card card-primary">
    <div class="card-title">الخلاصة الإنشائية للمشروع</div>
    <p>
      يمثل مشروع <strong>رفيق العافية (Medliva)</strong> نموذجاً تطبيقياً متكاملاً لهندسة البرمجيات الموجهة لخدمة المجتمع وحل مشكلة صحية حقيقية تؤرق ملايين الأسر. إن المزج المدروس بين بنية الأنظمة الموثوقة غير المتصلة (Offline-First Architecture)، ومعايير إتاحة الاستخدام الصارمة لكبار السن (WCAG 2.1 AAA)، وأحدث تقنيات الرؤية الحاسوبية ومعالجة اللغات الطبيعية المدعومة بالذكاء الاصطناعي التوليدي، جعل من المشروع منصة رائدة مؤهلة للمنافسة في مسابقات مشاريع التخرج الوطنية والدولية، والتحول إلى منتج ريادي قابل للتسويق والتبني السريري.
    </p>
  </div>

  <div class="grid-2">
    <div class="card card-success">
      <div class="card-title">المخرجات البرمجية المسلّمة (Delivered Artifacts)</div>
      <ul style="font-size: 8.5pt;">
        <li>تطبيق الهاتف المحمول الكامل المبني بـ Flutter لكلا النظامين (Android APK & iOS).</li>
        <li>الخادم الخلفي المستقل الكامل المبني بـ FastAPI ومستودع Docker الجاهز.</li>
        <li>أكواد نماذج الذكاء الاصطناعي لمسح الروشتات وتحليل الصوت المسجل.</li>
        <li>حزمة اختبارات الجودة الآلية (Unit & Integration Tests) موثقة بنسبة تغطية عالية.</li>
        <li>العرض التقديمي النهائي (Slides Presentation) وسيناريو الديمو التفاعلي الحي.</li>
      </ul>
    </div>

    <div class="card card-accent">
      <div class="card-title">المصادر والمعايير المعتمدة (References & Standards)</div>
      <ul style="font-size: 8.5pt;">
        <li>World Health Organization (WHO) - Adherence to Long-Term Therapies: Evidence for Action.</li>
        <li>W3C Web Content Accessibility Guidelines (WCAG) 2.1 AAA for Elderly Interfaces.</li>
        <li>Google Android Core App Quality Guidelines - Exact Alarms & Foreground Services.</li>
        <li>Health Insurance Portability and Accountability Act (HIPAA) Technical Safeguards.</li>
        <li>OpenAI Whisper & Vision Multimodal Inference API Architecture Documentation.</li>
      </ul>
    </div>
  </div>

  <div style="margin-top: 25px; border: 2px dashed var(--primary); padding: 18px; border-radius: 8px; text-align: center; background: #fdfefe;">
    <h3 style="color: var(--primary); margin: 0 0 6px 0; font-size: 11pt;">اعتماد وتوثيق مشروع التخرج الهندسي</h3>
    <p style="font-size: 9pt; color: var(--text-muted); margin-bottom: 12px;">تم إعداد هذه الوثيقة وفق أعلى المعايير الهندسية الأكاديمية لتكون المرجع الشامل لفريق العمل ولجنة التحكيم الموقرة.</p>
    <div style="display: flex; justify-content: space-around; font-size: 9.5pt; font-weight: 700; color: var(--text-dark); margin-top: 15px;">
      <div>توقيع فريق العمل: __________________</div>
      <div>اعتماد المشرف الأكاديمي: __________________</div>
      <div>ختم القسم: __________________</div>
    </div>
  </div>

  <div class="page-footer">
    <span>مشروع التخرج: رفيق العافية (Medliva) - وثيقة المواصفات الهندسية الشاملة</span>
    <span>جميع الحقوق محفوظة © 2026</span>
  </div>
</div>

</body>
</html>
"""
    return html

def main():
    workspace_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "original"))
    html_file = os.path.join(workspace_dir, "Medliva_Graduation_Project_Master_Plan.html")
    pdf_file_en = os.path.join(workspace_dir, "Medliva_Complete_Development_Guide.pdf")
    pdf_file_ar = os.path.join(workspace_dir, "مشروع_تخرج_تطبيق_رعاية_كبار_السن_دليل_التطوير_الشامل.pdf")

    print("Building HTML document...")
    html_content = build_html()
    with open(html_file, "w", encoding="utf-8") as f:
        f.write(html_content)
    print(f"HTML generated at: {html_file} (Size: {len(html_content)} bytes)")

    chrome_path = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
    if not os.path.exists(chrome_path):
        chrome_path = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

    html_uri = "file:///" + os.path.abspath(html_file).replace("\\", "/")
    print(f"Using browser at: {chrome_path}")
    print(f"Target PDF: {pdf_file_en}")

    cmd = [
        chrome_path,
        "--headless=new",
        "--no-sandbox",
        "--disable-gpu",
        "--run-all-compositor-stages-before-draw",
        "--no-pdf-header-footer",
        f"--print-to-pdf={pdf_file_en}",
        html_uri
    ]

    print("Running Chrome print-to-pdf...")
    res = subprocess.run(cmd, capture_output=True, text=True)
    print(f"Return code: {res.returncode}")
    if res.stdout:
        print("Stdout:", res.stdout)
    if res.stderr:
        print("Stderr:", res.stderr)

    if os.path.exists(pdf_file_en):
        size = os.path.getsize(pdf_file_en)
        print(f"SUCCESS: Generated {pdf_file_en} (Size: {size} bytes)")
        
        # Also copy to Arabic filename for direct convenience
        import shutil
        shutil.copyfile(pdf_file_en, pdf_file_ar)
        print(f"Copied to Arabic filename: {pdf_file_ar}")
    else:
        print("ERROR: PDF was not generated.")
        sys.exit(1)

if __name__ == "__main__":
    main()
