#!/usr/bin/env python3
"""
Build the Agent OS Playbook PDF ebook.
Combines QUICKSTART.md + PLAYBOOK.md with a cover page.
"""
import re
import sys
from pathlib import Path

import markdown as md
from reportlab.lib.colors import HexColor
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import inch
from reportlab.platypus import (
    BaseDocTemplate,
    Frame,
    PageBreak,
    PageTemplate,
    Paragraph,
    Preformatted,
    Spacer,
    Table,
    TableStyle,
)


# ---------- Styles ----------
INK   = HexColor("#1a1a1a")
MUTED = HexColor("#666666")
ACCENT = HexColor("#2563eb")
CODE_BG = HexColor("#f4f4f5")
CODE_FG = HexColor("#0f172a")
TABLE_HEADER_BG = HexColor("#0f172a")
TABLE_HEADER_FG = HexColor("#ffffff")
TABLE_ROW_ALT = HexColor("#fafafa")
RULE = HexColor("#e5e5e5")


def make_styles():
    s = getSampleStyleSheet()
    base_kwargs = dict(textColor=INK, leading=15, fontName="Helvetica")
    return {
        "h1": ParagraphStyle("h1", parent=s["Heading1"], fontSize=22, spaceBefore=20, spaceAfter=14, textColor=INK, fontName="Helvetica-Bold", leading=26),
        "h2": ParagraphStyle("h2", parent=s["Heading2"], fontSize=16, spaceBefore=18, spaceAfter=10, textColor=INK, fontName="Helvetica-Bold", leading=20),
        "h3": ParagraphStyle("h3", parent=s["Heading3"], fontSize=13, spaceBefore=14, spaceAfter=8, textColor=INK, fontName="Helvetica-Bold", leading=17),
        "h4": ParagraphStyle("h4", parent=s["Heading4"], fontSize=11, spaceBefore=10, spaceAfter=6, textColor=INK, fontName="Helvetica-Bold", leading=14),
        "body": ParagraphStyle("body", parent=s["BodyText"], fontSize=10, spaceAfter=6, textColor=INK, fontName="Helvetica", leading=14),
        "blockquote": ParagraphStyle("bq", parent=s["BodyText"], fontSize=10, spaceAfter=6, textColor=MUTED, fontName="Helvetica-Oblique", leading=14, leftIndent=18, borderPadding=4),
        "li": ParagraphStyle("li", parent=s["BodyText"], fontSize=10, spaceAfter=3, textColor=INK, fontName="Helvetica", leading=13, leftIndent=18, bulletIndent=6),
        "code": ParagraphStyle("code", fontName="Courier", fontSize=8.5, textColor=CODE_FG, leading=10.5, leftIndent=8, rightIndent=8, backColor=CODE_BG, borderPadding=6, spaceBefore=4, spaceAfter=8, borderRadius=3),
        "cover_title": ParagraphStyle("cover_title", fontSize=28, alignment=TA_CENTER, fontName="Helvetica-Bold", textColor=INK, leading=34, spaceAfter=18),
        "cover_sub": ParagraphStyle("cover_sub", fontSize=13, alignment=TA_CENTER, fontName="Helvetica", textColor=MUTED, leading=18, spaceAfter=120),
        "cover_meta": ParagraphStyle("cover_meta", fontSize=11, alignment=TA_CENTER, fontName="Helvetica", textColor=MUTED, leading=16),
        "cover_author": ParagraphStyle("cover_author", fontSize=14, alignment=TA_CENTER, fontName="Helvetica-Bold", textColor=INK, leading=18, spaceBefore=200),
        "part_label": ParagraphStyle("part_label", fontSize=10, alignment=TA_CENTER, fontName="Helvetica", textColor=MUTED, leading=14, spaceBefore=200, spaceAfter=20),
        "part_title": ParagraphStyle("part_title", fontSize=24, alignment=TA_CENTER, fontName="Helvetica-Bold", textColor=INK, leading=30, spaceAfter=200),
    }


# ---------- Inline markdown handling ----------
def md_inline_to_rl(text: str) -> str:
    """Convert inline markdown to ReportLab's mini-HTML."""
    # Escape ReportLab's special chars first (& < >)
    text = text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
    # Inline code: `foo` → <font name="Courier" backColor="#f4f4f5">foo</font>
    text = re.sub(r"`([^`]+)`", r'<font name="Courier" size="9" backColor="#eef2ff">\1</font>', text)
    # Bold: **foo** → <b>foo</b>
    text = re.sub(r"\*\*([^*]+)\*\*", r"<b>\1</b>", text)
    # Italic: *foo* or _foo_ → <i>foo</i>
    text = re.sub(r"(?<!\*)\*([^*]+)\*(?!\*)", r"<i>\1</i>", text)
    text = re.sub(r"(?<![a-zA-Z0-9])_([^_]+)_(?![a-zA-Z0-9])", r"<i>\1</i>", text)
    # Links: [text](url) → <link href="url">text</link>
    text = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", r'<link href="\2" color="#2563eb">\1</link>', text)
    # Strikethrough: ~~foo~~ → <strike>foo</strike>
    text = re.sub(r"~~([^~]+)~~", r"<strike>\1</strike>", text)
    return text


# ---------- Markdown → flowables ----------
def parse_markdown_to_flowables(md_text: str, styles: dict, source_label: str = ""):
    """Walk markdown line-by-line and emit ReportLab flowables.
    Handles: headings, paragraphs, fenced code blocks, lists, tables, blockquotes, hr."""
    flowables = []
    lines = md_text.split("\n")
    i = 0
    while i < len(lines):
        line = lines[i]
        stripped = line.strip()

        # Skip frontmatter / pure blank
        if not stripped:
            i += 1
            continue

        # Horizontal rule
        if re.match(r"^[-*_]{3,}\s*$", stripped):
            flowables.append(Spacer(1, 6))
            t = Table([[""]], colWidths=[6.5 * inch])
            t.setStyle(TableStyle([("LINEBELOW", (0, 0), (-1, -1), 0.5, RULE)]))
            flowables.append(t)
            flowables.append(Spacer(1, 6))
            i += 1
            continue

        # Fenced code block
        m = re.match(r"^```(\w*)\s*$", stripped)
        if m:
            lang = m.group(1)
            i += 1
            code_lines = []
            while i < len(lines) and not lines[i].strip().startswith("```"):
                code_lines.append(lines[i])
                i += 1
            code_text = "\n".join(code_lines)
            flowables.append(Preformatted(code_text, styles["code"]))
            i += 1  # skip closing ```
            continue

        # Headings
        m = re.match(r"^(#{1,4})\s+(.+?)\s*$", stripped)
        if m:
            level = len(m.group(1))
            heading = md_inline_to_rl(m.group(2))
            style_key = f"h{level}"
            flowables.append(Paragraph(heading, styles[style_key]))
            i += 1
            continue

        # Blockquote
        if stripped.startswith(">"):
            quote_lines = []
            while i < len(lines) and lines[i].strip().startswith(">"):
                quote_lines.append(lines[i].strip().lstrip(">").lstrip())
                i += 1
            quote = " ".join(quote_lines)
            flowables.append(Paragraph(md_inline_to_rl(quote), styles["blockquote"]))
            continue

        # Tables (must precede list/paragraph since pipes can appear in code)
        if "|" in stripped and i + 1 < len(lines) and re.match(r"^\s*\|?[\s:|-]+\|?\s*$", lines[i + 1]):
            table_rows = []
            while i < len(lines) and "|" in lines[i]:
                row = lines[i].strip()
                if re.match(r"^\s*\|?[\s:|-]+\|?\s*$", row):
                    i += 1
                    continue
                cells = [c.strip() for c in row.strip("|").split("|")]
                table_rows.append(cells)
                i += 1
            if table_rows:
                # Normalize widths
                ncols = max(len(r) for r in table_rows)
                for r in table_rows:
                    while len(r) < ncols:
                        r.append("")
                # Render cells through Paragraph for inline formatting + wrapping
                rendered = []
                cell_style = ParagraphStyle("cell", parent=styles["body"], fontSize=8.5, leading=11, spaceAfter=0)
                header_style = ParagraphStyle("hcell", parent=cell_style, fontName="Helvetica-Bold", textColor=TABLE_HEADER_FG)
                for ridx, row in enumerate(table_rows):
                    rendered.append([Paragraph(md_inline_to_rl(c), header_style if ridx == 0 else cell_style) for c in row])
                avail = 6.5 * inch
                col_widths = [avail / ncols] * ncols
                t = Table(rendered, colWidths=col_widths, repeatRows=1)
                tstyle = [
                    ("BACKGROUND", (0, 0), (-1, 0), TABLE_HEADER_BG),
                    ("TEXTCOLOR",  (0, 0), (-1, 0), TABLE_HEADER_FG),
                    ("VALIGN",     (0, 0), (-1, -1), "TOP"),
                    ("LEFTPADDING",(0, 0), (-1, -1), 6),
                    ("RIGHTPADDING",(0, 0), (-1, -1), 6),
                    ("TOPPADDING", (0, 0), (-1, -1), 5),
                    ("BOTTOMPADDING",(0, 0), (-1, -1), 5),
                    ("GRID",       (0, 0), (-1, -1), 0.25, RULE),
                ]
                for ridx in range(2, len(rendered) + 1, 2):
                    tstyle.append(("BACKGROUND", (0, ridx - 1), (-1, ridx - 1), TABLE_ROW_ALT))
                t.setStyle(TableStyle(tstyle))
                flowables.append(Spacer(1, 4))
                flowables.append(t)
                flowables.append(Spacer(1, 8))
            continue

        # Lists (-, *, 1. )
        list_match = re.match(r"^(\s*)([-*]|\d+\.)\s+(.*)$", line)
        if list_match:
            list_items = []
            while i < len(lines):
                m = re.match(r"^(\s*)([-*]|\d+\.)\s+(.*)$", lines[i])
                if not m:
                    break
                indent_spaces = len(m.group(1))
                marker = m.group(2)
                content = m.group(3)
                # Continuation lines (no marker, but indented)
                j = i + 1
                while j < len(lines):
                    nxt = lines[j]
                    if not nxt.strip():
                        break
                    if re.match(r"^(\s*)([-*]|\d+\.)\s", nxt):
                        break
                    if re.match(r"^#{1,4}\s", nxt.strip()):
                        break
                    # Break on fenced code blocks — they should render as code, not inline.
                    if nxt.strip().startswith("```"):
                        break
                    # Break on tables.
                    if "|" in nxt and j + 1 < len(lines) and re.match(r"^\s*\|?[\s:|-]+\|?\s*$", lines[j + 1]):
                        break
                    content += " " + nxt.strip()
                    j += 1
                bullet_char = "•" if marker in ("-", "*") else marker
                list_items.append((indent_spaces, bullet_char, content))
                i = j
            for indent_spaces, bullet, content in list_items:
                p = ParagraphStyle(
                    f"li_{indent_spaces}",
                    parent=styles["li"],
                    leftIndent=18 + indent_spaces * 6,
                    bulletIndent=6 + indent_spaces * 6,
                )
                flowables.append(Paragraph(md_inline_to_rl(content), p, bulletText=bullet))
            continue

        # Default: paragraph (collect until blank line / structural element)
        para_lines = [stripped]
        i += 1
        while i < len(lines):
            nxt = lines[i].rstrip()
            if not nxt.strip():
                break
            if re.match(r"^(#{1,4}\s|```|\s*[-*]\s|\s*\d+\.\s|>|\|)", nxt):
                break
            para_lines.append(nxt.strip())
            i += 1
        flowables.append(Paragraph(md_inline_to_rl(" ".join(para_lines)), styles["body"]))
    return flowables


# ---------- Page chrome ----------
def on_page(canvas, doc):
    canvas.saveState()
    # Footer
    page_num = canvas.getPageNumber()
    if page_num > 1:  # skip cover
        canvas.setFont("Helvetica", 8)
        canvas.setFillColor(MUTED)
        canvas.drawString(0.75 * inch, 0.5 * inch, "The Multi-AI Handover Playbook")
        canvas.drawRightString(7.75 * inch, 0.5 * inch, f"Page {page_num}")
        canvas.setStrokeColor(RULE)
        canvas.setLineWidth(0.25)
        canvas.line(0.75 * inch, 0.7 * inch, 7.75 * inch, 0.7 * inch)
    canvas.restoreState()


# ---------- Build ----------
def main():
    here = Path(__file__).resolve().parent.parent
    quickstart = (here / "QUICKSTART.md").read_text()
    playbook   = (here / "PLAYBOOK.md").read_text()
    out        = here / "PLAYBOOK.pdf"

    styles = make_styles()

    doc = BaseDocTemplate(
        str(out),
        pagesize=letter,
        leftMargin=0.85 * inch,
        rightMargin=0.85 * inch,
        topMargin=0.75 * inch,
        bottomMargin=0.85 * inch,
        title="The Multi-AI Handover Playbook",
        author="Mundo Sanchez",
        subject="Multi-AI development workflow + security template",
    )
    frame = Frame(doc.leftMargin, doc.bottomMargin, doc.width, doc.height, id="normal")
    template = PageTemplate(id="main", frames=[frame], onPage=on_page)
    doc.addPageTemplates([template])

    story = []

    # ---------- Cover ----------
    story.append(Spacer(1, 100))
    story.append(Paragraph("The Multi-AI Handover Playbook", styles["cover_title"]))
    story.append(Paragraph(
        "How to ship software across Claude Code, Codex, Cursor,<br/>and any AI assistant — without losing context, leaking secrets,<br/>or stepping on yourself.",
        styles["cover_sub"],
    ))
    story.append(Paragraph("Mundo Sanchez", styles["cover_author"]))
    story.append(Paragraph("Agent OS · v2.3.0", styles["cover_meta"]))
    story.append(Paragraph("github.com/munsanco13/agent-os", styles["cover_meta"]))
    story.append(PageBreak())

    # ---------- Part divider: QUICKSTART ----------
    story.append(Paragraph("PART ONE", styles["part_label"]))
    story.append(Paragraph("Quickstart", styles["part_title"]))
    story.append(Paragraph(
        "For people who&rsquo;ve never done this before. Plain English, every step.",
        ParagraphStyle("part_sub", fontSize=11, alignment=TA_CENTER, fontName="Helvetica-Oblique", textColor=MUTED, leading=15)
    ))
    story.append(PageBreak())

    # ---------- QUICKSTART body ----------
    story.extend(parse_markdown_to_flowables(quickstart, styles, "QUICKSTART"))
    story.append(PageBreak())

    # ---------- Part divider: PLAYBOOK ----------
    story.append(Paragraph("PART TWO", styles["part_label"]))
    story.append(Paragraph("The Playbook", styles["part_title"]))
    story.append(Paragraph(
        "The full system: architecture, security model, daily workflow.",
        ParagraphStyle("part_sub", fontSize=11, alignment=TA_CENTER, fontName="Helvetica-Oblique", textColor=MUTED, leading=15)
    ))
    story.append(PageBreak())

    # ---------- PLAYBOOK body ----------
    story.extend(parse_markdown_to_flowables(playbook, styles, "PLAYBOOK"))

    doc.build(story)
    print(f"✓ wrote {out}  ({out.stat().st_size:,} bytes)")


if __name__ == "__main__":
    main()
