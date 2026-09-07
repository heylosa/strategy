// MDMD Typst template — Korean-friendly, readable for print PDF
#let malgun = ("Malgun Gothic", "맑은 고딕", "Noto Sans CJK KR", "Noto Sans KR")
#let mono = ("Consolas", "Cascadia Mono", "DejaVu Sans Mono")

#let callout-fill = (
  "핵심": rgb("#E8F1FF"),
  "예시": rgb("#EAF8F0"),
  "트러블슈팅": rgb("#FFF4E5"),
  "아이디어": rgb("#F3E8FF"),
  "면접": rgb("#FFE8EE"),
  "주의": rgb("#FFF8D8"),
  "심화": rgb("#EEF0F4"),
)
#let callout-stroke = (
  "핵심": rgb("#2F6FED"),
  "예시": rgb("#1B8A5A"),
  "트러블슈팅": rgb("#C56A00"),
  "아이디어": rgb("#7A3EBE"),
  "면접": rgb("#C43B5A"),
  "주의": rgb("#B8860B"),
  "심화": rgb("#4A5568"),
)

#let mdmd-init(
  title: "MDMD",
  subtitle: "",
  body,
) = {
  set document(title: title, author: "MDMD PE Study")
  set page(
    paper: "a4",
    margin: (top: 22mm, bottom: 22mm, left: 18mm, right: 18mm),
    numbering: "1",
    header: context {
      let n = counter(page).get().first()
      if n > 1 {
        set text(size: 8.5pt, fill: rgb("#555"), font: malgun)
        grid(
          columns: (1fr, 1fr),
          align: (left, right),
          [MDMD · Tech R&D PE],
          [#title],
        )
        line(length: 100%, stroke: 0.3pt + rgb("#CCCCCC"))
      }
    },
    footer: context {
      set text(size: 8.5pt, fill: rgb("#555"), font: malgun)
      line(length: 100%, stroke: 0.3pt + rgb("#CCCCCC"))
      v(4pt)
      align(center)[#counter(page).display("1")]
    },
  )
  set text(font: malgun, size: 10pt, lang: "ko", hyphenate: false)
  set par(justify: true, leading: 0.72em, spacing: 0.85em)
  set heading(numbering: none)
  show heading.where(level: 1): it => {
    pagebreak(weak: true)
    v(4mm)
    block(width: 100%)[
      #set text(size: 20pt, weight: "bold", font: malgun)
      #it.body
    ]
    v(2mm)
    line(length: 100%, stroke: 1.1pt + rgb("#1F4E8A"))
    v(4mm)
  }
  show heading.where(level: 2): it => {
    v(5mm)
    block[
      #set text(size: 14pt, weight: "bold", fill: rgb("#1F4E8A"))
      #it.body
    ]
    v(2mm)
  }
  show heading.where(level: 3): it => {
    v(3.5mm)
    block[
      #set text(size: 12pt, weight: "bold", fill: rgb("#2C5282"))
      #it.body
    ]
    v(1.2mm)
  }
  show heading.where(level: 4): it => {
    v(2.5mm)
    block[
      #set text(size: 10.5pt, weight: "bold")
      #it.body
    ]
    v(0.8mm)
  }
  show raw.where(block: true): it => {
    set text(font: mono, size: 8pt)
    block(
      width: 100%,
      fill: rgb("#F4F6F8"),
      stroke: 0.4pt + rgb("#D0D5DD"),
      inset: 8pt,
      radius: 2pt,
      breakable: true,
    )[#it]
  }
  show raw.where(block: false): it => {
    set text(font: mono, size: 9pt)
    box(fill: rgb("#F0F2F5"), inset: (x: 3pt, y: 1pt), radius: 1pt)[#it]
  }
  set table(
    stroke: 0.4pt + rgb("#C5CDD8"),
    inset: 5pt,
    fill: (_, y) => if y == 0 { rgb("#E8EEF7") } else if calc.odd(y) { rgb("#FAFBFD") } else { white },
  )
  show table: it => {
    set text(size: 8.6pt)
    set par(justify: false, leading: 0.62em)
    block(breakable: true, width: 100%)[#it]
  }
  show outline.entry.where(level: 1): set text(weight: "bold")

  align(center)[
    #v(28mm)
    #text(size: 13pt, fill: rgb("#1F4E8A"), font: malgun)[A!SK 준비 · 기초에서 실무 심화]
    #v(6mm)
    #text(size: 26pt, weight: "bold")[#title]
    #v(4mm)
    #text(size: 12pt, fill: rgb("#333"))[#subtitle]
    #v(10mm)
    #text(size: 10.5pt)[SK hynix Tech R&D — Product Engineering]
    #v(2mm)
    #text(size: 10pt, fill: rgb("#555"))[공정 변수 → 소자 파라미터 → 제품 특성 → 트러블슈팅]
  ]
  pagebreak()
  outline(title: [목차], indent: 1.2em, depth: 2)
  body
}

#let callout(kind, body) = {
  let fill = callout-fill.at(kind, default: rgb("#F5F5F5"))
  let stroke = callout-stroke.at(kind, default: rgb("#666666"))
  block(
    width: 100%,
    fill: fill,
    stroke: (left: 2.4pt + stroke, rest: 0.3pt + stroke),
    inset: 9pt,
    radius: 2pt,
    breakable: true,
  )[
    #text(weight: "bold", fill: stroke, size: 9.5pt)[[#kind]]
    #v(2pt)
    #body
  ]
}
