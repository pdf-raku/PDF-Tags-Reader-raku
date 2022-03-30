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

    method read(PDF::Class :$pdf!, Bool :$create, Bool :$marks) returns PDF::Tags

Read tagged PDF structure from an existing file that has been previously tagged.

The `:create` option creates a new struct-tree root, if one does not already exist.

The `:marks` option causes PDF::Tag::Reader to descend into content and build a more detailed structure that includes the actual marks in the content stream as [PDF::Tags::Mark](PDF::Tags::Mark) objects. Otherwise just the content text is inserted as a child of type `Str`.

### method canvas-tags

    method canvas-tags(PDF::Content::Canvas) returns Hash

Renders a canvas object (Page or XObject form) and caches marked content as a hash of [PDF::Content::Tag](PDF::Content::Tag) objects, indexed by `MCID` (Marked Content ID).

Scripts in this Distribution
----------------------------

### `pdf-tag-dump.raku`

    pdf-tag-dump.raku --select=<xpath-expr> --omit=tag --password=Xxxx --max-depth=n --marks --/atts --/style --debug t/pdf/tagged.pdf

Options:

  * `--password=****` - password for the input PDF, if encrypted with a user password

  * `--max-depth=n` - depth to ascend/descend struct tree

  * `--/atts` disable tags attributes

  * `--debug` - write extra debugging information to XML

  * `--marks` - descend into marked content

  * `--strict` - warn about unknown tags, etc

  * `--/style` - omit stylesheet

  * `--select=xpath-expr` - twigs to include (relative to root)

This script reads tagged PDF content from PDF files as XML.

