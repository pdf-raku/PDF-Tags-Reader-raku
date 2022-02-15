use Test;
use PDF::Tags::Reader;
use PDF::Class;
use PDF::Tags::XML-Writer;

plan 3;

my PDF::Class $pdf .= open("t/pdf/tagged.pdf");
my PDF::Tags::Reader $dom .= read: :$pdf;

is-deeply $dom.root[0].xml.lines.head(3), (
    '<Document>',
    '  <L ListNumbering="Disc">',
    '    <LI>');

is-deeply $dom.root.xml(:root-tag<Docs>).lines.head(6), (
    '<?xml version="1.0" encoding="UTF-8"?>',
    PDF::Tags::XML-Writer.new.css,
    '<Docs>',
    '  <Document>',
    '    <L ListNumbering="Disc">',
    '      <LI>');

is $dom.root[0][0][0][1][0].xml.trim, qq{<Reference>\n  <Link TextDecorationType="Underline">\n    \nNAME \n  </Link>\n</Reference>};

done-testing;
