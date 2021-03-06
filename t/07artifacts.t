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
            .say: "Test para with hidden artifact";

            .tag: Artifact, {
                .text-position = 20, 596;
                .say: '_' x 30;
            }

            .tag: Span, {
                .say: "and nested spanning text";
            }
        }
    }
}

my $xml = q{<Document>
  <P>
    Test para with hidden artifact
    and nested spanning text
  </P>
</Document>
};

skip "PDF::Content v0.5.17+ needed for accurate pre-save XML" 
    unless PDF::Content.^ver >= v0.5.17;
is $tags[0].xml, $xml, 'XML, pre-saved';

$pdf.id =  $*PROGRAM-NAME.fmt('%-16.16s');
$pdf.save-as: "t/07artifacts.pdf", :!info;

$pdf .= open: "t/07artifacts.pdf";
$tags = PDF::Tags::Reader.read: :$pdf;

is $tags[0].xml, $xml, 'XML, round-tripped';

done-testing;
