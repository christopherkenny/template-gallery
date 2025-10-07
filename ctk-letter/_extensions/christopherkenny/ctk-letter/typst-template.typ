
#let to-string(content) = {
  if content.has("text") {
    content.text
  } else if content.has("children") {
    content.children.map(to-string).join("")
  } else if content.has("body") {
    to-string(content.body)
  } else if content == [ ] {
    " "
  }
}

#let ctk-letter(
  authors: none,
  recipient: none,
  date: none,
  cols: 1,
  margin: (x: 1in, y: 1in),
  paper: "us-letter",
  lang: "en",
  region: "US",
  font: (),
  fontsize: 12pt,
  linestretch: 1,
  linkcolor: "#800000",
  logo: none,
  signature: none,
  signaturename: none,
  signoff: none,
  doc,
) = {

  let author = if authors != none {
    authors.first()
  } else {
    none
  }

  set par(justify: true)

  set text(
    lang: lang,
    region: region,
    font: font,
    size: fontsize,
  )

  // show rules
  show link: this => {
    if type(this.dest) != label {
      text(this, fill: rgb(linkcolor.replace("\\#", "#")))
    } else {
      text(this, fill: rgb("#0000CC"))
    }
  }

  show ref: this => {
    text(this, fill: rgb("#640872"))
  }

  set page(
    paper: paper,
    margin: margin,
    numbering: "1",
  )

  v(-.5in)
  grid(
    columns: (1fr, 9fr),
    image(logo, height: 0.6in),
    grid.cell(
      table(
        columns: (1fr),
        column-gutter: 0pt,
        inset: 0pt,
        v(0.25em),
        align(
          left,
          text(size: 16pt, weight: "semibold")[#smallcaps(author.university)],
        ),
        v(1em),
        line(length: 100%),
        v(3.25em)
      ),
    )
  )

  set par(
    leading: linestretch * 0.65em,
    spacing: 0.95em
  )


  v(-0.6in)
  align(right)[#text(size: 10pt)[
      #if authors != none {
        text(weight: "bold")[
          #if "degrees" in author {
            author.name + ", " + author.degrees
          } else {
            author.name
          }
        ]

        if "department" in author [
          \ #author.department
        ]

        if "email" in author [
          #show link: set text(fill: black)
          \ #link("mailto:" + to-string(author.email))//[#smallcaps(to-string(author.email))]
        ]

        if "website" in author [
          \ #link("https://" + to-string(author.website))[#author.website]
        ]

        if "phone" in author [
          \ #to-string(author.phone)
        ]
      }
    ]]

  if date != none or recipient != none {
    v(-0.25in)
  }

  if date != none {
    align(left)[
      #date
    ]
  }

  if recipient != none {
    align(left)[
      #recipient
    ]
  }

  v(-0.75em)

  block()

  // add hanging indent to rest
  set par(
    justify: true,
    first-line-indent: 1em,
    leading: linestretch * 0.65em,
  )

  if cols == 1 {
    doc
  } else {
    columns(cols, doc)
  }

  if signature != none {
    align(right)[
      #block(
        width: 24%,
        {
          if signoff != none {
            align(left)[#signoff]
          }
          v(-10pt)
          align(center, scale(y: 70%)[#image(signature)])
          v(-14pt)
          if signaturename != none {
              text(weight: "bold", signaturename)
          }
        },
      )
    ]
  }


}

#set table(
  inset: 6pt,
  stroke: none,
)
