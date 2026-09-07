#!/usr/bin/env python3
"""MDMD: convert md/*.md to typst/chapters/*.typ and compile a single PDF."""

from __future__ import annotations

import argparse
import html
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MD_DIR = ROOT / "md"
TYP_DIR = ROOT / "typst"
CH_DIR = TYP_DIR / "chapters"
PDF_DIR = ROOT / "pdf"
TEMPLATE = TYP_DIR / "template.typ"
MAIN = TYP_DIR / "main.typ"
PDF_OUT = PDF_DIR / "MDMD_PE_ASK_Study.pdf"

CALLOUTS = ("핵심", "예시", "트러블슈팅", "아이디어", "면접", "주의", "심화")
CALLOUT_RE = re.compile(r"^>\s*\*\*\[(" + "|".join(CALLOUTS) + r")\]\*\*\s*(.*)$")


def escape_text(s: str) -> str:
    s = s.replace("\\", "\\\\")
    s = s.replace("#", r"\#")
    s = s.replace("$", r"\$")
    s = s.replace("@", r"\@")
    s = s.replace("<", r"\<")
    s = s.replace(">", r"\>")
    s = s.replace("_", r"\_")
    s = s.replace("*", r"\*")
    s = s.replace("[", r"\[")
    s = s.replace("]", r"\]")
    return s


def inline(s: str) -> str:
    """Convert a subset of markdown inline markup to Typst."""
    out: list[str] = []
    i = 0
    n = len(s)
    while i < n:
        if s.startswith("`", i):
            j = s.find("`", i + 1)
            if j == -1:
                out.append(escape_text(s[i:]))
                break
            code = s[i + 1 : j].replace("\\", "\\\\")
            out.append(f"`{code}`")
            i = j + 1
            continue
        if s.startswith("**", i):
            j = s.find("**", i + 2)
            if j == -1:
                out.append(escape_text(s[i:]))
                break
            inner = inline(s[i + 2 : j])
            out.append(f"*{inner}*")
            i = j + 2
            continue
        if s.startswith("*", i) and not s.startswith("**", i):
            j = s.find("*", i + 1)
            if j == -1:
                out.append(escape_text(s[i:]))
                break
            inner = inline(s[i + 1 : j])
            out.append(f"_{inner}_")
            i = j + 1
            continue
        if s.startswith("~~", i):
            out.append(escape_text("~"))
            i += 1
            continue
        out.append(escape_text(s[i]))
        i += 1
    return "".join(out)


def split_table_row(line: str) -> list[str]:
    line = line.strip()
    if line.startswith("|"):
        line = line[1:]
    if line.endswith("|"):
        line = line[:-1]
    return [c.strip() for c in line.split("|")]


def is_sep_row(cells: list[str]) -> bool:
    if not cells:
        return False
    return all(re.fullmatch(r":?-{3,}:?", c.replace(" ", "")) is not None for c in cells)


def convert_table(rows: list[list[str]]) -> str:
    if not rows:
        return ""
    header, body = rows[0], rows[1:]
    cols = max(len(header), max((len(r) for r in body), default=0))

    def pad(r: list[str]) -> list[str]:
        r = r + [""] * (cols - len(r))
        return r[:cols]

    header = pad(header)
    body = [pad(r) for r in body]
    lines = [
        f"#table(",
        f"  columns: {cols},",
        f"  align: left,",
        "  table.header(",
    ]
    for c in header:
        lines.append(f"    [*{inline(c)}*],")
    lines.append("  ),")
    for r in body:
        for c in r:
            lines.append(f"  [{inline(c)}],")
    lines.append(")")
    return "\n".join(lines)


def convert_md(text: str) -> str:
    text = text.replace("\r\n", "\n").replace("\r", "\n")
    lines = text.split("\n")
    out: list[str] = []
    i = 0
    in_code = False
    code_lines: list[str] = []
    para: list[str] = []
    list_buf: list[tuple[str, int, str]] = []

    def flush_para() -> None:
        nonlocal para
        if para:
            joined = " ".join(para)
            out.append(inline(joined))
            out.append("")
            para = []

    def flush_list() -> None:
        nonlocal list_buf
        if not list_buf:
            return
        # Typst list: '-' or '1.'
        for kind, indent, content in list_buf:
            pad = "  " * indent
            marker = "-" if kind == "ul" else "+"
            out.append(f"{pad}{marker} {inline(content)}")
        out.append("")
        list_buf = []

    def flush_all() -> None:
        flush_para()
        flush_list()

    while i < len(lines):
        line = lines[i]
        if in_code:
            if line.strip().startswith("```"):
                raw = "\n".join(code_lines)
                raw = raw.replace("\\", "\\\\").replace("`", "\\`")
                out.append("```text")
                out.append(raw)
                out.append("```")
                out.append("")
                in_code = False
                code_lines = []
            else:
                code_lines.append(line)
            i += 1
            continue

        if line.strip().startswith("```"):
            flush_all()
            in_code = True
            code_lines = []
            i += 1
            continue

        if re.match(r"^#{1,4} ", line):
            flush_all()
            hashes, title = line.split(" ", 1)
            level = min(len(hashes), 4)
            eq = "=" * level
            out.append(f"{eq} {inline(title.strip())}")
            out.append("")
            i += 1
            continue

        if re.fullmatch(r"-{3,}", line.strip()):
            flush_all()
            out.append("#line(length: 100%, stroke: 0.4pt + rgb(\"#CCCCCC\"))")
            out.append("")
            i += 1
            continue

        if line.strip().startswith("|") and "|" in line.strip()[1:]:
            flush_all()
            table_lines = []
            while i < len(lines) and lines[i].strip().startswith("|"):
                table_lines.append(lines[i])
                i += 1
            parsed = [split_table_row(t) for t in table_lines]
            parsed = [r for r in parsed if not is_sep_row(r)]
            out.append(convert_table(parsed))
            out.append("")
            continue

        if line.startswith(">"):
            flush_all()
            block = []
            while i < len(lines) and (lines[i].startswith(">") or lines[i].strip() == ""):
                if lines[i].strip() == "" and block:
                    # blank inside quote: keep if next is still quote
                    if i + 1 < len(lines) and lines[i + 1].startswith(">"):
                        block.append("")
                        i += 1
                        continue
                    break
                if lines[i].startswith(">"):
                    block.append(re.sub(r"^>\s?", "", lines[i]))
                i += 1
            kind = None
            rest_first = ""
            if block:
                m = CALLOUT_RE.match("> **[" + "]** dummy")
                m = re.match(
                    r"^\*\*\[(" + "|".join(CALLOUTS) + r")\]\*\*\s*(.*)$",
                    block[0],
                )
                if m:
                    kind = m.group(1)
                    rest_first = m.group(2)
                    body_lines = ([rest_first] if rest_first else []) + block[1:]
                else:
                    body_lines = block
            else:
                body_lines = []
            body = inline(" ".join(x for x in body_lines if x is not None))
            if kind:
                out.append(f'#callout("{kind}")[{body}]')
            else:
                out.append(f"#quote[{body}]")
            out.append("")
            continue

        ul = re.match(r"^(\s*)[-*] (.+)$", line)
        ol = re.match(r"^(\s*)(\d+)\. (.+)$", line)
        if ul or ol:
            flush_para()
            if ul:
                spaces, content = ul.group(1), ul.group(2)
                kind = "ul"
            else:
                spaces, content = ol.group(1), ol.group(3)
                kind = "ol"
            indent = len(spaces) // 2
            list_buf.append((kind, indent, content))
            i += 1
            continue

        if not line.strip():
            flush_all()
            i += 1
            continue

        flush_list()
        para.append(line.strip())
        i += 1

    flush_all()
    if in_code:
        raw = "\n".join(code_lines).replace("\\", "\\\\").replace("`", "\\`")
        out.append("```text")
        out.append(raw)
        out.append("```")

    # drop leading document title duplication handling is fine
    return "\n".join(out).strip() + "\n"


def write_main(chapter_files: list[Path]) -> None:
    includes = "\n".join(f'#include "chapters/{p.name}"' for p in chapter_files)
    MAIN.write_text(
        "#import \"template.typ\": mdmd-init\n"
        "#show: mdmd-init.with(\n"
        '  title: [MDMD 학습자료],\n'
        '  subtitle: [Product Engineering · DRAM / NAND / HBM],\n'
        ")\n\n"
        f"{includes}\n",
        encoding="utf-8",
    )


def compile_pdf() -> int:
    PDF_DIR.mkdir(parents=True, exist_ok=True)
    try:
        import typst  # type: ignore
    except ImportError:
        print("typst python package missing. pip install typst", file=sys.stderr)
        return 2
    font_paths = [
        r"C:\Windows\Fonts",
        str(Path.home() / "AppData/Local/Microsoft/Windows/Fonts"),
    ]
    print(f"compiling {MAIN} -> {PDF_OUT}")
    try:
        pdf_bytes = typst.compile(str(MAIN), font_paths=font_paths)
    except TypeError:
        pdf_bytes = typst.compile(str(MAIN))
    PDF_OUT.write_bytes(pdf_bytes)
    print(f"wrote {PDF_OUT} ({PDF_OUT.stat().st_size} bytes)")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--no-pdf", action="store_true")
    args = parser.parse_args()

    MD_DIR.mkdir(parents=True, exist_ok=True)
    CH_DIR.mkdir(parents=True, exist_ok=True)
    PDF_DIR.mkdir(parents=True, exist_ok=True)

    md_files = sorted(MD_DIR.glob("*.md"))
    if not md_files:
        print("no markdown in md/", file=sys.stderr)
        return 1

    typ_files: list[Path] = []
    for md in md_files:
        dest = CH_DIR / (md.stem + ".typ")
        print(f"convert {md.name} -> {dest.name}")
        body = convert_md(md.read_text(encoding="utf-8"))
        dest.write_text(
            '#import "../template.typ": callout\n\n' + body,
            encoding="utf-8",
        )
        typ_files.append(dest)

    write_main(typ_files)
    print(f"wrote {MAIN}")
    if args.no_pdf:
        return 0
    return compile_pdf()


if __name__ == "__main__":
    sys.exit(main())
