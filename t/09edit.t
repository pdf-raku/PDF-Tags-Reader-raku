use Test;
use PDF::Tags::Reader;
use PDF::Class;
use PDF::Content::Tag :InlineElemTags;

plan 7;

my PDF::Class $pdf .= open("t/pdf/tagged.pdf");
my PDF::Tags::Reader $dom .= read: :$pdf, :marks;

# 7th paragraph is actually a code block
with $dom.first('Document/P[7]') {
     is .node-path, 'Document/P[7]';
    .name = CODE;
    is .node-path, 'Document/Code[1]'
}

with $dom.first('Document/L[1]') {
     # layout attribute, defaulted owner
     .set-attribute('BorderThickness', 1);
     # layout attribute, explicit owner
     .set-attribute('Layout:BorderStyle', 'Dotted');
     # layout attribute, user-property
     .set-attribute('UserProperties:Foo', "Hi"); 
     # layout attribute, misc
     .set-attribute('Bar:Baz', 42); 

     is .attributes<BorderThickness>, 1;
     is .attributes<Layout:BorderStyle>, 'Dotted';
     is .attributes<UserProperties:Foo>, "Hi";
     is .attributes<Bar:Baz>, 42;
}

$pdf.id =  $*PROGRAM-NAME.fmt('%-16.16s');
$pdf.save-as: "t/09edit.pdf", :!info;

$pdf .= open: "t/09edit.pdf";
$dom .= read: :$pdf;

with $dom.first('Document/Code[1]') {
    is .name, CODE.value, 'renamed tag';
}
