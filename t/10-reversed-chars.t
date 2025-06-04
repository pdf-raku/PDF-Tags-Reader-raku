use Test;
plan 2;

use PDF::Class;
use PDF::Tags;
use PDF::Tags::Elem;
use PDF::Tags::Reader;
use PDF::Content;
use PDF::Content::Tag :Tags;

my PDF::Class $pdf .= new;
my PDF::Page $page = $pdf.add-page;
my PDF::Tags $tags .= create: :$pdf;
my PDF::Tags::Elem $doc = $tags.Document;

$page.graphics: -> $gfx {
    $doc.Paragraph: $gfx, {
        .text: {
            .text-position = 20, 600;
            .print: "Test para with ";

            .tag: ReversedChars, {
                .print: 'reversed';
            }

            .tag: Span, {
                .say: " characters.";
            }
        }
    }
}

my $xml = q{<Document>
  <P>
    Test para with desrever characters.
  </P>
</Document>
};

skip "PDF::Content v0.5.17+ needed for accurate pre-save XML" 
    unless PDF::Content.^ver >= v0.5.17;
is $tags[0].xml, $xml, 'XML, pre-saved';

$pdf.id =  $*PROGRAM.basename.fmt('%-16.16s');
$pdf.save-as: "t/10-reversed-chars.pdf", :!info;

$pdf .= open: "t/10-reversed-chars.pdf";
$tags = PDF::Tags::Reader.read: :$pdf, :quiet;

is $tags[0].xml, $xml, 'XML, round-tripped';

done-testing;
