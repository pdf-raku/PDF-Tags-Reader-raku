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
         Bool    :$fields = True,   #= Include referenced field data
         Bool    :$strict = True,   #= Warn about unknown tags, etc
         Bool    :$style = True,    #= Include stylesheet header
         Str     :$dtd,             #= Extern DtD to use
         Bool    :$valid = !$marks && !$roles, #= include external DtD declaration
         Str     :$select,          #= XPath of twigs to include (relative to root)
         TagName :$omit,            #= Tags to omit from output
         TagName :$root-tag,        #= Outer root tag name
        ) {

    my PDF::IO $input .= coerce(
       $infile eq '-'
           ?? $*IN.slurp-rest( :bin ) # sequential access
           !! $infile.IO              # random access
    );
    my %o = :$dtd with $dtd;

    my PDF::Class $pdf .= open( $input, :$password );
    my PDF::Tags::Reader $dom .= read: :$pdf, :$strict, :$marks;
    my PDF::Tags::XML-Writer $xml .= new: :$max-depth, :$atts, :$debug, :$omit, :$style, :$root-tag, :$marks, :$valid, :$roles, |%o;

    my PDF::Tags::Node @nodes = do with $select {
        $dom.find($_);
    }
    else {
        $dom.root;
    }

    my UInt $depth = 0;

    with $root-tag {
        unless @nodes[0] ~~ PDF::Tags:D {
            say '<' ~ $_ ~ '>';
            $depth++;
        }
    }

    $xml.say($*OUT, $_, :$depth) for @nodes;

    say '</' ~ $root-tag ~ '>' if $depth;
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
   --debug           add debugging to output
   --valid           add external DtD declaration
   --/atts           omit attributes in tags
   --/strict         suppress warnings
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

=head1 BUGS AND LIMITATIONS

=item Error - `tagged PDF has multiple top-level tags; no :root-tag given`

This error occur on PDF files that do not contain multple top level tags and does not result in a well-formed XML document. It can be corrected by using the `--root-tag` option to define a top-level tag, or using `--select` to trim
the tree, for example `--select=Document[1]`.

=head1 TODO

=item processing of links

=end pod
