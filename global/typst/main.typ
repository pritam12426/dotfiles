// Define Dark mode

#let bg = rgb("#0d1117")
#let fg = rgb("#f0f6fc")
#set page(fill: bg)
#set text(fill: fg)


#set document(
    author: "Pritam",
    title: "your New title",
    description: "Give a title by your Choice",
    date: { none },
)

#show link: underline
#show link: set text(
    fill: blue,
    weight: "bold",
)

// #show heading.where(level: 1): set block(
// 	above: 2.5em,
// 	below: 1.2em
// )

#set text(
    // font: "Calibri", // Uncomment if you have the font
    size: 11pt,
)

#set page(
    paper: "a4",
    margin: 1.5cm,
    numbering: "i",
    // background: [
    // #place(center + horizon)[
    // #image("assets/watermark.jpg", width: 30%)
    // ]
    // ],
)

#set heading(
    numbering: "1.",
    outlined: true,
)

#align(center + horizon)[
    #text(size: 40pt, fill: blue, weight: "bold", font: "Impact")[
        THIS TEXT WILL \ BE YOUR TILTE OF \ YOUR BOOK
    ]
    // #v(1cm)
]

#pagebreak()
#align(center + horizon)[
    #text(size: 10pt)[
        #lorem(250)
    ]
]


#pagebreak()
#show outline.entry.where(
    level: 1,
): set block(above: 1.2em)

#outline()
#pagebreak()

#set page(numbering: "1")
#counter(page).update(1)


= #lorem(10)
#lorem(22)

== #lorem(9)
#lorem(80)

=== #lorem(7)
#lorem(150)

=== #lorem(7)
#lorem(150)

=== #lorem(7)
#lorem(150)

=== #lorem(7)
#lorem(150)

=== #lorem(7)
#lorem(150)

=== #lorem(7)
#lorem(150)


== #lorem(9)
#lorem(80)

=== #lorem(7)
#lorem(150)

=== #lorem(7)
#lorem(150)

=== #lorem(7)
#lorem(150)

=== #lorem(7)
#lorem(150)



#pagebreak()
= #lorem(10)
#lorem(22)

== #lorem(9)
#lorem(80)

=== #lorem(7)
#lorem(150)

=== #lorem(7)
#lorem(150)

=== #lorem(7)
#lorem(150)

=== #lorem(7)
#lorem(150)

=== #lorem(7)
#lorem(150)

=== #lorem(7)
#lorem(150)


== #lorem(9)
#lorem(80)

=== #lorem(7)
#lorem(150)

=== #lorem(7)
#lorem(150)

=== #lorem(7)
#lorem(150)

=== #lorem(7)
#lorem(150)


#pagebreak()
= #lorem(10)
#lorem(22)

== #lorem(9)
#lorem(80)

=== #lorem(7)
#lorem(150)

=== #lorem(7)
#lorem(150)

=== #lorem(7)
#lorem(150)

=== #lorem(7)
#lorem(150)

=== #lorem(7)
#lorem(150)

=== #lorem(7)
#lorem(150)


== #lorem(9)
#lorem(80)

=== #lorem(7)
#lorem(150)

=== #lorem(7)
#lorem(150)

=== #lorem(7)
#lorem(150)

=== #lorem(7)
#lorem(150)



#pagebreak()
= Resources
- #link("https://www.google.com")[google] – Google main search page.
