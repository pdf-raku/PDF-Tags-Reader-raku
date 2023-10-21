unit class PDF::Tags::Reader:ver<0.0.9>;

use PDF::Tags;
also is PDF::Tags;

use PDF::Tags::Reader::TextDecoder;
constant TextDecoder = PDF::Tags::Reader::TextDecoder;

use PDF::Content::Canvas;
use PDF::Content;
use PDF::Content::Ops :GraphicsContext;
use PDF::Class;

has Bool $.strict = True;
has Bool $.quiet;
has Bool $.marks;
has Lock:D $.lock .= new;

method read(PDF::Class:D :$pdf!, Bool :$create, |c --> PDF::Tags:D) {
    with $pdf.catalog.StructTreeRoot -> $cos {
        self.new: :$cos, :root(self.WHAT), :$pdf, |c;
    }
    else {
        $create
            ?? self.create(:$pdf, |c)
            !! fail "PDF document does not contain marked content";
    }
}

constant Tags = Hash[PDF::Content::Tag];
has Tags %!canvas-tags{PDF::Content::Canvas};

sub build-tag-index(%tags, PDF::Content::Tag $tag) {
    with $tag.mcid {
        %tags{$_} = $tag;
    }
    else {
        build-tag-index(%tags, $_)
            for $tag.children;
    }
}

method canvas-tags($canvas --> Hash) {
    %!canvas-tags{$canvas} //= do {
        $*ERR.print: '.';
        my &callback = TextDecoder.new(:$!lock, :$!quiet).callback;
        my PDF::Content $gfx = $canvas.gfx: :&callback, :$!strict;
        $canvas.render;
        my PDF::Content::Tag %tags;
        build-tag-index(%tags, $_) for $gfx.tags.children;
        %tags;
    }
}

=begin pod

=head2 Synopsis

  use PDF::Class;
  use PDF::Tags::Reader;
  # read tags
  my PDF::Class $pdf .= open: "t/pdf/tagged.pdf");
  my PDF::Tags::Reader $tags .= read: :$pdf;
  my PDF::Tags::Elem $doc = $tags[0];
  say "document root {$doc.name}";
  say " - child {.name}" for $doc.kids;
  say $doc.xml; # dump tags and text content as XML

=head2 Description

This module implements reading of tagged PDF content from PDF files.

=head2 Methods

This class inherits from L<PDF::Tags|https://pdf-raku.github.io/PDF-Tags-raku/> and has its methods available.

 =head3 method read

   method read(PDF::Class :$pdf!, Bool :$create, Bool :$marks) returns PDF::Tags

Read tagged PDF structure from an existing file that has been previously tagged.

The `:create` option creates a new struct-tree root, if one does not already exist.

The `:marks` option causes PDF::Tag::Reader to descend into content and build a more
detailed structure that includes the actual marks in the content stream as L<PDF::Tags::Mark>
objects. Otherwise just the content text is inserted as a child of type `Str`.

=head3 method canvas-tags

   method canvas-tags(PDF::Content::Canvas) returns Hash

Renders a canvas object (Page or XObject form) and caches
marked content as a hash of L<PDF::Content::Tag> objects,
indexed by `MCID` (Marked Content ID).

=head2 Scripts in this Distribution

=head3 `pdf-tag-dump.raku`

=code pdf-tag-dump.raku --select=<xpath-expr> --omit=tag --password=Xxxx --max-depth=n --marks --/atts --/style --debug t/pdf/tagged.pdf

Options:

 =item `--password=****` -  password for the input PDF, if encrypted with a user password
 =item `--max-depth=n` - depth to ascend/descend struct tree
 =item `--/atts` disable tags attributes
 =item `--debug` - write extra debugging information to XML
 =item `--marks` - descend into marked content
 =item `--strict` - warn about unknown tags, etc
 =item `--/style` - omit stylesheet
 =item `--select=xpath-expr` - twigs to include (relative to root)
 =item `--valid` - include external DtD link
 =item `--omit=tag` - filter tag from output
 =item `--root=tag` - add outer root tag

This script reads tagged PDF content from PDF files as XML.

=end pod
