use PDF::Tags;

unit class PDF::Tags::Reader:ver<0.0.1>
    is PDF::Tags;

use PDF::Font::Loader::FontObj;
use PDF::Font::Loader;
use PDF::Content::Canvas;
use PDF::Content::Font;
use PDF::Content::FontObj;
use PDF::Content::Ops :GraphicsContext;
use PDF::Content::Matrix :&is-identity;
use PDF::Class;

has Bool $.strict = True;
has Bool $.graphics;
has Bool $.marks = $!graphics;

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
    has $.graphics;
    has $.current-font;
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
    method Save()      {
        @!save.push: %( :$!font );
    }
    method Restore()   {
        if @!save {
            given @!save.pop {
                $!font = .<font>;
            }
        }
    }
    method !set-graphics-attributes($tag, $gfx) {
        if $tag.defined {
            given $gfx.CTM {
                $tag.attributes<gm> = .join: ','
                     unless .&is-identity();
            }
            given $gfx.StrokeColor {
                unless .key ~~ 'DeviceGray' && .value[0] =~= 0 {
                    $tag.attributes<stroke> = (.key.subst(/^Device/, ''), .value).join: ',';
                }
            }
            given $gfx.FillColor {
                unless .key ~~ 'DeviceGray' && .value[0] =~= 0 {
                    $tag.attributes<fill> = (.key.subst(/^Device/, ''), .value).join: ',';
                }
            }

            if $gfx.context == GraphicsContext::Text {
                given $gfx.TextMatrix {
                    unless .&is-identity() {
                        $tag.attributes<tm> = .join: ',';
                    }
                }
            }
        }
    }
    method SetFont($,$?) is also<SetGraphicsState> {
        $!font = $_ with $*gfx.font-face;
    }
    method ShowText($text-encoded) {
        with $*gfx.open-tags.tail -> $tag {
            self!set-graphics-attributes: $tag, $*gfx
                if $!graphics;
            my $text = $.current-font.decode($text-encoded, :str);
            $tag.children.push: $text;
        }
        else {
            warn $.current-font.decode($text-encoded, :str);
        }
    }
    method ShowSpaceText(List $text) {
        with $*gfx.open-tags.tail -> $tag {
            self!set-graphics-attributes: $tag, $*gfx
                if $!graphics;
            my Str $last := ' ';
            my @chunks = $text.map: {
                when Str {
                    $last := $.current-font.decode($_, :str);
                }
                when $_ <= -120 && !($last ~~ /\s$/) {
                    # assume implicit space
                    ' '
                }
                default { Empty }
            }
            $tag.children.push: @chunks.join;
        }
        else {
            warn $text.raku;
        }
    }
    method Do($key) {
        warn "todo Do $key";
    }
}
constant Tags = Hash[PDF::Content::Tag];
has Tags %!canvas-tags{PDF::Content::Canvas};

method canvas-tags($obj --> Hash) {
    %!canvas-tags{$obj} //= do {
        $*ERR.print: '.';
        my &callback = TextDecoder.new(:$!graphics).callback;
        my $gfx = $obj.gfx: :&callback, :$!strict;
        $obj.render;
        my PDF::Content::Tag % = $gfx.tags.grep(*.mcid.defined).map: {.mcid => $_ };
    }
}

=begin pod

==head2 Synopsis

  use PDF::Class;
  use PDF::Tags::Reader;
  # read tags
  my PDF::Class $pdf .= open: "t/pdf/tagged.pdf");
  my PDF::Tags::Reader $tags .= read: :$pdf;
  my PDF::Tags::Elem $doc = $tags[0];
  say "document root {$doc.name}";
  say " - child {.name}" for $doc.kids;

=head2 Methods

This class inherits from L<PDF::Tags> and has its methods available.

 =head3 method read

   method read(PDF::Class :$pdf!, Bool :$create) returns PDF::Tags

Read tagged PDF structure from an existing file that has been previously tagged.

The `:create` option creates a new struct-tree root, if one does not already exist.
      
=head3 method canvas-tags

   method canvas-tags(PDF::Content::Canvas) returns Hash

Renders a canvas object (Page or XObject form) and caches
marked content as a hash of L<PDF::Content::Tag> objects,
indexed by `MCID` (Marked Content ID).

=end pod
