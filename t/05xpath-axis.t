use Test;
use PDF::Tags::Reader;
use PDF::Tags::Elem;
use PDF::Class;

plan 21;

sub names(@elems) {
    @elems>>.name.join(' ');
}

my PDF::Class $pdf .= open("t/pdf/tagged.pdf");

my PDF::Tags::Reader $dom .= read: :$pdf, :quiet;

is $dom.find('Document/L').&names, ['L', 'L'], "child, repeated";
is $dom.find('Document/L[1]/LI[1]/LBody/ancestor::*').&names, 'Document L LI', 'ancestor';
is $dom.find('/Document/L/LI[1]/LBody').&names, 'LBody LBody', 'child';
is $dom.find('Document/L/LI[1]/LBody/ancestor::*').&names, 'Document L LI L LI', 'ancestor';
is $dom.find('Document/L/LI[1]/LBody/ancestor-or-self::*').&names, 'Document L LI LBody L LI LBody', 'ancestor-or-self';
is $dom.find('/Document/L/attribute::ListNumbering').&names, 'ListNumbering', 'attribute';
is $dom.find('Document/L/LI[1]/LBody/child::*').&names, 'Reference P', 'child';
is $dom.find('Document/L/LI[1]/LBody/*').&names, 'Reference P', 'child element abbreviated';
is $dom.find('Document/L/LI[1]/LBody/descendant::*').&names, 'Reference Link P Code', 'descendant';
is $dom.find('Document/L/LI[1]/LBody/descendant-or-self::*').&names, 'LBody Reference Link LBody P Code', 'descendant-or-self';
is $dom.find('/Document/H1[last()]/following::*').&names, 'P', 'following';
my $li = $dom.first('Document/L[1]/LI[2]');
my $lbl = $li.first('Lbl');
my $lbody = $li.first('LBody');
is $lbl.find('following-sibling::*').&names, 'LBody', 'following-sibling';
is $lbody.find('/Document/L[1]/LI[1]/LBody/preceding::*').&names, 'Lbl', 'preceding';
is $lbody.find('preceding-sibling::*').&names, 'Lbl', 'preceding-sibling';
is $lbody.find('preceding-sibling::Lbl').&names, 'Lbl', 'preceding-sibling';
is $lbody.find('preceding-sibling::Blah').&names, '', 'preceding-sibling';
is $lbody.find('self::*').&names, 'LBody', 'self';
is $lbody.find('.').&names, 'LBody', 'self (abbreviated)';
is $lbody.find('parent::*').&names, 'LI', 'parent';
is $lbody.find('..').&names, 'LI', 'parent (abbreviated)';
is $lbody.find('.././*').&names, 'Lbl LBody', 'chained (parent/self/child)';

done-testing;
