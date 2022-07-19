use Test;
plan 1;
use PDF::Class;
use PDF::Tags;
use PDF::Tags::Elem;
use PDF::Content::Tag :ContentTags, :ParagraphTags;

my PDF::Class $pdf .= new;
my PDF::Tags $tags .= create: :$pdf;
# create the document root
my PDF::Tags::Elem $doc = $tags.Document;

$pdf.add-page.graphics: {
    .tag: Clipped, {
        .Rectangle: 100, 100, 125, 20;
        .Clip;
        .EndPath;
        $doc.Paragraph: $_, {
            .say: 'Clip me', :position[98, 98];
        }
    }
}

is-deeply $doc.xml.lines, (
'<Document>',
'  <P>',
'    Clip me',
'  </P>',
'</Document>'
), 'nested marked content';
