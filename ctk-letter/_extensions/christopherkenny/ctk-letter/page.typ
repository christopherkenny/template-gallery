#set page(
  paper: $if(papersize)$"$papersize$"$else$"us-letter"$endif$,
  margin: $if(margin)$($for(margin/pairs)$$margin.key$: $margin.value$,$endfor$)$else$(x: 1.25in, y: 1.25in)$endif$,
  numbering: $if(page-numbering)$"$page-numbering$"$else$none$endif$,
)