
# -*- coding: utf-8 -*-
import os
import sys
from pathlib import Path
import arabic_reshaper
from bidi.algorithm import get_display

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak, KeepTogether, HRFlowable
)
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen import canvas

# 1. Fonts
font_regular = "C:/Windows/Fonts/arial.ttf"
font_bold = "C:/Windows/Fonts/arialbd.ttf"
if not os.path.exists(font_regular):
    font_regular = "C:/Windows/Fonts/tahoma.ttf"
    font_bold = "C:/Windows/Fonts/tahomabd.ttf"

pdfmetrics.registerFont(TTFont("ArabicFont", font_regular))
pdfmetrics.registerFont(TTFont("ArabicFont-Bold", font_bold))

def ar_wrap(text, max_width_pt=500, font_name="ArabicFont", font_size=10):
    if not text:
        return ""
    paragraphs = str(text).split("\n")
    all_lines = []
    for p in paragraphs:
        p_clean = p.strip()
        if not p_clean:
            continue
        words = p_clean.split()
        current_line = []
        for word in words:
            test_line = " ".join(current_line + [word])
            w = pdfmetrics.stringWidth(test_line, font_name, font_size)
            if w <= max_width_pt:
                current_line.append(word)
            else:
                if current_line:
                    all_lines.append(" ".join(current_line))
                    current_line = [word]
                else:
                    all_lines.append(word)
                    current_line = []
        if current_line:
            all_lines.append(" ".join(current_line))
            
    reshaped_lines = []
    for l in all_lines:
        reshaped = arabic_reshaper.reshape(l)
        reshaped_lines.append(get_display(reshaped))
    return "<br/>".join(reshaped_lines)

def ar(text):
    if not text:
        return ""
    return get_display(arabic_reshaper.reshape(str(text)))

class NumberedCanvas(canvas.Canvas):
    def __init__(self, *args, **kwargs):
        super(NumberedCanvas, self).__init__(*args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            self.draw_page_decorations(num_pages)
            super(NumberedCanvas, self).showPage()
        super(NumberedCanvas, self).save()

    def draw_page_decorations(self, page_count):
        if self._pageNumber == 1:
            return  # Skip cover
        self.saveState()
        self.setFont("ArabicFont", 8.5)
        self.setFillColor(colors.HexColor("#64748B"))
        
        # Header (Top)
        header_text = ar("منصة Medliva — التقرير الفني والأكاديمي الشامل لتوثيق مخرجات وهندسة المشروع")
        self.drawRightString(A4[0] - 36, A4[1] - 30, header_text)
        self.setStrokeColor(colors.HexColor("#CBD5E1"))
        self.setLineWidth(0.6)
        self.line(36, A4[1] - 34, A4[0] - 36, A4[1] - 34)
        
        # Footer (Bottom)
        footer_page = ar(f"صفحة {self._pageNumber} من {page_count}")
        self.drawString(36, 24, footer_page)
        footer_right = ar("مشروع الرعاية الصحية الذكية وإدارة الالتزام الدوائي لكبار السن | أكتوبر 2026")
        self.drawRightString(A4[0] - 36, 24, footer_right)
        self.line(36, 34, A4[0] - 36, 34)
        
        self.restoreState()

C_PRIMARY = colors.HexColor("#1E3A8A")     # Navy
C_SECONDARY = colors.HexColor("#0F766E")   # Teal
C_DARK = colors.HexColor("#0F172A")        # Slate
C_BODY = colors.HexColor("#334155")        # Charcoal
C_BG_CARD = colors.HexColor("#F8FAFC")     # Off-white
C_BORDER = colors.HexColor("#CBD5E1")      # Border
C_GREEN = colors.HexColor("#16A34A")       # Green
C_AMBER = colors.HexColor("#D97706")       # Amber
C_RED = colors.HexColor("#DC2626")         # Red

styles = getSampleStyleSheet()

style_h1 = ParagraphStyle("H1", fontName="ArabicFont-Bold", fontSize=14.5, leading=20, textColor=C_PRIMARY, alignment=2, spaceBefore=8, spaceAfter=5)
style_h2 = ParagraphStyle("H2", fontName="ArabicFont-Bold", fontSize=11.5, leading=16, textColor=C_SECONDARY, alignment=2, spaceBefore=6, spaceAfter=3)
style_body = ParagraphStyle("Body", fontName="ArabicFont", fontSize=9.5, leading=14.5, textColor=C_BODY, alignment=2, spaceAfter=4.5)
style_bullet = ParagraphStyle("Bullet", fontName="ArabicFont", fontSize=9.5, leading=14, textColor=C_BODY, alignment=2, spaceAfter=2.5)
style_card_title = ParagraphStyle("CT", fontName="ArabicFont-Bold", fontSize=10, leading=14, textColor=C_PRIMARY, alignment=2)
style_card_body = ParagraphStyle("CB", fontName="ArabicFont", fontSize=9, leading=13.5, textColor=colors.HexColor("#1E293B"), alignment=2)

def p_body(text, width=523):
    return Paragraph(ar_wrap(text, max_width_pt=width, font_name="ArabicFont", font_size=9.5), style_body)

def p_bullet(text, width=510):
    formatted = f"• {text}"
    return Paragraph(ar_wrap(formatted, max_width_pt=width, font_name="ArabicFont", font_size=9.5), style_bullet)

def p_h1(text, width=523):
    return Paragraph(ar_wrap(text, max_width_pt=width, font_name="ArabicFont-Bold", font_size=14.5), style_h1)

def p_h2(text, width=523):
    return Paragraph(ar_wrap(text, max_width_pt=width, font_name="ArabicFont-Bold", font_size=11.5), style_h2)

def make_callout(title_text, body_text, border_color=C_PRIMARY, bg_color=C_BG_CARD, width=523):
    t_text = ar_wrap(title_text, max_width_pt=width-20, font_name="ArabicFont-Bold", font_size=9.5)
    b_text = ar_wrap(body_text, max_width_pt=width-20, font_name="ArabicFont", font_size=9)
    p_t = Paragraph(f"<b>{t_text}</b>", ParagraphStyle('CT', fontName='ArabicFont-Bold', fontSize=9.5, leading=13.5, textColor=border_color, alignment=2))
    p_b = Paragraph(b_text, style_card_body)
    t = Table([[p_t], [Spacer(1, 1.5)], [p_b]], colWidths=[width])
    t.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), bg_color),
        ('BOX', (0,0), (-1,-1), 1, border_color),
        ('PADDING', (0,0), (-1,-1), 6),
        ('BOTTOMPADDING', (0,-1), (-1,-1), 6),
    ]))
    return t

def make_table(headers, rows, col_widths=None, width=523, padding=4.5):
    n_cols = len(headers)
    if not col_widths:
        w = width / n_cols
        col_widths = [w] * n_cols
    
    table_data = []
    h_row = []
    for i, h in enumerate(headers):
        text_w = col_widths[i] - 10
        h_row.append(Paragraph(ar_wrap(h, max_width_pt=text_w, font_name="ArabicFont-Bold", font_size=8.5), 
                               ParagraphStyle('TH', fontName='ArabicFont-Bold', fontSize=8.5, leading=11.5, textColor=colors.white, alignment=1)))
    table_data.append(h_row)
    
    for r in rows:
        row_cells = []
        for i, val in enumerate(r):
            text_w = col_widths[i] - 10
            row_cells.append(Paragraph(ar_wrap(val, max_width_pt=text_w, font_name="ArabicFont", font_size=8), 
                                       ParagraphStyle('TC', fontName='ArabicFont', fontSize=8, leading=11, textColor=colors.HexColor("#1E293B"), alignment=2)))
        table_data.append(row_cells)
        
    t = Table(table_data, colWidths=col_widths)
    t.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), C_PRIMARY),
        ('ALIGN', (0,0), (-1,-1), 'RIGHT'),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('GRID', (0,0), (-1,-1), 0.5, C_BORDER),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, colors.HexColor("#F8FAFC")]),
        ('PADDING', (0,0), (-1,-1), padding),
    ]))
    return t

TOOLS_DIR = Path(__file__).resolve().parent
DOCS_DIR = TOOLS_DIR.parent
PROJECT_ROOT = DOCS_DIR.parent
ORIGINAL_DIR = DOCS_DIR / "original"

def resolve_output_path(filename: str | Path | None = None) -> Path:
    """Resolve the PDF output path.
    
    If an explicit path or filename is passed, it is resolved against current working dir (if relative).
    If no path is passed, defaults to docs/original/Medliva_Comprehensive_Academic_Report.pdf.
    """
    if filename:
        p = Path(filename)
        if not p.is_absolute():
            return (Path.cwd() / p).resolve()
        return p
    ORIGINAL_DIR.mkdir(parents=True, exist_ok=True)
    return ORIGINAL_DIR / "Medliva_Comprehensive_Academic_Report.pdf"

def build_pdf(filename=None):
    output_path = resolve_output_path(filename)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    target_filename = str(output_path)
    doc = SimpleDocTemplate(
        target_filename,
        pagesize=A4,
        leftMargin=36,
        rightMargin=36,
        topMargin=44,
        bottomMargin=44
    )
    
    story = []
    
    # -------------------------------------------------------------------------
    # صفحة الغلاف (Cover Page)
    # -------------------------------------------------------------------------
    story.append(Spacer(1, 15))
    cover_inst = Paragraph(ar_wrap("مشروع الأنظمة الذكية للرعاية الصحية — التوثيق الفني والأكاديمي الشامل", max_width_pt=500, font_name="ArabicFont-Bold", font_size=11), 
                           ParagraphStyle('CInst', fontName='ArabicFont-Bold', fontSize=11, leading=16, textColor=C_SECONDARY, alignment=1))
    story.append(cover_inst)
    story.append(Spacer(1, 8))
    story.append(HRFlowable(width="65%", thickness=1.5, color=C_SECONDARY, spaceBefore=0, spaceAfter=20))
    
    title_ar = Paragraph(ar_wrap("منصة ميدليفا (Medliva)", max_width_pt=500, font_name="ArabicFont-Bold", font_size=28), 
                         ParagraphStyle('CTitle', fontName='ArabicFont-Bold', fontSize=28, leading=38, textColor=C_PRIMARY, alignment=1))
    story.append(title_ar)
    story.append(Spacer(1, 6))
    
    title_en = Paragraph("Smart Healthcare & Medication Adherence Platform", 
                         ParagraphStyle('CTitleEn', fontName='Helvetica-Bold', fontSize=13, leading=18, textColor=C_SECONDARY, alignment=1))
    story.append(title_en)
    story.append(Spacer(1, 12))
    
    sub_title = Paragraph(ar_wrap("التقرير الفني والأكاديمي الشامل لتوثيق هندسة ومخرجات المنصة\nنظام متكامل لإدارة الالتزام الدوائي، والفرز الطبي، ومراقبة المرافقين، والذكاء الاصطناعي لكبار السن", max_width_pt=480, font_name="ArabicFont", font_size=11), 
                          ParagraphStyle('CSub', fontName='ArabicFont', fontSize=11, leading=19, textColor=C_BODY, alignment=1))
    story.append(sub_title)
    story.append(Spacer(1, 25))
    
    cover_meta_data = [
        [
            Paragraph(ar_wrap("بيئة التنفيذ البرمجية:", max_width_pt=180, font_name="ArabicFont-Bold", font_size=9.5), ParagraphStyle('CMB', fontName='ArabicFont-Bold', fontSize=9.5, leading=14, textColor=C_PRIMARY, alignment=2)),
            Paragraph(ar_wrap("تطبيق Flutter للهواتف الذكية + واجهة خلفية FastAPI + سحابة Supabase", max_width_pt=300, font_name="ArabicFont", font_size=9.5), ParagraphStyle('CMV', fontName='ArabicFont', fontSize=9.5, leading=14, textColor=C_BODY, alignment=2))
        ],
        [
            Paragraph(ar_wrap("نوع الوثيقة:", max_width_pt=180, font_name="ArabicFont-Bold", font_size=9.5), ParagraphStyle('CMB', fontName='ArabicFont-Bold', fontSize=9.5, leading=14, textColor=C_PRIMARY, alignment=2)),
            Paragraph(ar_wrap("تقرير تسليم هندسي وأكاديمي مفصل (Graduation & Technical Deliverable)", max_width_pt=300, font_name="ArabicFont", font_size=9.5), ParagraphStyle('CMV', fontName='ArabicFont', fontSize=9.5, leading=14, textColor=C_BODY, alignment=2))
        ],
        [
            Paragraph(ar_wrap("تاريخ التوثيق:", max_width_pt=180, font_name="ArabicFont-Bold", font_size=9.5), ParagraphStyle('CMB', fontName='ArabicFont-Bold', fontSize=9.5, leading=14, textColor=C_PRIMARY, alignment=2)),
            Paragraph(ar_wrap("أكتوبر 2026 (تحديث الإصدار النهائي المتكامل v1.0)", max_width_pt=300, font_name="ArabicFont", font_size=9.5), ParagraphStyle('CMV', fontName='ArabicFont', fontSize=9.5, leading=14, textColor=C_BODY, alignment=2))
        ],
        [
            Paragraph(ar_wrap("حالة الإنجاز والتحقق:", max_width_pt=180, font_name="ArabicFont-Bold", font_size=9.5), ParagraphStyle('CMB', fontName='ArabicFont-Bold', fontSize=9.5, leading=14, textColor=C_PRIMARY, alignment=2)),
            Paragraph(ar_wrap("مكتمل بالكامل (16 مرحلة تنفيذية موثقة ومجتازة لكافة الاختبارات الآلية)", max_width_pt=300, font_name="ArabicFont", font_size=9.5), ParagraphStyle('CMV', fontName='ArabicFont', fontSize=9.5, leading=14, textColor=C_GREEN, alignment=2))
        ],
        [
            Paragraph(ar_wrap("منهجية الصياغة:", max_width_pt=180, font_name="ArabicFont-Bold", font_size=9.5), ParagraphStyle('CMB', fontName='ArabicFont-Bold', fontSize=9.5, leading=14, textColor=C_PRIMARY, alignment=2)),
            Paragraph(ar_wrap("صياغة أكاديمية منهجية توثق كافة المخرجات والحلول الوظيفية بعيداً عن الكود", max_width_pt=300, font_name="ArabicFont", font_size=9.5), ParagraphStyle('CMV', fontName='ArabicFont', fontSize=9.5, leading=14, textColor=C_BODY, alignment=2))
        ]
    ]
    meta_table = Table(cover_meta_data, colWidths=[160, 340])
    meta_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), C_BG_CARD),
        ('BOX', (0,0), (-1,-1), 1.2, C_PRIMARY),
        ('INNERGRID', (0,0), (-1,-1), 0.5, C_BORDER),
        ('PADDING', (0,0), (-1,-1), 8),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
    ]))
    story.append(meta_table)
    story.append(Spacer(1, 25))
    
    cover_summary = make_callout(
        "نبذة موجزة عن المشروع وأهميته المجتمعية والطبية:",
        "يُعد مشروع Medliva حلاً تقنياً متكاملاً لمواجهة إحدى أخطر المعضلات الصحية العالمية، وهي ظاهرة عدم التزام كبار السن ومرضى الأمراض المزمنة بجرعات الأدوية المقررة. قمنا بتصميم وبناء بيئة رقمية هجينة تجمع بين تطبيق هاتف ذكي فائق السهولة للمريض ومرافقه، وخادم سحابي ذكي لمعالجة البيانات والفرز الطبي التلقائي، ومحرك تنبيهات صارم يعمل دون الحاجة لشبكة الإنترنت. يقدم هذا التقرير استعراضاً شاملاً ومفصلاً لكافة الأنظمة الفرعية التي قمنا بابتكارها وتنفيذها بالمشروع.",
        border_color=C_SECONDARY,
        width=523
    )
    story.append(cover_summary)
    story.append(PageBreak())
    
    # -------------------------------------------------------------------------
    # الفصل الأول: الإطار العام والدوافع والمشكلة البحثية
    # -------------------------------------------------------------------------
    story.append(p_h1("الفصل الأول: الإطار العام، المشكلة البحثية، ودوافع المشروع"))
    story.append(HRFlowable(width="100%", thickness=1, color=C_PRIMARY, spaceBefore=2, spaceAfter=8))
    
    story.append(p_h2("1.1 بيان المشكلة الطبية والواقعية (Problem Statement)"))
    story.append(p_body(
        "تشير الدراسات والتقارير الصادرة عن منظمة الصحة العالمية (WHO) إلى أن ما يزيد عن 50% من مرضى الأمراض المزمنة — وخاصة كبار السن المصابين بارتفاع ضغط الدم وداء السكري وأمراض القلب — يفشلون في الالتزام بمواعيد وبروتوكولات أدويتهم المحددة. ويعود ذلك لعدة أسباب بنيوية، من أبرزها: تداخل الجداول العلاجية وتعدد الأدوية يومياً، والتدهور التدريجي في الذاكرة والقدرات البصرية والإدراكية لكبار السن، وصعوبة قراءة وفهم الروشتات الطبية المعقدة، بالإضافة إلى غياب أدوات المتابعة الفورية لدى أفراد الأسرة والمرافقين المشغولين بمسؤوليات الحياة اليومية."
    ))
    story.append(p_body(
        "ينجم عن هذا الخلل عواقب صحية واقتصادية بالغة الخطورة؛ حيث تؤدي الجرعات الفائتة أو المضاعفة إلى تدهور مفاجئ في المؤشرات الحيوية، ودخول متكرر لأقسام الطوارئ والعناية المركزة، وارتفاع كبير في نفقات الرعاية الصحية التي يمكن تجنبها تماماً بالالتزام الوقائي الصارم."
    ))
    
    story.append(p_h2("1.2 الدوافع والأهداف الاستراتيجية للمشروع (Project Objectives)"))
    story.append(p_body("انطلاقاً من هذا التحدي الإنساني، قمنا بتحديد الأهداف الرئيسية للمشروع والعمل على تحقيقها وفق أرقى المعايير التقنية:"))
    story.append(p_bullet("تطوير منصة رقمية ذات تصميم مخصص بالكامل لكبار السن (Geriatric-Centered UI/UX) تكسر الحواجز الرقمية، وتلغي الاعتماد على القوائم المعقدة أو الخطوط الصغيرة."))
    story.append(p_bullet("ابتكار محرك تنبيهات محلي صارم (Strict Local Reminders) يعمل بملء الشاشة فوق شاشة القفل، ويستمر في التنبيه وتكراره دون أي اعتماد على وجود اتصال بشبكة الإنترنت."))
    story.append(p_bullet("بناء شبكة أمان تفاعلية ومحرك تصعيد ذكي (Escalation Engine) يربط المريض بمرافقه بشكل لحظي، وينبه المرافق تلقائياً في حال تأخر المريض عن تناول جرعته لأكثر من 15 دقيقة."))
    story.append(p_bullet("دمج الذكاء الاصطناعي البصري والصوتي (Vision & Voice AI) لتمكين كبار السن من مسح الروشتات الطبية بالكاميرا، وإدخال القياسات الحيوية بالصوت باللهجة العربية والمصرية وتصنيفها طبياً."))
    story.append(p_bullet("تمكين الأطباء من قراءة تقارير التزام شاملة وموثقة بصيغة PDF مستخرجة مباشرة من التطبيق أثناء الزيارة العيادية دون الحاجة لتثبيت برامج معقدة."))
    
    story.append(Spacer(1, 4))
    story.append(make_callout(
        "خلاصة المنهجية المتبعة:",
        "قمنا بصياغة حل تقني يركز على سد الفجوة بين قدرات كبار السن البسيطة، ومتطلبات الأدوية الدقيقة، وقلق المرافقين. لم يكن الهدف بناء تطبيق تقليدي لقوائم المهام، بل منظومة أمان صحي استباقية تحمي المريض حتى في غياب الإنترنت، وتصعّد الحالات الطارئة لحظياً للمرافقين.",
        border_color=C_PRIMARY,
        width=523
    ))
    story.append(Spacer(1, 10))
    
    # -------------------------------------------------------------------------
    # الفصل الثاني: المعمارية الهندسية الشاملة ومنهجية العمل
    # -------------------------------------------------------------------------
    story.append(p_h1("الفصل الثاني: المعمارية الهندسية الشاملة ومنهجية العمل"))
    story.append(HRFlowable(width="100%", thickness=1, color=C_PRIMARY, spaceBefore=2, spaceAfter=8))
    
    story.append(p_h2("2.1 معمارية النظام الموزع ثلاثية الطبقات (3-Tier Distributed Architecture)"))
    story.append(p_body(
        "قمنا بهندسة المنصة على أسس معمارية حديثة وموزعة تضمن الفصل الصارم بين طبقة العرض وتجربة المستخدم، وطبقة معالجة منطق الأعمال، وطبقة البيانات والهوية، وذلك عبر ثلاثة مكونات رئيسية:"
    ))
    story.append(p_bullet("الواجهة الأمامية للمستخدم (Mobile Client): تطبيق هجين موحد مبني بإطار عمل Flutter، مصمم وفق معمارية نظيفة (Clean Architecture) مفصولة الطبقات، ويعمل عبر محرك إدارة الحالة Riverpod، مع تخزين مؤقت وقواعد بيانات محلية لدعم العمل أوفلاين."))
    story.append(p_bullet("الواجهة الخلفية والخادم السحابي (Backend API): خادم عالي الكفاءة مبني باستخدام إطار العمل الحديث FastAPI بلغة بايثون، يعتمد على المعالجة غير المتزامنة (Asynchronous I/O)، ويوفر واجهات RESTful آمنة وموثقة آلياً عبر معايير OpenAPI/Swagger."))
    story.append(p_bullet("سحابة الهوية والبيانات (Cloud Database & Auth): قاعدة بيانات علائقية متقدمة PostgreSQL مستضافة على منصة Supabase، مع تفعيل آليات المصادقة وتشفير الجلسات، واستخدام تقنية الترحيل الهيكلي لقواعد البيانات (Alembic) لإدارة التحديثات بدقة."))
    
    story.append(p_h2("2.2 فلسفة العمل دون إنترنت (Offline-First Paradigm)"))
    story.append(p_body(
        "حرصنا في هذا المشروع على تطبيق مبدأ هندسي حاسم: 'لا يجوز أن يتوقف تطبيق الرعاية الصحية أو يفقد دواء المريض بسبب انقطاع الإنترنت أو ضعف التغطية في المنزل'. لتحقيق ذلك، قمنا ببناء:"
    ))
    story.append(p_bullet("استقلالية التنبيهات: تُجدول مواعيد الأدوية والتنبيهات محلياً داخل نظام تشغيل الهاتف مباشرة، وتعمل بدقة متناهية دون الحاجة لأي اتصال بالخادم."))
    story.append(p_bullet("طابور المزامنة الذكي (Sync Queue): عند تسجيل المريض لتناول الجرعة أو إدخال قياس حيوي في وضع عدم الاتصال، تُحفظ العملية محلياً برقم معرّف فريد للعميل (UUID). وفور استعادة الاتصال بالإنترنت، يرسل التطبيق دفعة مجمعة تلقائياً إلى الخادم لمعالجة السجلات وتحديث قاعدة البيانات المركزية دون أي تدخل يدوي."))
    story.append(p_bullet("الحماية من تكرار البيانات (Idempotency): قمنا ببرمجة الخادم ليكون محصناً ضد التكرار؛ حيث يتحقق من المعرف الفريد للجرعة لضمان عدم احتساب الجرعة مرتين مهما تكررت محاولات الإرسال الشبكي."))
    
    story.append(p_h2("2.3 معايير الأمان وحماية الخصوصية الطبية (Medical Privacy & Security)"))
    story.append(p_body(
        "قمنا بتطبيق تدابير أمنية محكمة تتوافق مع حساسيات البيانات الطبية والصحية الشخصية:"
    ))
    story.append(p_bullet("المصادقة الآمنة عبر الرموز البرمجية (Bearer Access Tokens): تشفير كل طلب برمجي برمز وصول صادر من سحابة Supabase ومتحقق منه في خادم FastAPI."))
    story.append(p_bullet("فحص الصلاحيات والوصول في كل نقطة (Strict Patient-Access Verification): قمنا ببرمجة وسيط أمني يفحص كل مسار للبيانات للتأكد من أن المستخدم إما هو المريض نفسه صاحب السجل، أو مرافق مسجل ومقترن رسمياً به، مع حجب أي وصول غريب وإرجاع رمز الحظر 403 Forbidden تلقائياً."))
    story.append(p_bullet("تفعيل سياسات أمان مستوى الصف (Row-Level Security - RLS) في قاعدة البيانات المركزية لحماية الجداول العامة من القراءة أو التعديل غير المصرح."))
    
    story.append(Spacer(1, 10))
    story.append(PageBreak())
    
    # -------------------------------------------------------------------------
    # الفصل الثالث: تصميم واجهات المستخدم وتجربة الاستخدام لكبار السن
    # -------------------------------------------------------------------------
    story.append(p_h1("الفصل الثالث: تصميم واجهات المستخدم وتجربة الاستخدام المخصصة لكبار السن"))
    story.append(HRFlowable(width="100%", thickness=1, color=C_PRIMARY, spaceBefore=2, spaceAfter=8))
    
    story.append(p_h2("3.1 مبادئ التصميم الإدراكي والمريح لكبار السن (Geriatric Ergonomics)"))
    story.append(p_body(
        "قمنا بدراسة التحديات الفسيولوجية والبصرية التي يواجهها كبار السن، وعلى ضوئها قمنا بصياغة واجهات التطبيق وفق معايير هندسية صارمة:"
    ))
    story.append(p_bullet("أهداف لمس واسعة ومحمية: ضبط كافة الأزرار وعناصر التفاعل لتكون بارتفاع 48 بكسل فما فوق (Touch Targets) لضمان سهولة الضغط بالأصابع المرتعشة أو الأيدي غير الدقيقة، وتفادي الضغط العرضي على العناصر المجاورة."))
    story.append(p_bullet("طباعة واضحة وخطوط مقروءة: اعتماد خطوط عربية رصينة بحجم أساسي 18 بكسل فما فوق (Body Text) مع تباين ألوان عالي ومريح للعين لتسهيل القراءة لضعاف النظر."))
    story.append(p_bullet("عدم الاعتماد على الألوان المنفردة: قمنا بربط كل حالة طبية أو دلالة وظيفية بثلاثي مركب (اللون البصري + الأيقونة الرمزية التعبيرية + النص الصريح المكتوب)؛ فمثلاً لا نكتفي باللون الأخضر للجرعة، بل نرفقه بأيقونة الصح وعلامة تم الأخذ ونوع الجرعة."))
    story.append(p_bullet("دعـم كامل للاتجاه العربي (Full RTL Safety): تصميم وتوزيع عناصر الشاشات بأسلوب اتجاهي سليم مع توفير دعم ثنائي كامل للغتين العربية والإنجليزية بتبديل فوري."))
    
    story.append(p_h2("3.2 هندسة التنقل الذكي حسب الدور (Role-Aware Navigation Architecture)"))
    story.append(p_body(
        "قمنا ببناء هيكل شاشات مزدوج يتكيف تلقائياً مع طبيعة المستخدم واحتياجاته فور تسجيل الدخول:"
    ))
    
    role_table_data = [
        ["وجه المقارنة", "واجهة المريض (Patient Experience)", "واجهة المرافق (Caregiver Experience)"],
        ["الفلسفة والهدف", "البساطة المطلقة، التركيز على أفعال اليوم، وتجنب أي تعقيد أو تشتيت.", "الرقابة الشاملة، متابعة مؤشرات الالتزام، والتدخل السريع عند الطوارئ."],
        ["الشاشة الرئيسية", "بطاقات جرعات اليوم مرتبة زمنياً مع أزرار الإجراءات السريعة والكبيرة.", "لوحة متابعة تعرض كروت المرضى المرتبطين، ونسب الالتزام، وشارات التنبيه."],
        ["الخصائص البارزة", "زر الاستغاثة SOS، إدخال القياسات بالصوت، ومسح الروشتة بالكاميرا.", "تصفح أدوية المريض عن بعد، سجل التنبيهات، ومراجعة سجلات الالتزام."],
        ["أسلوب التفاعل", "خطوات مباشرة (نقرة واحدة لتأكيد الدواء، ضغط مطول لطلب النجدة).", "إمكانية التبديل بين عدة مرضى، استعراض التحليلات، وإعادة طلب الأدوية."]
    ]
    story.append(make_table(role_table_data[0], role_table_data[1:], col_widths=[110, 205, 208]))
    story.append(Spacer(1, 10))
    
    # -------------------------------------------------------------------------
    # الفصل الرابع: نظام المصادقة وإدارة الحسابات والهوية
    # -------------------------------------------------------------------------
    story.append(p_h1("الفصل الرابع: نظام المصادقة وإدارة الحسابات والهوية الرقمية"))
    story.append(HRFlowable(width="100%", thickness=1, color=C_PRIMARY, spaceBefore=2, spaceAfter=8))
    
    story.append(p_h2("4.1 بنية المصادقة السحابية الآمنة (Supabase Auth Integration)"))
    story.append(p_body(
        "قمنا بتطوير نظام مصادقة عصري يعتمد على البريد الإلكتروني وكلمة المرور المشفرة عبر سحابة Supabase Auth. قمنا بالتخلص تماماً من الاعتماد على الرسائل النصية القصيرة (SMS OTP) نظراً لارتفاع تكاليفها ومشاكل تأخر وصول الرسائل في المناطق السكنية، واستبدلناها بآلية دخول رقمية فورية وموثوقة."
    ))
    story.append(p_body(
        "في هذا النظام، يتولى التطبيق حفظ رموز الجلسة بشكل آمن، بينما يقوم الخادم الخلفي (FastAPI) بالتحقق المستمر من صحة وصلاحية رمز الوصول (Access Token) في كل طلب برمجي وارد، وربط الرمز بملف المستخدم الشخصي في قاعدة البيانات."
    ))
    
    story.append(p_h2("4.2 اعتراض وتجديد الجلسات التلقائي (Session Hardening & Refresh Interceptor)"))
    story.append(p_body(
        "لضمان عدم انقطاع تجربة استخدام المريض، قمنا ببناء معترض شبكي ذكي (HTTP Client Interceptor) يقوم بما يلي:"
    ))
    story.append(p_bullet("رصد انتهاء صلاحية الجلسة تلقائياً عند مواجهة خطأ غير مصرح (401 Unauthorized)."))
    story.append(p_bullet("إرسال طلب تجديد الجلسة خلف الكواليس باستخدام رمز التحديث (Refresh Token) دون إزعاج المستخدم."))
    story.append(p_bullet("إعادة تنفيذ الطلب الأصلي بنجاح فور تجديد الرمز، أو تسجيل الخروج بأمان ونقل المستخدم لشاشة الدخول في حال فشل التجديد."))
    
    story.append(p_h2("4.3 إدارة الملف الشخصي والتفضيلات (Profile & Localization)"))
    story.append(p_body(
        "قمنا بتوفير شاشة للملف الشخصي تتيح للمستخدم ضبط الاسم الكامل، وتعديل لغة التطبيق بين العربية والإنجليزية مع تحديث فوري لكافة عناصر الواجهة، وضبط المنطقة الزمنية لضمان دقة توقيتات التنبيهات المجدولة."
    ))
    
    story.append(Spacer(1, 10))
    story.append(PageBreak())
    
    # -------------------------------------------------------------------------
    # الفصل الخامس: منظومة إدارة وجدولة الأدوية والتنبيهات الصارمة
    # -------------------------------------------------------------------------
    story.append(p_h1("الفصل الخامس: منظومة إدارة وجدولة الأدوية والتنبيهات الصارمة"))
    story.append(HRFlowable(width="100%", thickness=1, color=C_PRIMARY, spaceBefore=2, spaceAfter=8))
    
    story.append(p_h2("5.1 شاشة جرعات اليوم وإجراءات الاستجابة الفورية (Today Screen)"))
    story.append(p_body(
        "تُمثل شاشة 'جرعات اليوم' المحور الأساسي الذي يتعامل معه المريض عند فتح التطبيق. قمنا بتصميم هذه الشاشة لتعرض الجرعات الدوائية على شكل بطاقات عملاقة مرتبة حسب الوقت الزمني لاستحقاقها، متضمنةً اسم الدواء التجاري، التركيز، وقت الجرعة، والإرشادات الطبية (مثال: 'قرص واحد بعد الإفطار')."
    ))
    story.append(p_body(
        "زودنا كل بطاقة بأزرار استجابة مباشرة وفائقة الوضوح:"
    ))
    story.append(p_bullet("زر 'أخذته' (Taken): يؤكد تناول الجرعة فوراً، ويحول حالة البطاقة للون الأخضر مع علامة الإنجاز، ويقوم تلقائياً بخصم كمية الجرعة من المخزون المركزي، وإلغاء أي تذكيرات معلقة لهذا الموعد."))
    story.append(p_bullet("زر 'بعدين / غفوة' (Snooze): يتيح للمريض تأجيل الجرعة لمدة 10 دقائق إذا لم يكن مستعداً (مثلاً لم ينتهِ من تناول طعامه بعد)، ويعيد جدولة المنبه لتذكيره لاحقاً."))
    story.append(p_bullet("زر 'تخطي' (Skip): يتيح تسجيل عدم تناول الجرعة مع توثيق السبب، لمنع احتسابها كجرعة مهملة في إحصاءات الطبيب."))
    
    story.append(p_h2("5.2 محرك التنبيهات الصارم على مستوى نظام التشغيل (Strict Local Alarm Engine)"))
    story.append(p_body(
        "أحد أبرز إنجازاتنا الهندسية في المشروع هو تصميم نظام تنبيه صارم لا يتأثر بإغلاق التطبيق أو انقطاع الإنترنت أو حتى تشغيل وضع توفير الطاقة في الهواتف الذكية. يرتكز هذا المحرك على الخصائص التالية:"
    ))
    story.append(p_bullet("التنبيه بملء الشاشة (Full-Screen Intent): عند حلول موعد الدواء، يظهر إشعار تفاعلي ضخم فوق شاشة القفل مباشرة حتى لو كان الهاتف مقفلاً، مصحوباً بنغمة تصاعدية لضمان إيقاظ أو لفت انتباه المريض."))
    story.append(p_bullet("بروتوكول التكرار التلقائي (Periodic Repeat): إذا لم يستجب المريض للمنبه، يقوم النظام تلقائياً بتكرار التنبيه كل 5 دقائق لثلاث مرات متتالية لمنع نسيان الدواء."))
    story.append(p_bullet("المزامنة الذكية للإلغاء والجدولة: قمنا بربط خدمة التنبيهات المحلية بمزود البيانات الرئيسي؛ فعند تسجيل تناول الدواء يدوياً داخل التطبيق، تُلغى تذكيرات ذلك الموعد من نظام التشغيل فوراً لمنع إزعاج المريض لاحقاً."))
    story.append(p_bullet("التعافي بعد إعادة تشغيل الهاتف (Boot Recovery): قمنا ببرمجة مستقبل لنظام التشغيل يعيد قراءة كافة الجداول الدوائية من قاعدة البيانات المحلية وإعادة ضبط التنبيهات فور إعادة تشغيل الجهاز."))
    
    story.append(p_h2("5.3 إدارة الأدوية والجدولة الزمنية المرنة (Medication & Schedule Editor)"))
    story.append(p_body(
        "قمنا ببناء منظومة متكاملة تتيح للمريض أو مرافقه إدارة الأدوية بكل سلاسة:"
    ))
    story.append(p_bullet("استعراض قائمة الأدوية النشطة مع تفاصيل الشكل الدوائي (أقراص، كبسولات، شراب، حقن)."))
    story.append(p_bullet("إمكانية حذف أو تعطيل أي دواء مع رسالة تأكيد تحذيرية لتفادي الحذف الخاطئ."))
    story.append(p_bullet("محرر الجداول الدوائية الذي يتيح إضافة مواعيد متعددة للدواء الواحد خلال اليوم، وتخصيص أيام محددة في الأسبوع (مثال: أدوية تؤخذ كل يومين أو في أيام محددة)."))
    
    story.append(Spacer(1, 10))
    story.append(PageBreak())
    
    # -------------------------------------------------------------------------
    # الفصل السادس: منظومة مراقبة المرافقين ومحرك التصعيد الذكي
    # -------------------------------------------------------------------------
    story.append(p_h1("الفصل السادس: منظومة مراقبة المرافقين ومحرك التصعيد الذكي للجرعات الفائتة"))
    story.append(HRFlowable(width="100%", thickness=1, color=C_PRIMARY, spaceBefore=2, spaceAfter=8))
    
    story.append(p_h2("6.1 بروتوكول الاقتران السريع والآمن (Secure Pairing Flow)"))
    story.append(p_body(
        "لتسهيل ربط حساب المريض بحساب المرافق دون الحاجة لكتابة بريد إلكتروني طويل أو كلمات مرور معقدة، قمنا بابتكار آلية اقتران رقمية مبتكرة:"
    ))
    story.append(p_bullet("يقوم المريض بفتح شاشة طلب الاقتران، فيقوم الخادم بتوليد رمز سري مؤقت مكون من 6 أرقام كبيرة وواضحة (صالح لمدة 10 دقائق فقط لضمان الأمان)."))
    story.append(p_bullet("يقوم المرافق بفتح تطبيق هاتفه وإدخال الأرقام الستة، فيتم إتمام الربط وتوثيق العلاقة فوراً في قاعدة البيانات المركزية."))
    story.append(p_bullet("تظهر بيانات المريض مباشرة في لوحة تحكم المرافق مع إشعار فوري للطرفين."))
    
    story.append(p_h2("6.2 لوحة تحكم ومتابعة المرافقين (Caregiver Dashboard)"))
    story.append(p_body(
        "قمنا بتطوير شاشة مخصصة للمرافق تتيح له إدارة ومتابعة رعاية المرضى المرتبطين به:"
    ))
    story.append(p_bullet("بطاقة لكل مريض تعرض اسمه، وحالته الصحية العامة، ومؤشر نسبة الالتزام بجرعات اليوم (مثال: تم تناول 3 من أصل 4 جرعات)."))
    story.append(p_bullet("إمكانية النقر على أي مريض للانتقال إلى شاشة جرعاته التفصيلية في وضع القراءة، للاطلاع على مواعيد اليوم والجرعات المتبقية."))
    story.append(p_bullet("شارة تنبيهات تفاعلية بارزة توضح وجود أي إشعارات طارئة أو جرعات متأخرة تتطلب تدخلاً."))
    
    story.append(p_h2("6.3 محرك التصعيد الذكي للجرعات الفائتة (Missed-Dose Escalation Engine)"))
    story.append(p_body(
        "يُمثل محرك التصعيد القلب النابض لمنظومة الأمان في Medliva؛ حيث يضمن عدم ترك أي جرعة منسية دون متابعة. قمنا ببرمجة خوارزمية السلّم التصعيدي كالتالي:"
    ))
    
    escalation_table = [
        ["المرحلة الزمنية", "الإجراء المتخذ من النظام", "الهدف والنتيجة"],
        ["عند الموعد (دقيقة 0)", "انطلاق التنبيه الصارم بملء الشاشة على هاتف المريض مع تشغيل الصوت.", "تنبيه المريض في التوقيت الطبي المحدد لتناول الدواء."],
        ["بعد 5 دقائق", "إعادة تكرار المنبه المحلي تلقائياً في حال عدم الاستجابة.", "تذكير وقائي للمريض إذا كان بعيداً عن هاتفه."],
        ["بعد 15 دقيقة", "احتساب الجرعة فائتة آلياً لدى الخادم وإصدار تنبيه عاجل للمرافقين.", "إخطار المرافق فوراً بوجود جرعة منسية للتدخل السريع والاتصال بالمريض."],
        ["استجابة المرافق", "ظهور زر اتصال مباشر بالمريض داخل تنبيه المرافق للاطمئنان عليه هاتفياً.", "سد فجوة النسيان وضمان استدراك الجرعة قبل فوات الأوان."]
    ]
    story.append(make_table(escalation_table[0], escalation_table[1:], col_widths=[95, 230, 198]))
    story.append(Spacer(1, 10))
    
    # -------------------------------------------------------------------------
    # الفصل السابع: متابعة القياسات الحيوية والفرز الطبي الصوتي
    # -------------------------------------------------------------------------
    story.append(p_h1("الفصل السابع: متابعة القياسات الحيوية والفرز الطبي الصوتي بالذكاء الاصطناعي"))
    story.append(HRFlowable(width="100%", thickness=1, color=C_PRIMARY, spaceBefore=2, spaceAfter=8))
    
    story.append(p_h2("7.1 تسجيل القياسات الحيوية (Vitals Logging & Monitoring)"))
    story.append(p_body(
        "قمنا بتطوير منظومة رصد ومتابعة شاملة للمؤشرات الحيوية الأكثر ارتباطاً بصحة كبار السن ومرضى الأمراض المزمنة، وتشمل:"
    ))
    story.append(p_bullet("ضغط الدم (Blood Pressure): تسجيل القراءة الانقباضية والقراءة الانبساطية ومعدل النبض المصاحب."))
    story.append(p_bullet("سكر الدم (Blood Glucose): تسجيل تركيز السكر مع تحديد الحالة (صائم، عشوائي، بعد الأكل بساعتين)."))
    story.append(p_bullet("الوزن ومؤشر كتلة الجسم لرصد احتباس السوائل لدى مرضى القلب والقصور الكلوي."))
    
    story.append(p_h2("7.2 الإدخال الصوتي بالذكاء الاصطناعي واللهجة العربية (Voice Vitals Entry)"))
    story.append(p_body(
        "نظراً لصعوبة كتابة الأرقام الإنجليزية أو استخدام لوحات المفاتيح الصغيرة من قِبل كبار السن، قمنا بابتكار ميزة الإدخال الصوتي الذكي:"
    ))
    story.append(p_bullet("يوفر التطبيق زر ميكروفون أحمر كبير ينقر عليه المريض ويتحدث بتلقائية تامة."))
    story.append(p_bullet("يدعم النظام اللهجة العربية والمصرية الدارجة، مثل عبارات: 'الضغط النهارده 135 على 85' أو 'سكر الصائم 110'."))
    story.append(p_bullet("يقوم الخادم عبر تقنيات التعرف الصوتي (STT) وخوارزميات معالجة اللغة الطبيعية (NLP) بتحليل الجملة واستخلاص نوع القياس والقيم الرقمية بدقة."))
    story.append(p_bullet("تُعرض بطاقة تأكيد مرئية للمريض بالقيم المستخلصة للتأكد منها وتعديلها بنقرة واحدة قبل اعتماد الحفظ النهائي."))
    
    story.append(p_h2("7.3 محرك الفرز الطبي التلقائي (Automated Medical Triage System)"))
    story.append(p_body(
        "قمنا ببرمجة محرك فرز طبي فوري مدمج في الواجهة الخلفية يصنف كل قراءة حيوية مسجلة وفق البروتوكولات الإكلينيكية المعتمدة إلى ثلاث فئات واضحة:"
    ))
    
    triage_table = [
        ["المستوى الطبي", "معيار ضغط الدم (ملم زئبق)", "معيار السكر الصائم (مجم/ديسيلتر)", "الإجراء والتأثير في التطبيق"],
        ["طبيعي (Normal)", "أقل من 120/80", "بين 70 و 110", "عرض بطاقة خضراء مطمئنة مع أيقونة السلامة وتحديث سجل المتابعة."],
        ["حدّي (Borderline)", "انقباضي 130-139 أو انبساطي 80-89", "بين 111 و 140", "عرض بطاقة صفراء تحذيرية مع نصائح لشرب الماء وتقليل الملح والمتابعة."],
        ["حرج (Critical)", "انقباضي 180 فما فوق أو انبساطي 110 فما فوق أو انقباضي 90 فأقل", "أقل من 70 أو أعلى من 250", "إطلاق إنذار طارئ أحمر فوري للمريض والمرافق وإرسال تنبيه عاجل للتدخل."]
    ]
    story.append(make_table(triage_table[0], triage_table[1:], col_widths=[95, 140, 135, 153]))
    story.append(Spacer(1, 6))
    
    story.append(p_h2("7.4 شاشة تحليل الاتجاهات الصحية (Vitals Trends Screen)"))
    story.append(p_body(
        "قمنا بتطوير شاشة تحليل بياني واستعراض لمنحنيات ضغط الدم وسكر الدم عبر فترات زمنية (7 أيام و30 يوماً). تمكن هذه الشاشة المريض والمرافق والطبيب من ملاحظة مدى استقرار الحالة الصحية، والتعرف على الأنماط المتكررة (مثل الارتفاع الصباحي للضغط) لدعم القرار الطبي."
    ))
    
    story.append(Spacer(1, 10))
    story.append(PageBreak())
    
    # -------------------------------------------------------------------------
    # الفصل الثامن: مسح وتحليل الروشتات الطبية بالرؤية الحاسوبية
    # -------------------------------------------------------------------------
    story.append(p_h1("الفصل الثامن: مسح وتحليل الروشتات الطبية بالرؤية الحاسوبية وقاعدة الأدوية"))
    story.append(HRFlowable(width="100%", thickness=1, color=C_PRIMARY, spaceBefore=2, spaceAfter=8))
    
    story.append(p_h2("8.1 التقاط ومعالجة صور الروشتات الطبية (Prescription Capture)"))
    story.append(p_body(
        "تُمثل الروشتات المكتوبة بخط اليد عقبة كبرى أمام المرضى وأسرهم. قمنا بتطوير ميزة فحص متطورة تتيح للمستخدم تصوير الروشتة الورقية عبر كاميرا الهاتف مباشرة أو اختيار صورة مسبقة من معرض الصور، مع تحسين تباين الصورة وضغطها تمهيداً لمعالجتها برمجياً."
    ))
    
    story.append(p_h2("8.2 استخراج بيانات الوصفة بالذكاء الاصطناعي البصري (Gemini Vision OCR)"))
    story.append(p_body(
        "قمنا بدمج نماذج الرؤية الحاسوبية المتقدمة (Gemini 2.5 Flash Vision) لتحليل النصوص الطبية المعقدة واستخراج مكونات الروشتة في هيئة بيانات مهيكلة تشمل: الاسم التجاري للدواء، التركيز الطبي، معدل التكرار، والجرعة المقررة وعلاقتها بمواعيد الطعام."
    ))
    
    story.append(p_h2("8.3 خوارزمية المطابقة التقريبية ومنع الاختلاق (Drug Catalog Fuzzy Matching)"))
    story.append(p_body(
        "أهم التحديات في استخدام الذكاء الاصطناعي في المجال الطبي هو خطر 'اختلاق أسماء أدوية غير حقيقية' (AI Hallucinations) أو القراءة الخاطئة لخط الطبيب الرديء. لحل هذه المشكلة جذرياً، قمنا بما يلي:"
    ))
    story.append(p_bullet("بناء قاعدة بيانات محلية لدليل الأدوية (Drug Catalog) تضم الأسماء التجارية المعتمدة وبدائلها الأكثر شيوعاً في السوق المصري والعربي."))
    story.append(p_bullet("تطبيق خوارزمية مطابقة تقريبية ذكية (Fuzzy String Matching): بعد استخراج النص من الصورة، لا يعتمد النظام النص كما هو، بل يقارنه بدليل الأدوية ويصحح التهجئة تلقائياً لأقرب دواء رسمي معتمد."))
    story.append(p_bullet("منع اختلاق الأدوية: إذا لم يجد النظام تطابقاً معتمداً بنسبة ثقة كافية، يُصنف الدواء كغير مؤكد ويطلب مراجعة المستخدم، رافضاً إضافة أي اسم دواء غير موثوق."))
    
    story.append(p_h2("8.4 شاشة المراجعة والاعتماد البشري (Interactive Confirmation Screen)"))
    story.append(p_body(
        "تطبيقاً للمعيار الطبي الأخلاقي 'العنصر البشري في حلقة اتخاذ القرار' (Human-in-the-Loop)، قمنا ببرمجة شاشة مراجعة تعرض كافة الأدوية المستخرجة في كروت منظمة تتيح للمريض تعديل أي قيمة أو حذف دواء غير مرغوب فيه. وفور الضغط على زر الاعتماد، يقوم النظام تلقائياً بإنشاء الأدوية وجدولة مواعيدها في جدول 'جرعات اليوم' وإضافتها للمخزون دون الحاجة لأي كتابة يدوية."
    ))
    
    story.append(Spacer(1, 10))
    story.append(PageBreak())
    
    # -------------------------------------------------------------------------
    # الفصل التاسع: الإدارة الذكية للمخزون وإعادة التعبئة
    # -------------------------------------------------------------------------
    story.append(p_h1("الفصل التاسع: الإدارة الذكية للمخزون وإعادة التعبئة عبر الصيدليات"))
    story.append(HRFlowable(width="100%", thickness=1, color=C_PRIMARY, spaceBefore=2, spaceAfter=8))
    
    story.append(p_h2("9.1 تتبع المخزون والخصم التلقائي التناقصي (Automatic Inventory Deduction)"))
    story.append(p_body(
        "قمنا ببناء نظام فرعي متكامل لإدارة مخزون الأدوية في منزل المريض. يتميز النظام بالربط المباشر مع سجلات التناول؛ فعند قيام المريض بالضغط على زر 'أخذته' في شاشة الجرعات، يقوم الخادم تلقائياً بخصم كمية الجرعة من رصيد الحبات المتبقية لذلك الدواء فورياً وتحديث رصيد المخزون."
    ))
    
    story.append(p_h2("9.2 خوارزمية التنبؤ بموعد النفاد (Stockout Forecasting Algorithm)"))
    story.append(p_body(
        "قمنا بتطوير معادلة رياضية ذكية تحسب الأيام المتبقية حتى نفاد كل صنف دوائي بدقة:"
    ))
    story.append(p_bullet("الأيام المتبقية = الكمية المتبقية الحالية ÷ إجمالي عدد الجرعات اليومية المقررة."))
    story.append(p_bullet("إنذار انخفاض المخزون المبكر: عندما يقل الرصيد المتوقع عن 7 أيام، تظهر شارة تحذيرية صفراء، ويصدر تنبيه استباقي للمرافق لتجهيز شراء العبوة الجديدة قبل انقطاع الدواء المفاجئ."))
    story.append(p_bullet("إنذار الصلاحية: تنبيه وقائي قبل انتهاء تاريخ صلاحية الدواء بـ 30 يوماً لحماية المريض من تناول أدوية فاسدة."))
    
    story.append(p_h2("9.3 إعادة الطلب الآلي عبر واتساب (WhatsApp Pharmacy Refill Automation)"))
    story.append(p_body(
        "لإغلاق دائرة التوريد الدوائي بكل سهولة، قمنا بابتكار زر 'إعادة طلب الدواء' داخل التطبيق، والذي يقوم بما يلي:"
    ))
    story.append(p_bullet("توليد نص رسالة رسمي ومنسق تلقائياً يتضمن اسم المريض، أسماء الأدوية المطلوبة، التركيزات، وعدد العلب المقترحة."))
    story.append(p_bullet("فتح محادثة واتساب مشفرة مباشرة بنقرة واحدة عبر الرابط الرسمي (wa.me) مع رقم صيدلية المريض المعتمدة لتوصيل الأدوية للمنزل فوراً دون عناء كتابة الطلب."))
    
    story.append(Spacer(1, 10))
    # -------------------------------------------------------------------------
    # الفصل العاشر: منظومة الاستغاثة والطوارئ والتتبع الجغرافي
    # -------------------------------------------------------------------------
    story.append(p_h1("الفصل العاشر: منظومة الاستغاثة والطوارئ المتقدمة والتتبع الجغرافي"))
    story.append(HRFlowable(width="100%", thickness=1, color=C_PRIMARY, spaceBefore=2, spaceAfter=8))
    
    story.append(p_h2("10.1 شبكة جهات اتصال الطوارئ (Emergency Contacts Directory)"))
    story.append(p_body(
        "قمنا بإنشاء سجل مخصص لجهات الاتصال في حالات الطوارئ يضم أرقام هواتف الأبناء، الطبيب المعالج، والإسعاف المحلي، مع توفير أزرار اتصال سريع مباشرة تتيح للمريض طلب النجدة بنقرة واحدة دون الحاجة للبحث في جهات اتصال الهاتف المعقدة."
    ))
    
    story.append(p_h2("10.2 زر الاستغاثة الفوري المحمي (Protected SOS Emergency Button)"))
    story.append(p_body(
        "قمنا بتثبيت زر استغاثة أحمر عاجل (SOS) في موقع ثابت وبارز أسفل واجهة المريض. ولتفادي إطلاق الإنذارات الكاذبة الناتجة عن اللمس غير المقصود، قمنا بهندسة آلية تفعيل محمية:"
    ))
    story.append(p_bullet("تتطلب الاستغاثة ضغطاً مستمراً لمدة ثانيتين كاملتين (Long-Press Duration 2s) أو تأكيداً من خلال نافذة حوارية سريعة وكبيرة."))
    story.append(p_bullet("فور تأكيد الاستغاثة، يقوم التطبيق بتشغيل محرك التحديد الجغرافي (GPS) لالتقاط إحداثيات موقع المريض الحالية بدقة متناهية عبر خدمة Geolocator."))
    story.append(p_bullet("يُرسل نداء الاستغاثة فورياً إلى الخادم مع رابط موقع المريض على خرائط جوجل، ويقوم الخادم بتسجيل إنذار حرج وتوزيعه لحظياً على كافة المرافقين وجهات الاتصال المسجلة لإرسال المساعدة السريعة."))
    
    story.append(Spacer(1, 10))
    story.append(PageBreak())
    
    # -------------------------------------------------------------------------
    # الفصل الحادي عشر: مركز الإشعارات وتقارير زيارة الطبيب
    # -------------------------------------------------------------------------
    story.append(p_h1("الفصل الحادي عشر: مركز الإشعارات الموحد وتقارير زيارة الطبيب الشاملة"))
    story.append(HRFlowable(width="100%", thickness=1, color=C_PRIMARY, spaceBefore=2, spaceAfter=8))
    
    story.append(p_h2("11.1 مركز الإشعارات والتغذية الحية للتنبيهات (Unified Notifications Feed)"))
    story.append(p_body(
        "قمنا بتطوير شاشة موحدة للإشعارات تعتمد على تغذية برمجية حية من مسار تنبيهات الخادم، مصنفةً الأحداث عبر فلاتر ذكية وسلسة:"
    ))
    story.append(p_bullet("فلتر الكل (All): يعرض التاريخ الزمني الكامل للأحداث."))
    story.append(p_bullet("فلتر الأدوية (Medications): إشعارات الجرعات الفائتة، والتذكيرات المتكررة."))
    story.append(p_bullet("فلتر المرافقين (Caregivers): طلبات الاقتران، وإشعارات المتابعة."))
    story.append(p_bullet("فلتر الإنذارات الحرجة (Alerts): نداءات الاستغاثة SOS وقراءات القياسات الحيوية المصنفة كحرجة."))
    
    story.append(p_h2("11.2 منظومة تقرير زيارة الطبيب الذكي (Doctor Consultation Report)"))
    story.append(p_body(
        "من القرارات المعمارية والتصميمية الرائدة التي قمنا باتخاذها وتنفيذها، استبدال بوابة الويب المستقلة للطبيب بميزة 'توليد تقرير الطبيب التفاعلي' مباشرة داخل تطبيق الهاتف الذكي، وذلك لأن الطبيب في عيادته المزدحمة لا يرغب في إنشاء حساب أو تذكر كلمة مرور لتطبيق إضافي، بل يفضل فحص مستند رسمي ومباشر."
    ))
    story.append(p_body(
        "قمنا ببرمجة شاشة متكاملة لتقرير الطبيب تتيح:"
    ))
    story.append(p_bullet("تحديد النطاق الزمني للتقرير بدقة (آخر أسبوع، آخر شهر، آخر 3 أشهر)."))
    story.append(p_bullet("احتساب النسبة المئوية الدقيقة للالتزام الدوائي (Adherence Score %) بناءً على إجمالي الجرعات المتناولة مقارنة بالمقررة."))
    story.append(p_bullet("جدول مفصل بكافة الأدوية النشطة والجرعات، وتوثيق سجل الجرعات الفائتة وأسباب التخطي."))
    story.append(p_bullet("سجل كامل لقياسات ضغط الدم وسكر الدم الحيوية مع وضع علامات نصية واضحة للقيم غير الطبيعية."))
    story.append(p_bullet("توليد ملف PDF احترافي داخل التطبيق مباشرة بخطوط عربية مدمجة وتنسيق طبي رسمي، وإتاحته فورياً للطباعة المباشرة أو المشاركة عبر ورقة المشاركة الرسمية للهاتف (System Share Sheet)."))
    story.append(p_bullet("توليد رابط مشاركة إلكتروني مشفر وآمن (Secure Web Share Link) صالح لفترة زمنية محددة، يتيح للطبيب فتح التقرير من شاشة حاسوبه عبر المتصفح للقراءة فقط."))
    
    story.append(Spacer(1, 10))
    # -------------------------------------------------------------------------
    # الفصل الثاني عشر: بيئة المحاكاة والاختبارات وضمان الجودة
    # -------------------------------------------------------------------------
    story.append(p_h1("الفصل الثاني عشر: بيئة المحاكاة والعرض التجريبي، والاختبارات وضمان الجودة"))
    story.append(HRFlowable(width="100%", thickness=1, color=C_PRIMARY, spaceBefore=2, spaceAfter=8))
    
    story.append(p_h2("12.1 سكربت زراعة بيانات المحاكاة والعرض (Demo Seed Data Engine)"))
    story.append(p_body(
        "لدعم العروض التقديمية الحية ومناقشات لجان التحكيم دون الحاجة لقضاء ساعات في إدخال بيانات يدوية، قمنا بتطوير أداة برمجية متخصصة (seed_demo_data.py) تقوم بزرع بيئة محاكاة سريرية متكاملة وقابلة للتكرار:"
    ))
    story.append(p_bullet("ملء قاعدة البيانات بدليل الأدوية الشائعة متضمناً الأسماء التجارية والجرعات المعتمدة."))
    story.append(p_bullet("إنشاء ملف مريض تجريبي متكامل يحتوي على أدوية متعددة، وجداول أوقات منسقة، وسجلات التزام وتناول دواء على مدار أسبوع كامل، وسلسلة قياسات حيوية واقعية للضغط والسكر (تشمل قراءات طبيعية وحدّية وحرجة) لإظهار كافة قدرات الفرز والتنبيه والتقارير في ثوانٍ معدودة."))
    
    story.append(p_h2("12.2 استراتيجية الاختبارات وضمان الجودة البرمجية (Testing Strategy & QA)"))
    story.append(p_body(
        "قمنا بإخضاع المشروع لمنظومة اختبارات صارمة ومتعددة المستويات لضمان المتانة والأداء والخلو من الأخطاء:"
    ))
    
    qa_table_data = [
        ["نطاق الاختبار", "الأدوات والمنهجية المستخدمة", "نتائج التحقق والإنجاز الفعلي"],
        ["اختبارات الخادم الخلفي (API Tests)", "أطر Pytest و AsyncClient مع فحص التنسيق بـ Ruff.", "اجتياز 100% من الاختبارات التي تغطي مسارات المصادقة، والأدوية، والفرز، والأمان، وتأكيد حظر الوصول 403."],
        ["اختبارات تطبيق الموبايل (Widget & Unit Tests)", "بيئة Flutter Test و Mocktail لمحاكاة الشبكة.", "اجتياز كافة اختبارات الوحدات لطبقات البيانات واختبارات الشاشات التفاعلية (Screens & Routing)."],
        ["تدقيق إمكانية الوصول (Accessibility Audit)", "أداة تدقيق إمكانية الوصول لفحص واجهات كبار السن.", "تحقيق الامتثال التام لمعايير WCAG: أحجام لمس 48dp فما فوق، نصوص 18sp فما فوق، واجتياز الفحص دون أي ملاحظات حرجة."],
        ["التكامل المستمر (CI/CD Pipeline)", "مسارات عمل آلية عبر GitHub Actions (.github/workflows/ci.yml).", "تنفيذ آلي لكافة فحوصات الكود والاختبارات وضمان عدم قبول أي تحديث يخل بالاستقرار البرمجي."]
    ]
    story.append(make_table(qa_table_data[0], qa_table_data[1:], col_widths=[125, 175, 223], padding=4))
    story.append(Spacer(1, 10))
    story.append(PageBreak())
    
    # -------------------------------------------------------------------------
    # الفصل الثالث عشر: مصفوفة المخرجات، الخلاصة، والتطلعات المستقبلية
    # -------------------------------------------------------------------------
    story.append(p_h1("الفصل الثالث عشر: مصفوفة مخرجات المشروع، الخلاصة، والآفاق المستقبلية"))
    story.append(HRFlowable(width="100%", thickness=1, color=C_PRIMARY, spaceBefore=2, spaceAfter=8))
    
    story.append(p_h2("13.1 مصفوفة مطابقة المخرجات المنجزة بالخطة التنفيذية (Delivery Matrix)"))
    story.append(p_body(
        "يوضح الجدول التالي المخرجات الفعلية التي قمنا بتنفيذها والتحقق منها برمجياً مقارنة بما كان مخططاً له في خطة العمل التنفيذية (Execution Plan):"
    ))
    
    matrix_data = [
        ["المكون الوظيفي للمنصة", "ما قمنا بتنفيذه وتحقيقه فعلياً بالكامل", "حالة التحقق والاكتمال"],
        ["بنية المصادقة والأمان", "دخول بالبريد وكلمة المرور عبر Supabase، وتأمين المسارات بفحص وصول المريض الصارم.", "مُنجز ومُختبر 100%"],
        ["واجهة كبار السن المزدوجة", "شاشات مخصصة للمريض وأخرى للمرافق، خطوط كبيرة 18sp فما فوق، أزرار لمس 48dp فما فوق، ودعم عربي كامل.", "مُنجز ومُختبر 100%"],
        ["إدارة وجدولة الأدوية", "شاشة جرعات اليوم، بطاقات تفاعلية كبيرة، أزرار تأكيد/تأجيل، ومحرر مواعيد تفصيلي للأيام والوجبات.", "مُنجز ومُختبر 100%"],
        ["التنبيهات الصارمة وأوفلاين", "منبه محلي بملء الشاشة فوق شاشة القفل، تكرار كل 5 دقائق، وطابور مزامنة بدون إنترنت.", "مُنجز ومُختبر 100%"],
        ["متابعة المرافق والتصعيد", "اقتران بكود 6 أرقام، لوحة تحكم للمرافق، ومحرك تصعيد للجرعات المتأخرة لأكثر من 15 دقيقة.", "مُنجز ومُختبر 100%"],
        ["القياسات الحيوية والفرز", "تسجيل الضغط والسكر، إدخال صوتي باللهجة العربية، فرز طبي (طبيعي/حدي/حرج)، ومنحنيات الاتجاهات.", "مُنجز ومُختبر 100%"],
        ["مسح الروشتة بالذكاء الاصطناعي", "مسح بالكاميرا، تحليل بـ Gemini Vision، ومطابقة تقريبية مع قاعدة الأدوية لمنع الاختلاق.", "مُنجز ومُختبر 100%"],
        ["المخزون وإعادة الطلب", "خصم تلقائي مع الجرعات، تنبؤ بموعد النفاد، إنذار أقل من 7 أيام، ورسالة واتساب جاهزة للصيدلية.", "مُنجز ومُختبر 100%"],
        ["منظومة الطوارئ والاستغاثة", "زر SOS محمي بضغط مطول، تحديد الموقع الجغرافي GPS لحظياً، وإشعار فوري للمرافقين.", "مُنجز ومُختبر 100%"],
        ["مركز الإشعارات والتقارير", "تغذية إشعارات حية، وتوليد تقرير طبي PDF احترافي عربي للمشاركة مع الطبيب وروابط ويب مؤمنة.", "مُنجز ومُختبر 100%"]
    ]
    story.append(make_table(matrix_data[0], matrix_data[1:], col_widths=[125, 280, 118], padding=3.5))
    story.append(Spacer(1, 6))
    
    story.append(p_h2("13.2 الخلاصة والقيمة المضافة للمشروع (Project Impact & Conclusion)"))
    story.append(p_body(
        "يمثل مشروع Medliva نموذجاً تطبيقياً فريداً لتوظيف التقنيات الحديثة والذكاء الاصطناعي في خدمة الإنسانية وتحسين جودة حياة كبار السن ومرضى الأمراض المزمنة. استطعنا عبر هذا العمل المتكامل تحويل عملية تناول الأدوية المعقدة إلى روتين رقمي مبهج وفائق السهولة والأمان، مع توفير راحة بال مطلقة للمرافقين وأفراد الأسرة."
    ))
    story.append(p_body(
        "إن المنصة بوضعها الحالي ليست مجرد نموذج أولي تجريبي، بل نظام متكامل تم بناؤه بأعلى معايير الجودة البرمجية، واجتاز كافة اختبارات الوحدة، والتكامل، وإمكانية الوصول، والأمان الصارم، وهو جاهز تماماً للاستخدام الميداني الفعلي وخدمة المرضى والمجتمع."
    ))
    
    story.append(p_h2("13.3 الآفاق التطويرية المستقبلية (Future Roadmap)"))
    story.append(p_body("نوصي بتطوير التوسعات التالية في الإصدارات المستقبلية لتعزيز قدرات المنصة:"))
    story.append(p_bullet("الربط المباشر مع الأجهزة الطبية المنزلية عبر البلوتوث (Smart Bluetooth BP & Glucose Monitors) لنقل القراءات الحيوية لحظياً دون أي تدخل بشري."))
    story.append(p_bullet("تطوير مساعد محادثة صوتي تفاعلي كامل قائم على الذكاء الاصطناعي التوليدي للإجابة على استفسارات المرضى حول التداخلات الدوائية والأعراض الجانبية الشائعة."))
    story.append(p_bullet("التكامل مع منظومة التأمين الصحي الرقمي والمستشفيات لتسهيل المتابعة السريرية الشاملة وتحديث الروشتات الإلكترونية آلياً."))
    
    story.append(Spacer(1, 6))
    story.append(make_callout(
        "كلمة ختامية:",
        "تم بحمد الله وتوفيقه إنجاز وتوثيق كافة متطلبات مشروع ميدليفا (Medliva) بنجاح واكتمال تام، نسأل الله أن يكون هذا العمل نافعاً للمرضى وركيزة متقدمة في مجال النظم الطبية الذكية.",
        border_color=C_SECONDARY,
        width=523
    ))
    
    doc.build(story, canvasmaker=NumberedCanvas)
    print("PDF build complete:", target_filename, "Size:", os.path.getsize(target_filename))
    return target_filename

if __name__ == "__main__":
    cli_arg = sys.argv[1] if len(sys.argv) > 1 else None
    build_pdf(cli_arg)
