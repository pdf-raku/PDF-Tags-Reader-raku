unit class PDF::Tags::Reader::TextDecoder;

use PDF::Font::Loader;
use PDF::Font::Loader::Dict;
use PDF::Content::Ops :OpCode;
use PDF::Content::FontObj;
use PDF::Content::Tag :ContentTags;
use Method::Also;

has Hash @!save;
has PDF::Content::Font $!font;
has PDF::Content::FontObj $!font-obj;
has $.current-font;
has Numeric $.font-size = 10;
has PDF::Content::Tag $.mark;
has Bool $.artifacts;
has Int $!artifact;
has Int $!reversed-chars;
has Numeric $!ty;
has Lock:D $.lock .= new;
has Bool $.quiet;

method filtered { $!artifact && !$!artifacts }

method current-font {
    $!font-obj //= $!lock.protect: {
        unless $!font.font-obj ~~ PDF::Content::FontObj:D {
            my Bool $core-font = PDF::Font::Loader::Dict.is-core-font: :dict($!font);
            PDF::Font::Loader.load-font: :dict($!font), :$core-font, :$!quiet;
        }
        $!font.font-obj;
    }
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
        $!reversed-chars++ if $tag.name eq ReversedChars;
        $!mark = $tag with $tag.mcid;
    }
}
method EndMarkedContent() {
    with $*gfx.tags.closed-tag -> $tag {
        $!artifact-- if $tag.name eq Artifact;
        $!reversed-chars-- if $tag.name eq ReversedChars;
        with $!mark {
            $_ = Nil if $_ === $tag;
        }
    }
}
method Save()      {
    @!save.push: %( :$!font, :$!font-size, :$!font-obj );
}
method Restore()   {
    if @!save {
        given @!save.pop {
            $!font = .<font>;
            $!font-obj = .<font-obj>;
            $!font-size = .<font-size>;
        }
    }
}
method SetFont($, $!font-size) {
    $!font-obj = Nil;
    $!font = $_ with $*gfx.font-face;
}
method SetGraphicsState($gs) {
    if $gs<Font>:exists {
        $!font-obj = Nil;
        $!font = $*gfx.font-face;
        $!font-size = $*gfx.font-size;
    }
}
method !save-text($text is copy) {
    with $!mark // $*gfx.open-tags.tail -> $tag {
        $text .= flip if $!reversed-chars;
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
    unless $.filtered {
        self!set-ty;
        my $text = $.current-font.decode($_, :str);
        self!save-text: $text;
    }
}
method ShowSpaceText(List $_) {
    unless $.filtered {
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
    unless $.filtered {
        self!save-text: "\n";
    }
}
method TextMove($x, $y) {
    # treat a significant vertical shift from the
    # last text positioning as an explict newline
    unless $.filtered {
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
        unless $.filtered;
}

