use PDF::Tags;

unit class PDF::Tags::Reader:ver<0.0.4>
    is PDF::Tags;

use PDF::Font::Loader::FontObj;
use PDF::Font::Loader;
use PDF::Content::Canvas;
use PDF::Content::Font;
use PDF::Content::FontObj;
use PDF::Content::Ops :GraphicsContext;
use PDF::Content::Matrix :&is-identity;
use PDF::Content::Tag :InlineElemTags;
use PDF::Class;

has Bool $.strict = True;
has Bool $.marks;

method read(PDF::Class:D :$pdf!, Bool :$create, |c --> PDF::Tags:D) {
    with $pdf.catalog.StructTreeRoot -> $cos {
        self.new: :$cos, :root(self.WHAT), |c;
    }
    else {
        $create
            ?? self.create(:$pdf, |c)
            !! fail "PDF document does not contain marked content";
    }
}

class TextDecoder {
    use PDF::Content::Ops :OpCode;
    use Method::Also;
    has Hash @!save;
    has PDF::Content::Font $!font;
    has $.current-font;
    has Numeric $.font-size = 10;
    has PDF::Content::Tag $.mark;
    has Int $!artifact;
    has Numeric $!ty;

    method current-font {
        PDF::Font::Loader.load-font: :dict($!font)
            unless $!font.font-obj ~~ PDF::Content::FontObj:D;
        $!font.font-obj;
    }

    method callback {
        sub ($op, *@args) {
            my $method = OpCode($op).key;
            self."$method"(|@args)
                if self.can($method);
        }
    }
    method BeginMarkedContent($,$?) is also<BeginMarkedContentDict> {
        given $*gfx.tags.open-tags.tail -> $tag {
            $!artifact++ if $tag.name eq Artifact;
            $!mark = $tag if $tag.mcid;
        }
    }
    method EndMarkedContent() {
        with $*gfx.tags.closed-tag -> $tag {
            $!artifact-- if $tag.name eq Artifact;
            with $!mark {
                $_ = Nil if $_ === $tag;
            }
        }
    }
    method Save()      {
        @!save.push: %( :$!font, :$!font-size );
    }
    method Restore()   {
        if @!save {
            given @!save.pop {
                $!font = .<font>;
                $!font-size = .<font-size>;
            }
        }
    }
    method SetFont($, $!font-size) {
        $!font = $_ with $*gfx.font-face;
    }
    method SetGraphicsState($gs) {
        if $gs<Font>:exists {
            $!font = $*gfx.font-face;
            $!font-size = $*gfx.font-size;
        }
    }
    method !save-text($text) {
        with $!mark // $*gfx.open-tags.tail -> $tag {
            given $tag.children {
                if .tail ~~ Str:D {
                    .tail ~= $text;
                }
                else {
                    $tag.children.push: $text;
                }
            }
        }
        else {
            note "untagged text: {$text}";
        }
    }
    method !set-ty { $!ty = .[5] / .[3] given $*gfx.TextMatrix; }
    method ShowText($_) {
        unless $!artifact {
            self!set-ty;
            my $text = $.current-font.decode($_, :str);
            self!save-text: $text;
        }
    }
    method ShowSpaceText(List $_) {
        unless $!artifact {
            self!set-ty;
            my Str $last := ' ';
            my @chunks = .map: {
                when Str {
                    $last := $.current-font.decode($_, :str);
                }
                when $_ <= -120 && !($last ~~ /\s$/) {
                    # assume implicit space
                    ' '
                }
                default { Empty }
            }

            self!save-text: @chunks.join;
        }
    }
    method TextNextLine(|) is also<TextMoveSet MoveShowText MoveSetShowText> {
        # treat these as explict newlines
        unless $!artifact {
            self!save-text: "\n";
        }
    }
    method TextMove($x, $y) {
        # treat a significant vertical shift from the
        # last text positioning as an explict newline
        unless $!artifact {
            my $old-ty = $!ty;
            my $new-ty = self!set-ty;
            with $old-ty {
                my $leading = ($_ - $new-ty) / $!font-size;
                self!save-text: "\n"
                    unless -.3 <= $leading <= .3;
            }
        }
    }
    method Do($key) {
        warn "todo Do $key"
            unless $!artifact;
    }
}
constant Tags = Hash[PDF::Content::Tag];
has Tags %!canvas-tags{PDF::Content::Canvas};

method canvas-tags($obj --> Hash) {
    %!canvas-tags{$obj} //= do {
        $*ERR.print: '.';
        my &callback = TextDecoder.new.callback;
        my $gfx = $obj.gfx: :&callback, :$!strict;
        $obj.render;
        my PDF::Content::Tag % = $gfx.tags.grep(*.mcid.defined).map: {.mcid => $_ };
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

This script reads tagged PDF content from PDF files as XML.

=end pod
