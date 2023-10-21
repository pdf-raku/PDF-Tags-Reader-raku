use Test;
plan 3;

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
    my PDF::Tags::Elem:D $p = $doc.Paragraph: $gfx, :Lang<en>, {
        .text: {
            .text-position = 20, 600;
            .say: "structure tagged english.";
        }
    }
    is $p.Lang, 'en';
    $p = $doc.Paragraph;
    $p.mark: $gfx, :Lang<en>, {
        .text: {
            .text-position = 20, 580;
            .say: "content tagged english.";
        }
    }
}

my $xml = q{<Document>
  <P Lang="en">
    structure tagged english.
  </P>
  <P>
    <Span Lang="en">content tagged english.
    </Span>
  </P>
</Document>
};

is $tags[0].xml, $xml, 'XML, pre-saved';

$pdf.id =  $*PROGRAM-NAME.fmt('%-16.16s');
$pdf.save-as: "t/11-lang.pdf", :!info;

$pdf .= open: "t/11-lang.pdf";
$tags = PDF::Tags::Reader.read: :$pdf, :quiet;

is $tags[0].xml, $xml, 'XML, round-tripped';

done-testing;
