Synopsis
--------

    use PDF::Class;
    use PDF::Tags::Reader;
    # read tags
    my PDF::Class $pdf .= open: "t/pdf/tagged.pdf");
    my PDF::Tags::Reader $tags .= read: :$pdf;
    my PDF::Tags::Elem $doc = $tags[0];
    say "document root {$doc.name}";
    say " - child {.name}" for $doc.kids;
    say $doc.xml; # dump tags and text content as XML

Description
-----------

This module implements reading of tagged PDF content from PDF files.

Methods
-------

This class inherits from [PDF::Tags](https://pdf-raku.github.io/PDF-Tags-raku/) and has its methods available.

### method read

    method read(PDF::Class :$pdf!, Bool :$create) returns PDF::Tags

Read tagged PDF structure from an existing file that has been previously tagged.

The `:create` option creates a new struct-tree root, if one does not already exist.

### method canvas-tags

    method canvas-tags(PDF::Content::Canvas) returns Hash

Renders a canvas object (Page or XObject form) and caches marked content as a hash of [PDF::Content::Tag](PDF::Content::Tag) objects, indexed by `MCID` (Marked Content ID).

