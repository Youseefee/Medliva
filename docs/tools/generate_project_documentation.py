# -*- coding: utf-8 -*-
"""Build the Medliva academic project report as an editable DOCX and PDF.

The report describes the repository snapshot as it exists when this script is run.
It intentionally distinguishes working code from plans and unfinished integrations.
"""

from __future__ import annotations

import html
import math
import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import Iterable

from docx import Document
from docx.enum.section import WD_SECTION
from docx.enum.table import WD_CELL_VERTICAL_ALIGNMENT, WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Inches, Pt, RGBColor
from pypdf import PdfReader
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY, TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import inch
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    BaseDocTemplate,
    Frame,
    KeepTogether,
    PageBreak,
    PageTemplate,
    Paragraph,
    Spacer,
    Table,
    TableStyle,
)


ROOT = Path(__file__).resolve().parents[2]
DOCS = ROOT / "docs"
PDF_PATH = DOCS / "Medliva_Project_Documentation.pdf"
DOCX_PATH = DOCS / "Medliva_Project_Documentation.docx"
TEMP_PDF_PATH = DOCS / ".medliva_documentation_draft.pdf"
SNAPSHOT_DATE = "24 October 2026"
FONT_REGULAR = Path(r"C:\Windows\Fonts\times.ttf")
FONT_BOLD = Path(r"C:\Windows\Fonts\timesbd.ttf")
FONT_ITALIC = Path(r"C:\Windows\Fonts\timesi.ttf")
FONT_BOLD_ITALIC = Path(r"C:\Windows\Fonts\timesbi.ttf")


@dataclass
class PageSpec:
    key: str
    title: str
    paragraphs: list[str] = field(default_factory=list)
    bullets: list[str] = field(default_factory=list)
    table_title: str | None = None
    table_headers: list[str] = field(default_factory=list)
    table_rows: list[list[str]] = field(default_factory=list)
    callout_title: str | None = None
    callout: str | None = None
    figure_title: str | None = None
    figure_steps: list[str] = field(default_factory=list)
    chapter_title: str | None = None
    chapter_key: str | None = None
    chapter_intro: str | None = None
    source: list[str] = field(default_factory=list)
    toc: bool = True


PAGES: list[PageSpec] = []


def add_page(
    key: str,
    title: str,
    *paragraphs: str,
    bullets: Iterable[str] = (),
    table: tuple[str, list[str], list[list[str]]] | None = None,
    callout: tuple[str, str] | None = None,
    figure: tuple[str, list[str]] | None = None,
    chapter: tuple[str, str, str] | None = None,
    source: Iterable[str] = (),
    toc: bool = True,
) -> None:
    spec = PageSpec(
        key=key,
        title=title,
        paragraphs=list(paragraphs),
        bullets=list(bullets),
        source=list(source),
        toc=toc,
    )
    if table:
        spec.table_title, spec.table_headers, spec.table_rows = table
    if callout:
        spec.callout_title, spec.callout = callout
    if figure:
        spec.figure_title, spec.figure_steps = figure
    if chapter:
        spec.chapter_title, spec.chapter_key, spec.chapter_intro = chapter
    PAGES.append(spec)


def register_fonts() -> None:
    if not FONT_REGULAR.exists():
        raise FileNotFoundError(f"Times New Roman was not found at {FONT_REGULAR}")
    pdfmetrics.registerFont(TTFont("TNR", str(FONT_REGULAR)))
    pdfmetrics.registerFont(TTFont("TNR-Bold", str(FONT_BOLD)))
    pdfmetrics.registerFont(TTFont("TNR-Italic", str(FONT_ITALIC)))
    pdfmetrics.registerFont(TTFont("TNR-BoldItalic", str(FONT_BOLD_ITALIC)))
    pdfmetrics.registerFontFamily(
        "TNR", normal="TNR", bold="TNR-Bold", italic="TNR-Italic", boldItalic="TNR-BoldItalic"
    )


STYLES = getSampleStyleSheet()
STYLES.add(
    ParagraphStyle(
        name="BodyTNR", parent=STYLES["BodyText"], fontName="TNR", fontSize=10.8,
        leading=15.3, alignment=TA_JUSTIFY, spaceAfter=8, textColor=colors.HexColor("#181818"),
    )
)
STYLES.add(
    ParagraphStyle(
        name="PageTitleTNR", parent=STYLES["Heading2"], fontName="TNR-Bold", fontSize=15,
        leading=18, spaceBefore=0, spaceAfter=5, textColor=colors.HexColor("#142E43"),
    )
)
STYLES.add(
    ParagraphStyle(
        name="ChapterTNR", parent=STYLES["Heading1"], fontName="TNR-Bold", fontSize=18,
        leading=22, alignment=TA_CENTER, spaceAfter=6, textColor=colors.HexColor("#142E43"),
    )
)
STYLES.add(
    ParagraphStyle(
        name="SubheadTNR", parent=STYLES["Heading3"], fontName="TNR-Bold", fontSize=11.8,
        leading=14, spaceBefore=5, spaceAfter=3, textColor=colors.HexColor("#173F5B"),
    )
)
STYLES.add(
    ParagraphStyle(
        name="SmallTNR", parent=STYLES["BodyText"], fontName="TNR", fontSize=8.4,
        leading=10.5, spaceAfter=3, textColor=colors.HexColor("#404040"),
    )
)
STYLES.add(
    ParagraphStyle(
        name="CaptionTNR", parent=STYLES["BodyText"], fontName="TNR-Italic", fontSize=9,
        leading=11, alignment=TA_CENTER, spaceBefore=4, spaceAfter=7,
    )
)
STYLES.add(
    ParagraphStyle(
        name="CellTNR", parent=STYLES["BodyText"], fontName="TNR", fontSize=8.6,
        leading=10.3, spaceAfter=0, alignment=TA_LEFT,
    )
)
STYLES.add(
    ParagraphStyle(
        name="CellHeadTNR", parent=STYLES["BodyText"], fontName="TNR-Bold", fontSize=8.6,
        leading=10.4, spaceAfter=0, alignment=TA_LEFT, textColor=colors.white,
    )
)
STYLES.add(
    ParagraphStyle(
        name="TOCTNR", parent=STYLES["BodyText"], fontName="TNR", fontSize=9.4,
        leading=12, spaceAfter=2,
    )
)
STYLES.add(
    ParagraphStyle(
        name="CoverTitleTNR", parent=STYLES["Title"], fontName="TNR-Bold", fontSize=28,
        leading=34, alignment=TA_CENTER, textColor=colors.HexColor("#142E43"),
    )
)


def _para(text: str, style: str = "BodyTNR") -> Paragraph:
    return Paragraph(html.escape(text).replace("\n", "<br/>"), STYLES[style])


class TaggedParagraph(Paragraph):
    def __init__(self, text: str, style: ParagraphStyle, key: str, level: int, label: str):
        super().__init__(text, style)
        self.tag_key = key
        self.tag_level = level
        self.tag_label = label


class MedlivaDocTemplate(BaseDocTemplate):
    def __init__(self, filename: str, **kwargs):
        super().__init__(filename, **kwargs)
        self.page_map: dict[str, int] = {}
        self.chapter_start_page: int | None = None
        frame = Frame(
            self.leftMargin,
            self.bottomMargin,
            self.width,
            self.height,
            id="body",
            leftPadding=0,
            rightPadding=0,
            topPadding=0,
            bottomPadding=0,
        )
        self.addPageTemplates(
            [PageTemplate(id="main", frames=[frame], onPage=draw_page_chrome)]
        )

    def afterFlowable(self, flowable):
        if isinstance(flowable, TaggedParagraph):
            self.page_map[flowable.tag_key] = self.page
            if flowable.tag_key == "chapter_1":
                self.chapter_start_page = self.page
            if flowable.tag_level <= 1:
                self.canv.bookmarkPage(flowable.tag_key)
                self.canv.addOutlineEntry(
                    flowable.tag_label,
                    flowable.tag_key,
                    level=flowable.tag_level,
                    closed=False,
                )


def roman(number: int) -> str:
    pairs = [(1000, "m"), (900, "cm"), (500, "d"), (400, "cd"), (100, "c"),
             (90, "xc"), (50, "l"), (40, "xl"), (10, "x"), (9, "ix"),
             (5, "v"), (4, "iv"), (1, "i")]
    result = ""
    for value, symbol in pairs:
        count, number = divmod(number, value)
        result += symbol * count
    return result


def display_page(physical: int, chapter_start: int) -> str:
    if physical == 1:
        return ""
    if physical < chapter_start:
        return roman(physical - 1)
    return str(physical - chapter_start + 1)


def draw_page_chrome(canvas, doc) -> None:
    page = doc.page
    canvas.saveState()
    if page > 1:
        canvas.setStrokeColor(colors.HexColor("#B8C4CC"))
        canvas.setLineWidth(0.45)
        canvas.line(doc.leftMargin, A4[1] - 0.55 * inch, A4[0] - doc.rightMargin, A4[1] - 0.55 * inch)
        canvas.setFont("TNR", 8)
        canvas.setFillColor(colors.HexColor("#4B5963"))
        canvas.drawString(doc.leftMargin, A4[1] - 0.43 * inch, "Medliva | Comprehensive Project Documentation")
        canvas.drawRightString(A4[0] - doc.rightMargin, A4[1] - 0.43 * inch, SNAPSHOT_DATE)
        canvas.line(doc.leftMargin, 0.52 * inch, A4[0] - doc.rightMargin, 0.52 * inch)
        canvas.setFont("TNR", 8.5)
        canvas.drawRightString(
            A4[0] - doc.rightMargin,
            0.34 * inch,
            display_page(page, doc.chapter_start_page or 1),
        )
    canvas.restoreState()


def flow_diagram(title: str, steps: list[str], width: float) -> list:
    box_style = ParagraphStyle(
        "DiagramBox", parent=STYLES["CellTNR"], fontName="TNR-Bold", fontSize=8.1,
        leading=9.5, alignment=TA_CENTER, textColor=colors.HexColor("#173F5B"),
    )
    arrow_style = ParagraphStyle(
        "DiagramArrow", parent=STYLES["CellTNR"], fontName="TNR-Bold", fontSize=12,
        leading=14, alignment=TA_CENTER, textColor=colors.HexColor("#58707F"),
    )
    n = len(steps)
    arrow_w = 18
    box_w = max(78, (width - (n - 1) * arrow_w) / n)
    row = []
    widths = []
    for i, step in enumerate(steps):
        row.append(Paragraph(html.escape(step), box_style))
        widths.append(box_w)
        if i < n - 1:
            row.append(Paragraph("&#8594;", arrow_style))
            widths.append(arrow_w)
    grid = Table([row], colWidths=widths, hAlign="CENTER")
    grid.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, -1), colors.white),
                ("BOX", (0, 0), (0, 0), 0.8, colors.HexColor("#567080")),
                ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
                ("LEFTPADDING", (0, 0), (-1, -1), 4),
                ("RIGHTPADDING", (0, 0), (-1, -1), 4),
                ("TOPPADDING", (0, 0), (-1, -1), 8),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 8),
            ]
        )
    )
    for i in range(0, len(row), 2):
        grid.setStyle(TableStyle([("BACKGROUND", (i, 0), (i, 0), colors.HexColor("#EEF3F6")),
                                  ("BOX", (i, 0), (i, 0), 0.8, colors.HexColor("#567080"))]))
    return [grid, _para(title, "CaptionTNR")]


def data_table(title: str, headers: list[str], rows: list[list[str]], width: float) -> list:
    story = []
    if title:
        story.append(_para(title, "CaptionTNR"))
    columns = max(1, len(headers))
    col_width = width / columns
    data = [[Paragraph(html.escape(x), STYLES["CellHeadTNR"]) for x in headers]]
    data.extend(
        [[Paragraph(html.escape(str(cell)).replace("\n", "<br/>"), STYLES["CellTNR"]) for cell in row]
         for row in rows]
    )
    tbl = Table(data, colWidths=[col_width] * columns, repeatRows=1, hAlign="LEFT")
    tbl.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#26485F")),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                ("GRID", (0, 0), (-1, -1), 0.45, colors.HexColor("#AAB7C0")),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 5),
                ("RIGHTPADDING", (0, 0), (-1, -1), 5),
                ("TOPPADDING", (0, 0), (-1, -1), 4),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
                *[("BACKGROUND", (0, r), (-1, r), colors.HexColor("#F3F6F8"))
                  for r in range(2, len(data), 2)],
            ]
        )
    )
    story.append(tbl)
    story.append(Spacer(1, 5))
    return story


def tracked_page_heading(spec: PageSpec) -> list:
    story = []
    if spec.chapter_title:
        chapter_label = spec.chapter_title
        story.append(
            TaggedParagraph(
                html.escape(chapter_label), STYLES["ChapterTNR"],
                spec.chapter_key or spec.key + "_chapter", 0, chapter_label,
            )
        )
        if spec.chapter_intro:
            story.append(_para(spec.chapter_intro, "SmallTNR"))
        story.append(Spacer(1, 5))
    title = html.escape(spec.title)
    story.append(
        TaggedParagraph(title, STYLES["PageTitleTNR"], spec.key, 1, spec.title)
    )
    story.append(Paragraph("", STYLES["SmallTNR"]))
    rule = Table([[""]], colWidths=[A4[0] - 1.45 * inch], rowHeights=[1])
    rule.setStyle(TableStyle([("BACKGROUND", (0, 0), (-1, -1), colors.HexColor("#9DADB7")),
                              ("LEFTPADDING", (0, 0), (-1, -1), 0),
                              ("RIGHTPADDING", (0, 0), (-1, -1), 0),
                              ("TOPPADDING", (0, 0), (-1, -1), 0),
                              ("BOTTOMPADDING", (0, 0), (-1, -1), 0)]))
    story.extend([rule, Spacer(1, 7)])
    return story


def spec_story(spec: PageSpec, width: float) -> list:
    story = tracked_page_heading(spec)
    for paragraph in spec.paragraphs:
        story.append(_para(paragraph))
    if spec.figure_steps:
        story.extend(flow_diagram(spec.figure_title or "System flow", spec.figure_steps, width))
    if spec.bullets:
        for item in spec.bullets:
            story.append(Paragraph("&#8226; " + html.escape(item), STYLES["BodyTNR"]))
    if spec.table_rows:
        story.extend(data_table(spec.table_title or "", spec.table_headers, spec.table_rows, width))
    if spec.callout:
        title = html.escape(spec.callout_title or "Project note")
        body = html.escape(spec.callout)
        callout = Table(
            [[Paragraph(f"<b>{title}</b><br/>{body}", STYLES["SmallTNR"])]],
            colWidths=[width],
        )
        callout.setStyle(
            TableStyle(
                [
                    ("BACKGROUND", (0, 0), (-1, -1), colors.HexColor("#F1F5F7")),
                    ("BOX", (0, 0), (-1, -1), 0.8, colors.HexColor("#7A919F")),
                    ("LEFTPADDING", (0, 0), (-1, -1), 8),
                    ("RIGHTPADDING", (0, 0), (-1, -1), 8),
                    ("TOPPADDING", (0, 0), (-1, -1), 6),
                    ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
                ]
            )
        )
        story.extend([Spacer(1, 4), callout])
    return story


def toc_entries() -> list[tuple[str, str]]:
    entries: list[tuple[str, str]] = []
    for spec in PAGES:
        if spec.chapter_title and spec.chapter_key:
            entries.append((spec.chapter_title, spec.chapter_key))
        if spec.toc:
            entries.append((spec.title, spec.key))
    return entries


def make_index_story(
    heading: str,
    rows: list[tuple[str, str]],
    page_map: dict[str, int],
    chapter_start: int,
    per_page: int,
    width: float,
    link_entries: bool = False,
) -> list:
    story: list = []
    chunks = [rows[i : i + per_page] for i in range(0, len(rows), per_page)] or [[]]
    for part, chunk in enumerate(chunks):
        if part:
            story.append(PageBreak())
        story.append(_para(heading if part == 0 else heading + " (continued)", "PageTitleTNR"))
        story.append(Spacer(1, 7))
        grid = []
        for title, key in chunk:
            physical = page_map.get(key)
            number = display_page(physical, chapter_start) if physical and chapter_start else ""
            if link_entries:
                title_para = Paragraph(
                    f'<link href="#{html.escape(key)}" color="#173F5B">{html.escape(title)}</link>',
                    STYLES["TOCTNR"],
                )
            else:
                title_para = Paragraph(html.escape(title), STYLES["TOCTNR"])
            grid.append([title_para, Paragraph(number, STYLES["TOCTNR"])])
        table = Table(grid, colWidths=[width - 35, 35], hAlign="LEFT")
        table.setStyle(
            TableStyle(
                [
                    ("VALIGN", (0, 0), (-1, -1), "TOP"),
                    ("LINEBELOW", (0, 0), (-1, -1), 0.25, colors.HexColor("#D6DEE3")),
                    ("ALIGN", (1, 0), (1, -1), "RIGHT"),
                    ("LEFTPADDING", (0, 0), (-1, -1), 2),
                    ("RIGHTPADDING", (0, 0), (-1, -1), 2),
                    ("TOPPADDING", (0, 0), (-1, -1), 2),
                    ("BOTTOMPADDING", (0, 0), (-1, -1), 2),
                ]
            )
        )
        story.append(table)
    return story


def build_pdf_story(page_map: dict[str, int] | None = None) -> tuple[list, int]:
    page_map = page_map or {}
    width = A4[0] - 1.45 * inch
    chapter_start = page_map.get("chapter_1", 0)
    story: list = []

    # Cover page.
    story.extend([Spacer(1, 1.05 * inch), _para("Medliva", "PageTitleTNR"), Spacer(1, 0.25 * inch)])
    story.append(_para("An Accessible Medication Management and Family Care Coordination System", "CoverTitleTNR"))
    story.extend([Spacer(1, 0.25 * inch), _para("Comprehensive Project Documentation", "PageTitleTNR")])
    story.append(Spacer(1, 0.55 * inch))
    cover_box = Table(
        [[Paragraph("<b>Project report</b><br/>Flutter mobile application<br/>FastAPI modular backend<br/>Repository snapshot: " + SNAPSHOT_DATE,
                    STYLES["BodyTNR"])]],
        colWidths=[width * 0.72],
        hAlign="CENTER",
    )
    cover_box.setStyle(
        TableStyle(
            [
                ("BOX", (0, 0), (-1, -1), 1.2, colors.HexColor("#26485F")),
                ("BACKGROUND", (0, 0), (-1, -1), colors.HexColor("#F1F5F7")),
                ("LEFTPADDING", (0, 0), (-1, -1), 18),
                ("RIGHTPADDING", (0, 0), (-1, -1), 18),
                ("TOPPADDING", (0, 0), (-1, -1), 18),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 18),
            ]
        )
    )
    story.extend([cover_box, Spacer(1, 1.1 * inch)])
    story.append(_para("Prepared from the implementation, tests, and project documentation available in the repository.", "CaptionTNR"))
    story.append(PageBreak())

    # Acknowledgments and abstract.
    story.extend([_para("Acknowledgments", "ChapterTNR")])
    story.append(_para(
        "The Medliva project team acknowledges the engineering work represented by the current mobile and API codebases, the open-source maintainers whose tools support the project, and the reviewers who shaped the project requirements. This report uses the repository, its tests, and its implementation notes as evidence. It avoids assigning individual authorship or supervision because those details were not supplied with the project files."
    ))
    story.append(_para(
        "The report also distinguishes delivery from intent. A screen, model, route, or helper is described as implemented only when it appears in the current source. External services, clinical validation, and production deployment are not inferred from environment examples or roadmap text."
    ))
    story.append(PageBreak())
    story.append(_para("Abstract", "ChapterTNR"))
    story.append(_para(
        "Medliva is a software project for supporting older adults and their family caregivers with medication schedules, adherence records, vital-sign entry, medicine inventory, emergency contacts, and clinician-facing summaries. The current repository contains a Flutter application with Arabic and English localization, a FastAPI REST API, SQLAlchemy data models, Alembic migrations, and automated API and Flutter tests."
    ))
    story.append(_para(
        "The mobile client includes OTP-based sign-in flows, role-aware patient and caregiver screens, medication management, dose logging, caregiver pairing, manual and speech-assisted vital entry, prescription-image selection and review, inventory forecasts, an SOS interaction, and an in-app PDF report share flow. The API provides matching endpoints for identity, linked patients, medications, adherence, vitals, inventory, emergency contacts, reports, and device registration."
    ))
    story.append(_para(
        "This documentation evaluates the delivered code rather than presenting a target design as finished. Important prototype boundaries remain: the prescription endpoint returns fixed sample medicines and does not inspect the uploaded image; the reminder planner and secure offline queue are not connected to the active dose screen; SOS creates a database alert but does not dispatch a notification; and the report PDF is rendered in English with Arabic text transliterated. The project therefore demonstrates a broad end-to-end feature set while leaving external delivery, clinical validation, and production operational controls for later work."
    ))
    story.append(_para("Keywords: medication adherence, older adults, caregiver coordination, Flutter, FastAPI, accessibility, vital signs, software documentation.", "SmallTNR"))
    story.append(PageBreak())

    # Contents, figures, tables, and abbreviations.
    entries = toc_entries()
    story.extend(make_index_story("Table of Contents", entries, page_map, chapter_start, 28, width, True))
    story.append(PageBreak())
    figure_rows = [(spec.figure_title or "", spec.key) for spec in PAGES if spec.figure_title]
    story.extend(make_index_story("List of Figures", figure_rows, page_map, chapter_start, 24, width))
    story.append(PageBreak())
    table_rows = [(spec.table_title or "", spec.key) for spec in PAGES if spec.table_title]
    story.extend(make_index_story("List of Tables", table_rows, page_map, chapter_start, 25, width))
    story.append(PageBreak())
    story.append(_para("Abbreviations and Acronyms", "ChapterTNR"))
    acronyms = [
        ["API", "Application Programming Interface"], ["AI", "Artificial Intelligence"],
        ["CI", "Continuous Integration"], ["CRUD", "Create, Read, Update, Delete"],
        ["CORS", "Cross-Origin Resource Sharing"], ["Dart", "Programming language used by Flutter"],
        ["DTO", "Data Transfer Object"], ["FCM", "Firebase Cloud Messaging"],
        ["FR", "Functional Requirement"], ["JWT", "JSON Web Token"],
        ["MVP", "Minimum Viable Product"], ["OTP", "One-Time Password"],
        ["PDF", "Portable Document Format"], ["RBAC", "Role-Based Access Control"],
        ["REST", "Representational State Transfer"], ["SRS", "Software Requirements Specification"],
        ["STT", "Speech-to-Text"], ["TLS", "Transport Layer Security"],
        ["UI", "User Interface"], ["UX", "User Experience"], ["WCAG", "Web Content Accessibility Guidelines"],
    ]
    story.extend(data_table("", ["Term", "Meaning in this report"], acronyms, width))
    story.append(PageBreak())

    # Main report and appendices.
    first = True
    for spec in PAGES:
        if not first:
            story.append(PageBreak())
        story.extend(spec_story(spec, width))
        first = False
    return story, chapter_start


def render_pdf(path: Path, page_map: dict[str, int] | None = None) -> MedlivaDocTemplate:
    doc = MedlivaDocTemplate(
        str(path),
        pagesize=A4,
        leftMargin=0.72 * inch,
        rightMargin=0.72 * inch,
        topMargin=0.78 * inch,
        bottomMargin=0.72 * inch,
        title="Medliva Project Documentation",
        author="Medliva Project Team",
        subject="Implementation-grounded project report",
    )
    story, _ = build_pdf_story(page_map)
    doc.build(story)
    return doc


def define_chapters_one_to_three() -> None:
    add_page(
        "chapter_1_1", "1.1 Introduction",
        "Medliva is a mobile-first care coordination project built around a practical daily task: helping an older adult remember and record scheduled medicines while allowing a trusted caregiver to follow the same plan. The project also brings together vital-sign records, prescription review, stock estimates, emergency contacts, and a shareable doctor summary.",
        "The repository contains a Flutter client and a FastAPI service. The client presents the patient and caregiver flows in Arabic and English; the service exposes versioned JSON endpoints and persists application records through SQLAlchemy. This report describes the code present on 24 October 2026 and treats project notes as design history rather than proof of delivery.",
        table=("Table 1.1. The project at a glance", ["Dimension", "Current repository evidence"], [
            ["Primary users", "Older adult patient and linked caregiver"],
            ["Client", "Flutter, Riverpod, GoRouter, Dio"],
            ["Service", "FastAPI, SQLAlchemy async ORM, Alembic"],
            ["Core record types", "Users, medications, schedules, adherence logs, vitals, alerts"],
        ]),
        chapter=("Chapter 1 - Introduction", "chapter_1", "This chapter sets the project context, defines its problem and objectives, and states the implementation boundaries used throughout the report."),
        source=["README.md", "docs/START_HERE.md", "apps/mobile/lib/features/home/presentation/screens/home_screen.dart", "services/api/app/main.py"],
    )
    add_page(
        "chapter_1_2", "1.2 Background and Context",
        "Medication routines often involve several names, quantities, times, and meal instructions. An older person may need a display that reduces reading and navigation effort, while a family caregiver may need a simple view of whether planned doses were recorded. The repository responds to this context with a schedule model, a daily-dose screen, and a caregiver patient list.",
        "The project is not an electronic health record, a pharmacy fulfillment service, or a clinical decision system. It stores self-entered care information and applies deterministic rules to categorize vital readings. Its value in this phase is coordination and visibility; clinical interpretation remains with the treating professional.",
        bullets=["The patient is the source of their medication and measurement records.", "A caregiver gains patient access through a time-limited pairing code.", "A clinician receives a generated summary file rather than a separate portal account."],
        source=["docs/USE_CASES.md", "services/api/app/models/medication.py", "services/api/app/api/v1/endpoints/caregiver.py"],
    )
    add_page(
        "chapter_1_3", "1.3 Problem Statement",
        "Medliva addresses fragmented communication around recurring medication and monitoring tasks. In the current baseline, the patient can maintain a medication list and schedule, record a dose as taken or skipped, and record vital readings. A linked caregiver can view a patient's daily totals and missed-dose alerts that the API computes after a 15-minute grace period.",
        "The engineering problem is to keep these records understandable and consistent across a mobile client and a protected API while preserving a usable path when the network is unreliable. The delivered solution handles some offline adherence records through a secure-storage queue abstraction, but that queue is not wired into the active screen flow. The problem is therefore only partially addressed during disconnection.",
        callout=("Evidence boundary", "No patient outcome study, medication adherence improvement measurement, or clinical validation dataset is included in the repository. This report makes no effectiveness claim."),
        source=["apps/mobile/lib/features/medications/presentation/screens/today_screen.dart", "services/api/app/api/v1/endpoints/caregiver.py", "apps/mobile/lib/features/medications/data/offline_adherence_queue.dart"],
    )
    add_page(
        "chapter_1_4", "1.4 Research Questions and Project Motivation",
        "This is an implementation report rather than a clinical research study. Its questions are engineering questions grounded in the delivered code: how a mobile application can coordinate a patient's daily medication records with caregiver access; how a small REST API can protect patient-specific routes; and how sensitive or uncertain input should be confirmed before it becomes a stored record.",
        "The motivation is to turn a set of common care tasks into a single approachable workflow without implying that software replaces a clinician. The report also asks how to describe prototype boundaries honestly: a route may exist while its external integration remains simulated, and a helper may be tested while not yet connected to the user flow.",
        table=("Table 1.2. Documentation questions", ["Question", "Evidence used in this report"], [
            ["What can a patient complete today?", "Screens, repositories, routes, and tests"],
            ["How is caregiver access bounded?", "Pairing and patient-access dependencies"],
            ["Which features rely on real external services?", "Endpoint bodies, configuration, and runtime wiring"],
            ["What is still a prototype?", "Mocks, unreferenced services, and missing dispatch code"],
        ]),
        source=["docs/EXECUTION_PLAN.md", "services/api/app/core/deps.py", "apps/mobile/lib/core/router/app_router.dart"],
    )
    add_page(
        "chapter_1_5", "1.5 Project Aim and Objectives",
        "The project aim is to provide a bilingual mobile workflow for recording medication plans and care observations, with a protected service layer and a practical caregiver view. The objectives below are classified by repository evidence, not by aspirational wording in historical requirements.",
        "The current implementation achieves the main structural objectives: a role-aware mobile shell, patient medication CRUD, dose logging, caregiver pairing and dashboard data, manual and speech-assisted vitals, stock forecasts, contact management, an API-backed report summary, and a generated PDF. Some delivery objectives remain incomplete because supporting code is not wired or uses mock data.",
        table=("Table 1.3. Objective status", ["Objective", "Status in current source"], [
            ["Provide patient and caregiver mobile views", "Implemented screens; navigation gaps remain"],
            ["Protect patient-specific API records", "Access checks present and covered by tests"],
            ["Read real prescription content", "Not implemented; fixed sample output"],
            ["Dispatch SOS to contacts", "Alert record created; dispatch not implemented"],
            ["Generate a clinician summary PDF", "Implemented; English LTR output"],
        ]),
        source=["docs/EXECUTION_PLAN.md", "apps/mobile/lib/features/reports/data/reports_repository.dart", "services/api/app/api/v1/endpoints/ai.py"],
    )
    add_page(
        "chapter_1_6", "1.6 Project Scope and Boundaries",
        "The documented scope includes the existing Android-oriented Flutter application, the FastAPI v1 API, local SQLite development mode, SQLAlchemy models and Alembic migrations, the current test suites, and the project documentation needed to understand those parts. The app includes patient and caregiver roles, although normal OTP account creation defaults new users to the patient role.",
        "No standalone doctor portal is part of the current MVP. The doctor-portal folder records that decision and points to the mobile PDF flow. Push delivery, SMS, a live AI provider, pharmacy ordering, a production cloud deployment, and a comprehensive offline data store are outside the verified runtime in this snapshot.",
        bullets=["In scope: local reminders planner, but not automatic lifecycle wiring.", "In scope: report-share API model and token flow, but not a mobile public-link workflow.", "Out of scope: clinical validation, medication prescribing, diagnosis, and automated treatment changes."],
        source=["apps/doctor-portal/README.md", "apps/mobile/lib/core/router/app_router.dart", "infra/.env.example"],
    )
    add_page(
        "chapter_1_7", "1.7 Assumptions, Constraints, and Operating Context",
        "The mobile client assumes the API base URL is supplied correctly for the device or emulator. Its default URL uses the Android emulator host alias and is not a general production address. A developer build also defaults SKIP_AUTH to true, which redirects the initial authentication pages to the home route; connected sign-in flows require SKIP_AUTH=false.",
        "The API defaults to a local SQLite URL for development and checks production configuration for a non-default secret, disabled OTP return, explicit CORS origins, and a PostgreSQL URL. Environment examples include cloud services, but settings and endpoint implementations do not currently wire all listed storage, AI, SMS, or push providers.",
        table=("Table 1.4. Runtime assumptions", ["Area", "Current assumption or constraint"], [
            ["Client API URL", "Build-time API_BASE_URL; emulator default"],
            ["Authentication", "SKIP_AUTH defaults to true in source"],
            ["Local database", "SQLite with table creation at startup"],
            ["Production database", "PostgreSQL required by production validation"],
            ["External delivery", "SMS, FCM, storage, and AI are not verified integrations"],
        ]),
        source=["apps/mobile/lib/core/config/app_config.dart", "apps/mobile/lib/core/router/app_router.dart", "services/api/app/core/config.py", "services/api/app/main.py"],
    )
    add_page(
        "chapter_1_8", "1.8 Proposed Solution and System Overview",
        "The proposed solution has two runtime parts. The Flutter client collects user actions, renders localized screens, and calls a JSON API. The FastAPI service validates request schemas, loads the authenticated user, checks patient access for scoped operations, and reads or writes application records through SQLAlchemy sessions.",
        "The main workflow starts with a patient medication plan and schedule. The daily screen reads today's doses and records user choices. A caregiver obtains access through pairing, then sees summary counts and computed alerts. Vital readings can be entered directly or dictated, reviewed, and confirmed. Inventory forecasts and doctor-report data are calculated by the API and presented or exported by the app.",
        figure=("Figure 1.1. High-level Medliva request path", ["Patient or caregiver", "Flutter app", "FastAPI v1", "SQLAlchemy", "SQLite or PostgreSQL"]),
        source=["apps/mobile/lib/core/network/api_client.dart", "services/api/app/api/v1/router.py", "services/api/app/db/session.py"],
    )
    add_page(
        "chapter_1_9", "1.9 Expected and Verified Contributions",
        "The verified contribution is a working software baseline that connects multiple care-oriented modules through a shared mobile client and API contract. The project demonstrates request validation, token rotation, caregiver linking, patient-scoped access checks, deterministic vital triage, a basic stock forecast, and a PDF export flow.",
        "The work should not be described as a tested medical device, a clinically validated triage service, a production-grade AI prescription reader, or an emergency dispatch system. These are distinct levels of assurance and integration that the repository does not demonstrate. A traceable statement of what exists is itself a useful contribution because it supports safe review and future development planning.",
        table=("Table 1.5. Contribution and evidence", ["Contribution", "Evidence and limit"], [
            ["Mobile/API feature slice", "Screens, repositories, routes, and model schemas"],
            ["Authentication safeguards", "OTP limits, JWT expiry, refresh rotation, session hashes"],
            ["Caregiver access boundary", "Active link check for patient-scoped endpoints"],
            ["Operational reliability", "Partial; offline and reminder helpers lack full wiring"],
        ]),
        source=["services/api/app/api/v1/endpoints/auth.py", "services/api/app/core/deps.py", "apps/mobile/test"],
    )
    add_page(
        "chapter_1_10", "1.10 Report Organization",
        "Chapter 1 defines the project context and boundaries. Chapter 2 explains the technical concepts used by the code and compares the implemented approach with common software patterns without claiming unsupported novelty. Chapter 3 turns source evidence into requirements and acceptance conditions.",
        "Chapter 4 documents the architecture, data model, access rules, and workflows. Chapter 5 records the implementation and runtime setup. Chapter 6 maps the tests to features and states what was not measured. Chapter 7 summarizes the outcome and prioritizes future work. The appendices provide the detailed requirements, use cases, data dictionary, route catalogue, test register, user guide, examples, and system-component overview.",
        bullets=["Chapter 2: theoretical background and related work.", "Chapters 3-5: requirements, design, and implementation.", "Chapter 6: tests, evaluation limits, and threats to validity.", "Appendices: reference material for maintainers and reviewers."],
        source=["Documentation Template.pdf supplied with the task; mapped to current Medliva scope."],
    )
    add_page(
        "chapter_1_11", "1.11 Chapter Summary",
        "Medliva targets daily medication coordination for older adults and their caregivers through a bilingual mobile app and a protected REST service. The report follows the supplied academic structure while treating repository code and tests as the authoritative evidence for implemented behavior.",
        "Several requirements are only partially met. Local reminder scheduling and offline adherence support have standalone implementations but no active runtime wiring; prescription scanning is simulated; SOS and device registration do not dispatch messages; and the in-app clinician report differs from the historical requirement for embedded Arabic PDF output and a public web portal. These boundaries shape the requirements and evaluation chapters that follow.",
        callout=("Snapshot rule", "Every implementation claim in later chapters is bounded by the repository state on 24 October 2026."),
        source=["docs/START_HERE.md", "docs/EXECUTION_PLAN.md", "current source and test directories"],
    )

    add_page(
        "chapter_2_1", "2.1 Introduction to the Technical Background",
        "Medliva combines familiar mobile, API, and database patterns. The mobile layer is written in Flutter and Dart; Riverpod supplies application state; GoRouter maps URLs to screens; Dio sends HTTP requests; and FastAPI exposes typed endpoints backed by Pydantic schemas and SQLAlchemy models. The source implementation is the evidence for the packages used here; the cited publisher documentation provides technical context for Flutter and asynchronous SQLAlchemy patterns [R3, R8].",
        "This chapter explains the concepts needed to read the implementation. It separates standard engineering patterns from project-specific decisions and avoids treating a package's capability as proof that Medliva uses every available feature. For example, a notifications package can schedule alarms, but the current repository only contains a planner/service module and does not call it from application startup or the daily screen.",
        table=("Table 2.1. Technical layers", ["Layer", "Responsibility in Medliva"], [
            ["Presentation", "Localized Flutter screens and interactions"],
            ["Client data access", "Feature repositories using the shared Dio client"],
            ["API", "FastAPI routers, validation schemas, access dependencies"],
            ["Persistence", "SQLAlchemy async sessions and relational tables"],
            ["Verification", "Pytest API suite and Flutter unit/widget tests"],
        ]),
        chapter=("Chapter 2 - Theoretical Background and Related Work", "chapter_2", "The chapter introduces the ideas behind the system and examines how the current implementation realizes them."),
        source=["apps/mobile/pubspec.yaml", "services/api/pyproject.toml", "services/api/app/api/v1/router.py"],
    )
    add_page(
        "chapter_2_2", "2.2 Medication Scheduling and Reminder Concepts",
        "A medication schedule is represented by a medication record plus one or more schedule records. Each schedule stores a time of day, a seven-bit day mask, a dose amount, a meal relation, optional Arabic instructions, and optional start and end dates. The API constructs today's dose view from active medications and schedules.",
        "On Android, the planner creates an initial reminder and up to three repeats at five-minute intervals for each dose that is not already marked taken or skipped. It requests exact scheduling and a full-screen-intent notification. Android documents exact alarms as a special scheduling capability, while the Flutter plugin exposes local notification scheduling APIs [R6, R9]. The design does not currently define user actions on the notification itself, restart recovery, a text-to-speech alarm, a ten-minute snooze, or automatic cancellation immediately after a dose is recorded.",
        figure=("Figure 2.1. Planned reminder sequence", ["Today dose data", "Reminder planner", "Exact local schedule", "Android notification"]),
        callout=("Implementation status", "The reminder service is not referenced outside its own file and tests. It is a tested module, not an active end-to-end reminder workflow."),
        source=["services/api/app/models/medication.py", "apps/mobile/lib/features/medications/data/medication_reminder_planner.dart", "apps/mobile/test/features/medications/medication_reminder_planner_test.dart"],
    )
    add_page(
        "chapter_2_3", "2.3 Adherence Records and Idempotency",
        "A dose response is recorded as an intake log with a client UUID, schedule ID, patient ID, scheduled timestamp, optional actual timestamp, status, reason, and an offline flag. The client UUID is unique in the database, which is intended to distinguish a retry from a separate action. The API also accepts batch sync items for intake and vital records.",
        "The current active TodayScreen sends adherence directly through MedicationRepository. The secure queue class can store failed items, listen for connectivity, and submit a batch, but no runtime provider or screen call constructs that queue. Therefore the UI does not yet guarantee that a dose choice survives network failure. The record model is a useful foundation for idempotency, but the screen's integration path is the operational boundary.",
        table=("Table 2.2. Adherence status semantics", ["Status", "Meaning in current record flow"], [
            ["taken", "User confirms the dose was taken"],
            ["skipped", "User records that the dose was not taken"],
            ["missed", "Backend or caller records a missed dose"],
            ["snoozed", "Status exists in the API enum; no active screen action is shown"],
        ]),
        source=["services/api/app/models/medication.py", "services/api/app/api/v1/endpoints/adherence.py", "apps/mobile/lib/features/medications/presentation/screens/today_screen.dart", "apps/mobile/lib/features/medications/data/offline_adherence_queue.dart"],
    )
    add_page(
        "chapter_2_4", "2.4 Caregiver Linking and Shared Access",
        "The pairing flow uses a six-digit code created by the patient and given to a caregiver. The code expires after ten minutes. A successful pairing changes a CaregiverLink to active and stores the linked timestamp. The mobile client exposes one screen to show the code and another to submit it.",
        "A caregiver dashboard lists active linked patients and displays counts computed for the current UTC date. For each schedule today, the API counts a taken log or produces a missed-dose alert when a missed log exists or fifteen minutes have passed with no log. The dashboard can set a selected patient ID in an in-memory Riverpod provider and open a read-only daily view.",
        table=("Table 2.3. Caregiver access lifecycle", ["Stage", "Behavior"], [
            ["Issue code", "Patient receives a six-digit code with a ten-minute expiry"],
            ["Pair", "Caregiver submits code; link becomes active"],
            ["Read", "Active link permits patient-scoped API access"],
            ["Revoke", "Revoked state exists in the model; a revocation UI/route is absent"],
        ]),
        source=["services/api/app/api/v1/endpoints/caregiver.py", "services/api/app/core/deps.py", "apps/mobile/lib/features/caregiver/presentation/screens/caregiver_dashboard_screen.dart"],
    )
    add_page(
        "chapter_2_5", "2.5 Vital Signs and Deterministic Triage",
        "Vital records have a type, primary value, optional secondary value, meal context, triage band, optional raw transcript, and recorded timestamp. Supported types are blood pressure, glucose, and pulse. The service computes the band using explicit conditional rules rather than a learned model.",
        "The blood-pressure rule flags systolic values at or above 180, systolic values at or below 90, or diastolic values at or above 120 as critical; values from 130 systolic or 80 diastolic enter the borderline band. Glucose thresholds depend on fasting, post-meal, or general context. Pulse values below 50 or above 120 are critical, and values outside the 60-100 range are borderline.",
        callout=("Clinical boundary", "These are code-level thresholds, not evidence of medical validation. The app presents a triage label and disclaimer; users should rely on a qualified clinician for care decisions."),
        source=["services/api/app/services/triage.py", "services/api/app/api/v1/endpoints/vitals.py", "apps/mobile/lib/features/vitals/presentation/screens/vitals_screen.dart"],
    )
    add_page(
        "chapter_2_6", "2.6 Speech-to-Text and Confirmation",
        "The mobile voice-entry flow asks the device speech_to_text plugin for an Arabic Egypt or US English transcript, waits for a short capture window, and sends the recognized text to the API. The backend normalizes a small set of spoken Egyptian number phrases and separators, then infers blood pressure, glucose, or pulse and invokes the deterministic triage functions.",
        "The app shows the transcript and parsed values in an editable confirmation dialog. It writes a vital record only after the user chooses Save. This human confirmation is a critical safeguard because speech recognition and heuristic parsing can both return incorrect or default values. The implementation does not upload an audio recording or call Whisper or Gemini.",
        figure=("Figure 2.2. Voice entry path", ["Speak", "Device STT", "Text parser and triage", "Edit and confirm", "Save vital"]),
        source=["apps/mobile/lib/features/vitals/presentation/screens/voice_vital_entry.dart", "services/api/app/services/ai_service.py", "apps/mobile/test/features/vitals/voice_vital_entry_test.dart"],
    )
    add_page(
        "chapter_2_7", "2.7 Prescription Reading and Human Review",
        "A production prescription-reading service would need to extract text from an image, distinguish medication names and instructions, estimate uncertainty, match recognized names against a trusted catalog, and ask a person to confirm the result. The Medliva client already selects an image, posts it as multipart data, displays returned medication candidates, permits edits, and creates selected medications after confirmation.",
        "The server route accepts an optional file but currently does not read it. The AI service returns two fixed examples and fuzzy-matches them against a small in-code list or database catalog. The output is therefore a demonstrator of the review interaction, not OCR, computer vision, a language model, or a safe prescription interpretation system.",
        table=("Table 2.4. Prescription workflow status", ["Stage", "Current status"], [
            ["Camera/gallery selection", "Implemented in mobile client"],
            ["Multipart upload", "Implemented in client request"],
            ["Image OCR or vision inference", "Not implemented in current endpoint"],
            ["Candidate review and edit", "Implemented in mobile screen"],
            ["Create confirmed records", "Implemented through medication repository"],
        ]),
        source=["services/api/app/api/v1/endpoints/ai.py", "services/api/app/services/ai_service.py", "apps/mobile/lib/features/prescription/presentation/screens/prescription_scan_screen.dart"],
    )
    add_page(
        "chapter_2_8", "2.8 Offline Operation and Synchronization",
        "Offline-first systems usually define which records can be read or written without a network, how local changes are persisted, how retries are deduplicated, and which side wins a conflict. Medliva contains a narrower secure-storage queue abstraction for failed adherence writes and an API batch endpoint that accepts recognized sync items.",
        "There is no Drift or other local relational database in the mobile dependencies, and the queue is not initialized by the app. Other records are fetched from the API. The project should therefore be described as having an offline adherence queue component rather than as a complete offline-first application. Recovery across process restarts, queue migration, conflict resolution, retry telemetry, and user-visible sync status remain design work.",
        table=("Table 2.5. Offline capability matrix", ["Data or operation", "Current evidence"], [
            ["Medication list", "Remote API reads and writes"],
            ["Dose log helper", "Secure-storage queue class exists"],
            ["Dose log screen wiring", "Direct repository path; queue not used"],
            ["Vitals sync", "Batch schema exists; mobile queue integration absent"],
            ["Local database", "No Drift dependency or app database found"],
        ]),
        source=["apps/mobile/lib/features/medications/data/offline_adherence_queue.dart", "apps/mobile/lib/features/medications/presentation/screens/today_screen.dart", "services/api/app/api/v1/endpoints/adherence.py", "apps/mobile/pubspec.yaml"],
    )
    add_page(
        "chapter_2_9", "2.9 Authentication, Authorization, and Tokens",
        "The API accepts bearer access tokens. JWT claims include a subject, role, token type, issue time, expiry, and token identifier. Access tokens expire after fifteen minutes by default; refresh tokens last thirty days. Refresh sessions store a token fingerprint and identifier so the service can rotate and revoke a session without storing the raw refresh token. RFC 7519 defines the JWT claim format, and the FastAPI security guide describes a bearer/JWT integration pattern [R1, R2].",
        "OTP challenges store a keyed hash, expire after five minutes by default, have a resend cooldown, a per-hour request limit, and a bounded attempt count. In development the OTP can be returned in the API response. Production settings reject that flag, a default or short secret, wildcard CORS, and SQLite. Authentication identifies the user; the patient-access dependency separately checks patient ownership or an active caregiver link.",
        figure=("Figure 2.3. Session renewal", ["Access token expires", "Client calls refresh", "Server rotates session", "Client retries once"]),
        source=["services/api/app/core/security.py", "services/api/app/api/v1/endpoints/auth.py", "services/api/app/core/config.py", "apps/mobile/lib/core/network/api_client.dart"],
    )
    add_page(
        "chapter_2_10", "2.10 Accessibility and Localization",
        "The Flutter theme uses Cairo, provides Arabic and English localizations, selects the locale from the signed-in user, uses directional padding in many screens, and sets large text for major body styles and buttons. The theme uses a minimum padded tap-target configuration; several interactions add explicit semantic labels or selected state.",
        "These implementation choices support accessibility but do not constitute a formal WCAG conformance claim. Flutter provides localization and accessibility guidance, while WCAG 2.2 is a web-content standard; mobile assessment must also account for native platform semantics, assistive technologies, dynamic text, language direction, and device behavior [R3, R4, R5]. The project execution log records an accessibility audit and remediation, while this report does not claim an independent re-audit on every screen or platform.",
        bullets=["Labels and messages are kept in Arabic and English ARB files.", "Important controls use text and icons as well as color cues.", "Some small text styles remain below the 18-point size used for the main body."],
        source=["apps/mobile/lib/core/theme/app_theme.dart", "apps/mobile/lib/l10n/app_ar.arb", "apps/mobile/lib/l10n/app_en.arb", "docs/EXECUTION_PLAN.md"],
    )
    add_page(
        "chapter_2_11", "2.11 Reports and Controlled Sharing",
        "The authenticated report-summary endpoint returns patient identity, the date range, active medication details, adherence records, a percentage computed from stored logs, and vital records with their bands. The Flutter report screen loads the default recent period, shows a short summary, builds a PDF, and opens the operating system share sheet.",
        "The PDF builder is English and left-to-right. For Arabic patient names, it applies a character-by-character Latin transliteration rather than embedding an Arabic font and shaping Arabic script. The API also has a tokenized public-report endpoint that stores a hash of the share token, but the client report flow does not create or display that public link. The stored scope field is not shown to filter the returned payload in the current implementation.",
        callout=("Report calculation note", "The adherence percentage uses the intake logs present in the selected range as its denominator. Schedules with no corresponding log are not automatically counted as missed in this report endpoint."),
        source=["services/api/app/api/v1/endpoints/reports.py", "apps/mobile/lib/features/reports/data/reports_repository.dart", "apps/mobile/lib/features/reports/presentation/screens/doctor_report_screen.dart"],
    )
    add_page(
        "chapter_2_12", "2.12 Related Approaches and Comparative Analysis",
        "Medication reminder apps, family monitoring tools, and patient portals commonly separate medication lists, appointment or measurement records, and clinician communication. Medliva brings several such tasks into one mobile client. This comparison describes feature boundaries visible in the repository; it does not evaluate commercial products or claim that the combination is unique.",
        "The distinguishing implementation decision is the use of one mobile client for patients and caregivers with server-enforced patient access. The trade-off is a broad surface area with incomplete integrations: local reminder and queue code are not wired, several external channels are absent, and the clinician report is a generated file rather than a full portal. A production comparison would require a documented evaluation dataset, usability study, security assessment, and current competitor evidence.",
        table=("Table 2.6. Pattern comparison", ["Capability", "Common pattern", "Medliva snapshot"], [
            ["Medication schedule", "Remote CRUD and reminders", "CRUD present; local planner not wired"],
            ["Caregiver access", "Account relationship or invitation", "Six-digit temporary code and active link"],
            ["Vital entry", "Manual form or device import", "Manual entry and device speech recognition"],
            ["Clinician sharing", "Portal, export, or patient-authorized link", "In-app PDF plus separate API share endpoint"],
            ["AI prescription entry", "OCR/vision extraction with review", "Review UI with fixed sample server output"],
        ]),
        source=["Current mobile and API implementation; comparison criteria are analytical, not market research."],
    )
    add_page(
        "chapter_2_13", "2.13 Research and Development Gap",
        "The main development gap is the difference between an architectural hook and a complete user-facing service. Several code areas establish a starting point, but service deployment, external notifications, clinical validation, and end-to-end recovery require additional evidence. The repository does not include measured usability or performance results.",
        "This report proposes that the next engineering iteration prioritize security and end-to-end completeness before adding more AI capabilities: disable authentication bypass in distributable builds, connect the queue and reminder planner to lifecycle events, provide real messaging only behind audited providers, and replace prescription mock data with a privacy-reviewed, evaluated pipeline and mandatory human confirmation.",
        bullets=["Research gap: no evidence that reminders improve adherence for the intended users.", "Engineering gap: no complete offline database or notification dispatch.", "Safety gap: heuristic parser defaults and fixed thresholds require validation.", "Operational gap: no deployment or monitoring evidence is present."],
        source=["services/api/app/core/config.py", "apps/mobile/lib/core/router/app_router.dart", "services/api/app/services/ai_service.py", "infra/.env.example"],
    )
    add_page(
        "chapter_2_14", "2.14 Chapter Summary",
        "The project combines standard REST, JWT, relational persistence, and mobile localization patterns with care-specific workflows. The current implementation includes deterministic vital triage and user-confirmed input, while its prescription endpoint is simulated and its broad offline and alarm aspirations exceed current runtime wiring.",
        "The comparison and gap analysis are deliberately evidence-based. They describe the actual feature mix without claiming clinical effectiveness or market uniqueness. The next chapter converts this account into functional and non-functional requirements that can be traced to files and tests.",
        source=["docs/API_SPEC.md", "docs/SECURITY.md", "current API and mobile source"],
    )

    add_page(
        "chapter_3_1", "3.1 Requirements Analysis Approach",
        "Requirements were reconstructed from the current screens, repositories, API routes, Pydantic schemas, SQLAlchemy models, tests, and the execution-plan log. This source-based method describes what the system currently promises at its code boundary. It does not substitute for interviews with patients, caregivers, clinicians, or accessibility specialists.",
        "Each requirement in this chapter uses a unique identifier and a status: implemented, partial, or not implemented. Acceptance evidence is mapped to a route, screen, model, or test. Where the source contains an incomplete workflow, the requirement records the gap rather than promoting a historical design note to delivered behavior.",
        table=("Table 3.1. Requirement status definitions", ["Status", "Interpretation"], [
            ["Implemented", "The required behavior appears in source and has a direct route or screen."],
            ["Partial", "A component exists, but its full runtime path or promised outcome is incomplete."],
            ["Not implemented", "No current implementation was found in the inspected source."],
            ["Recorded test", "A test definition or execution-log result exists; no fresh run is implied."],
        ]),
        chapter=("Chapter 3 - Requirements Analysis and System Specification", "chapter_3", "This chapter defines the actors, functional requirements, quality constraints, workflows, and traceability rules for the repository snapshot."),
        source=["docs/EXECUTION_PLAN.md", "apps/mobile/test", "services/api/tests", "services/api/app/schemas"],
    )
    add_page(
        "chapter_3_2", "3.2 Stakeholder Identification",
        "The primary stakeholder is an older adult who needs to view scheduled medicines, record an action, and enter health readings using clear controls. A caregiver is a second user who wants a limited view of linked patient records. A clinician is an indirect stakeholder who may receive the PDF summary but does not use a separate portal in this MVP.",
        "The project team and service operator are operational stakeholders because they configure API URLs, secrets, databases, migrations, and any future external providers. Pharmacy staff are not system users in the current application; the refill flow only returns a prepared message and WhatsApp URL. Emergency contacts are stored records, not verified recipients of a delivered alert.",
        table=("Table 3.2. Stakeholder concerns", ["Stakeholder", "Primary concern", "Current interaction"], [
            ["Patient", "Readable daily plan and control over records", "Patient shell, forms, dose actions"],
            ["Caregiver", "See linked patient status", "Pairing and dashboard read flow"],
            ["Clinician", "Receive a concise history", "PDF export/share from mobile"],
            ["Operator", "Secure configuration and recoverable service", "Environment, migration, CI files"],
            ["Contact or pharmacy", "Receive a reliable message", "No delivery integration verified"],
        ]),
        source=["apps/mobile/lib/features/home/presentation/screens/home_screen.dart", "apps/mobile/lib/features/caregiver", "apps/doctor-portal/README.md"],
    )
    add_page(
        "chapter_3_3", "3.3 User Roles and System Actors",
        "The database role enum contains patient, caregiver, and admin. New OTP-created users default to patient. The pairing endpoints require the patient role to create a code and the caregiver role to redeem it, but the current OTP screen and API do not provide a role-selection or caregiver-account promotion flow.",
        "The mobile router derives the target shell from the loaded user role when authentication is active. The dashboard can select a linked patient, and the patient ID is held in a Riverpod provider in memory. The API remains authoritative: for scoped data it checks that the caller is the patient, an admin, or a caregiver with an active link.",
        table=("Table 3.3. Actors and privileges", ["Actor", "Available operations", "Important boundary"], [
            ["Patient", "Manage own profile, medication, vitals, contacts, reports", "Own patient ID"],
            ["Caregiver", "Pair and view linked patient data", "Active link required for scoped routes"],
            ["Admin", "Passes patient-access helper", "No admin UI or full admin workflow found"],
            ["Public report reader", "Read a non-expired share-token report", "Token is bearer access; no account"],
        ]),
        source=["services/api/app/models/user.py", "services/api/app/api/v1/endpoints/auth.py", "services/api/app/core/deps.py", "apps/mobile/lib/core/router/app_router.dart"],
    )
    add_page(
        "chapter_3_4", "3.4 Functional Requirements Overview",
        "Functional requirements are grouped by observable user or service outcomes: identity and profile, medication and schedule management, dose logging, caregiver linking, vital entry, prescription review, inventory, emergency records, reporting, and device registration. The API schema and test suites provide the most direct evidence of request and response behavior.",
        "A feature can be partially satisfied even if both a screen and endpoint exist. For example, an SOS button and endpoint form a complete request path for recording an alert, but not for dispatching that alert to another person. This distinction is reflected in the acceptance criteria and status table.",
        bullets=["FR identifiers use FR-AUTH, FR-MED, FR-CARE, FR-VITAL, FR-RX, FR-STOCK, FR-SOS, FR-REPORT, and FR-DEVICE.", "Requirements do not assert that an external service works unless an adapter and runtime configuration exist.", "Every high-risk write should have explicit user confirmation and server-side access checks."],
        source=["docs/API_SPEC.md", "services/api/app/api/v1/endpoints", "apps/mobile/lib/features"],
    )
    add_page(
        "chapter_3_5", "3.5.1 FR-AUTH: Identity and Session Management",
        "FR-AUTH-01 requires a user to request and verify a one-time code for an Egyptian mobile number. FR-AUTH-02 requires rate limits, expiry, failed-attempt bounds, and single-use behavior. FR-AUTH-03 requires the client to store access and refresh tokens securely, renew an expired access token once, and clear the session on refresh failure.",
        "FR-AUTH-04 requires the authenticated API to expose the current profile and allow supported profile updates. The API implements the OTP controls and token rotation; the mobile client stores tokens in flutter_secure_storage and has an interceptor that retries a protected request once after renewal. New accounts receive the patient role by default, so caregiver onboarding remains incomplete.",
        table=("Table 3.4. Authentication acceptance criteria", ["ID", "Acceptance condition", "Status"], [
            ["FR-AUTH-01", "Normalize and validate accepted Egyptian mobile formats", "Implemented"],
            ["FR-AUTH-02", "Limit requests, retries, and challenge lifetime", "Implemented"],
            ["FR-AUTH-03", "Refresh once and clear credentials on failure", "Implemented"],
            ["FR-AUTH-04", "Select patient or caregiver role during registration", "Not implemented"],
        ]),
        source=["services/api/app/api/v1/endpoints/auth.py", "services/api/app/core/phone.py", "apps/mobile/lib/core/network/api_client.dart", "apps/mobile/lib/core/storage/token_storage.dart"],
    )
    add_page(
        "chapter_3_6", "3.5.2 FR-PROFILE: Profile and Language",
        "FR-PROFILE-01 requires the user to view their name, phone number, and role. FR-PROFILE-02 allows the user to update the name and language through the authenticated profile endpoint. FR-PROFILE-03 requires the app locale to respond to the saved language and localize text for Arabic and English.",
        "The profile screen and API support name and language updates. The app selects Arabic unless the user language is English. Additional fields exist in the backend model, including time zone, birth date, and address, but they are not all exposed through the mobile profile screen and not all are accepted by the repository's profile update call.",
        callout=("Acceptance evidence", "A Flutter widget test covers changing the profile language and observing the app locale switch."),
        source=["services/api/app/schemas/user.py", "apps/mobile/lib/features/auth/presentation/screens/profile_screen.dart", "apps/mobile/lib/main.dart", "apps/mobile/test/features/auth/profile_screen_test.dart"],
    )
    add_page(
        "chapter_3_7", "3.5.3 FR-MED: Medication and Schedule Management",
        "FR-MED-01 requires the patient or linked caregiver to list active medications. FR-MED-02 supports creation and update of a medication, including name, strength, form, stock, threshold, expiry, and optional schedules. FR-MED-03 supports adding schedule times and meal relations. FR-MED-04 deactivates a medication rather than deleting its history.",
        "The mobile application provides medication list, add/edit, and detail/schedule screens. API ownership checks are performed on patient-scoped routes and medication-scoped routes resolve the related patient before allowing the operation. Historical dosage rules, interaction checks, and medication catalog verification are not implemented as clinical safeguards.",
        table=("Table 3.5. Medication requirements", ["ID", "Acceptance condition", "Evidence"], [
            ["FR-MED-01", "List active medication and schedules", "GET patient medications"],
            ["FR-MED-02", "Create and update medication data", "POST/PATCH endpoints and forms"],
            ["FR-MED-03", "Create dose schedule", "Schedule endpoint and detail screen"],
            ["FR-MED-04", "Deactivate with user confirmation", "DELETE endpoint and confirmation dialog"],
        ]),
        source=["services/api/app/api/v1/endpoints/medications.py", "apps/mobile/lib/features/medications/presentation/screens/medication_form_screen.dart", "apps/mobile/lib/features/medications/presentation/screens/medication_detail_screen.dart"],
    )
    add_page(
        "chapter_3_8", "3.5.4 FR-DOSE: Daily Doses and Adherence",
        "FR-DOSE-01 requires a patient to view scheduled doses for the current day with the medication name, dose, time, and state. FR-DOSE-02 records taken or skipped choices, updates the screen, and retains scheduled and actual timestamps. FR-DOSE-03 allows a duplicate submission to be recognized by a client UUID. FR-DOSE-04 aims to retry failed writes after connectivity returns.",
        "The daily screen and API provide the dose read and write path. A secure queue implementation and batch endpoint exist, but the daily screen does not call the queue. Therefore FR-DOSE-04 is partial. A backend uniqueness constraint on client_uuid supports duplicate detection at storage level; the error handling for every repeated POST should be validated before claiming graceful idempotency.",
        source=["apps/mobile/lib/features/medications/presentation/screens/today_screen.dart", "apps/mobile/lib/features/medications/data/offline_adherence_queue.dart", "services/api/app/api/v1/endpoints/adherence.py", "services/api/app/models/medication.py"],
    )
    add_page(
        "chapter_3_9", "3.5.5 FR-CARE: Pairing and Caregiver Dashboard",
        "FR-CARE-01 allows a patient to request a temporary pairing code. FR-CARE-02 allows a caregiver account to redeem a valid code. FR-CARE-03 shows linked patients with today's taken and missed counts. FR-CARE-04 allows the caregiver to open a selected patient's daily schedule in read-only mode.",
        "The API implements code expiry and active-link state; the dashboard uses an in-memory selected patient ID. The backend permission mask is stored but the access helper currently grants the same patient-level permission to any active link. Fine-grained view, edit, emergency, or report permissions are not enforced.",
        table=("Table 3.6. Caregiver requirements", ["ID", "Acceptance condition", "Status"], [
            ["FR-CARE-01", "Issue a six-digit code that expires after ten minutes", "Implemented"],
            ["FR-CARE-02", "Reject wrong, expired, or wrong-role pairing attempts", "Implemented"],
            ["FR-CARE-03", "Expose today's counts and alerts for linked patients", "Implemented"],
            ["FR-CARE-04", "Persist selected patient and enforce granular permissions", "Partial"],
        ]),
        source=["services/api/app/api/v1/endpoints/caregiver.py", "services/api/app/models/caregiver.py", "services/api/app/core/deps.py", "apps/mobile/lib/features/caregiver/presentation/screens/caregiver_dashboard_screen.dart"],
    )
    add_page(
        "chapter_3_10", "3.5.6 FR-VITAL: Manual Vital Recording",
        "FR-VITAL-01 requires listing patient vital records with an optional type filter and limit. FR-VITAL-02 requires a user to submit blood pressure, glucose, or pulse values with optional meal context. FR-VITAL-03 requires the service to calculate a band and the UI to show an icon, text, and color so that meaning is not communicated by color alone.",
        "The API calculates triage on creation and persists the band with the values. The mobile screen supports list and manual entry. The thresholds are fixed in source and are not configurable per patient or clinician. The app should state that readings are user-entered and the computed label is not a diagnosis.",
        source=["services/api/app/services/triage.py", "services/api/app/api/v1/endpoints/vitals.py", "apps/mobile/lib/features/vitals/presentation/screens/vitals_screen.dart"],
    )
    add_page(
        "chapter_3_11", "3.5.7 FR-VOICE: Speech-Assisted Vital Entry",
        "FR-VOICE-01 lets a user dictate a reading in Arabic or English. FR-VOICE-02 parses the transcript into a type and values. FR-VOICE-03 shows an editable confirmation view. FR-VOICE-04 stores nothing until the user confirms. FR-VOICE-05 preserves the raw transcript alongside the record for traceability.",
        "The mobile and API code implement these steps, with speech recognition on the device and text parsing on the server. The parser has heuristics and a default result path for unclear input; the confirmation screen is therefore mandatory. Automated tests cover a mocked parser result and ensure that saving follows confirmation, but they do not measure real-world speech recognition accuracy.",
        source=["apps/mobile/lib/features/vitals/presentation/screens/voice_vital_entry.dart", "services/api/app/services/ai_service.py", "services/api/app/models/vitals.py", "apps/mobile/test/features/vitals/voice_vital_entry_test.dart"],
    )
    add_page(
        "chapter_3_12", "3.5.8 FR-RX: Prescription Candidate Review",
        "FR-RX-01 allows a user to select an image from a device camera or gallery. FR-RX-02 submits an image as multipart form data. FR-RX-03 displays returned candidate medicines for editing and selection. FR-RX-04 creates only the selected items after explicit confirmation; cancel must create none.",
        "The mobile interaction implements selection, review, edit, confirm, and cancel. The current server response is static sample data and does not depend on the image. A future production requirement must include image limits, extraction confidence per field, a safe unknown-value state, catalog provenance, and clinical review before a medication schedule is created.",
        callout=("Status", "The interaction is implemented; image understanding is not."),
        source=["apps/mobile/lib/features/prescription/presentation/screens/prescription_scan_screen.dart", "apps/mobile/lib/features/prescription/data/prescription_repository.dart", "services/api/app/api/v1/endpoints/ai.py", "apps/mobile/test/features/prescription/prescription_scan_screen_test.dart"],
    )
    add_page(
        "chapter_3_13", "3.5.9 FR-STOCK: Inventory Forecast and Refill Text",
        "FR-STOCK-01 calculates an estimated days-remaining value for active medicines using current stock and the sum of active schedule dose amounts. FR-STOCK-02 flags low stock and expiry. FR-STOCK-03 generates a refill message and WhatsApp URL from the chosen items and pharmacy phone.",
        "The mobile screen displays days remaining, marks a warning when fewer than seven days remain or the API low-stock flag is set, and requests a refill message. The screen currently displays the returned message in a snackbar; it does not launch the WhatsApp URL. The forecast ignores schedule day masks and date windows, so it is a rough estimate rather than a reliable inventory ledger.",
        source=["services/api/app/services/inventory.py", "services/api/app/api/v1/endpoints/inventory.py", "apps/mobile/lib/features/inventory/presentation/screens/inventory_screen.dart"],
    )
    add_page(
        "chapter_3_14", "3.5.10 FR-SOS: Emergency Contacts and SOS",
        "FR-SOS-01 allows an authorized patient or caregiver to view and add patient emergency contacts. FR-SOS-02 requires a patient-facing SOS control with an intentional confirmation step. FR-SOS-03 includes current coordinates only when device permission is already granted. FR-SOS-04 creates a server-side SOS alert record.",
        "The mobile control opens a confirmation dialog after a long press and attempts to obtain coordinates without prompting for new permission. The API saves an alert payload and returns a count of contacts and active caregiver links. It does not send an SMS, phone call, push notification, or email; the returned count must not be described as delivery confirmation.",
        source=["apps/mobile/lib/features/emergency/presentation/widgets/sos_button_widget.dart", "services/api/app/api/v1/endpoints/emergency.py", "apps/mobile/test/features/emergency/sos_button_test.dart"],
    )
    add_page(
        "chapter_3_15", "3.5.11 FR-REPORT: Clinician Summary and Sharing",
        "FR-REPORT-01 returns a date-bounded patient summary with medications, adherence logs, and vital readings. FR-REPORT-02 builds a PDF locally. FR-REPORT-03 includes an explicit medical disclaimer. FR-REPORT-04 allows the user to share or print the generated file through the platform share sheet.",
        "The API defaults to the last thirty days if no dates are supplied. The app currently uses that default and does not expose a date picker. The API has a separate token-sharing route, but the current screen uses file sharing rather than that route. The report PDF is always English and does not embed an Arabic font.",
        source=["services/api/app/api/v1/endpoints/reports.py", "apps/mobile/lib/features/reports/presentation/screens/doctor_report_screen.dart", "apps/mobile/lib/features/reports/data/reports_repository.dart"],
    )
    add_page(
        "chapter_3_16", "3.5.12 FR-DEVICE: Device Registration",
        "FR-DEVICE-01 accepts an authenticated device token, platform, and optional app version and records a last-seen timestamp. FR-DEVICE-02 updates the owner and metadata if the same FCM token is registered again. The endpoint provides a registry record for potential future push delivery.",
        "The API implements registration and update. The Flutter app does not call this endpoint in the current source, and no FCM sender is present. Device registration is therefore a backend capability without a verified mobile registration or push notification workflow.",
        source=["services/api/app/api/v1/endpoints/devices.py", "services/api/app/models/devices.py", "apps/mobile/lib"],
    )
    add_page(
        "chapter_3_17", "3.6 Non-Functional Requirements",
        "Non-functional requirements describe the quality constraints that apply across features. For Medliva the most important are access control, data minimization, language and direction support, clear error handling, predictable session renewal, maintainable feature boundaries, and a responsive experience on common devices.",
        "Current evidence supports some of these constraints: typed schemas validate requests, the API wraps errors consistently, the client sets request timeouts, JWT refresh retries once, and the UI uses larger body styles and directional padding. No load test, uptime target, accessibility conformance report, retention schedule, encryption-at-rest audit, or clinical safety case is stored in the repository.",
        table=("Table 3.7. Non-functional requirements", ["ID", "Requirement", "Evidence or gap"], [
            ["NFR-SEC-01", "Patient routes require ownership or active link", "Access dependency and route tests"],
            ["NFR-UX-01", "Critical actions use visible, accessible controls", "Theme and widget patterns; not full audit"],
            ["NFR-REL-01", "Transient API failures preserve user actions", "Queue class exists; not wired"],
            ["NFR-PRIV-01", "Sensitive tokens are not stored as plaintext server-side", "Refresh token fingerprint stored"],
            ["NFR-PERF-01", "Response time and capacity objectives are measured", "No benchmark evidence found"],
        ]),
        source=["services/api/app/core/errors.py", "services/api/app/core/deps.py", "apps/mobile/lib/core/network/api_client.dart", "docs/SECURITY.md"],
    )
    add_page(
        "chapter_3_18", "3.6.1 Security and Access Control Requirements",
        "All protected routes must authenticate the caller. Patient-specific medication, schedule, adherence, vitals, inventory, contact, and report operations must verify that the caller owns the patient record or has an active caregiver link. User roles must be checked for role-specific operations such as pairing-code creation and redemption.",
        "A critical requirement is to make permission semantics explicit. The current permission mask is persisted but not interpreted by the access helper. A future revision should define whether a caregiver can view, edit, log doses, create reports, or manage contacts, and enforce each permission at the API boundary. Authentication bypass must remain a development-only option and be disabled by production build configuration.",
        source=["services/api/app/core/deps.py", "services/api/app/models/caregiver.py", "apps/mobile/lib/core/router/app_router.dart", "services/api/tests/test_security_access.py"],
    )
    add_page(
        "chapter_3_19", "3.6.2 Usability, Accessibility, and Language Requirements",
        "The app should support Arabic right-to-left and English left-to-right layouts, provide understandable labels, use sufficiently large touch targets, maintain readable contrast, and expose semantic names for interactive controls. Important state must not rely solely on color. The app should preserve the selected language across profile updates and reloads.",
        "The code provides localization delegates, language resources, Cairo typography, directional spacing, and accessible labels on selected controls. It has not been independently evaluated on screen readers, multiple text scales, low-vision settings, small screens, or all target operating systems as part of this documentation task. A release criterion should combine automated semantics checks with representative user testing.",
        bullets=["Minimum interactive target: at least 48 logical pixels where controls are custom-built.", "Provide a text label for normal, borderline, critical, taken, skipped, and missed states.", "Exercise Arabic text direction on forms, tables, icons, dialogs, and generated PDF output separately."],
        source=["apps/mobile/lib/core/theme/app_theme.dart", "apps/mobile/lib/l10n", "docs/EXECUTION_PLAN.md"],
    )
    add_page(
        "chapter_3_20", "3.6.3 Reliability and Error-Handling Requirements",
        "The client should show actionable errors rather than losing a record silently. The API should return a stable error envelope with status, code, and human-readable message. Retryable writes should carry stable client identifiers, and retries should not create duplicate records or stock changes.",
        "The API has a centralized AppError handler and the mobile client extracts its message and code. Token renewal retries one non-auth request once. The queue class deduplicates queued IDs and removes only IDs returned by sync. However, no general retry policy, retry backoff, offline indicator, or UI recovery path is connected to the medication screen.",
        source=["services/api/app/core/errors.py", "apps/mobile/lib/core/network/api_client.dart", "apps/mobile/lib/features/medications/data/offline_adherence_queue.dart"],
    )
    add_page(
        "chapter_3_21", "3.6.4 Maintainability and Testability Requirements",
        "Feature code should remain separated into data, domain model, and presentation responsibilities. API endpoints, schemas, models, and tests should evolve together. Client repositories should be mockable so the interaction can be tested without network services. New strings must appear in both supported locale resources.",
        "The mobile feature directories generally follow this separation, and repositories are exposed through Riverpod providers. Flutter tests use mocktail for API and service boundaries. The API uses pytest with an isolated async database fixture. The repository does not report a coverage percentage, and neither test count nor green CI proves clinical behavior or production integration.",
        table=("Table 3.8. Testability checks", ["Check", "Current evidence"], [
            ["Repository interfaces can be mocked", "Flutter providers and mocktail tests"],
            ["Endpoint behavior has async tests", "Pytest and HTTPX async client"],
            ["Security access has negative tests", "Unrelated-user 403 assertions"],
            ["Coverage target is enforced", "No coverage setting found"],
        ]),
        source=["apps/mobile/test", "services/api/tests/conftest.py", "services/api/tests/test_security_access.py", "docs/CONVENTIONS.md"],
    )
    add_page(
        "chapter_3_22", "3.7 Use-Case Model and Descriptions",
        "The use-case model has two primary authenticated actors: Patient and Caregiver. A public reader can open a valid report token. The system also includes external services as optional future actors, but the repository does not currently integrate an SMS gateway, FCM sender, object store, or AI provider.",
        "Patient use cases cover profile management, medication maintenance, daily dose recording, vital entry, prescription review, emergency contacts, SOS, inventory, and report export. Caregiver use cases cover pairing, selecting a linked patient, viewing the dashboard, and opening a read-only daily schedule. Each detailed use case should define preconditions, main flow, alternate paths, and the observable success result.",
        table=("Table 3.9. Primary use cases", ["ID", "Actor", "Outcome", "Status"], [
            ["UC-01", "Patient", "Review and log today's dose", "Core flow present"],
            ["UC-02", "Patient", "Review prescription candidates", "Server extraction is mocked"],
            ["UC-03", "Patient", "Record and review a vital", "Core flow present"],
            ["UC-04", "Patient/Caregiver", "Link and review patient status", "Core flow present; role setup gap"],
            ["UC-05-07", "Patient", "Refill, report, SOS", "Partial integrations"],
        ]),
        source=["docs/USE_CASES.md", "apps/mobile/lib/features", "services/api/app/api/v1/endpoints"],
    )
    add_page(
        "chapter_3_23", "3.8 System Workflows and Activity Models",
        "The main activity model begins when the app loads the current user or presents authentication. The user opens a feature, the screen reads a provider, the provider calls a repository, and the repository calls the API client. On the server, FastAPI validates the schema, authenticates the caller, checks access, runs the endpoint operation, commits the record, and returns a response model.",
        "For speech and prescription flows, confirmation occurs before the final write. For SOS, confirmation precedes a request that stores an alert. For report export, the server returns summary data and the client builds the PDF. A major alternative path is API unavailability: the dose screen currently receives an error rather than using the offline queue, while a local queue helper is available but unconnected.",
        figure=("Figure 3.1. Typical API-backed feature activity", ["Open feature", "Read or edit form", "Repository request", "API validation and access", "Persist and render result"]),
        source=["apps/mobile/lib/core/network/api_client.dart", "services/api/app/core/deps.py", "services/api/app/api/v1/endpoints"],
    )
    add_page(
        "chapter_3_24", "3.9 Data Requirements and Data Dictionary Overview",
        "The relational model uses UUID primary keys and shared creation/update timestamps. The core clinical workflow is represented by users, medications, schedules, intake logs, vital logs, caregiver links, and alerts. Additional tables hold OTP challenges, refresh sessions, a drug catalog, prescription metadata, emergency contacts, report shares, and device tokens.",
        "The code does not contain several entities shown in older design notes, including a local Drift database, voice-note table, audit-log table, or alert acknowledgement UI. The report data dictionary in Appendix C is generated from current SQLAlchemy models. Its purpose is to support schema review and migration planning, not to propose fields that are absent from the database.",
        source=["services/api/app/models", "services/api/alembic/versions", "docs/DATABASE.md"],
    )
    add_page(
        "chapter_3_25", "3.10 API and External Integration Requirements",
        "The API uses JSON under /api/v1 except the root health route. The prescription route accepts multipart form data. Authenticated requests use a bearer access token. The report summary accepts optional from and to dates. A public report read uses a random bearer token and does not require a user session.",
        "For external services, the code should define timeout, consent, privacy, failure, and observability requirements before integration. Environment examples mention Supabase storage, Redis, Gemini, FCM, and Twilio, but the Pydantic settings and current endpoints do not implement these client adapters. No data should be sent to a third party until the configuration and user-facing disclosure are complete.",
        table=("Table 3.10. Integration status", ["Integration", "Present in environment example", "Runtime code"], [
            ["PostgreSQL", "Yes", "Supported through DATABASE_URL and asyncpg"],
            ["Redis", "Yes", "URL setting only; no current use found"],
            ["Object storage", "Yes", "No upload/storage adapter found"],
            ["Gemini or OCR", "Yes", "No provider call; mock response"],
            ["FCM or Twilio", "Yes", "No message dispatcher"],
        ]),
        source=["infra/.env.example", "services/api/app/core/config.py", "services/api/app/services/ai_service.py", "services/api/app/api/v1/endpoints/emergency.py"],
    )
    add_page(
        "chapter_3_26", "3.11 Ethical, Legal, and Operational Constraints",
        "The system processes phone numbers, medication information, vital readings, and emergency contact details. These records are sensitive and should be restricted to the user and authorized caregiver. The app must communicate uncertainty and must not represent automated labels as medical diagnosis or treatment advice.",
        "The repository includes a medical disclaimer in the report output and production configuration guards. It does not contain a full consent flow, account deletion workflow, data-retention job, field encryption implementation, production TLS termination, audit trail, or legal review record. These are operational controls that must be completed before a real deployment handles patient data.",
        bullets=["Collect only the data required for the selected feature.", "Do not log raw credentials, OTP values, refresh tokens, or unnecessary health details.", "Confirm the patient's consent and caregiver access policy before linking accounts.", "Document retention, deletion, incident response, and service-provider agreements."],
        source=["docs/SECURITY.md", "services/api/app/core/config.py", "services/api/app/models/user.py", "apps/mobile/lib/features/reports/data/reports_repository.dart"],
    )
    add_page(
        "chapter_3_27", "3.12 Requirements Traceability Matrix",
        "Traceability connects each user need to a screen, API route, schema or model, and test evidence. A complete chain makes change review easier: if a status changes, the reviewer can identify all layers that must change. The matrix below is intentionally concise; detailed test identifiers are listed in Appendix E.",
        "Traceability also reveals partial flows. FR-RX is covered by a client review test and a backend endpoint test, but those tests exercise fixed sample data rather than image recognition. FR-SOS is covered through confirmation and API request behavior, but no test proves contact delivery because delivery is not implemented.",
        table=("Table 3.11. Requirement traceability", ["Requirement", "Client", "API/data", "Test evidence"], [
            ["FR-AUTH", "Phone/OTP screens", "auth routes and sessions", "Auth and client tests"],
            ["FR-MED", "Medication forms and lists", "medications/schedules", "Repository and widget tests"],
            ["FR-CARE", "Pairing and dashboard", "caregiver links/alerts", "Pairing and API tests"],
            ["FR-VITAL", "Vitals and voice confirm", "vitals and triage", "Triage/API/widget tests"],
            ["FR-RX", "Image review screen", "Mock scan endpoint", "Review test; no OCR test"],
            ["FR-SOS", "Confirmed button", "Alert record", "Button test; no delivery test"],
            ["FR-REPORT", "Share/print PDF", "Summary/share routes", "PDF and API tests"],
        ]),
        source=["apps/mobile/test", "services/api/tests", "services/api/app/api/v1/endpoints", "apps/mobile/lib/features"],
    )
    add_page(
        "chapter_3_28", "3.13 Chapter Summary",
        "The requirements chapter defines twelve feature groups and cross-cutting constraints for security, accessibility, reliability, and maintainability. The current implementation provides the core screen and API path for several features but leaves external delivery and lifecycle integration incomplete.",
        "The requirements that matter most for the next release are the ones whose partial state affects trust: account role provisioning, auth bypass configuration, full-dose offline behavior, reminder lifecycle wiring, real prescription extraction with evaluation, SOS notification dispatch, and clear consent and retention controls. Chapter 4 maps these requirements to components and data flows.",
        source=["Traceability matrix in this chapter and Appendix A"],
    )

    add_page(
        "chapter_4_1", "4.1 Design Goals and Architectural Principles",
        "The design aims to keep the user interaction simple, centralize identity and access decisions in the API, keep client feature code grouped by domain, and represent requests with explicit schemas. The client uses repositories to isolate network calls from widgets. The backend uses endpoint modules, shared dependencies, schema classes, models, and service helpers.",
        "A second goal is to make limitations visible. Several helpers represent a future extension point, but the runtime should not depend on an unconnected class. The architecture described here therefore separates the active request path from partial components such as the local reminder planner, offline adherence queue, and public report sharing API.",
        table=("Table 4.1. Design goals", ["Goal", "Design mechanism", "Current status"], [
            ["Role-aware navigation", "GoRouter redirect from auth state", "Implemented with auth bypass default"],
            ["Patient data isolation", "check_patient_access dependency", "Implemented for scoped routes"],
            ["Feature isolation", "Repository and presentation modules", "Generally implemented"],
            ["Offline resilience", "Secure queue plus sync endpoint", "Partial; not connected"],
            ["External alert delivery", "Device token or SMS providers", "Not implemented"],
        ]),
        chapter=("Chapter 4 - System Analysis and Architectural Design", "chapter_4", "This chapter explains the components, trust boundaries, information flows, and design trade-offs visible in the repository."),
        source=["apps/mobile/lib/core", "apps/mobile/lib/features", "services/api/app"],
    )
    add_page(
        "chapter_4_2", "4.2 Overall System Architecture",
        "The current system is a two-process client/server application. The Flutter app handles presentation, local state, input validation, platform plugin calls, and PDF construction. The FastAPI service provides JSON endpoints, validation, bearer authentication, patient access checks, business rules, and database operations.",
        "The service can run locally against SQLite. The settings also allow an async PostgreSQL URL, and Alembic migrations exist for schema evolution. The current repository does not include an API container image, a deployment manifest, object storage adapter, or task worker. Cloud service references in environment examples are configuration templates, not running infrastructure.",
        figure=("Figure 4.1. Current system context", ["Patient or caregiver", "Flutter client", "FastAPI REST API", "SQLAlchemy session", "SQLite or PostgreSQL"]),
        source=["services/api/app/main.py", "services/api/app/db/session.py", "apps/mobile/lib/main.dart", "infra/docker-compose.yml"],
    )
    add_page(
        "chapter_4_3", "4.3 Component Responsibilities",
        "The mobile core provides build configuration, token storage, request interception, routing, theming, and localization. Feature directories provide domain models, repositories, notifiers, and screens. The backend core provides settings, token verification, role checks, patient access, phone normalization, and standard error responses.",
        "Feature endpoints call service helpers for triage and stock forecasts where calculations are reused. SQLAlchemy models define persistence. Pydantic schemas define API input and output. Alembic migrations align the deployed schema with models. This division is compact enough for an MVP while preserving clear seams for future providers and domain services.",
        table=("Table 4.2. Component map", ["Component", "Primary responsibility", "Representative source"], [
            ["ApiClient", "Bearer header, refresh, retry, error conversion", "apps/mobile/lib/core/network"],
            ["Feature repositories", "Serialize calls and map response models", "apps/mobile/lib/features/*/data"],
            ["Endpoint routers", "Validate, authorize, execute business flow", "services/api/app/api/v1/endpoints"],
            ["Schemas", "Request and response contract", "services/api/app/schemas"],
            ["Models and migrations", "Persistent records and schema changes", "services/api/app/models; alembic/versions"],
        ]),
        source=["apps/mobile/lib/core/network/api_client.dart", "services/api/app/api/v1/router.py", "services/api/app/models"],
    )
    add_page(
        "chapter_4_4", "4.4 Mobile Client Architecture",
        "The Flutter application starts with a ProviderScope and MaterialApp.router. Riverpod constructs shared repositories and notifiers. GoRouter maps named paths to screens and observes authentication state. Dio is configured with a base URL, 15-second connection and receive timeouts, a JSON content type, and request/response interceptors.",
        "The selected patient ID is computed from the signed-in patient's own ID or held as an in-memory selection for a caregiver. It is not persisted. In a developer build, SKIP_AUTH is true by default; that path navigates to a generic home route even when no user has been loaded. For an authenticated feature demo, the flag must be disabled and the API URL must point to a reachable service.",
        figure=("Figure 4.2. Mobile request layers", ["Screen", "Riverpod provider", "Feature repository", "ApiClient and Dio", "FastAPI endpoint"]),
        source=["apps/mobile/lib/main.dart", "apps/mobile/lib/core/router/app_router.dart", "apps/mobile/lib/features/auth/presentation/auth_notifier.dart"],
    )
    add_page(
        "chapter_4_5", "4.5 Backend Architecture and Request Lifecycle",
        "The FastAPI factory reads settings, creates the application, configures CORS and error handlers, registers a health route, and includes the v1 router under the configured prefix. The lifespan creates tables automatically only when the configured URL contains SQLite; the PostgreSQL path relies on migrations.",
        "A normal request passes through Pydantic validation, an endpoint function, dependencies such as get_current_user or check_patient_access, a request-scoped AsyncSession, and a response model. Domain errors are returned in a common error envelope. Development documentation endpoints are disabled in production configuration.",
        figure=("Figure 4.3. Backend request path", ["HTTP request", "FastAPI route", "Schema and dependencies", "Endpoint and service", "Database response"]),
        source=["services/api/app/main.py", "services/api/app/api/v1/router.py", "services/api/app/core/errors.py", "services/api/app/db/session.py"],
    )
    add_page(
        "chapter_4_6", "4.6 Persistence Model and Relationships",
        "The current database has fourteen SQLAlchemy entity classes: users, OTP challenges, refresh sessions, caregiver links, drug catalog entries, medications, schedules, intake logs, vital logs, prescriptions, emergency contacts, alerts, report shares, and devices. Most records inherit a UUID ID and timestamps from a shared mixin.",
        "Foreign keys connect patient-owned records to users and schedules to medications. Intake logs have a unique client UUID, report shares have a unique token hash, device tokens are unique, and caregiver pairs have a unique caregiver/patient combination. The model uses string-backed enumerations for roles, link state, medication meal relation, intake status, vital type/band, and alert type.",
        table=("Table 4.3. Principal data relationships", ["Parent", "Child", "Relationship purpose"], [
            ["User", "Medication", "Patient's medication list"],
            ["Medication", "Schedule", "Recurring dose instructions"],
            ["Schedule and User", "IntakeLog", "Scheduled and actual dose outcome"],
            ["User", "VitalsLog", "Patient measurement history"],
            ["User", "CaregiverLink", "Patient/caregiver relationship"],
            ["User", "EmergencyContact / Alert / ReportShare", "Care and sharing records"],
        ]),
        source=["services/api/app/models", "services/api/app/db/base.py", "services/api/alembic/versions/2026_10_23_0003_domain_models.py"],
    )
    add_page(
        "chapter_4_7", "4.7 Authentication and Session Design",
        "The OTP challenge contains a phone, HMAC-SHA256 code hash, expiry, attempt count, and optional consumed timestamp. A refresh session stores a user ID, token identifier, SHA-256 fingerprint, expiration, and revoked timestamp. The API issues separate access and refresh JWTs and identifies their type in claims.",
        "On refresh, the API locks and validates the stored session, checks that it is not revoked or expired and that the raw token matches the saved hash, marks it revoked, then creates a new pair. The client calls the refresh endpoint with a separate Dio client to avoid interceptor recursion, stores the replacement pair, and retries the original request only once.",
        table=("Table 4.4. Session controls", ["Control", "Implementation"], [
            ["Challenge expiry", "Five minutes by default"],
            ["Request throttling", "Five OTP requests per phone per hour by default"],
            ["Resend cooldown", "Sixty seconds by default"],
            ["Wrong-code limit", "Five attempts per challenge by default"],
            ["Access token lifetime", "Fifteen minutes by default"],
            ["Refresh lifetime", "Thirty days by default with rotation"],
        ]),
        source=["services/api/app/core/security.py", "services/api/app/api/v1/endpoints/auth.py", "services/api/app/core/config.py", "apps/mobile/lib/core/network/api_client.dart"],
    )
    add_page(
        "chapter_4_8", "4.8 Authorization and Patient Access Boundary",
        "The patient-access helper permits a user to access their own patient ID, permits an admin role, or queries for an active caregiver link between the caller and the requested patient. Medication-scoped routes resolve the medication or schedule to its patient before applying the same boundary. The security test module asserts that an unrelated authenticated user receives a forbidden response across patient-scoped routes.",
        "The access boundary is a meaningful safeguard, but authorization policy remains coarse. The caregiver link's permissions_mask is not decoded by the helper, so an active link effectively grants broad patient-level access. The current system does not present a caregiver permission editor, nor an endpoint to revoke a link from the mobile interface.",
        callout=("Threat boundary", "A valid account or JWT is not sufficient to read another patient's records. The request must pass the patient access check as well."),
        source=["services/api/app/core/deps.py", "services/api/app/models/caregiver.py", "services/api/tests/test_security_access.py"],
    )
    add_page(
        "chapter_4_9", "4.9 Medication and Adherence Sequence",
        "When the patient opens the daily view, the client requests the current day's dose list. The API evaluates active medications and schedules, combines the schedule with any intake logs, and returns a status for each displayed dose. The patient selects Taken or Skip; the client posts an IntakeLogCreate payload with a client UUID and timestamps.",
        "The backend associates the log with the schedule and patient, validates access, records the status, and updates relevant inventory state. The UI refreshes its provider to reflect the recorded action. The current screen's request path does not invoke the secure offline queue, so a network error is surfaced instead of silently staging the dose action.",
        figure=("Figure 4.4. Medication confirmation sequence", ["Daily screen", "GET today's doses", "Patient action", "POST adherence log", "Refresh status"]),
        source=["services/api/app/api/v1/endpoints/medications.py", "services/api/app/api/v1/endpoints/adherence.py", "apps/mobile/lib/features/medications/presentation/screens/today_screen.dart"],
    )
    add_page(
        "chapter_4_10", "4.10 Caregiver Pairing and Escalation Sequence",
        "A patient requests a pairing code that is valid for ten minutes. The caregiver submits the code; the server checks the caller role, code, expiry, and self-pairing case, then activates the link. The caregiver dashboard lists linked patients and requests a summary computed from today's active schedules and records.",
        "The escalation rule in current code is a pull-based calculation: a dose with no log after fifteen minutes is returned as a missed-dose alert. There is no background worker, scheduled cron job, push delivery, or websocket update. Historical planning documents describe later notification tiers, but those are not part of the active implementation.",
        figure=("Figure 4.5. Current caregiver alert flow", ["Pairing code", "Active caregiver link", "Dashboard request", "15-minute rule", "Alert shown in response"]),
        source=["services/api/app/api/v1/endpoints/caregiver.py", "apps/mobile/lib/features/caregiver/presentation/screens/pairing_screens.dart", "apps/mobile/lib/features/caregiver/presentation/screens/caregiver_dashboard_screen.dart"],
    )
    add_page(
        "chapter_4_11", "4.11 Vital Recording and Classification Sequence",
        "Manual vital entry submits a type, primary and optional secondary value, and meal context to the patient vitals route. The server calls the triage service, stores the calculated band and timestamp, and returns the record. The mobile screen displays the classification with text and icon as well as color.",
        "For voice input, speech recognition first runs on the device. The transcript is parsed by a deterministic backend helper and shown in an editable dialog. The dialog must be confirmed before the repository creates a vital. This design keeps the user in the decision loop while making clear that parser output may be uncertain.",
        figure=("Figure 4.6. Vital entry sequence", ["Manual or dictated input", "Validate and parse", "Calculate triage band", "Confirm values", "Persist vital"]),
        source=["services/api/app/api/v1/endpoints/vitals.py", "services/api/app/services/triage.py", "apps/mobile/lib/features/vitals/presentation/screens/voice_vital_entry.dart"],
    )
    add_page(
        "chapter_4_12", "4.12 Prescription Review Sequence",
        "The mobile screen asks the platform image picker for a camera or gallery image, reads the selected file bytes, posts a multipart request, and maps the response into editable medicine candidates. The user can cancel or select and edit candidate fields before creation. The current review flow only creates items after explicit confirmation.",
        "On the server, the route queries the catalog and calls a mock extraction function without consuming the uploaded bytes. The returned sample medicine list is stable regardless of the input image. The architecture has a clean point for replacing the mock, but the replacement needs document parsing, confidence calibration, abuse controls, file size/type validation, and a reviewed error state.",
        figure=("Figure 4.7. Current prescription scan flow", ["Camera or gallery", "Multipart request", "Fixed sample candidates", "Review and edit", "Create selected medicines"]),
        source=["services/api/app/api/v1/endpoints/ai.py", "services/api/app/services/ai_service.py", "apps/mobile/lib/features/prescription"],
    )
    add_page(
        "chapter_4_13", "4.13 Inventory Forecast and Refill Sequence",
        "The API loads active medications and their schedules, sums active dose amounts, divides current stock by that total to estimate days remaining, and reports low-stock and expiry flags. The refill endpoint builds an Arabic message from patient name, items, address, and note, then URL-encodes the text for a WhatsApp URL.",
        "The forecast uses calendar date and a simplified daily-consumption sum. It does not apply the schedule day mask, start date, end date, or varying weekday pattern. The mobile screen detects fewer than seven days left in addition to the API's configured low-stock threshold, requests a refill message, and shows that text; it does not open the returned URL.",
        figure=("Figure 4.8. Refill preparation path", ["Stock and schedules", "Forecast calculation", "Refill request", "Message and URL", "User sees message"]),
        source=["services/api/app/services/inventory.py", "services/api/app/api/v1/endpoints/inventory.py", "apps/mobile/lib/features/inventory/presentation/screens/inventory_screen.dart"],
    )
    add_page(
        "chapter_4_14", "4.14 Emergency Contacts and SOS Sequence",
        "The contact screen lists and creates contact records. The patient shell shows the SOS control. A long press opens a confirmation dialog; after confirmation, the client checks whether location permission is already granted, attempts to get coordinates, and sends the SOS request with optional coordinates.",
        "The endpoint always attributes the SOS record to the authenticated caller, counts saved contacts and active caregiver links, stores a JSON payload in an Alert row, and returns active status plus an alert ID and count. It does not call any messaging service. Contact flags for SMS and call are stored but do not trigger a call or message.",
        figure=("Figure 4.9. SOS record flow", ["Long press", "Confirm dialog", "Optional location", "POST SOS", "Persist alert"]),
        source=["apps/mobile/lib/features/emergency/presentation/widgets/sos_button_widget.dart", "services/api/app/api/v1/endpoints/emergency.py", "services/api/app/models/emergency.py"],
    )
    add_page(
        "chapter_4_15", "4.15 Doctor Report Generation and Sharing",
        "The mobile report screen requests the authenticated report summary for the selected patient. The API uses a default thirty-day range unless query dates are provided, returns patient details, active medications, adherence logs, a rate, and vitals. The app builds a PDF from the response and invokes the platform share sheet with a patient-ID-based filename.",
        "The PDF contains medication, adherence, and vital tables plus a disclaimer. It is English-only, uses a built-in Helvetica font by default, and transliterates Arabic characters into Latin approximations. The screen does not currently expose a date selector, QR code, or public share token. The backend public share API is separate from this file-sharing path.",
        figure=("Figure 4.10. Report export flow", ["Select patient", "GET summary", "Build PDF bytes", "Preview or share sheet", "Doctor receives file"]),
        source=["services/api/app/api/v1/endpoints/reports.py", "apps/mobile/lib/features/reports/data/reports_repository.dart", "apps/mobile/lib/features/reports/presentation/screens/doctor_report_screen.dart"],
    )
    add_page(
        "chapter_4_16", "4.16 Offline Queue and Reminder Planner Boundaries",
        "Two mobile helper modules address time-sensitive and offline use. LocalReminderService initializes time-zone data, builds today's upcoming reminders, and schedules Android notifications. OfflineAdherenceQueue persists serialized items through secure storage and flushes them through a connectivity stream and syncBatch call.",
        "Neither module is referenced by the active TodayScreen or application startup. The notification service only plans future reminders from the current day's dose list and does not establish boot restoration or tomorrow's schedules. These modules should be connected through lifecycle-aware providers and tested end-to-end before the application is described as offline-first or as providing reliable medication alarms.",
        table=("Table 4.5. Runtime wiring audit", ["Module", "Available behavior", "Missing connection"], [
            ["LocalReminderService", "Exact Android schedule, repeats, cancellation helper", "No app startup or screen call"],
            ["OfflineAdherenceQueue", "Secure JSON queue and batch flush", "No provider or TodayScreen use"],
            ["Device endpoint", "Register/update FCM token", "No Flutter caller"],
            ["Report share endpoint", "Issue expiring token", "Report screen uses file share"],
        ]),
        source=["apps/mobile/lib/features/medications/data/medication_reminder_planner.dart", "apps/mobile/lib/features/medications/data/offline_adherence_queue.dart", "apps/mobile/lib/features/medications/presentation/screens/today_screen.dart"],
    )
    add_page(
        "chapter_4_17", "4.17 Errors, Configuration, and Observability",
        "The API converts domain errors, HTTP errors, and request-validation errors into a consistent JSON envelope. The client extracts the returned message and code and applies connection and receive timeouts. The health route returns application status, name, and environment but does not check database or external dependency health.",
        "Configuration is loaded from environment variables and optional repository env files. Production validation rejects insecure defaults for JWT secret, OTP response, CORS, and SQLite. No metrics exporter, structured request logging, distributed tracing, alerting, or operational dashboard is present in the current repository. Error messages are localized on the API side in Arabic, while some mobile error display paths show raw exception text.",
        source=["services/api/app/core/config.py", "services/api/app/core/errors.py", "services/api/app/main.py", "apps/mobile/lib/core/network/api_client.dart"],
    )
    add_page(
        "chapter_4_18", "4.18 Security Threat Model and Control Status",
        "The main assets are phone numbers, credentials, medication plans, intake history, vital readings, emergency contact details, share tokens, and device tokens. The main threats include stolen bearer tokens, cross-patient access, insecure production configuration, unintended disclosure through a public report link, and an emergency flow that is mistaken for message delivery.",
        "Controls visible in source include OTP rate and attempt limits, hashed challenge values, short-lived access JWTs, rotating refresh sessions, protected client token storage, server-side patient access checks, and a production-settings validator. Controls listed in older security notes such as pgcrypto, SQLCipher, signed object URLs, consent, deletion, and audit logs are not demonstrated by current code.",
        table=("Table 4.6. Security claim ledger", ["Control", "Evidence status"], [
            ["OTP throttling and expiry", "Implemented in API"],
            ["Refresh token rotation and hash storage", "Implemented in API"],
            ["Patient route access checks", "Implemented and covered by security tests"],
            ["Fine-grained caregiver permissions", "Mask stored; enforcement absent"],
            ["Database field encryption and audit trail", "Not found in current code"],
            ["Production TLS termination", "Deployment not included; cannot verify"],
        ]),
        source=["services/api/app/core/security.py", "services/api/app/core/deps.py", "services/api/app/core/config.py", "docs/SECURITY.md"],
    )
    add_page(
        "chapter_4_19", "4.19 User Interface and Accessibility Design",
        "The app uses a high-contrast medical teal theme, Cairo font family, large headline and primary button typography, padded tap targets, rounded cards, and directional layout spacing. The patient home shows today's doses and an SOS control; the caregiver home shows linked-patient information. Medication and profile screens are reachable from top-bar actions.",
        "Although routes exist for vitals, contacts, inventory, prescription scan, pairing, and doctor report, the main home shell does not expose all of them through visible navigation controls. A user may need a direct route or an undisplayed entry point to reach those screens. A navigation review should map each feature to an intentional user journey rather than treating route registration as discoverability.",
        table=("Table 4.7. Accessibility design evidence", ["Pattern", "Current evidence", "Review need"], [
            ["Language", "Arabic and English ARB resources", "Check every new key and screen"],
            ["Touch size", "Padded Material controls and 48/60 px buttons", "Audit custom controls on device"],
            ["Semantic state", "Labels and selected state on selected controls", "Screen-reader review across all flows"],
            ["Directionality", "Directional padding and icons in several screens", "Review every table, form, and icon"],
            ["Navigation", "Routes exist for all feature screens", "Several routes not visible from home"],
        ]),
        source=["apps/mobile/lib/core/theme/app_theme.dart", "apps/mobile/lib/core/router/app_router.dart", "apps/mobile/lib/features/home/presentation/screens/home_screen.dart"],
    )
    add_page(
        "chapter_4_20", "4.20 Design Decisions and Trade-Offs",
        "The MVP uses a modular monolith instead of separate services. This reduces deployment complexity and keeps domain routes close to shared models and access dependencies. The client uses feature repositories and a shared API client instead of each screen constructing raw HTTP calls. The doctor web portal was dropped in favor of a file generated inside the mobile app.",
        "The trade-offs include a larger blast radius in one API process, reliance on one shared relational schema, and stronger coupling between client and response contracts. The prototype gains breadth quickly, but unfinished integrations can obscure the trust boundary unless UI labels and operational runbooks are explicit. A future split into services should be driven by deployment and scaling evidence, not by directory count.",
        table=("Table 4.8. Decision record summary", ["Decision", "Benefit", "Trade-off"], [
            ["Modular monolith", "Simple local setup and shared access controls", "Shared release and database lifecycle"],
            ["In-app PDF report", "No separate clinician portal account", "Limited interactivity and date selection"],
            ["Deterministic triage", "Explainable, repeatable code path", "Threshold validity and context limitations"],
            ["Secure-storage queue helper", "Small persistence seam for retries", "Not a complete local database"],
            ["OTP dev response", "Easy local development", "Must remain disabled outside development"],
        ]),
        source=["docs/EXECUTION_PLAN.md", "apps/doctor-portal/README.md", "services/api/app/services/triage.py", "services/api/app/core/config.py"],
    )
    add_page(
        "chapter_4_21", "4.21 Chapter Summary",
        "The architecture consists of a bilingual Flutter client and a FastAPI modular monolith backed by SQLAlchemy models and migrations. Server-side dependencies enforce authentication and patient access, while feature repositories keep client request code organized.",
        "The architecture also has explicit gaps: no deployed cloud environment, no complete local database, unconnected reminder and queue modules, no outbound emergency or push dispatcher, and no real image extraction provider. Chapter 5 describes the actual implementation package by package and shows how to run the development baseline.",
        source=["Current mobile, API, and infra source"],
    )

    add_page(
        "chapter_5_1", "5.1 Development Environment and Technology Stack",
        "The API targets Python 3.12 or later within the declared version range and uses FastAPI, Uvicorn, SQLAlchemy's async extension, Alembic, Pydantic Settings, PyJWT, RapidFuzz, and python-multipart. Development dependencies include pytest, pytest-asyncio, HTTPX, aiosqlite, and Ruff.",
        "The mobile client uses Flutter with Riverpod, GoRouter, Dio, secure storage, localization, Cairo via Google Fonts, local notifications, timezone data, connectivity_plus, speech_to_text, image_picker, geolocator, pdf, printing, and mocktail-based tests. The package manifest expresses allowed version ranges; actual locked package versions are recorded in the lockfiles.",
        table=("Table 5.1. Technology stack", ["Area", "Technology", "Use"], [
            ["Mobile", "Flutter / Dart", "Cross-platform user interface"],
            ["State/navigation", "Riverpod / GoRouter", "Provider state and route transitions"],
            ["HTTP client", "Dio", "REST requests and token refresh"],
            ["Backend", "FastAPI / Pydantic", "Async API and schema validation"],
            ["Persistence", "SQLAlchemy / Alembic", "ORM mapping and schema migrations"],
            ["Testing", "pytest / flutter_test / mocktail", "API, unit, and widget tests"],
        ]),
        chapter=("Chapter 5 - System Implementation and Integration", "chapter_5", "This chapter records implemented modules, package roles, development setup, and integration status."),
        source=["apps/mobile/pubspec.yaml", "services/api/pyproject.toml", "services/api/uv.lock", "apps/mobile/pubspec.lock"],
    )
    add_page(
        "chapter_5_2", "5.2 Repository Structure",
        "The repository separates the mobile client, backend API, documentation, optional infrastructure examples, and a reserved doctor-portal folder. The mobile code is under apps/mobile/lib. The backend code is under services/api/app, with Alembic migrations and pytest suites beside it. Current API and mobile READMEs contain some older descriptions; source code should be used when those descriptions conflict.",
        "The feature structure is a mix of core services and domain folders. Mobile feature directories include auth, caregiver, emergency, home, inventory, medications, prescription, reports, and vitals. Backend endpoint modules group auth, users, caregiver, medications, adherence, vitals, AI, inventory, emergency, reports, and devices.",
        table=("Table 5.2. Repository areas", ["Path", "Role"], [
            ["apps/mobile/lib/core", "Configuration, network, storage, router, theme, utilities"],
            ["apps/mobile/lib/features", "Patient and caregiver feature modules"],
            ["services/api/app/api/v1/endpoints", "HTTP route modules"],
            ["services/api/app/models and schemas", "Persistence and request/response contracts"],
            ["services/api/tests and apps/mobile/test", "Automated test source"],
            ["docs", "Plans, contracts, architecture notes, and this report"],
        ]),
        source=["apps/mobile/lib", "services/api/app", "services/api/tests", "apps/mobile/test"],
    )
    add_page(
        "chapter_5_3", "5.3 Application Configuration and Startup",
        "The API settings load environment variables and optional files under infra/.env and services/api/.env. The default environment is development, the API prefix is /api/v1, and the default database URL points to a local SQLite file. Production validation requires explicit trusted CORS origins, a non-default secret of sufficient length, disabled OTP response delivery, and PostgreSQL.",
        "The mobile API URL is supplied through the API_BASE_URL compile-time define and defaults to an Android emulator address. The SKIP_AUTH compile-time flag defaults to true and bypasses login routing for local UI work. For an integrated authentication demonstration, the flag must be set false. The app's default base URL and role bypass should not be copied into a store or production build without explicit configuration.",
        table=("Table 5.3. Important configuration values", ["Variable or flag", "Default / effect", "Usage note"], [
            ["ENV", "dev", "Use prod only after secure configuration"],
            ["DATABASE_URL", "Local SQLite async URL", "PostgreSQL is required in prod"],
            ["JWT_SECRET", "Development-only placeholder", "Must be replaced in prod"],
            ["OTP_RETURN_IN_RESPONSE", "true in example development config", "Production validator rejects true"],
            ["API_BASE_URL", "10.0.2.2:8000/api/v1", "Android emulator default"],
            ["SKIP_AUTH", "true", "Set false to exercise OTP/session routes"],
        ]),
        source=["services/api/app/core/config.py", "infra/.env.example", "apps/mobile/lib/core/config/app_config.dart", "apps/mobile/lib/core/router/app_router.dart"],
    )
    add_page(
        "chapter_5_4", "5.4 API Application and Routing Implementation",
        "The create_app factory sets the project title, exposes OpenAPI, Swagger UI, and ReDoc in non-production mode, configures credentialed CORS, registers normalized error handlers, defines /health, and includes API v1 routes. In local SQLite mode, startup calls SQLAlchemy metadata create_all; production databases use Alembic migrations.",
        "The v1 router includes eleven endpoint modules. Their route prefix is applied once by the factory, while endpoint groups declare local prefixes such as /auth, /caregiver, and /ai. Request and response models are Pydantic classes, allowing FastAPI to validate input and serialize typed output.",
        source=["services/api/app/main.py", "services/api/app/api/v1/router.py", "services/api/app/schemas"],
    )
    add_page(
        "chapter_5_5", "5.5 API Authentication Implementation",
        "OTP requests normalize the phone number to an Egyptian E.164-style form, count challenges created within the preceding hour, and enforce a resend cooldown. Codes are generated from numeric digits and stored as an HMAC hash. Verification checks expiry, attempt limits, and the code hash before consuming the challenge.",
        "After verification, the service retrieves or creates a user, creates an access and refresh JWT, and persists the refresh session fingerprint. Refresh rotates the session; logout revokes it when valid and returns 204 for invalid or expired tokens. The SMS provider is not called: the development response may include the code, while production validation requires it to be disabled.",
        figure=("Figure 5.1. OTP sign-in sequence", ["Normalize phone", "Request OTP", "Verify hash and expiry", "Issue token pair", "Store refresh fingerprint"]),
        source=["services/api/app/api/v1/endpoints/auth.py", "services/api/app/core/phone.py", "services/api/app/core/security.py"],
    )
    add_page(
        "chapter_5_6", "5.6 Mobile Authentication and Profile Implementation",
        "The mobile client validates and normalizes Egyptian mobile numbers before requesting an OTP. The OTP screen optionally collects a name for first registration, submits the code, stores the returned token pair, loads /me, and updates the notifier with the resulting user. The profile screen sends supported name and language changes to PATCH /me.",
        "On application startup, the auth notifier reads the access token from secure storage and requests /me. If the request fails, it clears stored tokens and returns an unauthenticated state. The router watches the notifier to redirect between splash, login, patient shell, and caregiver shell, subject to the development bypass flag.",
        source=["apps/mobile/lib/features/auth", "apps/mobile/lib/core/storage/token_storage.dart", "apps/mobile/lib/core/router/app_router.dart", "apps/mobile/test/features/auth/profile_screen_test.dart"],
    )
    add_page(
        "chapter_5_7", "5.7 Medication, Schedule, and Adherence Implementation",
        "MedicationRepository maps list, create, update, deactivate, schedule list/create, daily doses, adherence logging, and sync batch operations to API routes. Model constructors map snake_case JSON keys into Dart properties. Notifiers load feature data and refresh screen state after user actions.",
        "Medication creation may include schedule fields. The schedule editor can add a time, the medication list uses a confirmation dialog before deactivation, and the Today screen presents status cards with Taken and Skip actions. The API uses soft deactivation so prior logs and relationships remain stored. Stock reduction occurs in the adherence path for taken doses, subject to the endpoint's business logic.",
        table=("Table 5.4. Medication client operations", ["Operation", "HTTP route"], [
            ["List active medicines", "GET /patients/{patient_id}/medications"],
            ["Create medicine", "POST /patients/{patient_id}/medications"],
            ["Edit or deactivate", "PATCH or DELETE /medications/{medication_id}"],
            ["Read or add a schedule", "GET/POST /medications/{medication_id}/schedules"],
            ["Read today's doses", "GET /patients/{patient_id}/today"],
            ["Record a dose", "POST /adherence/log"],
        ]),
        source=["apps/mobile/lib/features/medications", "services/api/app/api/v1/endpoints/medications.py", "services/api/app/api/v1/endpoints/adherence.py"],
    )
    add_page(
        "chapter_5_8", "5.8 Caregiver API and Mobile Screens",
        "CaregiverRepository wraps pairing-code creation, code redemption, linked patient listing, and caregiver data. The patient code screen displays a six-digit value from the API. The caregiver pairing screen submits the value. The dashboard shows linked patient cards and selects the patient ID for subsequent reads.",
        "The API computes daily adherence and alerts during the GET request. The mobile selected patient state is memory-only, so a caregiver who restarts the app may need to choose the patient again. There is no visible revoke-link screen, caregiver permission editor, or independent role enrollment route in the current app.",
        source=["apps/mobile/lib/features/caregiver", "services/api/app/api/v1/endpoints/caregiver.py", "apps/mobile/test/features/caregiver"],
    )
    add_page(
        "chapter_5_9", "5.9 Vital Records and Triage Implementation",
        "VitalsRepository maps list and create routes, plus the text parser route. VitalsNotifier loads the current patient history and submits a new reading. The backend triage module returns a band and a message; create_vital persists both with values and context. The list endpoint can filter by type and limit.",
        "The voice flow is split into device capture, API parse, editable confirmation, and record creation. The app uses ar_EG for Arabic locale and en_US for English. Capture waits for a short fixed interval and then stops listening. There is no clinical calibration routine or server-side model confidence in this path.",
        source=["apps/mobile/lib/features/vitals", "services/api/app/services/triage.py", "services/api/app/api/v1/endpoints/vitals.py", "services/api/tests/test_vitals_and_triage.py"],
    )
    add_page(
        "chapter_5_10", "5.10 Prescription Service Implementation",
        "The mobile repository reads the selected image bytes and builds a multipart form payload. The screen maps response items into editable controls, allows a selection, and creates a medication with derived schedule entries after confirmation. The model carries candidate name, dosage, frequency, meal relation, times, stock count, confidence, and active ingredient.",
        "The backend AI service includes a small static Egyptian medicine candidate list, a RapidFuzz name matcher, a deterministic spoken-number parser, and a mock prescription function. The scan endpoint obtains catalog rows but invokes the mock without passing the uploaded file. The current module is a prototype seam for later OCR, not a live AI integration.",
        callout=("Data safety", "Do not use the current scan response to populate a real medication plan without independent verification; its values are fixed sample output."),
        source=["services/api/app/services/ai_service.py", "services/api/app/api/v1/endpoints/ai.py", "apps/mobile/lib/features/prescription"],
    )
    add_page(
        "chapter_5_11", "5.11 Inventory, Emergency, and Device Services",
        "The inventory service calculates a simple forecast and builds a localized refill message. The emergency service persists contacts and SOS alert records. The devices endpoint creates or updates a device row by FCM token. These modules demonstrate route and model structure for the related workflows.",
        "The inventory client does not navigate to WhatsApp after receiving the URL. The emergency endpoint does not dispatch to the contacts or caregivers it counts. The mobile client does not call /devices. Contact preferences for notification by SMS or call are stored but no transport implementation consumes them. These services require additional provider integrations before production use.",
        table=("Table 5.5. Service integration status", ["Feature", "Implemented", "Still missing"], [
            ["Inventory forecast", "API calculation and screen cards", "Calendar-aware dosing and launched order link"],
            ["Emergency contacts", "CRUD reads and creates", "Edit/delete and contact dispatch"],
            ["SOS", "Confirmed request and alert record", "SMS, call, FCM delivery and receipt status"],
            ["Device registration", "API token record", "Mobile token acquisition and FCM sender"],
        ]),
        source=["services/api/app/api/v1/endpoints/inventory.py", "services/api/app/api/v1/endpoints/emergency.py", "services/api/app/api/v1/endpoints/devices.py", "apps/mobile/lib/features/inventory", "apps/mobile/lib/features/emergency"],
    )
    add_page(
        "chapter_5_12", "5.12 Report API and PDF Implementation",
        "The report summary endpoint accepts optional inclusive date bounds, fetches the patient and active medication list, collects schedules, intake logs, and vital records, and returns a ReportSummaryOut. When no dates are supplied it uses the current UTC date and a start date thirty days earlier.",
        "The mobile builder creates a multipage A4 PDF with three tables and a disclaimer. It uses a built-in Helvetica face unless a custom font is passed. Arabic characters are mapped to approximate Latin sequences and the report direction is fixed left-to-right. The report UI currently shows the default date range and shares bytes via Printing.sharePdf.",
        source=["services/api/app/api/v1/endpoints/reports.py", "services/api/app/schemas/reports.py", "apps/mobile/lib/features/reports/data/reports_repository.dart", "apps/mobile/lib/features/reports/presentation/screens/doctor_report_screen.dart"],
    )
    add_page(
        "chapter_5_13", "5.13 Mobile Routes and Home Shell",
        "GoRouter defines authentication routes, patient and caregiver shells, profile, medication list/form/detail, caregiver pairing, vitals, prescription scan, contacts, inventory, and doctor report routes. The HomeScreen changes its main panel based on the loaded user's role and only shows the SOS control for a patient.",
        "The home bar exposes medication and profile actions. Although several other routes are registered, the inspected home screen does not provide visible navigation for all of them. This is an integration issue between route availability and feature discoverability, not a server capability gap. The app's authentication bypass can also render a patient-like home without a loaded user.",
        table=("Table 5.6. Registered mobile routes", ["Route group", "Screens"], [
            ["Authentication", "/splash, /login, /otp"],
            ["Role shells", "/patient, /caregiver, /home"],
            ["Profile and medicines", "/profile, /medications, /medications/new, /medications/:id"],
            ["Care workflows", "/caregiver/pairing-code, /caregiver/pair, /vitals, /contacts"],
            ["Additional features", "/prescription/scan, /inventory, /reports/doctor"],
        ]),
        source=["apps/mobile/lib/core/router/app_router.dart", "apps/mobile/lib/features/home/presentation/screens/home_screen.dart"],
    )
    add_page(
        "chapter_5_14", "5.14 Localization, Theme, and Accessibility Implementation",
        "The localization pipeline is configured through l10n.yaml and generated Dart delegates. Arabic is the fallback locale, and language can be updated through the user profile. AppTheme applies Cairo typography, teal and blue colors, 18-point major body text, padded Material touch targets, 60-point primary buttons, and directional form padding.",
        "The execution-plan log records an accessibility audit and remediation for semantics, visual selected states, tap targets, font size, and RTL-safe spacing. Current source should be revisited screen by screen when adding features; generated l10n output should be regenerated from both app_ar.arb and app_en.arb rather than edited manually.",
        source=["apps/mobile/lib/core/theme/app_theme.dart", "apps/mobile/l10n.yaml", "apps/mobile/lib/l10n/app_ar.arb", "apps/mobile/lib/l10n/app_en.arb", "docs/EXECUTION_PLAN.md"],
    )
    add_page(
        "chapter_5_15", "5.15 Reminder and Offline Modules",
        "MedicationReminderPlanner is a pure scheduling helper that maps today's dose models to notification IDs and timestamps. LocalReminderService initializes timezone data, schedules Android notifications in exact idle mode, and can cancel IDs for a schedule. OfflineAdherenceQueue serializes failed adherence operations to secure storage, deduplicates queued IDs, and flushes a batch when connectivity returns.",
        "The planner has unit tests for repeat times, taken/skipped filtering, and cancellation IDs. The queue test covers an offline record becoming a queued item and a successful flush. These tests validate the helper modules; they do not prove that the application calls those helpers because a repository-wide source search found no construction or invocation from the screen, router, or main entrypoint.",
        callout=("Operational conclusion", "The modules are implemented and tested in isolation. They must be connected and verified in a running application before being described as active product behavior."),
        source=["apps/mobile/lib/features/medications/data/medication_reminder_planner.dart", "apps/mobile/lib/features/medications/data/offline_adherence_queue.dart", "apps/mobile/test/features/medications/medication_reminder_planner_test.dart", "apps/mobile/test/features/medications/offline_adherence_queue_test.dart"],
    )
    add_page(
        "chapter_5_16", "5.16 Database Migrations and Data Lifecycle",
        "The API has three Alembic revision files: the initial user and OTP schema, refresh sessions, and domain models. SQLAlchemy's shared ID/timestamp mixin gives mapped classes UUID identifiers and timestamps. Local SQLite mode creates tables at application startup for developer convenience; schema changes intended for PostgreSQL should be expressed as migrations.",
        "A review of older database documentation shows planned tables and controls not present in the current model package. The current model list should be used to write data retention and deletion procedures. There is no account deletion endpoint or scheduled cleanup of expired OTP challenges, reports, or device records in the current route set.",
        source=["services/api/app/db/base.py", "services/api/app/db/session.py", "services/api/alembic/versions", "services/api/app/models"],
    )
    add_page(
        "chapter_5_17", "5.17 Continuous Integration and Quality Gates",
        "The GitHub Actions workflow defines an API job and a mobile job for pushes to main or develop and for pull requests. The API job sets up Python 3.12, installs uv, synchronizes locked dependencies, runs Ruff, and runs pytest. The mobile job uses the Flutter stable channel, fetches packages, analyzes the Dart source, and runs Flutter tests.",
        "The execution-plan log records a green API suite with 21 tests and a green Flutter suite with 35 tests on 23 October 2026. These are historical logged results, not freshly rerun by this documentation task. The workflow does not build platform release artifacts, deploy a service, run static security analysis, or measure performance.",
        table=("Table 5.7. CI jobs", ["Job", "Commands", "Not covered"], [
            ["API", "uv sync --locked; ruff check; pytest", "Deployment, load, migration-on-prod"],
            ["Mobile", "flutter pub get; flutter analyze; flutter test", "Release APK/IPA, device test matrix"],
        ]),
        source=[".github/workflows/ci.yml", "docs/EXECUTION_PLAN.md", "services/api/tests", "apps/mobile/test"],
    )
    add_page(
        "chapter_5_18", "5.18 Implemented, Partial, and Planned Feature Ledger",
        "This ledger separates feature status across the user interface, API, and external service. A green status means the core route or client flow exists, not that the product is ready for clinical use. A partial status means at least one layer exists but the promised outcome is incomplete.",
        "The most visible completed paths are medication CRUD, daily logging, caregiver linking, manual and voice vitals, inventory display, and local report construction. The main partial paths are caregiver role provisioning, app navigation to all feature routes, reminder activation, offline queue activation, prescription extraction, SOS dispatch, and public report sharing from the client.",
        table=("Table 5.8. Feature implementation ledger", ["Feature", "Client", "API", "External outcome"], [
            ["Medication CRUD", "Implemented", "Implemented", "Core data workflow"],
            ["Caregiver link", "Implemented", "Implemented", "Account-role setup incomplete"],
            ["Voice vitals", "Implemented", "Deterministic parser", "No model accuracy evaluation"],
            ["Prescription scan", "Review UI", "Static samples", "No OCR or vision"],
            ["Reminder", "Planner module", "Today data", "Service not wired"],
            ["SOS", "Confirmed request", "Alert record", "No dispatch"],
            ["Doctor report", "PDF share", "Summary and share routes", "No standalone portal"],
        ]),
        source=["Current source directories and tests; details referenced in prior sections"],
    )
    add_page(
        "chapter_5_19", "5.19 Local Setup and Run Procedure",
        "For the API, open a terminal in services/api, synchronize dependencies with uv, apply Alembic migrations for a PostgreSQL database when configured, and start the local server with Uvicorn on port 8000. The local SQLite development mode creates tables during startup. The health route is available at the root path; interactive docs are enabled outside production.",
        "For the mobile app, install Flutter dependencies from apps/mobile and run against an emulator or device with API_BASE_URL set appropriately. Set SKIP_AUTH=false to exercise the OTP flow. An Android emulator can use the default 10.0.2.2 address; a physical device needs a reachable host address and compatible CORS/network configuration. Keep development OTP-return behavior and placeholder secrets out of production.",
        table=("Table 5.9. Developer run sequence", ["Step", "Action"], [
            ["1", "Configure infra/.env or services/api/.env for local API settings"],
            ["2", "From services/api: uv sync and start app.main with Uvicorn"],
            ["3", "From apps/mobile: flutter pub get"],
            ["4", "Run with API_BASE_URL and SKIP_AUTH=false for integrated auth"],
            ["5", "Use the project CI checks when a code change needs verification"],
        ]),
        source=["AGENTS.md", "services/api/README.md", "apps/mobile/README.md", "services/api/app/core/config.py", "apps/mobile/lib/core/router/app_router.dart"],
    )
    add_page(
        "chapter_5_20", "5.20 Chapter Summary",
        "The repository implements a broad MVP across Flutter and FastAPI, with layered client code, typed API contracts, relational models, access checks, localization, and CI. The report has also identified multiple implementation seams that remain prototypes or are not active in the user journey.",
        "Development can proceed using the current local setup, but release readiness depends on connecting and validating the reminder and offline paths, role provisioning, image extraction, emergency dispatch, and report accessibility. The next chapter reviews the current test evidence and its limits.",
        source=["apps/mobile", "services/api", ".github/workflows/ci.yml"],
    )

    add_page(
        "chapter_6_1", "6.1 Evaluation Objectives and Evidence Boundary",
        "The evaluation chapter asks whether the repository contains source and test evidence for the main user journeys, whether access controls reject unrelated users, and whether automated checks cover the feature modules. It also identifies important behaviors for which the repository contains no measurement or runtime evidence.",
        "The project execution log records API lint and test results and Flutter analyze and test results from 23 October 2026. Current source contains 21 API test functions and 35 Flutter test declarations. These counts can be established by source inspection, but test success is reported as historical log evidence because this documentation task did not rerun the suites.",
        table=("Table 6.1. Evaluation evidence", ["Evidence type", "Available evidence", "Limit"], [
            ["API tests", "21 test functions in current test files", "Not executed during documentation work"],
            ["Flutter tests", "35 test/testWidgets declarations", "Not executed during documentation work"],
            ["CI definition", "API and mobile jobs in GitHub Actions", "No deployment or load job"],
            ["Usability study", "No study results found", "No user outcome claims"],
            ["Performance data", "No benchmark result found", "No latency or capacity claim"],
        ]),
        chapter=("Chapter 6 - Testing, Evaluation, and Results", "chapter_6", "This chapter maps the tests and recorded checks to system behavior and states what they do not establish."),
        source=["docs/EXECUTION_PLAN.md", "services/api/tests", "apps/mobile/test", ".github/workflows/ci.yml"],
    )
    add_page(
        "chapter_6_2", "6.2 Evaluation Environment and Test Data",
        "The API tests use pytest, pytest-asyncio, HTTPX AsyncClient, and an asynchronous SQLite database fixture. The mobile tests use flutter_test with mocktail mocks for repositories and platform-facing services. Tests are structured around request behavior, parsers, widget rendering, user interaction, and error-retry logic.",
        "Test fixtures and examples use synthetic users and values. This is appropriate for repeatable software checks but does not establish that the triage thresholds are medically appropriate or that a speech recognizer performs accurately across dialects, devices, ages, or noisy environments. No real patient dataset is documented in this repository.",
        table=("Table 6.2. Test environments", ["Suite", "Tools and data", "Primary purpose"], [
            ["API", "pytest, HTTPX, async SQLite", "Routes, schemas, access rules, calculations"],
            ["Mobile", "flutter_test, mocktail", "Repositories, screens, state transitions"],
            ["CI", "GitHub Actions", "Repeatable lint, analyze, and test workflow"],
            ["Clinical dataset", "Not found", "No clinical performance evaluation"],
        ]),
        source=["services/api/tests/conftest.py", "services/api/pyproject.toml", "apps/mobile/pubspec.yaml"],
    )
    add_page(
        "chapter_6_3", "6.3 Software Testing Strategy",
        "The API suite combines small pure-function checks with integration-style requests to an in-process service and test database. The mobile suite tests domain parsing, repository HTTP calls, route redirects, and screens with mocked dependencies. CI runs the API linter and tests and runs Flutter package resolution, static analysis, and tests.",
        "The strategy gives good coverage of the implemented client/API seams. Its main limitations are the absence of real device tests, no accessibility automation job, no database migration validation job in CI, no external provider contract tests, and no build or deployment smoke tests. A green unit suite cannot verify that Android alarms survive reboot, that FCM delivers an SOS, or that OCR reads a real prescription.",
        figure=("Figure 6.1. Current verification layers", ["Pure logic tests", "Repository and route tests", "Widget tests", "CI lint and analysis", "Manual device validation needed"]),
        source=[".github/workflows/ci.yml", "apps/mobile/test", "services/api/tests"],
    )
    add_page(
        "chapter_6_4", "6.4 API Authentication and Configuration Tests",
        "The API suite includes health-route behavior, OTP request and verification, profile endpoints, unauthorized access, OTP rate limiting, phone normalization cases, production configuration validation, refresh/session behavior inside the authentication flow, and rejection of expired access tokens.",
        "These tests address useful failure conditions: missing credentials, invalid phone formats, request thresholds, and insecure production defaults. They do not independently establish deployment secret management, transport security, brute-force resilience under concurrency, multi-instance rate limiting, or SMS delivery because no SMS provider is wired.",
        table=("Table 6.3. Authentication test modules", ["Test file", "Coverage themes"], [
            ["test_auth.py", "Health, OTP flow, /me, unauthorized response, rate limit"],
            ["test_phone.py", "Normalization, alternate formats, invalid numbers"],
            ["test_config.py", "Production rejects unsafe defaults and accepts explicit settings"],
            ["test_security_access.py", "Expired access token rejection"],
        ]),
        source=["services/api/tests/test_auth.py", "services/api/tests/test_phone.py", "services/api/tests/test_config.py", "services/api/tests/test_security_access.py"],
    )
    add_page(
        "chapter_6_5", "6.5 Medication, Adherence, and Inventory API Tests",
        "The medication test exercises medicine CRUD and adherence logging. The inventory test exercises the forecast and refill response. Together they check the service contract for common database-backed operations and the response shape expected by the client.",
        "The repository test files do not show a dedicated API test for every schedule edge case, time-zone boundary, day-mask pattern, duplicate client UUID retry, expired medication, zero or negative stock, or inconsistent dose amount. Those cases should be added before relying on the forecast and synchronization behavior for operational decisions.",
        table=("Table 6.4. Medication and inventory verification", ["Area", "Current case", "Useful next cases"], [
            ["Medication CRUD", "Create/read/update/deactivate and adherence path", "Permission combinations and repeated writes"],
            ["Schedule", "Creation and daily response exercised indirectly", "Date range and day mask boundaries"],
            ["Inventory", "Forecast and refill response", "Irregular schedules and expiry edge cases"],
            ["Sync", "Mobile helper test exists", "API duplicate/replay and partial batch failure"],
        ]),
        source=["services/api/tests/test_medications_and_adherence.py", "services/api/tests/test_inventory_and_refill.py", "services/api/app/services/inventory.py"],
    )
    add_page(
        "chapter_6_6", "6.6 Caregiver and Patient-Access Tests",
        "The caregiver suite tests the pairing flow and the fifteen-minute missed-dose rule. The security-access test logs in separate users and asserts that an unrelated user receives 403 across eighteen patient or medication routes, then verifies that an expired token receives 401.",
        "The tests provide direct evidence for the central patient-access boundary. Further cases should exercise revoked links, permission-mask variations, caregiver role provisioning, parallel pairing-code redemption, code collisions, expired pairing codes, and every response field that exposes linked-patient data.",
        callout=("Recorded result", "The execution log records 21 API tests passing on 23 October 2026. This report does not rerun them."),
        source=["services/api/tests/test_caregiver.py", "services/api/tests/test_security_access.py", "docs/EXECUTION_PLAN.md"],
    )
    add_page(
        "chapter_6_7", "6.7 Vital, Parser, and Triage Tests",
        "The vital test module checks blood-pressure, glucose, and pulse classification, a sample Egyptian Arabic voice transcript, and API creation/listing. These tests help preserve deterministic boundaries for values and test the request/response shape of vital routes.",
        "They do not measure the clinical sensitivity or specificity of the bands, validate the thresholds against a care guideline, or test parser performance on representative recordings. The parser has fallback behavior when it cannot find a clear type or value; an evaluation should explicitly test ambiguous speech and ensure that default values cannot be mistaken for user measurements.",
        table=("Table 6.5. Vital test categories", ["Category", "Test evidence", "Unverified claim"], [
            ["Blood pressure", "Rule boundaries and API path", "Clinical safety or diagnosis"],
            ["Glucose", "Context-dependent values", "Patient-specific targets"],
            ["Pulse", "Normal/borderline/critical bands", "Real device measurement"],
            ["Voice parsing", "Synthetic Arabic transcript", "Real-world accuracy or WER"],
        ]),
        source=["services/api/tests/test_vitals_and_triage.py", "services/api/app/services/ai_service.py", "services/api/app/services/triage.py"],
    )
    add_page(
        "chapter_6_8", "6.8 Prescription, Reports, and Public Sharing Tests",
        "The prescription/report API test exercises the mock scan response and report data. The report screen tests check that PDF bytes can be built from sample data and that the screen displays the report summary. These tests verify wiring from the response model to the export routine.",
        "They do not prove image OCR, Arabic PDF shaping, a selectable date range, public link delivery from the mobile UI, scope filtering, report privacy under token theft, or correctness when schedules have no logs. The fixed mock output can make UI tests deterministic while concealing the absence of extraction behavior.",
        source=["services/api/tests/test_prescription_and_reports.py", "apps/mobile/test/features/reports/doctor_report_test.dart", "apps/mobile/test/features/prescription/prescription_scan_screen_test.dart"],
    )
    add_page(
        "chapter_6_9", "6.9 Mobile Core and Navigation Tests",
        "The mobile suite tests Egyptian phone normalization, the phone screen rendering, automatic token refresh and retry, refresh-failure behavior, and patient/caregiver route selection. The profile test verifies that saving the language updates the locale. These tests target core dependencies used across multiple feature screens.",
        "The execution plan records Flutter analyze with no issues and 35 Flutter tests passing on 23 October 2026. This does not establish that the SKIP_AUTH build default is safe for distribution, that all registered routes are accessible through navigation, or that the app behaves consistently across operating systems and assistive technologies.",
        table=("Table 6.6. Mobile core test inventory", ["Test module", "Main coverage"], [
            ["phone_validator_test.dart", "Normalize local and international Egyptian numbers"],
            ["api_client_test.dart", "401 refresh, single retry, and refresh failure"],
            ["role_routing_test.dart", "Patient and caregiver shell routing"],
            ["profile_screen_test.dart", "Name/language update and locale change"],
            ["widget_test.dart", "Arabic phone screen presentation"],
        ]),
        source=["apps/mobile/test/core", "apps/mobile/test/phone_validator_test.dart", "apps/mobile/test/widget_test.dart", "docs/EXECUTION_PLAN.md"],
    )
    add_page(
        "chapter_6_10", "6.10 Medication and Caregiver Widget Tests",
        "Medication tests cover repository calls for list/create/update/delete, schedule listing and creation, daily dose display and Taken interaction, list deletion after confirmation, required-field validation, schedule editing, reminder-plan generation, and secure offline-queue flush behavior.",
        "Caregiver tests cover six-digit code display, code submission, and dashboard behavior. They rely on mocked repositories, which isolates screen interactions but does not exercise the entire app against a live API. The reminder and queue tests validate helper classes without proving their app lifecycle integration.",
        source=["apps/mobile/test/features/medications", "apps/mobile/test/features/caregiver"],
    )
    add_page(
        "chapter_6_11", "6.11 Additional Feature Widget Tests",
        "Additional mobile tests cover vital creation and triage label display, voice transcript confirmation, prescription candidate review and cancellation, emergency contact listing and creation, SOS confirmation behavior, inventory warning state, and doctor report generation/display.",
        "These tests offer broad functional checks for the screen surface. They do not test actual camera hardware, microphone recognizer quality, GPS permissions on a device, real WhatsApp launch, notification appearance, PDF rendering in multiple viewers, or message delivery. A future test plan should pair unit tests with device-level integration checks for platform plugins.",
        table=("Table 6.7. Feature widget test files", ["Module", "Scenario evidence"], [
            ["vitals", "Manual entry and confirmed voice parser result"],
            ["prescription", "Edit/confirm/cancel candidates"],
            ["emergency", "Contact add and SOS confirmation"],
            ["inventory", "Low-stock warning and refill request"],
            ["reports", "PDF bytes and summary screen"],
        ]),
        source=["apps/mobile/test/features/vitals", "apps/mobile/test/features/prescription", "apps/mobile/test/features/emergency", "apps/mobile/test/features/inventory", "apps/mobile/test/features/reports"],
    )
    add_page(
        "chapter_6_12", "6.12 Functional Requirement Verification Summary",
        "The functional requirements with the strongest automated evidence are authentication mechanics, phone normalization, medication CRUD, caregiver pairing, patient access checks, deterministic triage, core screen interactions, and PDF byte generation. Each has either API integration checks, widget tests, or both.",
        "Partial flows have a different evidence profile. Prescription tests validate a mock response; SOS tests validate a confirmed request but not delivery; reminders and offline queue tests validate helper logic but not app wiring; reports test a default summary and PDF but not date selection or Arabic rendering. The acceptance record should preserve these distinctions in future release reviews.",
        table=("Table 6.8. Verification status by feature", ["Feature", "Automated evidence", "Evaluation result"], [
            ["Auth/session", "API and Dio tests", "Core flow tested"],
            ["Patient access", "Cross-user 403 and expired JWT tests", "Boundary tested"],
            ["Prescription", "Mock extraction and review tests", "Interaction only"],
            ["Reminders/offline", "Planner and queue unit tests", "Helpers only"],
            ["SOS", "Long press and confirm widget test", "Request only"],
            ["Clinical behavior", "Threshold unit tests", "No clinical validation"],
        ]),
        source=["apps/mobile/test", "services/api/tests", "docs/EXECUTION_PLAN.md"],
    )
    add_page(
        "chapter_6_13", "6.13 Performance, Reliability, and Usability Evaluation",
        "The repository does not provide response-time targets, load profiles, availability measurements, device battery measurements, queue recovery rates, notification delivery metrics, or usability study results. Therefore no quantitative performance or user outcome result can be reported.",
        "The code does define request timeouts and a CI pipeline, and the execution plan records successful quality checks. A future evaluation should test representative devices, network loss and recovery, time-zone boundaries, high-volume patient histories, report generation for large datasets, and accessible use with screen readers and increased text sizes.",
        table=("Table 6.9. Evaluation gaps", ["Question", "Evidence needed"], [
            ["How quickly does a report load?", "Measured latency across record sizes"],
            ["Can an alarm survive restart and Doze?", "Device tests over reboot and power modes"],
            ["Are parsed readings accurate?", "Annotated recordings and error analysis"],
            ["Can older adults complete tasks?", "Consent-based usability study"],
            ["Does SOS reach contacts?", "Provider delivery receipts and failure tests"],
        ]),
        source=["Current test and CI source; no benchmark or study artifact found"],
    )
    add_page(
        "chapter_6_14", "6.14 Limitations and Threats to Validity",
        "The evaluation is limited by a single repository snapshot, historical test results, mocked external providers, and the lack of real patient or device data. Some route or screen modules may be reachable through code paths not visible from the inspected home navigation, and this report does not perform a dynamic device walkthrough.",
        "Test counts describe definitions and recorded results, not test coverage. A route test can validate a response contract while leaving real-world semantics untested. Threshold tests can show deterministic behavior but not medical validity. The prescription widget can show confirmation while the API still ignores the image. These validity boundaries should accompany any claims made in a presentation or release note.",
        bullets=["Construct validity: code presence is not the same as completed user value.", "Internal validity: mock dependencies remove platform and network failure modes.", "External validity: no evidence across diverse older users or device environments.", "Conclusion validity: no performance, clinical, or usability statistics are available."],
        source=["Current source, tests, and documentation snapshot"],
    )
    add_page(
        "chapter_6_15", "6.15 Chapter Summary",
        "The source contains a broad automated suite, and the project log records successful API and mobile checks on 23 October 2026. Those checks cover many core request and screen paths and include negative access-control cases.",
        "The evidence does not establish production readiness, clinical safety, real AI extraction, alarm reliability, emergency dispatch, or user outcomes. Future verification should focus on the incomplete integrations and on measurements that match the product's intended use. Chapter 7 summarizes the result and proposes an evidence-driven development order.",
        source=["docs/EXECUTION_PLAN.md", "services/api/tests", "apps/mobile/test"],
    )

    add_page(
        "chapter_7_1", "7.1 Conclusion",
        "Medliva is a substantial mobile and API MVP for medication and family-care coordination. It demonstrates a bilingual Flutter interface, a modular REST backend, relational data models, OTP and JWT session handling, patient-scoped authorization, dose and vital records, caregiver pairing, inventory forecasts, and a mobile-generated doctor report.",
        "The project is strongest where its UI, API, model, and test layers form an observable end-to-end path. It is less complete where a feature depends on an external provider or lifecycle event. The report therefore treats mock and helper modules as partial work and does not overstate them as production services.",
        chapter=("Chapter 7 - Conclusion and Future Work", "chapter_7", "This chapter summarizes the outcome, records lessons and limitations, and recommends a practical order for future implementation."),
        source=["Current repository snapshot and progress log"],
    )
    add_page(
        "chapter_7_2", "7.2 Summary of the Project",
        "The patient client supports sign-in and profile, medication maintenance, daily dose decisions, vital measurement entry, prescription candidate review, emergency contact management, inventory visibility, SOS recording, and clinician-report export. The caregiver client supports pairing, patient selection, and a patient summary view. The API implements the matching domain routes and enforces patient access for scoped data.",
        "The implementation includes 21 API test functions and 35 Flutter test declarations. The execution log records passing API and mobile checks on 23 October 2026. These test suites improve confidence in code behavior while leaving platform integration and clinical evidence open.",
        table=("Table 7.1. Outcome summary", ["Area", "Outcome"], [
            ["Mobile", "Bilingual screens across the core feature set"],
            ["API", "Versioned REST routes and typed schemas"],
            ["Security", "OTP limits, session rotation, and patient access checks"],
            ["Testing", "API and Flutter test suites, with recorded green run"],
            ["Readiness", "Prototype boundaries remain in several critical integrations"],
        ]),
        source=["docs/START_HERE.md", "docs/EXECUTION_PLAN.md", "services/api/tests", "apps/mobile/test"],
    )
    add_page(
        "chapter_7_3", "7.3 Achievement of Project Objectives",
        "The repository meets the objective of connecting a patient-focused mobile experience to a modular API and of supporting caregiver views with server-enforced patient relationships. It also meets the objective of providing manual and speech-assisted vital input with an editable confirmation step and a report export path.",
        "The objective of reliable offline medication operation is only partially met because the queue and reminder modules are not wired into the running app. Prescription scanning is only an interaction prototype. Emergency alert delivery, clinician portal functionality, and push notifications are not achieved in this snapshot. This table can serve as the acceptance record for a project review.",
        table=("Table 7.2. Objective achievement", ["Objective", "Assessment"], [
            ["Create patient and caregiver mobile flows", "Mostly achieved; navigation and role setup need work"],
            ["Protect cross-patient information", "Achieved in API checks; permission model is coarse"],
            ["Support user-confirmed vital capture", "Achieved as an app/API flow; clinical validation absent"],
            ["Support prescription image extraction", "Not achieved; server mock remains"],
            ["Deliver emergency notifications", "Not achieved; alert record only"],
            ["Produce and share a doctor report", "Achieved as English PDF file sharing"],
        ]),
        source=["Requirements traceability in Chapter 3; tests listed in Appendix E"],
    )
    add_page(
        "chapter_7_4", "7.4 Technical Contributions and Lessons Learned",
        "The work establishes common contracts across Flutter models, repository calls, FastAPI schemas, and SQLAlchemy records. The client refresh interceptor and server refresh-session rotation provide a concrete cross-layer session flow. The caregiver access helper puts the patient boundary on the server instead of trusting only client routing.",
        "The main lesson is that breadth must be paired with explicit integration status. A platform dependency or helper class is not active until lifecycle code constructs and calls it. A count of contacts is not proof that a message was delivered. A PDF that can be generated in a unit test is not automatically readable in every language. Such distinctions should be captured in implementation reviews and user-facing labels.",
        bullets=["Build the smallest complete end-to-end path before adding secondary modules.", "Add runtime-wiring checks to the integration review for plugin-backed features.", "Use explicit acceptance tests for asynchronous delivery and offline behavior.", "Document clinical and privacy boundaries before connecting external services."],
        source=["apps/mobile/lib/core/network/api_client.dart", "services/api/app/core/deps.py", "current feature modules"],
    )
    add_page(
        "chapter_7_5", "7.5 Project Limitations",
        "The most important limitations are: developer authentication bypass enabled by default; no caregiver-role enrollment path; broad permissions for every active caregiver link; local reminders and offline queue not integrated; static prescription sample output; alert records without dispatch; no device registration call from the app; and an English-only report PDF with transliteration rather than Arabic text shaping.",
        "The data layer also lacks a documented retention/deletion workflow, operational audit logging, and field-level encryption. Schedules and inventory forecasts do not fully account for time zone, day mask, or date windows. The report percentage is based on existing logs rather than all expected schedule occurrences. These limits affect reliability and interpretation, so the product must be presented as a development prototype.",
        table=("Table 7.3. Limitations by risk", ["Limitation", "Potential consequence", "Priority"], [
            ["Auth bypass default", "Unauthenticated demo paths appear active", "Critical"],
            ["No SOS delivery", "User may assume help was contacted", "Critical"],
            ["Mock prescription scan", "False medicine candidates", "Critical"],
            ["Reminder/queue not wired", "Missed or lost actions when app/network fails", "High"],
            ["Coarse caregiver permission", "Linked caregiver has broad access", "High"],
            ["No retention/deletion controls", "Sensitive data remains without lifecycle policy", "High"],
        ]),
        source=["Current source; see Chapters 4-6 for each evidence path"],
    )
    add_page(
        "chapter_7_6", "7.6 Recommendations for Future Development",
        "The next release should prioritize trust and complete journeys. First, make authentication mandatory by default, add a role enrollment or invitation policy, expose caregiver permissions, and provide visible navigation for all supported screens. Second, wire reminder scheduling and offline queue lifecycle into the app and confirm behavior across restart and connectivity changes.",
        "Next, replace the prescription mock with a privacy-reviewed extraction service and test it on a consented, de-identified, labeled dataset. Add explicit user confirmation and safe unknown handling. Implement real SOS delivery only with verified provider callbacks, retry rules, delivery status, and user-visible limitations. Complete Arabic report rendering and user-selectable date ranges before expanding clinician sharing.",
        table=("Table 7.4. Prioritized roadmap", ["Phase", "Work", "Exit evidence"], [
            ["1. Trust baseline", "Auth default, caregiver roles/permissions, navigation", "Security and route tests; release config review"],
            ["2. Reliability", "Wire alarms and queue, test restart/network recovery", "Device integration evidence"],
            ["3. Safe integrations", "Real scan and SOS providers", "Accuracy review and delivery receipts"],
            ["4. Deployment", "TLS, monitoring, deletion/retention, backups", "Operational runbook and security review"],
            ["5. User evaluation", "Accessibility and usability study", "Consent-based measured results"],
        ]),
        source=["Roadmap derived from verified gaps in this report; no future work is presented as complete."],
    )
    add_page(
        "chapter_7_7", "7.7 Research and Evaluation Directions",
        "Future research should evaluate whether the interface helps older adults complete medication and measurement tasks accurately and with acceptable effort. A study should define participant eligibility, consent, task scripts, error recording, assistive technology setup, and a protocol for clinical concerns.",
        "The speech and prescription features need separate evaluation datasets. For speech, report recognition and parsing errors by language, dialect, noise, device, and value type. For image extraction, assess field-level accuracy, uncertainty calibration, and safe rejection of illegible or unsupported content. Neither feature should be marketed as clinically reliable until its error profile has been measured and reviewed.",
        bullets=["Use synthetic and de-identified records for software tests.", "Use clinician-reviewed criteria before evaluating medical thresholds.", "Report failure modes and confidence, not only an average accuracy number.", "Keep human confirmation in place while uncertainty remains material."],
        source=["Current implementation and evaluation gaps in Chapter 6"],
    )
    add_page(
        "chapter_7_8", "7.8 Final Conclusion",
        "Medliva provides a substantial foundation for an accessible family-care application. Its present implementation connects many patient and caregiver tasks through a Flutter client and FastAPI service, and it includes useful patterns for typed APIs, session rotation, patient-level authorization, bilingual screens, and testable feature modules.",
        "The next step is to finish and validate the critical runtime paths before expanding the feature set. With the current limits made explicit, the project can be reviewed accurately, improved safely, and evaluated against outcomes that matter to patients, caregivers, and clinicians.",
        callout=("Final statement", "This report documents the code in the repository snapshot. It is not a clinical validation, security certification, or production deployment sign-off."),
        source=["Medliva project repository snapshot, 24 October 2026"],
    )

    add_page(
        "references_1", "References - Standards and Technical Foundations",
        "The following primary sources provide technical context for concepts used by the project. They are cited for definitions and platform behavior only. Their inclusion does not certify Medliva against a standard or imply that every documented platform capability is enabled in this implementation.",
        table=("Table R.1. External technical references", ["ID", "Source", "Use in this report"], [
            ["R1", "IETF RFC 7519, JSON Web Token (JWT), https://www.rfc-editor.org/rfc/rfc7519.html", "JWT claim and token format context"],
            ["R2", "FastAPI, OAuth2 with Password and Bearer with JWT tokens, https://fastapi.tiangolo.com/tutorial/security/oauth2-jwt/", "Bearer/JWT API pattern context"],
            ["R3", "Flutter, Internationalizing Flutter apps, https://docs.flutter.dev/ui/internationalization", "Flutter localization concepts"],
            ["R4", "Flutter, Accessibility, https://docs.flutter.dev/ui/accessibility", "Mobile accessibility implementation context"],
            ["R5", "W3C, Web Content Accessibility Guidelines (WCAG) 2.2, https://www.w3.org/TR/WCAG22/", "Accessibility principles; not a mobile conformance claim"],
            ["R6", "Android Developers, Schedule alarms, https://developer.android.com/develop/background-work/services/alarms", "Exact-alarm platform behavior"],
            ["R7", "OWASP, Mobile Application Security Verification Standard, https://mas.owasp.org/MASVS/", "Mobile security review reference"],
            ["R8", "SQLAlchemy 2.0, Asynchronous I/O, https://docs.sqlalchemy.org/en/20/orm/extensions/asyncio.html", "Async ORM implementation context"],
            ["R9", "Dart API Docs, flutter_local_notifications, https://pub.dev/documentation/flutter_local_notifications/latest/", "Local notification plugin capability context"],
        ]),
        callout=("Access date", "Online references were checked on 24 October 2026. Consult the publisher for the current version before implementation or policy decisions."),
        toc=True,
        source=["Primary publisher documentation and standards bodies"],
    )
    add_page(
        "references_2", "References - Project Documents",
        "Project documents are useful evidence of intent, decisions, and recorded progress, but they vary in currency. The report uses current code and tests to resolve conflicts. Older architecture pages and planning documents are cited as historical or target-state sources only when their claims match the repository.",
        table=("Table R.2. Project document references", ["ID", "Document", "Role in this report"], [
            ["P1", "Project working instructions", "Project boundaries and documentation workflow"],
            ["P2", "Project status guide", "Current status summary, checked against code"],
            ["P3", "Execution history", "Task history and dated check results"],
            ["P4", "API specification", "Route map, verified against the implementation"],
            ["P5", "Database and architecture documentation", "Design reference reconciled against runtime models"],
            ["P6", "Security guidance", "Security intent reconciled against current controls"],
            ["P7", "Use cases and AI pipeline notes", "Product use cases and design history"],
            ["P8", "Project and component readmes", "Setup and project orientation"],
        ]),
        source=["Repository files listed in the table"],
    )
    add_page(
        "references_3", "References - Code, Tests, and Package Manifests",
        "The report was prepared by reviewing the mobile application, API service, data models, API contracts, automated check definitions, platform settings, and database migration history together. Where an older project document disagreed with current source, the implementation determined the behavior described here.",
        "This report's snapshot date refers to the project state inspected for this task; it is not a release tag or signed commit identifier.",
        bullets=["Mobile client: localized patient and caregiver workflows.", "API service: authenticated routes, validation, access checks, and persistence.", "Verification: API and mobile test suites plus continuous-integration checks.", "Operations: environment examples and optional service configuration."],
        source=["Current working-tree snapshot on 24 October 2026"],
    )

    add_page(
        "appendix_a_1", "Appendix A - Detailed Software Requirements Specification",
        "This appendix expands the requirements into reviewable acceptance statements. It is a specification of the present MVP and its explicitly identified gaps, not a commitment that all listed requirements are already complete. Product owners should confirm these statements with representative users before a release decision.",
        table=("Table A.1. Identity and profile requirements", ["ID", "Requirement", "Acceptance evidence"], [
            ["A-AUTH-01", "Normalize accepted Egyptian phone formats to one stored representation.", "Phone normalization unit tests"],
            ["A-AUTH-02", "Limit OTP requests, expiry, resend timing, and wrong-code attempts.", "OTP API tests and settings"],
            ["A-AUTH-03", "Rotate and revoke refresh sessions; do not store raw refresh tokens.", "Auth flow and model inspection"],
            ["A-AUTH-04", "Keep development OTP response and auth bypass disabled in release builds.", "Production config and build review"],
            ["A-PRO-01", "Read and update supported profile fields and locale.", "Profile route and locale widget test"],
            ["A-PRO-02", "Provide a supported way to create or invite a caregiver account.", "Not implemented; future requirement"],
        ]),
        chapter=("Appendix A - Detailed Software Requirements Specification", "appendix_a", "Requirements are grouped by capability and use stable IDs for future traceability."),
        source=["services/api/app/api/v1/endpoints/auth.py", "apps/mobile/lib/features/auth", "apps/mobile/lib/core/router/app_router.dart"],
    )
    add_page(
        "appendix_a_2", "Appendix A - Medication and Adherence Requirements",
        "Medication requirements cover creation, editing, deactivation, schedule maintenance, daily review, dose recording, and inventory side effects. Every write should validate that the caller can access the owning patient. Dose actions should remain understandable when the network is unavailable.",
        table=("Table A.2. Medication and dose requirements", ["ID", "Requirement", "Status"], [
            ["A-MED-01", "List only active medicines for an accessible patient.", "Implemented"],
            ["A-MED-02", "Create and update medication fields without losing existing schedules.", "Implemented in current form/API flow"],
            ["A-MED-03", "Allow schedule time, day mask, amount, meal relation, and instructions.", "Schema/API support; UI subset"],
            ["A-MED-04", "Deactivate medicine through a clear confirmation step.", "Implemented"],
            ["A-DOSE-01", "Display today's dose state and capture taken or skipped status.", "Implemented"],
            ["A-DOSE-02", "Queue failed dose actions and flush safely when online.", "Helper exists; app wiring incomplete"],
            ["A-DOSE-03", "Prevent accidental duplicate inventory deductions on retry.", "Requires replay/error-path validation"],
        ]),
        source=["services/api/app/api/v1/endpoints/medications.py", "services/api/app/api/v1/endpoints/adherence.py", "apps/mobile/lib/features/medications"],
    )
    add_page(
        "appendix_a_3", "Appendix A - Caregiver and Vital Requirements",
        "Caregiver requirements specify role-checked pairing, code expiry, linked-patient selection, read-only daily review, and a consistent alert definition. Vital requirements specify manual and voice-assisted input, type-aware values, triage labels, raw transcript retention, and user confirmation before storage.",
        table=("Table A.3. Care and vital requirements", ["ID", "Requirement", "Status"], [
            ["A-CARE-01", "Create a short-lived patient pairing code.", "Implemented"],
            ["A-CARE-02", "Require a caregiver role and reject expired codes.", "Implemented; role setup gap"],
            ["A-CARE-03", "Apply per-capability caregiver permissions.", "Permission mask not enforced"],
            ["A-CARE-04", "Show 15-minute no-log alerts in caregiver response.", "Implemented as pull calculation"],
            ["A-VIT-01", "Record blood pressure, glucose, or pulse values.", "Implemented"],
            ["A-VIT-02", "Calculate a deterministic band and explain it in text.", "Implemented; not clinically validated"],
            ["A-VIT-03", "Review voice-derived values before persistence.", "Implemented"],
        ]),
        source=["services/api/app/api/v1/endpoints/caregiver.py", "services/api/app/api/v1/endpoints/vitals.py", "services/api/app/services/triage.py"],
    )
    add_page(
        "appendix_a_4", "Appendix A - Prescription, Inventory, and Emergency Requirements",
        "These features require particular care because they can influence medication use or create expectations of emergency response. Candidate data must be clearly labeled until verified. Forecasts must explain their assumptions. SOS success must distinguish a record saved by the server from a message delivered to a person.",
        table=("Table A.4. High-risk feature requirements", ["ID", "Requirement", "Current result"], [
            ["A-RX-01", "Use image content to extract candidate fields with uncertainty.", "Not implemented; fixed samples"],
            ["A-RX-02", "Require user review and confirmation before creating records.", "Review UI implemented"],
            ["A-STK-01", "Estimate days remaining from applicable schedule days.", "Current estimate ignores day masks/date windows"],
            ["A-STK-02", "Open a refill message only after user review.", "Message shown; URL not launched"],
            ["A-SOS-01", "Require deliberate confirmation for SOS.", "Implemented"],
            ["A-SOS-02", "Display delivery outcome only when provider confirms it.", "No provider integration"],
        ]),
        source=["services/api/app/services/ai_service.py", "services/api/app/services/inventory.py", "services/api/app/api/v1/endpoints/emergency.py"],
    )
    add_page(
        "appendix_a_5", "Appendix A - Reporting and Sharing Requirements",
        "A clinician summary should identify the patient and reporting period, list active medicines and schedules, summarize documented dose events, include readings with timestamps and triage labels, and carry a medical disclaimer. A share route should have an explicit scope, expiry, revocation, and privacy review.",
        table=("Table A.5. Report requirements", ["ID", "Requirement", "Status"], [
            ["A-REP-01", "Return data for an explicit date range or default period.", "API implemented; UI uses default"],
            ["A-REP-02", "Generate a readable PDF with clinical sections.", "Implemented in English LTR"],
            ["A-REP-03", "Render Arabic labels and names as shaped RTL text.", "Not implemented in PDF builder"],
            ["A-REP-04", "Share or print through the platform.", "Implemented"],
            ["A-REP-05", "Enforce requested scope on public token reads.", "Scope stored; filtering not visible"],
            ["A-REP-06", "Count expected but unlogged doses transparently.", "Not included in summary denominator"],
        ]),
        source=["services/api/app/api/v1/endpoints/reports.py", "apps/mobile/lib/features/reports"],
    )
    add_page(
        "appendix_a_6", "Appendix A - Cross-Cutting Quality Requirements",
        "Cross-cutting requirements cover patient privacy, least privilege, bilingual user experience, usable error recovery, operational traceability, and maintainable change. Requirements should be reviewed when an external service is added because each integration changes data flow and failure behavior.",
        table=("Table A.6. Quality and release requirements", ["ID", "Requirement", "Release evidence"], [
            ["A-SEC-01", "Use explicit production configuration and secret management.", "Configuration review"],
            ["A-SEC-02", "Apply least-privilege caregiver scopes.", "Authorization tests per capability"],
            ["A-PRIV-01", "Define consent, retention, deletion, and provider data flow.", "Approved privacy and operations plan"],
            ["A-UX-01", "Support Arabic RTL and English LTR on all screens.", "Visual and assistive-tech review"],
            ["A-REL-01", "Validate recovery from network failure and app restart.", "Device integration suite"],
            ["A-OPS-01", "Observe API health, dependencies, and alert delivery.", "Monitoring and runbook"],
        ]),
        source=["docs/SECURITY.md", "docs/CONVENTIONS.md", "apps/mobile/lib/l10n"],
    )

    add_page(
        "appendix_b_1", "Appendix B - UC-01: Review and Record a Medication Dose",
        "Primary actor: Patient. Preconditions: the user has a valid session and an active medication schedule for the selected date. Trigger: the patient opens the daily dose screen. Success condition: the server stores the chosen action and the screen reflects the new state.",
        table=("Table B.1. Main and alternate flows", ["Step", "Flow"], [
            ["1", "App requests GET /patients/{id}/today."],
            ["2", "Server checks patient access and returns scheduled doses."],
            ["3", "Patient reviews name, dose, time, and current status."],
            ["4", "Patient chooses Taken or Skip; app creates a client UUID."],
            ["5", "App posts the adherence log and refreshes the dose list."],
            ["Alternate", "If the request fails, the current screen reports failure; the offline queue is not invoked."],
        ]),
        chapter=("Appendix B - Extended Use-Case Descriptions", "appendix_b", "Each use case describes observable behavior and its current implementation boundary."),
        source=["apps/mobile/lib/features/medications/presentation/screens/today_screen.dart", "services/api/app/api/v1/endpoints/adherence.py"],
    )
    add_page(
        "appendix_b_2", "Appendix B - UC-02: Review Prescription Candidates",
        "Primary actor: Patient. Preconditions: camera or gallery access is available and the user has an authenticated session. Trigger: the patient chooses Scan Prescription. Success condition: selected candidate records and schedules are created only after review and confirmation.",
        table=("Table B.2. Main and alternate flows", ["Step", "Flow"], [
            ["1", "User selects camera or gallery and chooses an image."],
            ["2", "Client uploads bytes as multipart form data."],
            ["3", "API currently returns fixed sample candidates; image is not read."],
            ["4", "User edits fields and selects intended candidates."],
            ["5", "User confirms; client creates medicines and schedules."],
            ["Alternate", "User cancels; no medicine is created."],
        ]),
        source=["apps/mobile/lib/features/prescription/presentation/screens/prescription_scan_screen.dart", "services/api/app/api/v1/endpoints/ai.py"],
    )
    add_page(
        "appendix_b_3", "Appendix B - UC-03: Record a Vital Reading",
        "Primary actor: Patient. Preconditions: the user can access the patient record. Trigger: the user opens Vitals and selects manual or voice entry. Success condition: a confirmed reading is stored with type, values, context, band, and timestamp.",
        table=("Table B.3. Main and alternate flows", ["Step", "Flow"], [
            ["1", "User enters values manually or dictates a phrase."],
            ["2", "For voice entry, device STT returns a transcript."],
            ["3", "API parser returns a type, values, context, and band."],
            ["4", "User reviews and can edit the parsed value."],
            ["5", "User confirms; app posts the vital record."],
            ["Alternate", "If recognition is unavailable or transcript is empty, no record is saved."],
        ]),
        source=["apps/mobile/lib/features/vitals", "services/api/app/api/v1/endpoints/vitals.py"],
    )
    add_page(
        "appendix_b_4", "Appendix B - UC-04: Pair a Caregiver",
        "Primary actors: Patient and Caregiver. Preconditions: the patient has an account; the caregiver has an account with caregiver role. Trigger: the patient requests a pairing code. Success condition: the active link is stored and the caregiver can list the patient.",
        table=("Table B.4. Main and alternate flows", ["Step", "Flow"], [
            ["1", "Patient requests a six-digit code valid for ten minutes."],
            ["2", "Patient shares the code through an agreed private channel."],
            ["3", "Caregiver submits the code."],
            ["4", "API validates role, code, expiry, and self-pairing restriction."],
            ["5", "API marks the link active and returns patient information."],
            ["Alternate", "Unknown or expired code returns an error; caregiver self-pair is rejected."],
        ]),
        source=["services/api/app/api/v1/endpoints/caregiver.py", "apps/mobile/lib/features/caregiver/presentation/screens/pairing_screens.dart"],
    )
    add_page(
        "appendix_b_5", "Appendix B - UC-05: Review Inventory and Prepare Refill",
        "Primary actor: Patient or linked caregiver. Preconditions: at least one accessible patient medication exists. Trigger: the user opens Inventory. Success condition: the user sees estimated stock days and can request a prepared refill message.",
        table=("Table B.5. Main and alternate flows", ["Step", "Flow"], [
            ["1", "Client requests the patient inventory forecast."],
            ["2", "API estimates daily use from active schedules and stock."],
            ["3", "Client marks low-stock medicines with a warning."],
            ["4", "User requests a refill message for one medicine."],
            ["5", "API returns message text and a WhatsApp URL."],
            ["Current limit", "Client shows the message; it does not open the URL."],
        ]),
        source=["services/api/app/services/inventory.py", "apps/mobile/lib/features/inventory/presentation/screens/inventory_screen.dart"],
    )
    add_page(
        "appendix_b_6", "Appendix B - UC-06: Share a Doctor Summary",
        "Primary actor: Patient or linked caregiver. Secondary recipient: Clinician. Preconditions: caller has access to the patient and report data is available. Trigger: user opens Doctor Report. Success condition: a PDF is created and handed to the platform share sheet.",
        table=("Table B.6. Main and alternate flows", ["Step", "Flow"], [
            ["1", "Client requests the default report period or supplied date range."],
            ["2", "API aggregates patient profile, active medicines, logs, and vitals."],
            ["3", "Client renders tables and a medical disclaimer into PDF bytes."],
            ["4", "User chooses a share or print destination."],
            ["Alternate", "API error is shown; no local report is generated."],
            ["Current limit", "UI uses default dates and PDF is English LTR."],
        ]),
        source=["services/api/app/api/v1/endpoints/reports.py", "apps/mobile/lib/features/reports"],
    )
    add_page(
        "appendix_b_7", "Appendix B - UC-07: Record an SOS Alert",
        "Primary actor: Patient. Preconditions: the patient is signed in and the network is available. Trigger: the patient long-presses SOS and confirms. Success condition: the API creates an alert record and returns an alert ID.",
        table=("Table B.7. Main and alternate flows", ["Step", "Flow"], [
            ["1", "Patient long-presses the SOS button."],
            ["2", "Confirmation dialog states that an SOS will be sent."],
            ["3", "Client includes coordinates only when permission already exists."],
            ["4", "API stores alert payload and returns a contact count."],
            ["Alternate", "Canceling the dialog sends no request."],
            ["Critical boundary", "No SMS, call, or push dispatch is implemented."],
        ]),
        source=["apps/mobile/lib/features/emergency/presentation/widgets/sos_button_widget.dart", "services/api/app/api/v1/endpoints/emergency.py"],
    )
    add_page(
        "appendix_b_8", "Appendix B - Use-Case Exception and Recovery Catalog",
        "A production use case should define recovery for expired tokens, expired pairing codes, network loss, duplicate request, denied permissions, invalid user input, missing schedules, empty records, and external-provider failure. Several of these are already represented in API error responses or widget tests; others remain unhandled or not connected to visible user feedback.",
        table=("Table B.8. Recovery behavior", ["Condition", "Current behavior", "Recommended outcome"], [
            ["Expired access token", "Client attempts refresh once", "Preserve form state through renewal"],
            ["Refresh failure", "Tokens cleared and auth state invalidated", "Show clear sign-in action"],
            ["Offline dose action", "Screen request may fail", "Queue action and show pending state"],
            ["No location permission", "SOS proceeds without coordinates", "Explain location omission"],
            ["Mock scan candidate", "Sample list returned", "Label prototype data clearly until replaced"],
            ["SOS delivery unavailable", "Alert row still returns active", "Never imply recipient delivery"],
        ]),
        source=["apps/mobile/lib/core/network/api_client.dart", "apps/mobile/lib/features/emergency", "services/api/app/core/errors.py"],
    )

    add_page(
        "appendix_c_1", "Appendix C - Database Entities: Identity and Relationships",
        "All mapped entities inherit a UUID ID and created/updated timestamps from IdTimestampMixin unless a field is explicitly represented by a relationship key. The database uses foreign keys to connect a patient and caregiver relationship to user rows and to attach medicines, schedules, logs, alerts, and reports to their owners.",
        table=("Table C.1. Identity and access entities", ["Entity", "Important fields", "Constraints and use"], [
            ["users", "phone, name, role, language, timezone, birth_date, address", "Phone is unique; role values: patient/caregiver/admin"],
            ["otp_challenges", "phone, code_hash, expires_at, attempts, consumed_at", "Challenge state for OTP verification"],
            ["refresh_sessions", "user_id, jti, token_hash, expires_at, revoked_at", "Unique jti and token hash; refresh rotation"],
            ["caregiver_links", "caregiver_id, patient_id, pairing code/expiry, status, permissions_mask, linked_at", "Unique caregiver/patient pair; active link grants current access"],
        ]),
        chapter=("Appendix C - Database Schema and Data Dictionary", "appendix_c", "This data dictionary reflects mapped SQLAlchemy models in services/api/app/models."),
        source=["services/api/app/models/user.py", "services/api/app/models/caregiver.py", "services/api/app/db/base.py"],
    )
    add_page(
        "appendix_c_2", "Appendix C - Database Entities: Medication and Adherence",
        "The medication tables represent the catalog, a patient's current medicine, recurring schedules, and user-reported dose events. A medication may optionally reference a catalog item. Schedules belong to a medication, while each intake log records the patient and scheduled event.",
        table=("Table C.2. Medication and adherence entities", ["Entity", "Important fields", "Constraints and use"], [
            ["drug_catalog", "trade_name, active_ingredient, strength, form, manufacturer, price_egp", "Indexed trade name; matching candidate source"],
            ["medications", "patient_id, catalog_id, names, form, strength, stock_count, threshold, expiry, is_active", "Patient-owned medicine; soft deactivation"],
            ["schedules", "medication_id, time_of_day, days_mask, dose_amount, meal_relation, dates, is_active", "Recurring instructions for a medicine"],
            ["intake_logs", "client_uuid, schedule_id, patient_id, scheduled_time, actual_time, status, reason, logged_offline", "Unique client_uuid; dose event history"],
        ]),
        source=["services/api/app/models/medication.py"],
    )
    add_page(
        "appendix_c_3", "Appendix C - Database Entities: Vitals and Prescription Records",
        "The vital record stores structured measurements and the text transcript when one is available. The prescription entity can hold a file URL and extracted JSON fields, but the current scan route does not persist uploaded files or create a prescription row.",
        table=("Table C.3. Health record entities", ["Entity", "Important fields", "Constraints and use"], [
            ["vitals_logs", "client_uuid, patient_id, type, values, meal_context, band, raw_transcript, recorded_at", "Blood pressure, glucose, pulse; optional client UUID"],
            ["prescriptions", "patient_id, image_url, doctor_name, raw_extracted_json, confidence, verified_at, verified_by", "Persistence model exists; scan route does not use it"],
        ]),
        callout=("Model versus workflow", "A table definition establishes storage capability only. It does not prove that a screen or endpoint writes a record to that table."),
        source=["services/api/app/models/vitals.py", "services/api/app/models/prescriptions.py", "services/api/app/api/v1/endpoints/ai.py"],
    )
    add_page(
        "appendix_c_4", "Appendix C - Database Entities: Emergency, Sharing, and Devices",
        "Emergency contacts are linked to a patient and contain flags indicating desired contact methods. Alert records hold an alert type, tier, JSON payload, sent time, and acknowledgement time. Report-share records store a token hash, scope, expiry, view count, and revoked flag. Device records store an FCM token and metadata.",
        table=("Table C.4. Supporting entities", ["Entity", "Important fields", "Current use"], [
            ["emergency_contacts", "patient_id, name, phone, relationship, is_primary, notify_sms, notify_call", "List/create routes; flags not dispatched"],
            ["alerts", "patient_id, type, tier, payload_json, sent_at, acknowledged_at", "SOS endpoint creates a row"],
            ["report_shares", "patient_id, token_hash, scope, expires_at, views_count, revoked", "Public report token flow"],
            ["devices", "user_id, fcm_token, platform, app_version, last_seen", "API registration/update route"],
        ]),
        source=["services/api/app/models/emergency.py", "services/api/app/models/reports.py", "services/api/app/models/devices.py"],
    )
    add_page(
        "appendix_c_5", "Appendix C - Enums, Keys, and Database Notes",
        "Enumerations use explicit values for user roles, caregiver-link state, meal relation, intake status, vital type, vital band, and alert type. Foreign-key cascades remove dependent records when a user or parent record is deleted, while optional catalog references can be cleared when a catalog row is removed.",
        table=("Table C.5. Enum values", ["Enum", "Values"], [
            ["UserRole", "patient, caregiver, admin"],
            ["CaregiverLinkStatus", "pending, active, revoked"],
            ["MealRelation", "before_meal, after_meal, with_meal, independent"],
            ["IntakeStatus", "taken, snoozed, missed, skipped"],
            ["VitalType / VitalBand", "bp, glucose, pulse / normal, borderline, critical"],
            ["AlertType", "missed_dose, critical_vital, low_stock, expiry, sos"],
        ]),
        callout=("Schema omissions", "Current models do not include the planned local Drift database, voice notes, a dedicated audit log entity, or several entities listed in older diagrams."),
        source=["services/api/app/models", "services/api/alembic/versions"],
    )

    add_page(
        "appendix_d_1", "Appendix D - API Catalogue: Health, Authentication, and Profile",
        "The API version prefix is /api/v1. The health endpoint is the only route at the root. Error responses use an error object with code and message; request-validation errors can include field details. Interactive OpenAPI documentation is enabled outside production.",
        table=("Table D.1. System, authentication, and profile routes", ["Method and path", "Auth", "Purpose"], [
            ["GET /health", "Public", "Return service status/name/environment"],
            ["POST /api/v1/auth/otp/request", "Public", "Create OTP challenge for normalized phone"],
            ["POST /api/v1/auth/otp/verify", "Public", "Consume OTP and return user/token pair"],
            ["POST /api/v1/auth/refresh", "Refresh token", "Rotate refresh session and issue access token"],
            ["POST /api/v1/auth/logout", "Refresh token", "Revoke refresh session; 204 response"],
            ["GET /api/v1/me", "Bearer", "Read current user profile"],
            ["PATCH /api/v1/me", "Bearer", "Update supported profile fields"],
        ]),
        chapter=("Appendix D - API Specification and Integration Details", "appendix_d", "The route inventory below follows the current API router and endpoint functions."),
        source=["services/api/app/main.py", "services/api/app/api/v1/router.py", "services/api/app/api/v1/endpoints/auth.py", "services/api/app/api/v1/endpoints/users.py"],
    )
    add_page(
        "appendix_d_2", "Appendix D - API Catalogue: Caregiver and Medication Routes",
        "Patient-scoped routes require ownership, an admin role, or an active caregiver link. Pairing routes perform role checks in their endpoint handlers. Medication-scoped routes resolve the related patient before applying the access boundary.",
        table=("Table D.2. Caregiver and medication routes", ["Method and path", "Auth", "Purpose"], [
            ["POST /api/v1/caregiver/pairing-code", "Patient", "Issue temporary pairing code"],
            ["POST /api/v1/caregiver/pair", "Caregiver", "Redeem a valid code"],
            ["GET /api/v1/caregiver/patients", "Bearer", "List linked patients and daily summary"],
            ["GET /api/v1/caregiver/alerts", "Bearer", "Return computed missed-dose alerts"],
            ["GET/POST /api/v1/patients/{id}/medications", "Patient/linked caregiver", "List or create medicine"],
            ["PATCH/DELETE /api/v1/medications/{id}", "Patient/linked caregiver", "Update or deactivate medicine"],
            ["GET/POST /api/v1/medications/{id}/schedules", "Patient/linked caregiver", "List or create schedule"],
        ]),
        source=["services/api/app/api/v1/endpoints/caregiver.py", "services/api/app/api/v1/endpoints/medications.py", "services/api/app/core/deps.py"],
    )
    add_page(
        "appendix_d_3", "Appendix D - API Catalogue: Daily Doses, Adherence, and Vitals",
        "The batch endpoint accepts supported log operations for synchronization. The vitals routes calculate or return stored triage bands. The speech route accepts text transcript data; it is not an audio-upload endpoint.",
        table=("Table D.3. Dose and vital routes", ["Method and path", "Auth", "Purpose"], [
            ["GET /api/v1/patients/{id}/today", "Patient/linked caregiver", "Return today's scheduled doses and states"],
            ["POST /api/v1/adherence/log", "Patient/linked caregiver", "Create one adherence event"],
            ["POST /api/v1/sync/batch", "Bearer + patient access", "Submit supported offline log items"],
            ["GET /api/v1/patients/{id}/vitals", "Patient/linked caregiver", "List/filter vital records"],
            ["POST /api/v1/patients/{id}/vitals", "Patient/linked caregiver", "Create vital and calculate band"],
            ["POST /api/v1/ai/parse-voice-vitals", "Bearer", "Parse a text transcript into values"],
        ]),
        source=["services/api/app/api/v1/endpoints/medications.py", "services/api/app/api/v1/endpoints/adherence.py", "services/api/app/api/v1/endpoints/vitals.py"],
    )
    add_page(
        "appendix_d_4", "Appendix D - API Catalogue: AI, Inventory, and Emergency",
        "The scan route consumes multipart form data in the contract but currently returns fixed sample candidates. Inventory endpoints calculate estimated days and build a refill message. The SOS endpoint records a new alert and does not dispatch external messages.",
        table=("Table D.4. AI, inventory, and emergency routes", ["Method and path", "Auth", "Purpose"], [
            ["POST /api/v1/ai/scan-prescription", "Bearer", "Return prescription candidates; current output is mock data"],
            ["GET /api/v1/patients/{id}/inventory/forecast", "Patient/linked caregiver", "Return medication forecasts"],
            ["POST /api/v1/patients/{id}/inventory/refill-order", "Patient/linked caregiver", "Return message and WhatsApp URL"],
            ["POST /api/v1/emergency/sos", "Bearer", "Create an SOS alert record for caller"],
            ["GET /api/v1/patients/{id}/contacts", "Patient/linked caregiver", "List emergency contacts"],
            ["POST /api/v1/patients/{id}/contacts", "Patient/linked caregiver", "Create emergency contact"],
        ]),
        source=["services/api/app/api/v1/endpoints/ai.py", "services/api/app/api/v1/endpoints/inventory.py", "services/api/app/api/v1/endpoints/emergency.py"],
    )
    add_page(
        "appendix_d_5", "Appendix D - API Catalogue: Reports and Devices",
        "The report summary is authenticated and patient-scoped. Public share reads use a bearer token embedded in the path. Device registration is authenticated and keyed by FCM token. The mobile app currently uses the report summary and does not call the device registration or public share route.",
        table=("Table D.5. Reports and device routes", ["Method and path", "Auth", "Purpose"], [
            ["POST /api/v1/patients/{id}/reports/share", "Patient/linked caregiver", "Create expiring share token"],
            ["GET /api/v1/patients/{id}/reports/summary", "Patient/linked caregiver", "Return PDF source data for a date range"],
            ["GET /api/v1/public/reports/{token}", "Public token", "Return report data while token is valid"],
            ["POST /api/v1/devices", "Bearer", "Create or update device token metadata"],
        ]),
        source=["services/api/app/api/v1/endpoints/reports.py", "services/api/app/api/v1/endpoints/devices.py"],
    )
    add_page(
        "appendix_d_6", "Appendix D - API Contract and Access Notes",
        "JSON is the default request and response format. The prescription scan uses multipart form data. Authenticated requests send Authorization: Bearer with an access token. Dates in report queries use ISO date values under the aliases from and to. All timestamps should be interpreted with care because user.timezone is stored but several date calculations use UTC.",
        table=("Table D.6. Contract conventions", ["Concern", "Current convention", "Review note"], [
            ["Success response", "Schema-specific JSON; some routes return 204", "Use response model as contract"],
            ["Validation error", "422 envelope with code/message/details", "Details list field and message"],
            ["Unauthorized", "401 envelope", "Expired or missing token"],
            ["Forbidden", "403 envelope", "Wrong role or no patient link"],
            ["Not found", "404 envelope", "Resource or share token missing/expired"],
            ["Time handling", "UTC-aware timestamps in API logic", "Patient time zone not consistently applied"],
        ]),
        source=["services/api/app/core/errors.py", "services/api/app/schemas", "docs/API_SPEC.md"],
    )
    add_page(
        "appendix_d_7", "Appendix D - API Error and Permission Matrix",
        "The API centralizes error formatting so the mobile client can extract a stable message and code. Permission failures should be tested on every route that accepts a patient or medication identifier. Routes without a patient path still require a clear actor policy, such as the SOS route's current-user attribution.",
        table=("Table D.7. Error and access matrix", ["Route family", "Authentication", "Resource authorization"], [
            ["OTP request/verify", "Public", "Phone challenge limits"],
            ["Profile and device", "Bearer", "Current user owns resource"],
            ["Patient routes", "Bearer", "Self/admin/active caregiver link"],
            ["Pairing code", "Bearer + role check", "Patient to caregiver transition"],
            ["Public report", "No user session", "Unexpired, non-revoked token"],
            ["SOS", "Bearer", "Attributed to caller; no external dispatch"],
        ]),
        source=["services/api/app/core/deps.py", "services/api/app/core/errors.py", "services/api/tests/test_security_access.py"],
    )

    add_page(
        "appendix_e_1", "Appendix E - API Test Register",
        "The current API test suite contains 21 test function definitions across nine test modules. The execution log records 21 API tests passing on 23 October 2026. The list below describes current test themes; it is not a new test run.",
        table=("Table E.1. API test modules", ["Module", "Count", "Test themes"], [
            ["test_auth.py", "4", "health, OTP flow, profile, missing auth, request rate"],
            ["test_caregiver.py", "2", "pairing and 15-minute missed-dose alerts"],
            ["test_config.py", "2", "production config rejects defaults / accepts secure values"],
            ["test_inventory_and_refill.py", "1", "forecast and refill response"],
            ["test_medications_and_adherence.py", "1", "medication CRUD and adherence"],
            ["test_phone.py", "3", "standard, variant, and invalid phone formats"],
            ["test_prescription_and_reports.py", "1", "mock scan and report flow"],
            ["test_security_access.py", "2", "unrelated-user 403s and expired token"],
            ["test_vitals_and_triage.py", "5", "three triage groups, voice parse, vitals API"],
        ]),
        chapter=("Appendix E - Test Cases and Detailed Results", "appendix_e", "The register summarizes the automated evidence present in the repository and its recorded execution status."),
        source=["services/api/tests", "docs/EXECUTION_PLAN.md"],
    )
    add_page(
        "appendix_e_2", "Appendix E - API Security Test Scenarios",
        "The security access module exercises a patient or medication resource under a user that is not the owner and has no active caregiver link. It expects forbidden responses across eighteen scoped routes. A separate case uses an expired access token and expects an unauthorized response.",
        table=("Table E.2. Security scenario groups", ["Scenario", "Expected result", "Evidence file"], [
            ["No bearer token to protected endpoint", "401", "test_auth.py"],
            ["Expired JWT on protected endpoint", "401", "test_security_access.py"],
            ["Unrelated user reads patient data", "403", "test_security_access.py"],
            ["Wrong OTP or exhausted attempts", "400 error envelope", "test_auth.py"],
            ["Too many OTP requests", "429 error envelope", "test_auth.py"],
            ["Production SQLite/default secret", "Configuration validation error", "test_config.py"],
        ]),
        callout=("Future coverage", "Add cases for revoked caregiver links, permission-mask values, refresh-token replay, simultaneous code redemption, and public token scope enforcement."),
        source=["services/api/tests/test_security_access.py", "services/api/tests/test_auth.py", "services/api/tests/test_config.py"],
    )
    add_page(
        "appendix_e_3", "Appendix E - Mobile Test Register: Core and Medication",
        "The current mobile test source contains 35 test and widget-test declarations. Core tests cover the phone validator, default Arabic phone screen, refresh retry, route redirection by role, and profile language. Medication tests cover repository calls, dose cards, editing, delete confirmation, scheduling, reminder planning, and queue flushing.",
        table=("Table E.3. Mobile core/medication tests", ["Test module", "Count", "Primary evidence"], [
            ["phone_validator_test.dart", "3", "normalize and reject phone formats"],
            ["widget_test.dart", "1", "Arabic phone screen"],
            ["core/network/api_client_test.dart", "2", "401 refresh/retry and refresh failure"],
            ["core/router/role_routing_test.dart", "2", "patient and caregiver shell routing"],
            ["features/auth/profile_screen_test.dart", "1", "profile update changes locale"],
            ["features/medications/medication_repository_test.dart", "7", "list/create/update/delete/schedules/today"],
            ["features/medications/other tests", "6", "today, form, list, schedule, reminders, offline queue"],
        ]),
        source=["apps/mobile/test/core", "apps/mobile/test/features/auth", "apps/mobile/test/features/medications", "apps/mobile/test/phone_validator_test.dart"],
    )
    add_page(
        "appendix_e_4", "Appendix E - Mobile Test Register: Additional Features",
        "Feature widget tests cover caregiver pairing/dashboard, emergency contacts and SOS, inventory warning behavior, vitals and speech confirmation, prescription candidate review, and doctor report screen/PDF output. Tests generally use mock repositories or platform service abstractions to avoid device and network dependencies.",
        table=("Table E.4. Additional mobile tests", ["Test module", "Count", "Primary evidence"], [
            ["caregiver/dashboard", "3", "patient list, pairing code, pair submission"],
            ["emergency", "2", "list/add contact and confirmed SOS request"],
            ["inventory", "1", "forecast warning and refill interaction"],
            ["vitals", "2", "manual triage label and voice confirmation"],
            ["prescription", "1", "edit, confirm, and cancel scan candidates"],
            ["reports", "2", "PDF bytes and report summary screen"],
        ]),
        source=["apps/mobile/test/features/caregiver", "apps/mobile/test/features/emergency", "apps/mobile/test/features/inventory", "apps/mobile/test/features/vitals", "apps/mobile/test/features/prescription", "apps/mobile/test/features/reports"],
    )
    add_page(
        "appendix_e_5", "Appendix E - Verification Matrix and Recommended Additions",
        "Automated tests should be paired with checks that prove the real platform integration. The highest priority additions are not more widget snapshots but tests for workflows that cross a platform plugin, app lifecycle, network boundary, or external provider.",
        table=("Table E.5. Recommended end-to-end tests", ["Scenario", "Why it matters", "Evidence to collect"], [
            ["Alarm reschedule after app restart", "Current alarm service is not lifecycle-wired", "Device alarm state and notification"],
            ["Dose action queued during offline mode", "Queue class is not called by TodayScreen", "Persistent queued status and later sync"],
            ["SOS provider accepted and delivered", "Current endpoint only writes an alert row", "Provider receipt and user-visible result"],
            ["Arabic PDF viewed in target readers", "Current builder transliterates Arabic", "Rendered screenshots and language check"],
            ["Prescription image extraction cases", "Current output ignores image bytes", "Ground-truth field accuracy and rejects"],
            ["Caregiver revocation and scope", "Permissions are coarse and no revocation UI", "403 per restricted operation"],
        ]),
        source=["Current incomplete integrations identified in Chapters 4 and 6"],
    )

    add_page(
        "appendix_f_1", "Appendix F - User Guide: Sign-In and Profile",
        "The normal sign-in flow begins by entering an Egyptian mobile number and requesting an OTP. In development the API can return a test code in its response. A user enters the code and may enter a name for first-time registration. The app then loads the profile and routes to a patient or caregiver shell based on the user role.",
        "The profile screen lets the user update the name and switch between Arabic and English. If the app appears to skip login during local development, the build may have SKIP_AUTH enabled; that is a developer setting and should not be mistaken for a verified authenticated session. A caregiver account role must already exist because new OTP accounts default to patient.",
        table=("Table F.1. Sign-in checklist", ["Check", "Action"], [
            ["Phone", "Use a supported Egyptian mobile number"],
            ["OTP", "Use the development code only in a configured local environment"],
            ["Profile", "Save display name and preferred language"],
            ["Role", "Confirm the account is provisioned for the intended role"],
        ]),
        chapter=("Appendix F - User Guide and Interaction Walkthroughs", "appendix_f", "This guide documents current screen behavior and names unfinished workflows directly."),
        source=["apps/mobile/lib/features/auth", "services/api/app/api/v1/endpoints/auth.py", "apps/mobile/lib/core/router/app_router.dart"],
    )
    add_page(
        "appendix_f_2", "Appendix F - User Guide: Medication List and Schedule",
        "From the home screen, open Medications to review active entries. Add a medicine by entering its name and any available dose details, then save. Open a medicine to add a schedule time and meal relation. To remove it from the active list, use the delete action and confirm the dialog; the API deactivates the medicine rather than erasing history.",
        "Schedules include a time of day, optional weekdays, dose amount, meal relation, and instructions. The interface should be checked carefully after changing an existing medicine because the server remains the source of record. Do not treat a schedule created from a mock prescription candidate as a verified prescription.",
        bullets=["Check medicine name and strength against the clinician's instructions.", "Review every schedule time and meal instruction before saving.", "Use the profile locale setting to switch the UI language."],
        source=["apps/mobile/lib/features/medications/presentation/screens/medication_list_screen.dart", "apps/mobile/lib/features/medications/presentation/screens/medication_form_screen.dart", "apps/mobile/lib/features/medications/presentation/screens/medication_detail_screen.dart"],
    )
    add_page(
        "appendix_f_3", "Appendix F - User Guide: Today's Doses",
        "Open the patient home to review today's dose cards. Each card presents medicine information, time, and current status. Choose Taken or Skip to submit the event. The screen refreshes after the API response. If a network error occurs, follow the visible error state; the current UI does not guarantee offline queueing.",
        "The caregiver home can show today's counts and open a selected patient's daily schedule read-only. Alerts are computed when the caregiver requests the dashboard. A missed-dose indicator means the server found no log at least fifteen minutes after the scheduled time or found a missed log; it does not mean a push notification was sent.",
        callout=("User-facing wording", "A dose alert is a record returned by the dashboard API. The app does not currently send a remote alert to a caregiver's phone."),
        source=["apps/mobile/lib/features/medications/presentation/screens/today_screen.dart", "apps/mobile/lib/features/caregiver/presentation/screens/caregiver_dashboard_screen.dart", "services/api/app/api/v1/endpoints/caregiver.py"],
    )
    add_page(
        "appendix_f_4", "Appendix F - User Guide: Caregiver Pairing",
        "The patient opens the pairing-code screen and requests a code. Share it privately with the intended caregiver before it expires after ten minutes. The caregiver enters the code in the pairing screen. Once linked, the patient appears in the caregiver dashboard and can be selected for read-only review.",
        "The current account creation flow does not choose the caregiver role. If a caregiver cannot redeem a code because the account has the wrong role, support or an administrative provisioning method is needed. The application has no visible unlink/revoke control in this snapshot; access should be reviewed before using real patient information.",
        bullets=["Share the code only with the intended person.", "Generate a fresh code if the previous one expires.", "Revisit the linked-patient list when the caregiver opens the dashboard."],
        source=["apps/mobile/lib/features/caregiver/presentation/screens/pairing_screens.dart", "services/api/app/api/v1/endpoints/caregiver.py"],
    )
    add_page(
        "appendix_f_5", "Appendix F - User Guide: Vital Measurements",
        "Open Vitals to add a manual reading or use the voice-entry action. For voice entry, speak a clear phrase such as a measurement type and value, then review the transcript and parsed numbers. Correct the values if needed and use Confirm to save. Cancel leaves the record unchanged.",
        "The classification shown by the app is a software label from fixed project rules, not a diagnosis. If the recognized transcript is uncertain, do not confirm it as a true measurement. The app stores the source transcript where provided so that the data origin remains visible in the record.",
        source=["apps/mobile/lib/features/vitals/presentation/screens/vitals_screen.dart", "apps/mobile/lib/features/vitals/presentation/screens/voice_vital_entry.dart", "services/api/app/services/triage.py"],
    )
    add_page(
        "appendix_f_6", "Appendix F - User Guide: Prescription Review",
        "Open the prescription scan screen and choose camera or gallery. The screen presents medicine candidates returned by the API. Review and edit the fields, select only medicines that match the clinician's written instructions, then confirm to create them. Cancel closes the review without creating records.",
        "In the current prototype, the API returns fixed example candidates regardless of the chosen image. The screen is useful for demonstrating review interactions but must not be used to interpret a real prescription. Confirm all medicines and schedules directly with a qualified professional.",
        callout=("Prototype notice", "The selected image is uploaded by the client but is not read by the current API implementation."),
        source=["apps/mobile/lib/features/prescription/presentation/screens/prescription_scan_screen.dart", "services/api/app/api/v1/endpoints/ai.py"],
    )
    add_page(
        "appendix_f_7", "Appendix F - User Guide: Inventory and Refill Message",
        "Open Inventory to see a forecast card for each active medicine. A warning appears when the app estimates fewer than seven days remaining or when the API marks a medicine under its configured low-stock threshold. Select the refill action to ask the API to prepare a message.",
        "The current app displays the returned message in a snackbar and does not open WhatsApp. The forecast is approximate and does not fully account for weekdays or date-limited schedules. Check the physical stock and the prescribed schedule before making a refill decision.",
        source=["apps/mobile/lib/features/inventory/presentation/screens/inventory_screen.dart", "services/api/app/services/inventory.py"],
    )
    add_page(
        "appendix_f_8", "Appendix F - User Guide: SOS and Doctor Report",
        "For SOS, long-press the red control, read the confirmation dialog, and confirm only when appropriate. If location permission is already available, the app attempts to include coordinates. The API stores an SOS record; this version does not contact emergency services or send SMS, call, or push notifications.",
        "For a doctor report, open the report screen and use the share action to create and share a PDF from the default recent period. The PDF contains patient details, medication information, adherence history, vitals, and a disclaimer. It is English LTR and uses transliteration for Arabic text. Protect the exported file as sensitive health information.",
        table=("Table F.2. Sensitive action reminders", ["Action", "Current result", "User check"], [
            ["SOS", "Alert row stored", "Do not assume anyone was contacted"],
            ["Report share", "PDF sent to platform share destination", "Choose trusted recipient and protect file"],
            ["Inventory refill", "Prepared message shown", "Verify quantities and pharmacy details"],
        ]),
        source=["apps/mobile/lib/features/emergency", "apps/mobile/lib/features/reports", "services/api/app/api/v1/endpoints/emergency.py"],
    )

    add_page(
        "appendix_g_1", "Appendix G - Example Authentication Contract",
        "The example below is synthetic and illustrates the API contract rather than a real user's data. A local development configuration may return a test OTP in the response. Production configuration must disable that behavior and connect an approved verification provider before a real sign-in rollout.",
        table=("Table G.1. OTP request/response fields", ["Direction", "Example fields", "Notes"], [
            ["Request", "phone: +201000000000", "Accepted number is normalized by API"],
            ["Response", "phone, expires_in, dev_code?", "dev_code is omitted when response delivery is disabled"],
            ["Verify request", "phone, code, optional name", "Name is used for a new user"],
            ["Verify response", "access_token, refresh_token, token_type, user", "Client stores tokens securely"],
        ]),
        chapter=("Appendix G - Sample Contracts and Records", "appendix_g", "Examples use synthetic values and are intended for developer orientation only."),
        source=["services/api/app/schemas/auth.py", "services/api/app/api/v1/endpoints/auth.py", "apps/mobile/lib/features/auth/data/auth_repository.dart"],
    )
    add_page(
        "appendix_g_2", "Appendix G - Example Medication and Dose Contract",
        "A medication creation request can contain medicine identity fields and an optional list of schedule objects. An adherence request identifies a schedule, stable client UUID, scheduled timestamp, optional actual timestamp, status, and optional reason. The server associates the request with the patient after verifying access.",
        table=("Table G.2. Example field groups", ["Contract", "Representative fields"], [
            ["MedicationCreate", "name, trade_name, active_ingredient, form, strength, stock_count, alert_threshold_days, expiry_date, schedules"],
            ["ScheduleCreate", "time_of_day, days_mask, dose_amount, meal_relation, instructions_ar"],
            ["IntakeLogCreate", "client_uuid, schedule_id, scheduled_time, actual_time, status, reason, logged_offline"],
            ["SyncBatchRequest", "items containing entity, operation, and payload"],
        ]),
        source=["services/api/app/schemas/medication.py", "services/api/app/schemas/adherence.py", "apps/mobile/lib/features/medications/domain/models/medication.dart"],
    )
    add_page(
        "appendix_g_3", "Appendix G - Example Vital and Voice-Parse Contract",
        "A manual vital write includes type, primary value, optional secondary value, meal context, and optional raw transcript. The API calculates the band; the client should not submit a band as authoritative. The voice parser accepts a transcript and requested type and returns extracted values, meal context, a band, and an Arabic message.",
        table=("Table G.3. Example vital fields", ["Field", "Example", "Interpretation"], [
            ["type", "bp", "blood pressure; alternatives glucose or pulse"],
            ["value_primary", "128", "systolic for blood pressure; primary value otherwise"],
            ["value_secondary", "82", "diastolic for blood pressure"],
            ["meal_context", "fasting", "context used for glucose thresholds"],
            ["band", "borderline", "Calculated server-side category"],
            ["raw_transcript", "English or Arabic speech text", "Optional provenance for voice path"],
        ]),
        source=["services/api/app/schemas/vitals.py", "services/api/app/api/v1/endpoints/vitals.py", "services/api/app/services/ai_service.py"],
    )
    add_page(
        "appendix_g_4", "Appendix G - Example Report Summary Interpretation",
        "The report summary response includes patient_id, patient_name, patient_phone, from_date, to_date, adherence_rate_pct, total_doses, taken_doses, skipped_doses, missed_doses_count, active_medications, adherence_history, and vitals_history. Each history list contains structured maps used by the PDF builder.",
        "The current adherence percentage is calculated from the number of stored intake logs in the selected date range. It does not generate an expected-dose denominator from every schedule occurrence, so periods with no log rows can yield a high rate or an empty-data default that should be clearly interpreted. A future contract should expose both logged events and expected schedule counts.",
        table=("Table G.4. Report summary interpretation", ["Response group", "Meaning", "Caveat"], [
            ["Patient fields", "Identity displayed in report", "Contains sensitive data"],
            ["Date range", "Inclusive dates used by endpoint", "Timezone basis is UTC in current logic"],
            ["Dose totals", "Counts of stored intake logs", "Missing schedule events are not synthesized"],
            ["Medication list", "Active medicines and schedule times", "Some schedules are not filtered by active state"],
            ["Vitals history", "Stored values and triage bands", "Band is a project rule, not clinical diagnosis"],
        ]),
        source=["services/api/app/schemas/reports.py", "services/api/app/api/v1/endpoints/reports.py", "apps/mobile/lib/features/reports/domain/models/report_summary.dart"],
    )

    add_page(
        "appendix_h_1", "Appendix H - System Components and Verification Overview",
        "This appendix summarizes the main responsibilities in the application so readers can understand how the product is organized without requiring a source-code directory listing.",
        table=("Table H.1. Main system responsibilities", ["Component", "Responsibility"], [
            ["Application runtime", "Starts the API, registers routes, applies cross-origin rules, and reports service health"],
            ["Configuration", "Loads environment values and checks production requirements"],
            ["Identity and access", "Validates OTPs and tokens, applies role rules, and checks patient access"],
            ["Data persistence", "Manages asynchronous database sessions and schema evolution"],
            ["Mobile networking", "Adds credentials, renews sessions, retries a request once, and reports errors"],
            ["Mobile experience", "Provides navigation, language selection, theme, and shared accessibility defaults"],
        ]),
        chapter=("Appendix H - System Components and Verification Overview", "appendix_h", "This appendix explains the project structure by responsibility rather than listing repository paths."),
    )
    add_page(
        "appendix_h_2", "Appendix H - Backend Capability Groups",
        "The API is organized around user-facing capabilities. Each group combines route handling with typed request and response contracts, data models, and focused service logic where needed.",
        table=("Table H.2. Backend capability groups", ["Capability", "What it handles"], [
            ["Authentication and profile", "OTP, session rotation, logout, and supported profile updates"],
            ["Caregiver coordination", "Temporary pairing codes, linked patients, daily summaries, and computed alerts"],
            ["Medication and adherence", "Medicine records, schedules, today's doses, intake logs, and batch sync"],
            ["Vitals and assisted entry", "Measurement history, deterministic triage, and transcript parsing"],
            ["Inventory and emergency", "Stock estimates, refill text, emergency contacts, and SOS records"],
            ["Reports and devices", "Report summaries, expiring share records, and device-token metadata"],
        ]),
    )
    add_page(
        "appendix_h_3", "Appendix H - Mobile Application Layers",
        "The mobile application separates shared services from feature workflows. This division keeps request handling and session state reusable while allowing each product area to present its own screens and models.",
        table=("Table H.3. Mobile application layers", ["Layer", "Responsibility"], [
            ["Configuration", "API address, feature flags, and build-time values"],
            ["Networking", "HTTP client, authorization header, refresh handling, and typed errors"],
            ["Session and routing", "Secure token storage, user state, and role-aware navigation"],
            ["Presentation", "Localized screens, forms, status cards, and confirmation dialogs"],
            ["Feature data", "Repositories that translate user actions into API operations"],
            ["Localization and theme", "Arabic and English resources, typography, colors, and directional layout"],
        ]),
    )
    add_page(
        "appendix_h_4", "Appendix H - Mobile Feature Responsibilities",
        "Each mobile feature groups related user actions and data. Several features rely on platform plugins, while their user-facing flows remain separate from provider-specific integrations.",
        table=("Table H.4. Mobile feature responsibilities", ["Feature", "User-facing responsibility"], [
            ["Medications", "Medication forms, dose status, schedule editing, and reminder planning"],
            ["Caregiver", "Pairing code display, code entry, and linked-patient dashboard"],
            ["Vitals", "Manual measurement entry, speech-assisted input, and history"],
            ["Prescription", "Image selection, candidate review, editing, and confirmation"],
            ["Inventory", "Stock estimates, low-stock warnings, and refill preparation"],
            ["Emergency", "Contact management and confirmed SOS record creation"],
            ["Reports", "Summary display, PDF generation, and sharing"],
        ]),
    )
    add_page(
        "appendix_h_5", "Appendix H - Verification and Delivery Overview",
        "Automated checks cover API behavior and mobile repositories and screens. Database migrations describe schema changes over time. Continuous integration runs static analysis and test suites, but the current workflow does not build release artifacts or deploy the service.",
        table=("Table H.5. Verification and operations overview", ["Area", "Review coverage"], [
            ["API checks", "Routes, service logic, access control, and configuration"],
            ["Mobile checks", "Repositories, widgets, navigation, and user interactions"],
            ["Database changes", "Versioned schema evolution for server persistence"],
            ["Continuous integration", "API lint and tests plus Flutter analysis and tests"],
            ["Environment setup", "Illustrative local and cloud configuration values"],
            ["Optional services", "Examples for database, cache, and object-storage development"],
        ]),
    )

    add_page(
        "appendix_i_1", "Appendix I - Operations Checklist: Local Development",
        "A local development environment needs Python and uv for the API, Flutter and Dart for the mobile client, a reachable API address, and a local or configured database. Keep the test database separate from any user data. Do not copy the untracked development database or environment secrets into a release artifact.",
        table=("Table I.1. Local startup checklist", ["Item", "Check"], [
            ["API dependency sync", "Run uv sync from services/api"],
            ["Database", "Use the default SQLite mode or configure PostgreSQL"],
            ["Schema", "Apply Alembic migrations for PostgreSQL"],
            ["API process", "Start Uvicorn on the expected local port"],
            ["Mobile dependencies", "Run flutter pub get from apps/mobile"],
            ["Client config", "Set API_BASE_URL and SKIP_AUTH=false for auth flow"],
            ["Device access", "Use emulator alias or a reachable LAN address"],
        ]),
        chapter=("Appendix I - Deployment and Operations Checklist", "appendix_i", "This checklist distinguishes current development steps from future production controls."),
        source=["AGENTS.md", "services/api/app/core/config.py", "apps/mobile/lib/core/config/app_config.dart"],
    )
    add_page(
        "appendix_i_2", "Appendix I - Operations Checklist: Production Configuration",
        "Before deploying, replace the development secret with a randomly generated secret of sufficient length, disable OTP delivery in the response, allow only trusted CORS origins, configure PostgreSQL, and review access to environment files. Configure TLS termination and secure network policy at the hosting layer.",
        "The code validates several dangerous settings, but a passing validator is not a complete deployment review. The current repository does not include a deployable API container or release pipeline. Confirm database migrations, backups, secrets rotation, logging redaction, and external provider configuration in the deployment environment.",
        table=("Table I.2. Production gate", ["Control", "Code evidence", "Operational evidence still required"], [
            ["JWT secret", "Minimum and non-default check", "Secret manager and rotation record"],
            ["OTP", "Response flag rejected in prod", "Approved delivery provider and abuse controls"],
            ["CORS", "Explicit origins required", "Reviewed hostnames and client origins"],
            ["Database", "SQLite rejected in prod", "PostgreSQL backups and restore drill"],
            ["Transport", "No TLS termination in repo", "Hosting TLS and secure headers"],
        ]),
        source=["services/api/app/core/config.py", "infra/.env.example", "infra/docker-compose.yml"],
    )
    add_page(
        "appendix_i_3", "Appendix I - Operations Checklist: Data Protection and Recovery",
        "The project stores personal and health-related information. A deployment should define data minimization, consent, caregiver revocation, retention and deletion, encrypted backups, access logging, incident response, and provider data-flow policies. Public report tokens should be treated as secrets and handled with expiry and revocation safeguards.",
        "No complete account-deletion, retention, audit, or backup/restore workflow is present in the current application. A production operator should not rely on table cascade rules as a substitute for a tested data deletion process. Review database snapshots and logs for accidental exposure of test credentials or sensitive records.",
        bullets=["Document which data is sent to each provider before enabling an integration.", "Redact OTP, JWT, report token, phone, and health details from logs.", "Test restore from an encrypted backup and record the result.", "Provide a clear process to unlink a caregiver and revoke a report token."],
        source=["docs/SECURITY.md", "services/api/app/models", "services/api/app/api/v1/endpoints/reports.py"],
    )
    add_page(
        "appendix_i_4", "Appendix I - Operations Checklist: External Providers",
        "Each future provider integration requires a client adapter, timeout and retry policy, credentials stored outside source control, privacy review, failure-state UX, automated contract tests, and observable delivery or processing status. The endpoint should not return a success message that can be interpreted as downstream completion unless the provider confirms it.",
        table=("Table I.3. Provider integration readiness", ["Provider path", "Current code", "Required before release"], [
            ["Prescription vision/OCR", "Mock function only", "Image processing, evaluation, consent, delete policy"],
            ["SMS/OTP", "Dev code response", "Gateway, abuse controls, delivery status"],
            ["FCM", "Device model/route", "Mobile token registration and sender"],
            ["SOS contact delivery", "Alert row only", "Recipient selection, retries, receipts, truthful UI"],
            ["Object storage", "Environment example", "Signed upload/download, access controls, retention"],
            ["WhatsApp refill", "Message URL returned", "Explicit open action and user review"],
        ]),
        source=["infra/.env.example", "services/api/app/api/v1/endpoints", "services/api/app/services/ai_service.py"],
    )
    add_page(
        "appendix_j_1", "Appendix J - Glossary",
        "The terms below use the meanings applied in this report. They are intended to make the project easier to review across product, mobile, backend, and quality roles.",
        table=("Table J.1. Glossary", ["Term", "Meaning"], [
            ["Active caregiver link", "A stored relationship with active status used by patient access checks"],
            ["Adherence log", "A record of a scheduled dose and the user's reported outcome"],
            ["Access token", "Short-lived signed credential used for protected API calls"],
            ["Caregiver pairing code", "Six-digit code with a ten-minute expiry used to create a link"],
            ["Client UUID", "Unique client-generated identifier associated with a write"],
            ["Deterministic triage", "Band calculation from fixed rules rather than a learned model"],
            ["Local reminder planner", "Helper that builds Android notification requests from today's doses"],
            ["Mock response", "Fixed sample output used in place of real inference or provider work"],
        ]),
        chapter=("Appendix J - Glossary and Interpretation Notes", "appendix_j", "Project terminology is defined by current source and this report's evidence rules."),
        source=["Current schemas, models, and feature source"],
    )
    add_page(
        "appendix_j_2", "Appendix J - Interpretation and Status Notes",
        "Use 'implemented' for a behavior with a current code path; use 'partial' when the pieces exist but the end-to-end flow is incomplete; use 'not implemented' when no current code path was found. A dated execution-plan test result is historical evidence and should not be described as a test run performed during this documentation task.",
        table=("Table J.2. Interpretation rules", ["Statement type", "How it should be read"], [
            ["A route exists", "The endpoint is registered; it may still use mocked or incomplete logic"],
            ["A model exists", "The database can represent a record; a workflow may not create it"],
            ["A test exists", "A scenario is specified in test code; it may not have been run recently"],
            ["An env key exists", "A configuration example is present; the provider may not be integrated"],
            ["A feature is tested", "Only the exact test assertions are covered, not every product claim"],
            ["An alert count is returned", "No external delivery is implied without provider receipt"],
        ]),
        source=["Documentation methodology for this report"],
    )


def clean_visible_repository_paths() -> None:
    replacements = (
        (re.compile(r"(?i)apps/mobile(?:/[\w.*-]+)*"), "the mobile application"),
        (re.compile(r"(?i)apps/doctor-portal(?:/[\w.*-]+)*"), "the doctor-report area"),
        (re.compile(r"(?i)services/api(?:/[\w.*-]+)*"), "the API service"),
        (re.compile(r"(?i)docs/[\w./-]+"), "project documentation"),
        (re.compile(r"(?i)infra/[\w./-]+"), "infrastructure configuration"),
        (re.compile(r"(?i)\.github/workflows/[\w./-]+"), "continuous-integration workflow"),
    )
    extension_labels = {
        "py": "API test module",
        "dart": "mobile test module",
        "md": "project document",
        "yaml": "configuration file",
        "yml": "configuration file",
        "toml": "project configuration",
        "kt": "Android source file",
        "xml": "platform configuration",
        "arb": "localization resource",
        "json": "configuration file",
        "plist": "platform configuration",
    }
    filename_pattern = re.compile(
        r"(?i)(?<![\w/.-])[\w-]+\.(?:py|dart|md|yaml|yml|toml|kt|xml|arb|json|plist)\b"
    )

    def clean(value: str | None) -> str | None:
        if value is None:
            return None
        for pattern, replacement in replacements:
            value = pattern.sub(replacement, value)
        return filename_pattern.sub(
            lambda match: extension_labels[match.group(0).rsplit(".", 1)[-1].lower()],
            value,
        )

    for spec in PAGES:
        spec.title = clean(spec.title) or spec.title
        spec.paragraphs = [clean(value) or value for value in spec.paragraphs]
        spec.bullets = [clean(value) or value for value in spec.bullets]
        spec.table_title = clean(spec.table_title)
        spec.table_headers = [clean(value) or value for value in spec.table_headers]
        spec.table_rows = [[clean(value) or value for value in row] for row in spec.table_rows]
        spec.callout_title = clean(spec.callout_title)
        spec.callout = clean(spec.callout)
        spec.figure_title = clean(spec.figure_title)
        spec.figure_steps = [clean(value) or value for value in spec.figure_steps]
        spec.chapter_title = clean(spec.chapter_title)
        spec.chapter_intro = clean(spec.chapter_intro)


def set_cell_shading(cell, fill: str) -> None:
    properties = cell._tc.get_or_add_tcPr()
    shading = OxmlElement("w:shd")
    shading.set(qn("w:fill"), fill)
    properties.append(shading)


def set_cell_margins(cell, top: int = 75, start: int = 90, bottom: int = 75, end: int = 90) -> None:
    properties = cell._tc.get_or_add_tcPr()
    margins = OxmlElement("w:tcMar")
    for name, value in (("top", top), ("start", start), ("bottom", bottom), ("end", end)):
        node = OxmlElement(f"w:{name}")
        node.set(qn("w:w"), str(value))
        node.set(qn("w:type"), "dxa")
        margins.append(node)
    properties.append(margins)


def add_field(paragraph, instruction: str) -> None:
    field = OxmlElement("w:fldSimple")
    field.set(qn("w:instr"), instruction)
    paragraph._p.append(field)


def set_run_font(run, size: float = 10.5, bold: bool = False, italic: bool = False) -> None:
    run.font.name = "Times New Roman"
    run._element.rPr.rFonts.set(qn("w:eastAsia"), "Times New Roman")
    run.font.size = Pt(size)
    run.bold = bold
    run.italic = italic


def add_docx_paragraph(doc: Document, text: str, *, small: bool = False) -> None:
    paragraph = doc.add_paragraph()
    paragraph.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    paragraph.paragraph_format.space_after = Pt(6 if not small else 3)
    paragraph.paragraph_format.line_spacing = 1.12
    run = paragraph.add_run(text)
    set_run_font(run, 8.4 if small else 10.5, italic=small)


def add_docx_table(doc: Document, title: str, headers: list[str], rows: list[list[str]]) -> None:
    if title:
        caption = doc.add_paragraph()
        caption.alignment = WD_ALIGN_PARAGRAPH.CENTER
        caption.paragraph_format.space_before = Pt(3)
        caption.paragraph_format.space_after = Pt(4)
        set_run_font(caption.add_run(title), 9.2, italic=True)
    table = doc.add_table(rows=1, cols=len(headers))
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.autofit = True
    for index, header in enumerate(headers):
        cell = table.rows[0].cells[index]
        cell.text = header
        set_cell_shading(cell, "26485F")
        cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER
        set_cell_margins(cell)
        for paragraph in cell.paragraphs:
            for run in paragraph.runs:
                set_run_font(run, 8.6, bold=True)
                run.font.color.rgb = RGBColor(255, 255, 255)
    for row_index, row in enumerate(rows):
        cells = table.add_row().cells
        for index, value in enumerate(row):
            cell = cells[index]
            cell.text = str(value)
            cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.TOP
            set_cell_margins(cell)
            if row_index % 2 == 1:
                set_cell_shading(cell, "F3F6F8")
            for paragraph in cell.paragraphs:
                paragraph.paragraph_format.space_after = Pt(0)
                for run in paragraph.runs:
                    set_run_font(run, 8.25)
    doc.add_paragraph().paragraph_format.space_after = Pt(1)


def add_docx_diagram(doc: Document, title: str, steps: list[str]) -> None:
    table = doc.add_table(rows=1, cols=len(steps) * 2 - 1)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    for index, step in enumerate(steps):
        cell = table.rows[0].cells[index * 2]
        cell.text = step
        set_cell_shading(cell, "EEF3F6")
        set_cell_margins(cell, 80, 65, 80, 65)
        for paragraph in cell.paragraphs:
            paragraph.alignment = WD_ALIGN_PARAGRAPH.CENTER
            for run in paragraph.runs:
                set_run_font(run, 8.1, bold=True)
        if index < len(steps) - 1:
            arrow_cell = table.rows[0].cells[index * 2 + 1]
            arrow_cell.text = "→"
            for paragraph in arrow_cell.paragraphs:
                paragraph.alignment = WD_ALIGN_PARAGRAPH.CENTER
                for run in paragraph.runs:
                    set_run_font(run, 11, bold=True)
    caption = doc.add_paragraph()
    caption.alignment = WD_ALIGN_PARAGRAPH.CENTER
    set_run_font(caption.add_run(title), 9.2, italic=True)


def add_docx_spec(doc: Document, spec: PageSpec) -> None:
    if spec.chapter_title:
        doc.add_heading(spec.chapter_title, level=1)
        if spec.chapter_intro:
            add_docx_paragraph(doc, spec.chapter_intro, small=True)
    doc.add_heading(spec.title, level=2)
    for paragraph in spec.paragraphs:
        add_docx_paragraph(doc, paragraph)
    if spec.figure_steps:
        add_docx_diagram(doc, spec.figure_title or "System flow", spec.figure_steps)
    for bullet in spec.bullets:
        paragraph = doc.add_paragraph(style="List Bullet")
        paragraph.paragraph_format.space_after = Pt(3)
        set_run_font(paragraph.add_run(bullet), 10.2)
    if spec.table_rows:
        add_docx_table(doc, spec.table_title or "", spec.table_headers, spec.table_rows)
    if spec.callout:
        callout = doc.add_table(rows=1, cols=1)
        cell = callout.cell(0, 0)
        cell.text = (spec.callout_title or "Project note") + "\n" + spec.callout
        set_cell_shading(cell, "F1F5F7")
        set_cell_margins(cell, 100, 130, 100, 130)
        for paragraph in cell.paragraphs:
            for run in paragraph.runs:
                set_run_font(run, 9.0, bold=run.text == (spec.callout_title or "Project note"))
def build_docx() -> None:
    doc = Document()
    section = doc.sections[0]
    section.page_width = Inches(8.27)
    section.page_height = Inches(11.69)
    section.top_margin = Inches(0.78)
    section.bottom_margin = Inches(0.72)
    section.left_margin = Inches(0.82)
    section.right_margin = Inches(0.82)
    section.different_first_page_header_footer = True

    normal = doc.styles["Normal"]
    normal.font.name = "Times New Roman"
    normal._element.rPr.rFonts.set(qn("w:eastAsia"), "Times New Roman")
    normal.font.size = Pt(10.5)
    for style_name, size in (("Heading 1", 17), ("Heading 2", 13.5), ("Heading 3", 11.5)):
        style = doc.styles[style_name]
        style.font.name = "Times New Roman"
        style._element.rPr.rFonts.set(qn("w:eastAsia"), "Times New Roman")
        style.font.size = Pt(size)
        style.font.bold = True
        style.font.color.rgb = RGBColor(20, 46, 67)

    header = section.header.paragraphs[0]
    header.text = "Medliva | Comprehensive Project Documentation"
    for run in header.runs:
        set_run_font(run, 8.2)
        run.font.color.rgb = RGBColor(75, 89, 99)
    footer = section.footer.paragraphs[0]
    footer.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    set_run_font(footer.add_run(SNAPSHOT_DATE + "  |  "), 8.2)
    add_field(footer, "PAGE")

    cover = doc.add_paragraph()
    cover.paragraph_format.space_before = Pt(105)
    cover.alignment = WD_ALIGN_PARAGRAPH.CENTER
    set_run_font(cover.add_run("Medliva"), 17, bold=True)
    title = doc.add_paragraph()
    title.alignment = WD_ALIGN_PARAGRAPH.CENTER
    title.paragraph_format.space_before = Pt(24)
    title.paragraph_format.space_after = Pt(15)
    set_run_font(title.add_run("An Accessible Medication Management and Family Care Coordination System"), 24, bold=True)
    subtitle = doc.add_paragraph()
    subtitle.alignment = WD_ALIGN_PARAGRAPH.CENTER
    set_run_font(subtitle.add_run("Comprehensive Project Documentation"), 16, bold=True)
    doc.add_paragraph()
    add_docx_table(
        doc, "", ["Project report"], [[
            "Flutter mobile application\nFastAPI modular backend\nRepository snapshot: " + SNAPSHOT_DATE
        ]],
    )
    note = doc.add_paragraph()
    note.paragraph_format.space_before = Pt(75)
    note.alignment = WD_ALIGN_PARAGRAPH.CENTER
    set_run_font(note.add_run("Prepared from the implementation, tests, and project documentation available in the repository."), 9, italic=True)

    doc.add_page_break()
    doc.add_heading("Acknowledgments", level=1)
    add_docx_paragraph(doc, "The Medliva project team acknowledges the engineering work represented by the current mobile and API codebases, the open-source maintainers whose tools support the project, and the reviewers who shaped the project requirements. This report uses the repository, its tests, and its implementation notes as evidence. It avoids assigning individual authorship or supervision because those details were not supplied with the project files.")
    add_docx_paragraph(doc, "The report also distinguishes delivery from intent. A screen, model, route, or helper is described as implemented only when it appears in the current source. External services, clinical validation, and production deployment are not inferred from environment examples or roadmap text.")

    doc.add_page_break()
    doc.add_heading("Abstract", level=1)
    for text in (
        "Medliva is a software project for supporting older adults and their family caregivers with medication schedules, adherence records, vital-sign entry, medicine inventory, emergency contacts, and clinician-facing summaries. The current repository contains a Flutter application with Arabic and English localization, a FastAPI REST API, SQLAlchemy data models, Alembic migrations, and automated API and Flutter tests.",
        "The mobile client includes OTP-based sign-in flows, role-aware patient and caregiver screens, medication management, dose logging, caregiver pairing, manual and speech-assisted vital entry, prescription-image selection and review, inventory forecasts, an SOS interaction, and an in-app PDF report share flow. The API provides matching endpoints for identity, linked patients, medications, adherence, vitals, inventory, emergency contacts, reports, and device registration.",
        "This documentation evaluates the delivered code rather than presenting a target design as finished. Important prototype boundaries remain: the prescription endpoint returns fixed sample medicines and does not inspect the uploaded image; the reminder planner and secure offline queue are not connected to the active dose screen; SOS creates a database alert but does not dispatch a notification; and the report PDF is rendered in English with Arabic text transliterated. The project demonstrates a broad feature set while leaving external delivery, clinical validation, and production controls for later work.",
    ):
        add_docx_paragraph(doc, text)
    add_docx_paragraph(doc, "Keywords: medication adherence, older adults, caregiver coordination, Flutter, FastAPI, accessibility, vital signs, software documentation.", small=True)

    doc.add_page_break()
    doc.add_heading("Table of Contents", level=1)
    toc_note = doc.add_paragraph()
    set_run_font(toc_note.add_run("This editable Word table of contents is generated by Word. Select it and choose Update Field to populate current page numbers. The companion PDF contains a completed contents list."), 9, italic=True)
    toc = doc.add_paragraph()
    add_field(toc, 'TOC \\o "1-2" \\h \\z \\u')

    for heading, specs, label in (
        ("List of Figures", [spec for spec in PAGES if spec.figure_title], "figure_title"),
        ("List of Tables", [spec for spec in PAGES if spec.table_title], "table_title"),
    ):
        doc.add_page_break()
        doc.add_heading(heading, level=1)
        for spec in specs:
            item = doc.add_paragraph()
            item.paragraph_format.space_after = Pt(2)
            value = getattr(spec, label)
            set_run_font(item.add_run(str(value)), 9.2)

    doc.add_page_break()
    doc.add_heading("Abbreviations and Acronyms", level=1)
    add_docx_table(
        doc, "", ["Term", "Meaning in this report"], [
            ["API", "Application Programming Interface"], ["AI", "Artificial Intelligence"],
            ["CI", "Continuous Integration"], ["CRUD", "Create, Read, Update, Delete"],
            ["CORS", "Cross-Origin Resource Sharing"], ["DTO", "Data Transfer Object"],
            ["FCM", "Firebase Cloud Messaging"], ["FR", "Functional Requirement"],
            ["JWT", "JSON Web Token"], ["MVP", "Minimum Viable Product"],
            ["OTP", "One-Time Password"], ["PDF", "Portable Document Format"],
            ["RBAC", "Role-Based Access Control"], ["REST", "Representational State Transfer"],
            ["SRS", "Software Requirements Specification"], ["STT", "Speech-to-Text"],
            ["TLS", "Transport Layer Security"], ["UI", "User Interface"],
            ["UX", "User Experience"], ["WCAG", "Web Content Accessibility Guidelines"],
        ],
    )

    for spec in PAGES:
        doc.add_page_break()
        add_docx_spec(doc, spec)

    doc.core_properties.title = "Medliva Project Documentation"
    doc.core_properties.subject = "Implementation-grounded comprehensive project report"
    doc.core_properties.author = "Medliva Project Team"
    doc.core_properties.keywords = "Medliva, Flutter, FastAPI, medication management, caregiver"
    doc.save(DOCX_PATH)


def main() -> None:
    define_chapters_one_to_three()
    clean_visible_repository_paths()
    register_fonts()
    first_pass = render_pdf(TEMP_PDF_PATH)
    page_map = dict(first_pass.page_map)
    chapter_start = page_map.get("chapter_1", 1)
    final_doc = MedlivaDocTemplate(
        str(PDF_PATH),
        pagesize=A4,
        leftMargin=0.72 * inch,
        rightMargin=0.72 * inch,
        topMargin=0.78 * inch,
        bottomMargin=0.72 * inch,
        title="Medliva Project Documentation",
        author="Medliva Project Team",
        subject="Implementation-grounded project report",
    )
    final_doc.chapter_start_page = chapter_start
    story, _ = build_pdf_story(page_map)
    final_doc.build(story)
    TEMP_PDF_PATH.unlink(missing_ok=True)
    build_docx()

    page_count = len(PdfReader(str(PDF_PATH)).pages)
    if page_count <= 100:
        raise RuntimeError(f"PDF is only {page_count} pages; expected more than 100.")
    print(f"PDF: {PDF_PATH} ({page_count} pages)")
    print(f"DOCX: {DOCX_PATH}")
    print(f"Defined sections: {len(PAGES)}; indexed content starts on PDF page {chapter_start}")


if __name__ == "__main__":
    main()

