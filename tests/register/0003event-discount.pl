#0003event-discount.pl

pass('0003event-discount.pl');

my $last = lastSale();

ok($sale->open($last), 'open the sale');
#diag(Dumper($sale));
checkFld('id', $last);
checkFld('customer', '');
#checkFld('tranzDate', '');
checkFld('suspended', '0', 1);
checkFld('clerk', '100', 1);
checkFld('taxMask', '32767', 1);
checkFld('total', '5000', 1);
checkFld('balance', '0', 1);
checkFld('terminal', Sys::Hostname::hostname());
checkFld('notes', undef);
checkFld('voidAt', undef);
checkFld('voidBy', undef);
#checkFld('created', '');
#checkFld('createdBy', '');
#checkFld('modified', '');
#checkFld('modifiedBy', '');

checkFld('allTaxes', 0, 1);
checkFld('ratranz', 0, 1);
checkFld('change', 0, 1);
checkFld('due', 0, 1);
checkFld('subt', 5000, 1);

checkSubFld('items', 0, 'plu', '2');
checkSubFld('items', 0, 'lineNo', '0', 1);
checkSubFld('items', 0, 'id', $last, 1);
checkSubFld('items', 0, 'qty', '1', 1);
checkSubFld('items', 0, 'amt', 10000, 1);
checkSubFld('items', 1, 'plu', ':50');
checkSubFld('items', 1, 'lineNo', 1, 1);
checkSubFld('items', 1, 'id', $last, 1);
checkSubFld('items', 1, 'qty', '1', 1);
checkSubFld('items', 1, 'amt', 5000, 1);

checkSubFld('taxes', 0, 'id', $last, 1);
checkSubFld('taxes', 0, 'rate', '6.2500');
checkSubFld('taxes', 0, 'tax', 0, 1);
checkSubFld('taxes', 0, 'taxable', 0, 1);
checkSubFld('taxes', 0, 'taxId', 1, 1);
checkSubFld('taxes', 1, 'id', $last, 1);
checkSubFld('taxes', 1, 'rate', '0.5000');
checkSubFld('taxes', 1, 'tax', 0, 1);
checkSubFld('taxes', 1, 'taxable', 0, 1);
checkSubFld('taxes', 1, 'taxId', 2, 1);

checkSubFld('tenders', 0, 'id', $last, 1);
checkSubFld('tenders', 0, 'lineNo', 0, 1);
checkSubFld('tenders', 0, 'ext', {}, 'deeply');
checkSubFld('tenders', 0, 'amt', 5000, 1);
checkSubFld('tenders', 0, 'tender', 0, 1);

#checkFld('', '');
#is($sale->{''}, '', 'the s match');
