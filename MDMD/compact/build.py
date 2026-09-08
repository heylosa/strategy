#!/usr/bin/env python3
"""Build the ~30-page compact booklet. Reuses MDMD/build.py converter."""

from __future__ import annotations

import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
sys.path.insert(0, str(ROOT))

from build import convert_md  # noqa: E402

MD_DIR = HERE / "md"
TYP_DIR = HERE / "typst"
CH_DIR = TYP_DIR / "chapters"
PDF_DIR = ROOT / "pdf"
TEMPLATE = TYP_DIR / "template.typ"
MAIN = TYP_DIR / "main.typ"
PDF_OUT = PDF_DIR / "MDMD_PE_ASK_Compact.pdf"


def write_main(chapter_files: list[Path]) -> None:
    includes = "\n".join(f'#include "chapters/{p.name}"' for p in chapter_files)
    MAIN.write_text(
        "#import \"template.typ\": mdmd-init\n"
        "#show: mdmd-init.with(\n"
        "  title: [PE 핵심 암기],\n"
        "  subtitle: [컴팩트 · 기초 0에서 30페이지],\n"
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
    no_pdf = "--no-pdf" in sys.argv
    MD_DIR.mkdir(parents=True, exist_ok=True)
    CH_DIR.mkdir(parents=True, exist_ok=True)
    PDF_DIR.mkdir(parents=True, exist_ok=True)

    md_files = sorted(MD_DIR.glob("*.md"))
    if not md_files:
        print("no markdown in compact/md/", file=sys.stderr)
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
    if no_pdf:
        return 0
    return compile_pdf()


if __name__ == "__main__":
    sys.exit(main())
