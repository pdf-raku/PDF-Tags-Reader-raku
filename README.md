PDF-Tags-Reader-raku
=============

The Raku module extends [PDF::Tags](https://pdf-raku.github.io/PDF-Tags-raku/PDF/Tags),
adding the ability to read structured content from tagged PDF files.

Synopsis
--------

```
use PDF::API6;
use PDF::Tags::Reader;
use PDF::Tags::Elem;

my PDF::API6 $pdf .= open: "t/pdf/tagged.pdf";
my PDF::Tags::Reader $tags .= read: :$pdf;
my PDF::Tags::Elem $root = $tags[0];
say $root.name; # Document

# DOM traversal
for $root.kids {
    say .name; # L, P, H1, P ...
}

# XPath navigation
my @tags = $root.find('Document/L/LI[1]/LBody//*')>>.name;
say @tags.join(','); # Reference,P,Code

# XML Serialization
say $root.xml;

```

Scripts in this Distribution
------

##### `pdf-tag-dump.raku --select=XPath --omit=tag --password=Xxxx --max-depth=n --marks --graphics --/atts --/style --debug t/pdf/tagged.pdf`

