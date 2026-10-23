# -*- coding: utf-8 -*-
"""
Script to generate the 11-page English Use Cases and Features Guide for CareElder.
User Updates:
1. Removed the top header bar (.page-header) completely from all pages.
2. Removed the bottom footer bar (.page-footer) completely from all pages.
3. Enlarged font size across the document (titles, body, lists, tables).
4. Pure Black and White / Minimalist styling with Alexandria font.
Output: CareElder_UseCases_and_Features_EN.pdf (Exactly 11 pages)
"""

import os
import subprocess
import pypdf

WORKSPACE = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "original"))
HTML_FILE = os.path.join(WORKSPACE, "CareElder_UseCases_and_Features_EN.html")
PDF_FILE = os.path.join(WORKSPACE, "CareElder_UseCases_and_Features_EN.pdf")

CHROME_PATH = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
if not os.path.exists(CHROME_PATH):
    CHROME_PATH = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

def build_english_html():
    return """<!DOCTYPE html>
<html lang="en" dir="ltr">
<head>
<meta charset="UTF-8">
<title>CareElder - Engineering Use Cases & System Feature Specifications</title>
<style>
@import url('https://fonts.googleapis.com/css2?family=Alexandria:wght@300;400;500;600;700;800;900&family=JetBrains+Mono:wght@400;600;700&display=swap');

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
  font-family: 'Alexandria', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
  color: var(--text-primary);
  background-color: #ffffff;
  line-height: 1.55;
  font-size: 10.2pt;
  direction: ltr;
  text-align: left;
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
  padding: 16mm 18mm 16mm 18mm;
  page-break-after: always;
  break-after: page;
  background: var(--bg-white);
  display: flex;
  flex-direction: column;
  justify-content: flex-start;
  overflow: hidden;
  position: relative;
  margin: 0 auto;
}

.pdf-page:last-child {
  page-break-after: avoid;
  break-after: avoid;
}

/* Page Titles (No header/footer) */
.page-title-row {
  margin-bottom: 14px;
  border-bottom: 2px solid var(--black);
  padding-bottom: 8px;
}

.page-title {
  font-size: 16pt;
  font-weight: 900;
  color: var(--black);
  line-height: 1.25;
}

.page-subtitle {
  font-size: 9.6pt;
  color: var(--text-secondary);
  font-weight: 500;
  margin-top: 3px;
}

/* Content Area */
.content-area {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 12px;
  overflow: hidden;
}

.grid-2 {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}

.grid-3 {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr;
  gap: 12px;
}

.grid-4 {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr 1fr;
  gap: 10px;
}

/* Minimalist Clean Box */
.box {
  background: var(--bg-white);
  border: 1px solid var(--border-light);
  padding: 12px 14px;
}

.box-dark-border {
  border: 1.5px solid var(--black);
}

.box-header {
  font-size: 11pt;
  font-weight: 800;
  color: var(--black);
  margin-bottom: 8px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-bottom: 1px solid var(--border-subtle);
  padding-bottom: 5px;
}

.tag-clean {
  display: inline-block;
  font-size: 7.8pt;
  font-weight: 700;
  padding: 2px 7px;
  border: 1px solid var(--black);
  background: var(--bg-white);
  color: var(--black);
}

.tag-black {
  background: var(--black);
  color: #fff;
  border: 1px solid var(--black);
}

/* Tables */
.table-clean {
  width: 100%;
  border-collapse: collapse;
  font-size: 9pt;
  margin-top: 6px;
}

.table-clean th {
  background: #f2f2f2;
  color: var(--black);
  font-weight: 800;
  text-align: left;
  padding: 8px 10px;
  border: 1px solid var(--black);
}

.table-clean td {
  padding: 7px 10px;
  border: 1px solid var(--border-light);
  vertical-align: top;
  color: var(--text-primary);
}

.table-clean tr:nth-child(even) td {
  background: #fafafa;
}

/* Lists */
ul.bullet-list {
  padding-left: 20px;
  font-size: 9.4pt;
  line-height: 1.6;
}

ul.bullet-list li {
  margin-bottom: 6px;
}

/* Flow Step Items */
.step-item {
  display: flex;
  gap: 10px;
  align-items: flex-start;
  margin-bottom: 9px;
  font-size: 9.4pt;
}

.step-num {
  font-weight: 900;
  font-size: 9.5pt;
  color: var(--black);
  min-width: 20px;
}

.step-body, .step-content {
  flex: 1;
}

.step-body strong, .step-content strong {
  color: var(--black);
  font-weight: 800;
}

/* Spec Meta Line */
.spec-meta-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 8px;
  font-size: 8.6pt;
  border: 1.5px solid var(--black);
  padding: 8px 12px;
  background: #fafafa;
}

.spec-meta-grid .item-title {
  font-weight: 800;
  color: var(--black);
}

.mono {
  font-family: 'JetBrains Mono', monospace;
  font-size: 8.2pt;
}

/* Stat Box */
.kpi-box {
  border: 1.5px solid var(--black);
  padding: 10px 8px;
  text-align: center;
}

.kpi-val {
  font-size: 16pt;
  font-weight: 900;
  color: var(--black);
  line-height: 1.1;
}

.kpi-label {
  font-size: 8pt;
  color: var(--text-secondary);
  font-weight: 600;
  margin-top: 4px;
}

/* Cover Styling */
.cover-frame {
  height: 100%;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  border: 2px solid var(--black);
  padding: 35px 30px;
}

.cover-header {
  border-bottom: 2px solid var(--black);
  padding-bottom: 16px;
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
}

.cover-header h3 {
  font-size: 14pt;
  font-weight: 900;
  color: var(--black);
}

.cover-header p {
  font-size: 9.5pt;
  color: var(--text-secondary);
  font-weight: 600;
  margin-top: 3px;
}

.cover-center {
  margin: 25px 0;
  text-align: left;
}

.cover-tag-box {
  display: inline-block;
  border: 2px solid var(--black);
  padding: 5px 14px;
  font-size: 9.2pt;
  font-weight: 800;
  margin-bottom: 18px;
}

.cover-main-title {
  font-size: 29pt;
  font-weight: 900;
  color: var(--black);
  line-height: 1.25;
  margin-bottom: 14px;
  letter-spacing: -0.5px;
}

.cover-sub-title {
  font-size: 13pt;
  font-weight: 700;
  color: var(--text-secondary);
  line-height: 1.5;
  margin-bottom: 16px;
}

.cover-desc {
  font-size: 9.8pt;
  color: var(--text-secondary);
  line-height: 1.65;
  max-width: 630px;
  border-left: 3px solid var(--black);
  padding-left: 14px;
}

.cover-meta-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 9.2pt;
  margin-top: 25px;
  border: 1.5px solid var(--black);
}

.cover-meta-table td {
  padding: 9px 14px;
  border: 1px solid var(--border-light);
}

.cover-meta-table td.header-td {
  background: #f7f7f7;
  font-weight: 800;
  width: 25%;
  color: var(--black);
}

.cover-footer {
  border-top: 2px solid var(--black);
  padding-top: 14px;
  display: flex;
  justify-content: space-between;
  font-size: 8.8pt;
  font-weight: 700;
  color: var(--black);
}
</style>
</head>
<body>

<!-- ============================================================== -->
<!-- PAGE 1: COVER PAGE -->
<!-- ============================================================== -->
<div class="pdf-page">
  <div class="cover-frame">
    <div class="cover-header">
      <div>
        <h3>Academic & Clinical Graduation Project | 2026</h3>
        <p>Department of Software Engineering & Information Technology</p>
      </div>
      <div>
        <span class="tag-clean tag-black" style="padding: 5px 12px; font-size: 9pt;">CareElder Platform</span>
      </div>
    </div>

    <div class="cover-center">
      <div class="cover-tag-box">ENGINEERING SPECIFICATION & USE CASES</div>
      <h1 class="cover-main-title">CareElder (رفيق العافية)</h1>
      <h2 class="cover-sub-title">Intelligent Healthcare, Medication Adherence & Clinical Monitoring Platform for Seniors</h2>
      <p class="cover-desc">
        A rigorous architectural and functional specification detailing verified Use Cases, clinical problem formulations, accessible geriatric user experience design, and cross-stakeholder workflows linking senior patients, family caregivers, and attending physicians.
      </p>

      <table class="cover-meta-table">
        <tr>
          <td class="header-td">System Architecture:</td>
          <td>Offline-First Architecture & Delta Sync</td>
          <td class="header-td">Technology Stack:</td>
          <td>Flutter + FastAPI + Computer Vision OCR</td>
        </tr>
        <tr>
          <td class="header-td">Target Demographics:</td>
          <td>Chronic Disease Patients & Elderly Seniors</td>
          <td class="header-td">Accessibility:</td>
          <td>Geriatric Accessibility (WCAG AAA)</td>
        </tr>
        <tr>
          <td class="header-td">Document Type:</td>
          <td>Engineering Specification & Use Cases</td>
          <td class="header-td">Release / Status:</td>
          <td>Version 2.6 (Streamlined Minimalist Edition)</td>
        </tr>
      </table>
    </div>

    <div class="cover-footer">
      <div>Engineering Team: CareElder Graduation Project Team - Class of 2026</div>
      <div>Date: 2026</div>
    </div>
  </div>
</div>

<!-- ============================================================== -->
<!-- PAGE 2: EXECUTIVE SUMMARY & TABLE OF CONTENTS -->
<!-- ============================================================== -->
<div class="pdf-page">
  <div class="page-title-row">
    <h2 class="page-title">00. Executive Summary & Table of Contents</h2>
    <p class="page-subtitle">Strategic platform vision, primary KPIs, and comprehensive 11-page document directory</p>
  </div>

  <div class="content-area">
    <div class="box box-dark-border">
      <div class="box-header">
        <span>Executive Summary</span>
      </div>
      <p style="font-size: 9.6pt; line-height: 1.6;">
        <strong>CareElder (رفيق العافية)</strong> is a specialized digital health platform designed for aging seniors and chronic patients. Departing from complex commercial apps, CareElder implements an <strong>Offline-First Architecture</strong> with simplified interfaces tailored to geriatric motor and cognitive realities. The system synchronizes the senior patient, family caregiver, and physician via hardware-level exact alarms, multimodal prescription OCR, zero-typing colloquial voice logging, pill inventory management, and longitudinal clinical analytics.
      </p>
    </div>

    <div class="grid-4">
      <div class="kpi-box">
        <div class="kpi-val">&gt; 96%</div>
        <div class="kpi-label">Target Adherence Rate</div>
      </div>
      <div class="kpi-box">
        <div class="kpi-val">&lt; 3.5s</div>
        <div class="kpi-label">AI Prescription OCR Speed</div>
      </div>
      <div class="kpi-box">
        <div class="kpi-val">100%</div>
        <div class="kpi-label">Offline Alarm Guarantee</div>
      </div>
      <div class="kpi-box">
        <div class="kpi-val">Zero</div>
        <div class="kpi-label">Typing (100% Voice UX)</div>
      </div>
    </div>

    <div class="box" style="flex: 1;">
      <div class="box-header">
        <span>Document Directory (11 Dedicated Engineering Pages)</span>
      </div>
      <table class="table-clean">
        <thead>
          <tr>
            <th style="width: 14%;">Page</th>
            <th style="width: 46%;">Topic / Specification</th>
            <th style="width: 40%;">Target Audience / Deliverable</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td><strong>Page 01</strong></td>
            <td>Official Cover & System Identification</td>
            <td>Project Metadata & Academic Certification</td>
          </tr>
          <tr>
            <td><strong>Page 02</strong></td>
            <td>Executive Summary, Table of Contents & KPI Matrix</td>
            <td>Strategic Vision & Engineering Targets</td>
          </tr>
          <tr>
            <td><strong>Page 03</strong></td>
            <td>Root Problem Statement & Clinical Challenges</td>
            <td>WHO Data & Polypharmacy Complications</td>
          </tr>
          <tr>
            <td><strong>Page 04</strong></td>
            <td>Platform Value Pillars & System Features</td>
            <td>Five Core Pillars & Operational Pipeline</td>
          </tr>
          <tr>
            <td><strong>Page 05</strong></td>
            <td>Stakeholder Ecosystem & User Personas</td>
            <td>Patient, Caregiver, and Attending Doctor</td>
          </tr>
          <tr>
            <td><strong>Page 06</strong></td>
            <td>Use Case UC-01: Smart Medication Alarm & Acknowledgment</td>
            <td>Full-Screen Intent Wakeup & Offline Storage</td>
          </tr>
          <tr>
            <td><strong>Page 07</strong></td>
            <td>Use Case UC-02: AI Prescription OCR & Medical NER</td>
            <td>Vision Handwriting Extraction to Regimen Schema</td>
          </tr>
          <tr>
            <td><strong>Page 08</strong></td>
            <td>Use Case UC-03: Voice Vitals Logging & Clinical Triage</td>
            <td>Colloquial Voice Input & Immediate Decision Triage</td>
          </tr>
          <tr>
            <td><strong>Page 09</strong></td>
            <td>Use Case UC-04: Remote Caregiver Supervision & Sync</td>
            <td>Live Adherence Feed & 3-Tier Escalation Ladder</td>
          </tr>
          <tr>
            <td><strong>Page 10</strong></td>
            <td>Use Case UC-05: Automated Pill Inventory & Low-Stock Alerts</td>
            <td>Predictive Depletion Modeling & 1-Tap Pharmacy Order</td>
          </tr>
          <tr>
            <td><strong>Page 11</strong></td>
            <td>Use Case UC-06: Longitudinal Clinical Reporting for Doctors</td>
            <td>Biometric Longitudinal Charts & Encrypted QR Portal</td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</div>

<!-- ============================================================== -->
<!-- PAGE 3: ROOT PROBLEM STATEMENT & CLINICAL CRISIS -->
<!-- ============================================================== -->
<div class="pdf-page">
  <div class="page-title-row">
    <h2 class="page-title">01. Root Problem Statement & Clinical Challenges</h2>
    <p class="page-subtitle">Global health metrics, polypharmacy hazards, and the silent crisis of geriatric non-adherence</p>
  </div>

  <div class="content-area">
    <div class="box box-dark-border">
      <div class="box-header">
        <span>The Clinical & Economic Crisis (WHO Benchmark Data)</span>
      </div>
      <p style="font-size: 9.4pt; line-height: 1.6;">
        According to the <strong>World Health Organization (WHO)</strong>, over <strong>50%</strong> of patients with chronic diseases (hypertension, diabetes, cardiovascular failure) fail to take prescribed medications correctly. This widespread non-adherence causes <strong>33% to 45% of all emergency hospital readmissions</strong> and significant preventable complications such as stroke and renal failure, imposing severe emotional and financial burdens on families and healthcare systems.
      </p>
    </div>

    <div class="grid-2">
      <div class="box">
        <div class="box-header">
          <span>1. The Senior Patient Dilemma</span>
        </div>
        <ul class="bullet-list">
          <li><strong>Extreme Polypharmacy:</strong> Managing 5 to 9 daily pills with differing intervals exceeds normal cognitive working memory in aging seniors.</li>
          <li><strong>Sensory & Motor Impairment:</strong> Presbyopia prevents reading tiny labels; tremors and arthritis make phone keyboards unusable.</li>
          <li><strong>Temporal Confusion:</strong> Constant disorientation regarding whether today's dose was taken or merely remembered from yesterday.</li>
          <li><strong>Commercial App Overload:</strong> Existing applications are cluttered with ads, small fonts, and convoluted multi-step workflows.</li>
        </ul>
      </div>

      <div class="box">
        <div class="box-header">
          <span>2. Caregiver Burnout & Distance Gap</span>
        </div>
        <ul class="bullet-list">
          <li><strong>Work-Life Strain:</strong> Adult working children suffer constant anxiety during office hours, repeatedly calling without getting clear confirmation.</li>
          <li><strong>The "Courtesy Bias" Trap:</strong> When asked "Did you take your pills?", seniors frequently say "Yes" to avoid feeling burdensome.</li>
          <li><strong>Chaotic Inventory Management:</strong> Discovering that insulin pens or heart medication strips ran out at 11:00 PM on a weekend.</li>
          <li><strong>Clinical Recall Void:</strong> Doctors must guess therapy efficacy based on inaccurate patient memory during consultations.</li>
        </ul>
      </div>
    </div>

    <div class="box">
      <div class="box-header">
        <span>Comparative Analysis: Status Quo vs. CareElder Solution</span>
      </div>
      <table class="table-clean">
        <thead>
          <tr>
            <th style="width: 25%;">Evaluation Metric</th>
            <th style="width: 37%;">Commercial Apps & Traditional Habits</th>
            <th style="width: 38%;">CareElder Engineering Innovation</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td><strong>Medication Alarms</strong></td>
            <td>Subtle banner notifications that dismiss instantly and fail offline.</td>
            <td><strong>Full-Screen Intent</strong> override with loud audio & offline hardware alarms.</td>
          </tr>
          <tr>
            <td><strong>Prescription Entry</strong></td>
            <td>Tedious manual text typing in English; high user friction.</td>
            <td><strong>Multimodal AI OCR</strong> converts paper prescriptions to schedules in one click.</td>
          </tr>
          <tr>
            <td><strong>Vital Signs Logging</strong></td>
            <td>Manual numeric keypad entry with frequent transpositions.</td>
            <td><strong>100% Voice-driven colloquial NLP</strong> with automatic clinical color triage.</td>
          </tr>
          <tr>
            <td><strong>Inventory Governance</strong></td>
            <td>Manual guesswork and frequent emergency stock-outs.</td>
            <td><strong>Automatic dose decrementing</strong> with proactive 5-day WhatsApp refill generation.</td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</div>

<!-- ============================================================== -->
<!-- PAGE 4: PLATFORM VALUE PILLARS & SOLUTIONS -->
<!-- ============================================================== -->
<div class="pdf-page">
  <div class="page-title-row">
    <h2 class="page-title">02. Platform Value Pillars & What The System Offers</h2>
    <p class="page-subtitle">Five core engineering pillars delivering holistic, preventative senior healthcare</p>
  </div>

  <div class="content-area">
    <div class="box box-dark-border">
      <div class="box-header">
        <span>Architectural Philosophy: Empathetic Geriatric Engineering</span>
      </div>
      <p style="font-size: 9.6pt; line-height: 1.6;">
        CareElder is engineered as a <strong>continuous preventative healthcare ecosystem</strong> bridging patients, families, and clinicians. The platform is grounded in five core architectural pillars that ensure offline reliability, ease of use, and verified clinical utility.
      </p>
    </div>

    <div class="grid-3">
      <div class="box">
        <div class="box-header">
          <span>1. Exact Offline Alarms</span>
        </div>
        <p style="font-size: 8.8pt; line-height: 1.55;">
          Leverages OS-native AlarmManager and Full-Screen Intent to trigger critical wakeups even when the phone is locked, silenced, or disconnected from the internet.
        </p>
      </div>

      <div class="box">
        <div class="box-header">
          <span>2. AI Prescription OCR</span>
        </div>
        <p style="font-size: 8.8pt; line-height: 1.55;">
          Computer Vision model tailored for doctor handwriting extracts drug names, strengths, frequencies, and food correlations with sub-4s latency.
        </p>
      </div>

      <div class="box">
        <div class="box-header">
          <span>3. Zero-Typing Voice UX</span>
        </div>
        <p style="font-size: 8.8pt; line-height: 1.55;">
          Colloquial speech-to-text pipeline extracts numeric vital signs (BP, Glucose) and evaluates clinical ranges instantly without keyboard interaction.
        </p>
      </div>
    </div>

    <div class="grid-2">
      <div class="box">
        <div class="box-header">
          <span>4. Caregiver Cloud Escort</span>
        </div>
        <p style="font-size: 8.8pt; line-height: 1.55;">
          Real-time timeline displaying dose verification timestamps and an automated 3-tier escalation ladder for unconfirmed medications.
        </p>
      </div>

      <div class="box">
        <div class="box-header">
          <span>5. Clinical Reports & Inventory</span>
        </div>
        <p style="font-size: 8.8pt; line-height: 1.55;">
          Automated pill decrementing preventing therapy lapses, and longitudinal PDF reports with encrypted QR access for attending physicians.
        </p>
      </div>
    </div>

    <div class="box">
      <div class="box-header">
        <span>CareElder Closed-Loop Daily Care Execution Pipeline</span>
      </div>
      <table class="table-clean" style="text-align: center;">
        <thead>
          <tr>
            <th>1. Scan Prescription</th>
            <th>2. Local Schedule</th>
            <th>3. Wakeup & Voice</th>
            <th>4. Sync & Inventory</th>
            <th>5. Clinical Audit</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>AI Vision extracts drug entities from paper Rx</td>
            <td>Exact hardware alarms set inside local database</td>
            <td>Full-Screen Intent wakes phone with spoken guidance</td>
            <td>Live caregiver update & pill inventory decrement</td>
            <td>Longitudinal PDF trends & encrypted QR code review</td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</div>

<!-- ============================================================== -->
<!-- PAGE 5: STAKEHOLDER ECOSYSTEM & PERSONAS -->
<!-- ============================================================== -->
<div class="pdf-page">
  <div class="page-title-row">
    <h2 class="page-title">03. Stakeholder Ecosystem & User Personas</h2>
    <p class="page-subtitle">Detailed architectural profiling of target personas and cross-stakeholder interactions</p>
  </div>

  <div class="content-area">
    <div class="grid-3">
      <div class="box">
        <div class="box-header">
          <span>Haj Ibrahim (Age 73)</span>
          <span class="tag-clean">Chronic Patient</span>
        </div>
        <p style="font-size: 8.8pt; line-height: 1.55; margin-bottom: 8px;">
          <strong>Clinical Condition:</strong> Type-2 Diabetes & Hypertension; takes 6 daily medications.<br>
          <strong>Digital Literacy:</strong> Low; struggles with small fonts and clumsy typing.<br>
          <strong>Core Needs:</strong> High-contrast giant buttons, audible voice prompts in warm English/Arabic, and speaking vital measurements without touching keypad digits.
        </p>
        <div style="border-top: 1px solid var(--border-subtle); padding-top: 6px; font-size: 8.2pt;">
          <strong>Active Interface:</strong> Senior Mode (High Contrast, 24sp fonts, Zero Typing).
        </div>
      </div>

      <div class="box">
        <div class="box-header">
          <span>Mona (Age 39)</span>
          <span class="tag-clean">Family Caregiver</span>
        </div>
        <p style="font-size: 8.8pt; line-height: 1.55; margin-bottom: 8px;">
          <strong>Social Profile:</strong> Full-time working mother living 35 km away from her father.<br>
          <strong>Core Pain Point:</strong> Chronic work-hours anxiety and fear that her father forgets his heart pills.<br>
          <strong>Core Needs:</strong> Live dashboard displaying intake confirmations, automatic escalation alerts if doses are neglected, and remote pill refill automation.
        </p>
        <div style="border-top: 1px solid var(--border-subtle); padding-top: 6px; font-size: 8.2pt;">
          <strong>Active Interface:</strong> Caregiver Hub (Live Timeline, Rx Scanner, Refill Alerts).
        </div>
      </div>

      <div class="box">
        <div class="box-header">
          <span>Dr. Tarek (Age 52)</span>
          <span class="tag-clean">Attending Doctor</span>
        </div>
        <p style="font-size: 8.8pt; line-height: 1.55; margin-bottom: 8px;">
          <strong>Clinical Context:</strong> Evaluates senior patients quarterly to calibrate medication dosages.<br>
          <strong>Core Pain Point:</strong> Patient recall bias ("I think my pressure was around 130...").<br>
          <strong>Core Needs:</strong> Objective 90-day longitudinal adherence scores, BP/Glucose trend curves, and missed dose logs delivered via 1-tap QR scan or clinical PDF.
        </p>
        <div style="border-top: 1px solid var(--border-subtle); padding-top: 6px; font-size: 8.2pt;">
          <strong>Active Interface:</strong> Clinical Web Portal & Instant QR Report Viewer.
        </div>
      </div>
    </div>

    <div class="box" style="flex: 1;">
      <div class="box-header">
        <span>Cross-Stakeholder Interaction & Data Flow Matrix</span>
      </div>
      <table class="table-clean">
        <thead>
          <tr>
            <th style="width: 20%;">Actor</th>
            <th style="width: 35%;">Primary Input to System</th>
            <th style="width: 35%;">Delivered Output & Clinical Value</th>
            <th style="width: 10%;">Channel</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td><strong>Senior Patient</strong></td>
            <td>Dose confirmation (1-tap), voice-spoken vitals</td>
            <td>Audible guidance, giant visual cues, independence without typing</td>
            <td>Senior Mode UI</td>
          </tr>
          <tr>
            <td><strong>Family Caregiver</strong></td>
            <td>Prescription photo, schedule adjustments, inventory setup</td>
            <td>Real-time compliance feed, escalation alerts, refill alerts via WhatsApp</td>
            <td>Caregiver Hub</td>
          </tr>
          <tr>
            <td><strong>Attending Doctor</strong></td>
            <td>Prescription updates, biomarker safety boundaries</td>
            <td>Longitudinal PDF trends, adherence rate %, missed dose forensic log</td>
            <td>QR Scan / PDF Export</td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</div>

<!-- ============================================================== -->
<!-- PAGE 6: USE CASE 01 - MEDICATION ALARM & ACKNOWLEDGMENT -->
<!-- ============================================================== -->
<div class="pdf-page">
  <div class="page-title-row">
    <h2 class="page-title">04. Use Case 01: Smart Medication Alarm & Acknowledgment</h2>
    <p class="page-subtitle">Offline-First Exact Hardware Alarms, Full-Screen Intent Wakeup & Zero-Latency Acknowledgment</p>
  </div>

  <div class="content-area">
    <div class="spec-meta-grid">
      <div><span class="item-title">Use Case ID:</span> <span class="mono">UC-01</span></div>
      <div><span class="item-title">Primary Actor:</span> Senior Patient</div>
      <div><span class="item-title">Priority:</span> Critical (Must Have)</div>
      <div><span class="item-title">Execution:</span> 100% Offline-Ready</div>
    </div>

    <div class="box box-dark-border">
      <div class="box-header">
        <span>Operational Context & Goal</span>
      </div>
      <p style="font-size: 9.4pt; line-height: 1.6;">
        Guarantee that the senior patient is reliably awakened and alerted at the exact scheduled second, bypassing system silence and screen locks, with audible spoken instructions, high-contrast imagery of the specific pill, and instant offline acknowledgment.
      </p>
    </div>

    <div class="box" style="flex: 1;">
      <div class="box-header">
        <span>Main Success Scenario (Step-by-Step Execution Flow)</span>
      </div>
      
      <div class="step-item">
        <div class="step-num">1.</div>
        <div class="step-body">
          <strong>Exact Alarm Hardware Trigger:</strong> The OS-level Exact Alarm Scheduler (Android AlarmManager / iOS Background Task) triggers at the precise scheduled timestamp, independent of battery optimizations or internet connectivity.
        </div>
      </div>

      <div class="step-item">
        <div class="step-num">2.</div>
        <div class="step-body">
          <strong>Full-Screen Intent Wakeup:</strong> The display wakes up completely over the locked screen with high-contrast styling (AAA), pulsating visual cues, and an escalating, pleasant acoustic chime.
        </div>
      </div>

      <div class="step-item">
        <div class="step-num">3.</div>
        <div class="step-body">
          <strong>Audible Voice Guidance (TTS):</strong> The system speaks aloud: <em>"Time for Concor 5mg heart tablet after lunch, Haj Ibrahim"</em> while displaying an enlarged high-resolution image of the pill blister.
        </div>
      </div>

      <div class="step-item">
        <div class="step-num">4.</div>
        <div class="step-body">
          <strong>One-Tap Acknowledgment:</strong> The patient taps the giant button <strong>[Pill Taken Now]</strong>. The chime stops immediately, and the app speaks a confirmation message.
        </div>
      </div>

      <div class="step-item">
        <div class="step-num">5.</div>
        <div class="step-body">
          <strong>Local Persistence & Delta Sync:</strong> The event is committed locally to the Isar/SQLite database with a microsecond timestamp, and a compact encrypted delta payload is dispatched to the cloud for caregiver synchronization.
        </div>
      </div>
    </div>

    <div class="grid-2">
      <div class="box">
        <div class="box-header">
          <span>Alternative Flow 1: 10-Min Snooze</span>
        </div>
        <p style="font-size: 8.8pt; line-height: 1.55;">
          If the patient is eating or indisposed, they tap [Snooze 10 Mins]. The system reschedules the alarm for exactly 10 minutes later. Up to 3 snoozes are permitted before caregiver escalation initiates.
        </p>
      </div>

      <div class="box">
        <div class="box-header">
          <span>Alternative Flow 2: Ignored / Missed Alarm</span>
        </div>
        <p style="font-size: 8.8pt; line-height: 1.55;">
          If the alarm chimes for 60 seconds without touch, it transitions to a pending state. If unconfirmed after 30 minutes, the Cloud Adherence Watcher triggers a Tier-1 alert to the caregiver's phone.
        </p>
      </div>
    </div>
  </div>
</div>

<!-- ============================================================== -->
<!-- PAGE 7: USE CASE 02 - AI PRESCRIPTION OCR SCANNING -->
<!-- ============================================================== -->
<div class="pdf-page">
  <div class="page-title-row">
    <h2 class="page-title">05. Use Case 02: AI Prescription OCR & Medical NER</h2>
    <p class="page-subtitle">Multimodal Vision-Language Extraction of Handwritten Prescriptions into Structured Regimens</p>
  </div>

  <div class="content-area">
    <div class="spec-meta-grid">
      <div><span class="item-title">Use Case ID:</span> <span class="mono">UC-02</span></div>
      <div><span class="item-title">Primary Actor:</span> Caregiver / Senior</div>
      <div><span class="item-title">Priority:</span> Critical (Must Have)</div>
      <div><span class="item-title">Target Latency:</span> &lt; 3.5 Seconds</div>
    </div>

    <div class="box box-dark-border">
      <div class="box-header">
        <span>Operational Context & Goal</span>
      </div>
      <p style="font-size: 9.4pt; line-height: 1.6;">
        Enable caregivers to snap a photo of paper prescriptions (whether typed or handwritten by doctors) and have an AI vision engine extract drug entities, strengths, frequencies, and food correlations into an automated alarm schedule with human verification for clinical safety.
      </p>
    </div>

    <div class="box" style="flex: 1;">
      <div class="box-header">
        <span>Computer Vision & Natural Language Processing Pipeline</span>
      </div>
      
      <div class="step-item">
        <div class="step-num">1.</div>
        <div class="step-body">
          <strong>Guided Optical Capture:</strong> The camera UI renders a dynamic rectangular framing guide with on-device gyro-assisted angle detection to prevent perspective skewing and motion blur.
        </div>
      </div>

      <div class="step-item">
        <div class="step-num">2.</div>
        <div class="step-body">
          <strong>Adaptive Image Pre-Processing:</strong> Automatic document contour detection, perspective unwarping, shadow suppression, and adaptive thresholding optimize handwriting legibility.
        </div>
      </div>

      <div class="step-item">
        <div class="step-num">3.</div>
        <div class="step-body">
          <strong>OCR & Medical Entity Recognition (NER):</strong> The processed image passes to a multimodal vision pipeline with medical dictionary fuzzy matching to parse:
          <span class="mono">[Drug Name, Strength_mg, Frequency, Food_Relation, Duration]</span>.
        </div>
      </div>

      <div class="step-item">
        <div class="step-num">4.</div>
        <div class="step-body">
          <strong>Interactive Verification Card (Human-in-the-Loop):</strong> The extracted medications populate an editable confirmation card. Fields with confidence scores below 85% are highlighted for instant tap-confirmation.
        </div>
      </div>

      <div class="step-item">
        <div class="step-num">5.</div>
        <div class="step-body">
          <strong>Automated Schedule & Inventory Synthesis:</strong> Upon approval, alarms are programmatically synchronized with the senior's phone, and initial pill inventory quotas are registered automatically.
        </div>
      </div>
    </div>

    <div class="box">
      <div class="box-header">
        <span>Structured Output Schema (JSON Contract)</span>
      </div>
      <pre style="direction: ltr; text-align: left; font-family: 'JetBrains Mono', monospace; font-size: 8pt; background: #fafafa; border: 1px solid var(--border-light); color: #000; padding: 8px; overflow-x: auto;">
{
  "drug_trade_name": "Glucophage",
  "dosage_mg": 500,
  "frequency_per_day": 2,
  "meal_relation": "after_meals",
  "times": ["08:30", "20:30"],
  "inventory_pills": 60,
  "confidence_score": 0.96
}</pre>
    </div>
  </div>
</div>

<!-- ============================================================== -->
<!-- PAGE 8: USE CASE 03 - VOICE VITALS LOGGING & CLINICAL TRIAGE -->
<!-- ============================================================== -->
<div class="pdf-page">
  <div class="page-title-row">
    <h2 class="page-title">06. Use Case 03: Voice Vitals Logging & Clinical Triage</h2>
    <p class="page-subtitle">Zero-Typing Speech-to-Text Vitals Extraction with Instant Clinical Boundary Classification</p>
  </div>

  <div class="content-area">
    <div class="spec-meta-grid">
      <div><span class="item-title">Use Case ID:</span> <span class="mono">UC-03</span></div>
      <div><span class="item-title">Primary Actor:</span> Senior Patient</div>
      <div><span class="item-title">Priority:</span> Critical (Must Have)</div>
      <div><span class="item-title">Languages:</span> Colloquial Arabic & English</div>
    </div>

    <div class="box box-dark-border">
      <div class="box-header">
        <span>Operational Context & Goal</span>
      </div>
      <p style="font-size: 9.4pt; line-height: 1.6;">
        Empower the elderly patient to record daily biometric readings (blood pressure, fasting/random glucose, pulse) by speaking numbers naturally without typing a single digit. The engine parses the values, classifies them according to clinical guidelines, and notifies caregivers if critical.
      </p>
    </div>

    <div class="box" style="flex: 1;">
      <div class="box-header">
        <span>Execution Sequence & Clinical Evaluation Protocol</span>
      </div>
      
      <div class="step-item">
        <div class="step-num">1.</div>
        <div class="step-body">
          <strong>Single-Tap Voice Initiation:</strong> The senior taps the large microphone button in the center of the dashboard. An audio chime indicates that the system is actively listening.
        </div>
      </div>

      <div class="step-item">
        <div class="step-num">2.</div>
        <div class="step-body">
          <strong>Natural Spoken Utterance:</strong> The patient speaks casually: <em>"My pressure today is 135 over 85"</em> or <em>"Fasting sugar is 120"</em>.
        </div>
      </div>

      <div class="step-item">
        <div class="step-num">3.</div>
        <div class="step-body">
          <strong>Speech-to-Text & Numeric Parsing:</strong> The on-device/cloud STT engine transcribes speech, extracts metric types and numeric values, and speaks an audio confirmation back to the patient.
        </div>
      </div>

      <div class="step-item">
        <div class="step-num">4.</div>
        <div class="step-body">
          <strong>Instant Clinical Decision Triage:</strong> The system matches values against standard clinical guidelines (AHA/WHO) and displays clear status feedback immediately:
        </div>
      </div>

      <div class="grid-3" style="margin-top: 6px;">
        <div class="box" style="text-align: center;">
          <strong style="font-size: 9.2pt;">1. Optimal Band</strong>
          <p style="font-size: 8pt; margin-top: 3px;">BP &lt; 120/80<br>Fasting Glucose 70-110</p>
          <span style="font-size: 7.8pt; font-weight: 700;">"Normal stable reading"</span>
        </div>
        <div class="box" style="text-align: center;">
          <strong style="font-size: 9.2pt;">2. Borderline Band</strong>
          <p style="font-size: 8pt; margin-top: 3px;">BP 130-139 / 80-89<br>Fasting Glucose 111-140</p>
          <span style="font-size: 7.8pt; font-weight: 700;">"Mildly elevated, monitor salt"</span>
        </div>
        <div class="box" style="text-align: center; border: 1.5px solid var(--black);">
          <strong style="font-size: 9.2pt;">3. Critical Band</strong>
          <p style="font-size: 8pt; margin-top: 3px;">BP &ge; 180 or &le; 90<br>Glucose &lt; 70 or &gt; 250</p>
          <span style="font-size: 7.8pt; font-weight: 700;">"Instant Caregiver Alert!"</span>
        </div>
      </div>
    </div>

    <div class="box">
      <div class="box-header">
        <span>Critical Band Intervention Protocol</span>
      </div>
      <p style="font-size: 8.8pt; line-height: 1.55;">
        If a severe anomaly is detected (e.g. acute hypoglycemia &lt; 60 mg/dL or hypertensive urgency &gt; 180 mmHg), the app speaks immediate soothing guidance: <em>"Haj Ibrahim, please sit down calmly and drink some fruit juice"</em> while simultaneously pushing an alert to the caregiver's device.
      </p>
    </div>
  </div>
</div>

<!-- ============================================================== -->
<!-- PAGE 9: USE CASE 04 - REMOTE CAREGIVER SUPERVISION -->
<!-- ============================================================== -->
<div class="pdf-page">
  <div class="page-title-row">
    <h2 class="page-title">07. Use Case 04: Remote Caregiver Supervision & Real-Time Sync</h2>
    <p class="page-subtitle">Real-Time Cloud Synchronization, Multi-Tier Adherence Escalation & Remote Schedule Governance</p>
  </div>

  <div class="content-area">
    <div class="spec-meta-grid">
      <div><span class="item-title">Use Case ID:</span> <span class="mono">UC-04</span></div>
      <div><span class="item-title">Primary Actor:</span> Family Caregiver</div>
      <div><span class="item-title">Priority:</span> Critical (Must Have)</div>
      <div><span class="item-title">Sync Protocol:</span> WebSocket & FCM Delta Sync</div>
    </div>

    <div class="box box-dark-border">
      <div class="box-header">
        <span>Operational Context & Family Peace of Mind</span>
      </div>
      <p style="font-size: 9.4pt; line-height: 1.6;">
        Provide working or distant family members with 24/7 visibility into the senior's medication status and vital signs via a reactive mobile dashboard, backed by an automated escalation engine that intervenes whenever doses are missed without burdening the senior.
      </p>
    </div>

    <div class="grid-2" style="flex: 1;">
      <div class="box">
        <div class="box-header">
          <span>Caregiver Mobile Hub Components</span>
        </div>
        <ul class="bullet-list">
          <li><strong>Live Medication Timeline:</strong> Dynamic feed displaying today's regimen: Taken at 08:14 AM, Snoozed, or Upcoming.</li>
          <li><strong>Vitals Stream:</strong> Instant cards displaying latest blood pressure and blood sugar readings alongside 7-day rolling averages.</li>
          <li><strong>Personalized Audio Notes:</strong> Caregivers can record warm voice memos from grandchildren that play with the alarm to motivate the senior.</li>
          <li><strong>Live Intake Confirmation:</strong> Real-time push updates delivering total peace of mind during office hours.</li>
        </ul>
      </div>

      <div class="box">
        <div class="box-header">
          <span>Automated 3-Tier Adherence Escalation Ladder</span>
        </div>
        <div style="font-size: 8.8pt; display: flex; flex-direction: column; gap: 8px;">
          <div style="border-left: 2px solid var(--black); padding-left: 8px;">
            <strong>Minute 0:</strong> Exact hardware alarm sounds on senior's phone with audible spoken pill guidance.
          </div>
          <div style="border-left: 2px solid var(--black); padding-left: 8px;">
            <strong>Minute +15:</strong> Gentle secondary chime on patient device if unconfirmed.
          </div>
          <div style="border-left: 2px solid var(--black); padding-left: 8px;">
            <strong>Minute +30:</strong> Tier-1 Care Alert pushed to caregiver: <em>"Notice: Your father has not confirmed his morning heart dose."</em>
          </div>
          <div style="border-left: 2px solid var(--black); padding-left: 8px;">
            <strong>Minute +60:</strong> Tier-2 Urgent Alert with an embedded 1-tap call button encouraging immediate contact.
          </div>
        </div>
      </div>
    </div>

    <div class="box">
      <div class="box-header">
        <span>Remote Prescription & Schedule Governance</span>
      </div>
      <p style="font-size: 8.8pt; line-height: 1.55;">
        Caregivers can adjust dosages or add newly prescribed medications directly from their own smartphones. All schema modifications sync instantly to the senior's phone without requiring any complex technical interaction from the senior.
      </p>
    </div>
  </div>
</div>

<!-- ============================================================== -->
<!-- PAGE 10: USE CASE 05 - AUTOMATED PILL INVENTORY -->
<!-- ============================================================== -->
<div class="pdf-page">
  <div class="page-title-row">
    <h2 class="page-title">08. Use Case 05: Automated Pill Inventory & Low-Stock Alerts</h2>
    <p class="page-subtitle">Predictive Medication Stock Burn-Rate Calculation & One-Tap Pharmacy Reordering</p>
  </div>

  <div class="content-area">
    <div class="spec-meta-grid">
      <div><span class="item-title">Use Case ID:</span> <span class="mono">UC-05</span></div>
      <div><span class="item-title">Primary Actor:</span> Caregiver / Inventory Engine</div>
      <div><span class="item-title">Priority:</span> Important (Should Have)</div>
      <div><span class="item-title">Objective:</span> Eliminate chronic medicine shortages</div>
    </div>

    <div class="box box-dark-border">
      <div class="box-header">
        <span>Operational Context & Goal</span>
      </div>
      <p style="font-size: 9.4pt; line-height: 1.6;">
        Completely eradicate sudden medication stock-outs by tracking remaining tablet counts in real-time, forecasting exact depletion dates based on consumption patterns, and triggering proactive caregiver warnings 5 days prior with a pre-formatted pharmacy refill order.
      </p>
    </div>

    <div class="box" style="flex: 1;">
      <div class="box-header">
        <span>Inventory Tracking & Predictive Replenishment Workflow</span>
      </div>
      
      <div class="step-item">
        <div class="step-num">1.</div>
        <div class="step-body">
          <strong>Batch Registration:</strong> When registering a new medication (via OCR scan or manual entry), the caregiver inputs the total pill count (e.g. 2 blister strips = 20 tablets of Concor 5mg).
        </div>
      </div>

      <div class="step-item">
        <div class="step-num">2.</div>
        <div class="step-body">
          <strong>Synchronized Auto-Decrement:</strong> Each time the senior confirms a dose, the system automatically decrements the inventory quota across both local and cloud databases.
        </div>
      </div>

      <div class="step-item">
        <div class="step-num">3.</div>
        <div class="step-body">
          <strong>Depletion Date Forecasting:</strong> The algorithm calculates the precise depletion milestone: <span class="mono">Depletion_Date = Today + (Pills_Remaining / Daily_Doses)</span>.
        </div>
      </div>

      <div class="step-item">
        <div class="step-num">4.</div>
        <div class="step-body">
          <strong>Proactive 5-Day Threshold Warning:</strong> When remaining stock falls below 5 days of therapy, an alert notifies the caregiver: <em>"Stock Alert: 5 days of heart medication remaining for Haj Ibrahim."</em>
        </div>
      </div>

      <div class="step-item">
        <div class="step-num">5.</div>
        <div class="step-body">
          <strong>1-Tap Neighborhood Pharmacy Reorder:</strong> The caregiver taps [Generate Order], which compiles a structured refill manifest ready to send via WhatsApp to the family's preferred local pharmacy with a single tap.
        </div>
      </div>
    </div>

    <div class="grid-2">
      <div class="box">
        <div class="box-header">
          <span>Sample Automated Pharmacy WhatsApp Manifest</span>
        </div>
        <div style="font-size: 8.2pt; background: #fafafa; border: 1px solid var(--border-light); padding: 8px; font-family: 'JetBrains Mono', monospace;">
          Hello Care Pharmacy, please prepare refills for Patient Ibrahim:<br>
          1. Concor 5mg (Box of 30 tabs)<br>
          2. Glucophage 500mg (Box of 60 tabs)<br>
          Delivery Address: 12 Tahrir St, Apt 4.
        </div>
      </div>

      <div class="box">
        <div class="box-header">
          <span>Medication Expiration Date Guard</span>
        </div>
        <p style="font-size: 8.8pt; line-height: 1.55;">
          Caregivers can capture the expiration date stamped on the blister strip. The system monitors shelf life and flags medications 30 days before expiration, preventing the inadvertent intake of expired pharmaceuticals.
        </p>
      </div>
    </div>
  </div>
</div>

<!-- ============================================================== -->
<!-- PAGE 11: USE CASE 06 - CLINICAL REPORTING FOR DOCTORS -->
<!-- ============================================================== -->
<div class="pdf-page">
  <div class="page-title-row">
    <h2 class="page-title">09. Use Case 06: Longitudinal Clinical Reporting for Doctors</h2>
    <p class="page-subtitle">Longitudinal Adherence Trend Analytics, Clinical Vital Graphing & Encrypted QR Doctor Portals</p>
  </div>

  <div class="content-area">
    <div class="spec-meta-grid">
      <div><span class="item-title">Use Case ID:</span> <span class="mono">UC-06</span></div>
      <div><span class="item-title">Primary Actor:</span> Doctor / Caregiver / Patient</div>
      <div><span class="item-title">Priority:</span> Critical (Must Have)</div>
      <div><span class="item-title">Formats:</span> Clinical PDF & Encrypted QR</div>
    </div>

    <div class="box box-dark-border">
      <div class="box-header">
        <span>Clinical Value Proposition</span>
      </div>
      <p style="font-size: 9.4pt; line-height: 1.6;">
        Transform clinical consultations from subjective, memory-based guesswork into precision data reviews. CareElder compiles 30 to 90 days of verified adherence data and vital sign readings into an executive clinical report that empowers physicians to make informed therapeutic adjustments.
      </p>
    </div>

    <div class="box" style="flex: 1;">
      <div class="box-header">
        <span>Clinical Longitudinal Report Architecture</span>
      </div>
      
      <div class="grid-2">
        <div class="box">
          <strong style="font-size: 9.2pt;">1. Cumulative Adherence Score %</strong>
          <p style="font-size: 8.4pt; color: var(--text-secondary); margin-top: 3px;">
            A verified metric computing on-time medication intake versus prescribed schedules (e.g. 94.5% adherence over the past quarter).
          </p>
        </div>

        <div class="box">
          <strong style="font-size: 9.2pt;">2. Biometric Longitudinal Curves</strong>
          <p style="font-size: 8.4pt; color: var(--text-secondary); margin-top: 3px;">
            Continuous trend graphs mapping systolic/diastolic blood pressure and fasting/postprandial glucose over 30 or 90 days.
          </p>
        </div>

        <div class="box">
          <strong style="font-size: 9.2pt;">3. Missed Dose Forensic Log</strong>
          <p style="font-size: 8.4pt; color: var(--text-secondary); margin-top: 3px;">
            Granular incident logs documenting unconfirmed doses, timestamps, and recorded reasons (forgetfulness, stock shortage, or repeated snoozing).
          </p>
        </div>

        <div class="box">
          <strong style="font-size: 9.2pt;">4. Active Multi-Drug Regimen</strong>
          <p style="font-size: 8.4pt; color: var(--text-secondary); margin-top: 3px;">
            Comprehensive listing of brand names, active scientific entities, and dosages to prevent dangerous prescribing duplications.
          </p>
        </div>
      </div>

      <div style="margin-top: 8px; border: 1px dashed var(--black); padding: 8px; background: #fafafa;">
        <strong style="font-size: 9pt;">Zero-Install Clinical QR Consultation Scan</strong>
        <p style="font-size: 8.4pt; color: var(--text-secondary); margin-top: 2px;">
          Instead of carrying cumbersome paper binders, the caregiver presents a temporary <strong>encrypted QR code</strong>. The physician scans it with their clinic smartphone or workstation camera, immediately opening a secure, interactive web dashboard without installing any software.
        </p>
      </div>
    </div>

    <div class="box">
      <div class="box-header">
        <span>Clinical Efficacy & Impact on Dosage Decisions</span>
      </div>
      <p style="font-size: 8.8pt; line-height: 1.55;">
        Clinical research demonstrates that objective adherence reporting reduces diagnostic consultation time by 40% and prevents clinicians from inadvertently increasing drug dosages when poor control is actually caused by missed pills rather than pharmacological tolerance.
      </p>
    </div>
  </div>
</div>

</body>
</html>
"""

def main():
    print("Writing updated English HTML document (no header/footer, larger font)...")
    html_content = build_english_html()
    with open(HTML_FILE, "w", encoding="utf-8") as f:
        f.write(html_content)
    print(f"English HTML written: {HTML_FILE} ({len(html_content)} bytes)")

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
        print(f"English PDF successfully generated! Size: {size} bytes")
        reader = pypdf.PdfReader(PDF_FILE)
        total_pages = len(reader.pages)
        print(f"TOTAL PAGES IN UPDATED ENGLISH PDF: {total_pages}")
        return total_pages
    else:
        print("Error: PDF file was not created.")
        return 0

if __name__ == "__main__":
    main()
