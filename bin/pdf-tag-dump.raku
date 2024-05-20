#!/usr/bin/env perl6
use v6;

use PDF::Class;
use PDF::Catalog;
use PDF::StructTreeRoot;
use PDF::Tags::Reader;
use PDF::Tags::XML-Writer;
use PDF::Tags::Node :TagName;
use PDF::IO;

subset Number of Int where * > 0;

sub MAIN(Str $infile,               #= Input PDF
	 Str     :$password = '',   #= Password for the input PDF, if encrypted
         Number  :$max-depth = 16,  #= Depth to ascend/descend struct tree
         Bool    :$atts = True,     #= Include attributes in tags
         Bool    :$roles,           #= Apply role-map
         Bool    :$debug,           #= write extra debugging information
         Bool    :$marks,           #= Descend into marked content
         Bool    :$artifacts,       #= Descend into artifacts
         Bool    :$fields = True,   #= Include referenced field data
         Bool    :$strict = True,   #= Warn about unknown tags, etc
         Bool    :$quiet,           #= avoid printing any messages to stderr
         Bool    :$style = True,    #= Include stylesheet header
         Str     :$dtd,             #= Extern DtD to use
         Bool    :$valid = !$marks && !$roles, #= include external DtD declaration
         Str     :$select,          #= XPath of twigs to include (relative to root)
         TagName :$omit,            #= Tags to omit from output
         TagName :$root = $select ?? 'DocumentFragment' !! Str,  #= Outer root tag name
        ) is hidden-from-backtrace {

    my PDF::IO $input .= coerce(
       $infile eq '-'
           ?? $*IN.slurp-rest( :bin ) # sequential access
           !! $infile.IO              # random access
    );
    my %o = :$dtd with $dtd;

    my PDF::Class $pdf .= open( $input, :$password );
    my PDF::Tags::Reader $dom .= read: :$pdf, :$strict, :$marks, :$quiet, :$artifacts;
    my PDF::Tags::XML-Writer $xml .= new: :$max-depth, :$atts, :$debug, :$omit, :$style, :$marks, :$valid, :$roles, :$artifacts, |%o;

    my PDF::Tags::Node @nodes = do with $select {
        $dom.find($_);
    }
    else {
        $dom.root;
    }

    my UInt $depth = 0;

    with $root {
        unless @nodes[0] ~~ PDF::Tags:D {
            say '<' ~ $_ ~ '>';
            print '  ' if @nodes;
            $depth++;
        }
    }

    $xml.say($*OUT, $_, :$depth) for @nodes;

    say '</' ~ $root ~ '>' if $depth;
}

=begin pod

=head1 SYNOPSIS

pdf-dom-dump.raku [options] file.pdf

Options:
   --password        password for an encrypted PDF
   --max-depth=n     maximum tag-depth to descend
   --select=XPath    nodes to be included
   --omit=tag-name   nodes to be excluded
   --root=tag-name   define outer root tag
   --roles           apply role-map
   --/fields         disable field values
   --marks           descend into marked content
   --artifacts       descend into artifacts
   --debug           add debugging to output
   --/valid          remove external DtD declaration
   --/atts           omit attributes in tags
   --/strict         suppress warnings
   --quiet           avoid printing messages
   --/style          omit root stylesheet link

=head1 DESCRIPTION

Dumps structure elements from a tagged PDF.

Produces tagged output in an XML format.

Only some PDF files contain tagged PDF. pdf-info.raku can be
used to check this:

    % pdf-info.raku my-doc.pdf | grep Tagged:
    Tagged:     yes

=head1 DEPENDENCIES

This script requires the freetype6 native library and the PDF::Font::Loader
Raku module to be installed on your system.


=end pod
