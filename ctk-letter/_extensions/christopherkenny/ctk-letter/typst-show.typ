#show: doc => ctk-letter(
$if(by-author)$
  authors: (
$for(by-author)$
$if(it.name.literal)$
    (
      name: [$it.name.literal$],
      $for(it.affiliations)$
      $if(it.name)$
      university: [$it.name$],
      $endif$
      $if(it.department)$
      department: [$it.department$],
      $endif$
      $endfor$

      $if(it.degrees)$
      degrees: [$for(it.degrees)$$it$$sep$, $endfor$],
      $endif$

      $if(it.metadata.title)$
      role:  [$it.metadata.title$],
      $endif$

      $if(it.phone)$
      phone: [$it.phone$],
      $endif$

      $if(it.email)$
      email: [$it.email$],
      $endif$
      $if(it.url)$
      website: [$it.url$]
      $endif$
    ),
$endif$
$endfor$
    ),
$endif$
$if(recipient)$
  recipient: [$recipient$],
$endif$
$if(date)$
  date: [$date$],
$endif$
$if(lang)$
  lang: "$lang$",
$endif$
$if(region)$
  region: "$region$",
$endif$
$if(margin)$
  margin: ($for(margin/pairs)$$margin.key$: $margin.value$,$endfor$),
$endif$
$if(papersize)$
  paper: "$papersize$",
$endif$
$if(mainfont)$
  font: ($for(mainfont)$"$mainfont$",$endfor$),
$endif$
$if(fontsize)$
  fontsize: $fontsize$,
$endif$
$if(linkcolor)$
  linkcolor: "$linkcolor$",
$endif$
$if(linestretch)$
  linestretch: $linestretch$,
$endif$
$if(logo)$
  logo: "$logo.path$",
$endif$
$if(signature)$
  signature: "$signature$",
$endif$
$if(signaturename)$
  signaturename: "$signaturename$",
$endif$
$if(signoff)$
  signoff: "$signoff$",
$endif$
  doc,
)
