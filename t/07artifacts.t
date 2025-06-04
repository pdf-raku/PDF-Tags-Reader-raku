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
    $doc.Paragraph: $gfx, {
        .text: {
            .text-position = 20, 600;
            .say: "Test para with hidden artifact";

            # content-level artifact
            .tag: Artifact, {
                .text-position = 20, 596;
                .say: '_' x 30;
            }

            .tag: Span, {
                .say: "and nested spanning text";
            }
        }
    }

    # structural artifact
    $doc.Artifact: $gfx, {
        .say: 'Page 1', :position[585, 10], :align<right>;
    }
}

my $xml = q{<Document>
  <P>
    Test para with hidden artifact
    and nested spanning text
  </P>
</Document>
};

my $xml2 = q{<Document>
  <P>
    Test para with hidden artifact
    ______________________________
    and nested spanning text
  </P>
  <Artifact>
    Page 1
  </Artifact>
</Document>
};

is $tags[0].xml, $xml, 'XML, pre-saved';

$pdf.id =  $*PROGRAM.basename.fmt('%-16.16s');
$pdf.save-as: "t/07artifacts.pdf", :!info;

$pdf .= open: "t/07artifacts.pdf";
$tags = PDF::Tags::Reader.read: :$pdf, :quiet;

is $tags[0].xml, $xml, 'XML, round-tripped';

$pdf .= open: "t/07artifacts.pdf";
$tags = PDF::Tags::Reader.read: :$pdf, :quiet, :artifacts;

is $tags[0].xml(:artifacts), $xml2, 'XML, round-tripped, with artifacts';

done-testing;
