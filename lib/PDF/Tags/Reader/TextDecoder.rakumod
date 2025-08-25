unit class PDF::Tags::Reader::TextDecoder;

use PDF::Font::Loader;
use PDF::Font::Loader::Dict;
use PDF::Content::Ops :OpCode;
use PDF::Content::FontObj;
use PDF::Content::Tag :ContentTags;
use PDF::Destination;
use Method::Also;

has Hash @!save;
has PDF::Content::Font $!font;
has PDF::Content::FontObj $!font-obj;
has $.current-font;
has Numeric $.font-size = 10;
has Bool $.artifacts;
has Int $!artifact;
has Int $!reversed-chars;
has Numeric $!ty;
has Lock:D $.lock .= new;
has Bool $.quiet;
has PDF::Destination %.dests;
has PDF::Content::Tag $!mark;

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
method ($,$?) is also<BeginMarkedContent BeginMarkedContentDict> {
    given $*gfx.tags.open-tags.tail -> $tag {
        $!mark = $tag if $tag.mcid.defined;
        $!artifact++ if $tag.name eq Artifact;
        $!reversed-chars++ if $tag.name eq ReversedChars;
    }
}
method EndMarkedContent() {
    with $*gfx.tags.closed-tag -> $tag {
        $!mark = Nil if $tag.mcid.defined;
        $!artifact-- if $tag.name eq Artifact;
        $!reversed-chars-- if $tag.name eq ReversedChars;
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
    $text .= flip if $!reversed-chars;
    with $*gfx.open-tags.tail -> $tag {
        $tag.children.push: $text;
    }
    else {
        note "untagged text: {$text}";
    }
}

sub match-dest(PDF::Destination $dest, :$base-y! is rw, PDF::Content:D :$gfx!) {
    if $dest.can('top') {
        $base-y //= $gfx.base-coords(0, 0, :text)[1];
        $base-y <= ($dest.top // Inf);
    }
    else {
        True;
    }
}

method !set-ty {
    if %!dests && $!mark && !$!mark.dest-name {
        # use this as a trigger to resolve any named destinations
        # which have come into visual range
        my Numeric $base-y;
        with %!dests.sort.first({.value.&match-dest(:$base-y, :$*gfx)}) {
            %!dests{.key}:delete;
            $!mark.dest-name = .key;
        }
    }

    $!ty = .[5] / (.[3]||1) given $*gfx.TextMatrix;

}
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
            when $_ <= -120 && $last !~~ /\s$/ {
                # assume implicit space
                ' '
            }
            default { Empty }
        }

        self!save-text: @chunks.join;
    }
}
method (*@) is also<TextNextLine TextMoveSet MoveShowText MoveSetShowText> {
    # treat these as implict newlines
    unless $.filtered {
        self!save-text: "\n";
    }
}
method TextMove($x, $y) {
    # treat a significant vertical shift from the
    # last text positioning as an implict newline
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

