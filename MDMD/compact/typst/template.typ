// Compact Typst template — dense 30-page cram booklet
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
  title: "MDMD Compact",
  subtitle: "",
  body,
) = {
  set document(title: title, author: "MDMD PE Compact")
  set page(
    paper: "a4",
    margin: (top: 14mm, bottom: 14mm, left: 14mm, right: 14mm),
    numbering: "1",
    header: context {
      let n = counter(page).get().first()
      if n > 1 {
        set text(size: 7.5pt, fill: rgb("#555"), font: malgun)
        grid(
          columns: (1fr, 1fr),
          align: (left, right),
          [MDMD Compact · PE 핵심 암기],
          [#title],
        )
        line(length: 100%, stroke: 0.3pt + rgb("#CCCCCC"))
      }
    },
    footer: context {
      set text(size: 7.5pt, fill: rgb("#555"), font: malgun)
      line(length: 100%, stroke: 0.3pt + rgb("#CCCCCC"))
      v(2pt)
      align(center)[#counter(page).display("1")]
    },
  )
  set text(font: malgun, size: 9.3pt, lang: "ko", hyphenate: false)
  set par(justify: true, leading: 0.68em, spacing: 0.74em)
  set heading(numbering: none)
  show heading.where(level: 1): it => {
    v(2mm)
    block(width: 100%)[
      #set text(size: 15pt, weight: "bold", font: malgun)
      #it.body
    ]
    v(1.2mm)
    line(length: 100%, stroke: 0.9pt + rgb("#1F4E8A"))
    v(2mm)
  }
  show heading.where(level: 2): it => {
    v(4.2mm)
    block[
      #set text(size: 12pt, weight: "bold", fill: rgb("#1F4E8A"))
      #it.body
    ]
    v(1.6mm)
  }
  show heading.where(level: 3): it => {
    v(2.2mm)
    block[
      #set text(size: 10pt, weight: "bold", fill: rgb("#2C5282"))
      #it.body
    ]
    v(0.8mm)
  }
  show heading.where(level: 4): it => {
    v(1.6mm)
    block[
      #set text(size: 9pt, weight: "bold")
      #it.body
    ]
    v(0.5mm)
  }
  show raw.where(block: true): it => {
    set text(font: mono, size: 6.8pt)
    block(
      width: 100%,
      fill: rgb("#F4F6F8"),
      stroke: 0.4pt + rgb("#D0D5DD"),
      inset: 5pt,
      radius: 2pt,
      breakable: true,
    )[#it]
  }
  show raw.where(block: false): it => {
    set text(font: mono, size: 7.8pt)
    box(fill: rgb("#F0F2F5"), inset: (x: 2pt, y: 0.5pt), radius: 1pt)[#it]
  }
  set table(
    stroke: 0.35pt + rgb("#C5CDD8"),
    inset: 4.2pt,
    fill: (_, y) => if y == 0 { rgb("#E8EEF7") } else if calc.odd(y) { rgb("#FAFBFD") } else { white },
  )
  show table: it => {
    set text(size: 8.1pt)
    set par(justify: false, leading: 0.56em)
    block(breakable: true, width: 100%)[#it]
  }
  show outline.entry.where(level: 1): set text(weight: "bold")

  align(center)[
    #v(8mm)
    #text(size: 11pt, fill: rgb("#1F4E8A"), font: malgun)[A!SK 급행 · 아무것도 모를 때]
    #v(3mm)
    #text(size: 20pt, weight: "bold")[#title]
    #v(2mm)
    #text(size: 10.5pt, fill: rgb("#333"))[#subtitle]
    #v(4mm)
    #text(size: 9pt)[SK hynix Tech R&D — Product Engineering]
    #v(1.5mm)
    #text(size: 8.5pt, fill: rgb("#555"))[약 30페이지 · 숫자와 화살표만 외운다]
  ]
  v(4mm)
  outline(title: [목차], indent: 1em, depth: 2)
  v(3mm)
  body
}

#let callout(kind, body) = {
  let fill = callout-fill.at(kind, default: rgb("#F5F5F5"))
  let stroke = callout-stroke.at(kind, default: rgb("#666666"))
  block(
    width: 100%,
    fill: fill,
    stroke: (left: 2.2pt + stroke, rest: 0.3pt + stroke),
    inset: 6pt,
    radius: 2pt,
    breakable: true,
  )[
    #text(weight: "bold", fill: stroke, size: 8pt)[[#kind]]
    #v(1.5pt)
    #set text(size: 8.2pt)
    #body
  ]
}
