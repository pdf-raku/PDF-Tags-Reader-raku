use Test;
use PDF::Tags::Reader;
use PDF::Class;
use PDF::Tags::XML-Writer;

plan 3;

my PDF::Class $pdf .= open: "t/pdf/tagged.pdf";
my PDF::Tags::Reader $dom .= read: :$pdf, :quiet;


is-deeply $dom.root[0].xml.lines.head(3), (
    '<Document>',
    '  <L ListNumbering="Disc">',
    '    <LI>');

is-deeply $dom.root.xml(:root-tag<Docs>, :!valid, :!style).lines.head(5), (
    '<?xml version="1.0" encoding="UTF-8"?>',
    '<Docs Producer="Prince 13.1 (www.princexml.com)" Title="XML::LibXML::Document - DOM Document Class">',
    '  <Document>',
    '    <L ListNumbering="Disc">',
    '      <LI>');

is $dom.root[0][0][0][1][0].xml.trim, qq{<Reference><Link TextDecorationType="Underline">NAME </Link></Reference>};

done-testing;
