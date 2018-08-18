#0003event-raz.pl

pass('0003event-raz.pl');

my @payments;
my @payTime;

my $last = ($sale->getByCust('2173424900'))[-2];
push @payments, $last;
#my $last = ($sale->getSuspended())[-1];
ok($sale->open($last), "open the sale $last");
#diag(Dumper($sale));
checkFld('id', $last);
checkFld('customer', '2173424900');
#checkFld('tranzDate', '');
push @payTime, $sale->{'tranzDate'};
checkFld('suspended', 0, 1);
checkFld('clerk', '100', 1);
checkFld('taxMask', 0, 1);
checkFld('total', '14231', 1);
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
checkFld('ratranz', 1, 1);
checkFld('change', 0, 1);
checkFld('due', 0, 1);
checkFld('subt', 14231, 1);

checkSubFld('items', 0, 'plu', 'RA-TRANZ');
checkSubFld('items', 0, 'lineNo', '0', 1);
checkSubFld('items', 0, 'id', $last, 1);
checkSubFld('items', 0, 'qty', '1', 1);
checkSubFld('items', 0, 'amt', 14231, 1);

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
checkSubFld('tenders', 0, 'amt', 14231, 1);
checkSubFld('tenders', 0, 'tender', 0, 1);

#check the autodiscounted sale too
$last = ($sale->getByCust('2173424900'))[-1];
push @payments, $last;
ok($sale->open($last), "open the sale $last");
#diag(Dumper($sale));
checkFld('id', $last);
checkFld('customer', '2173424900');
#checkFld('tranzDate', '');
push @payTime, $sale->{'tranzDate'};
checkFld('suspended', 0, 1);
checkFld('clerk', '100', 1);
checkFld('taxMask', 0, 1);
checkFld('total', -769, 1);
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
checkFld('subt', -769, 1);

checkSubFld('items', 0, 'plu', ':100');
checkSubFld('items', 0, 'lineNo', '0', 1);
checkSubFld('items', 0, 'id', $last, 1);
checkSubFld('items', 0, 'qty', '1', 1);
checkSubFld('items', 0, 'amt', 769, 1);

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
checkSubFld('tenders', 0, 'amt', -769, 1);
checkSubFld('tenders', 0, 'tender', 0, 1);

#check the sale too
$last = ($sale->getByCust('2173424900'))[-3];
ok($sale->open($last), "open the sale $last");
#diag(Dumper($sale));
checkFld('id', $last);
checkFld('customer', '2173424900');
#checkFld('tranzDate', '');
checkFld('suspended', 0, 1);
checkFld('clerk', '100', 1);
checkFld('taxMask', 0, 1);
checkFld('total', 15000, 1);
checkFld('balance', 0, 1);
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
checkFld('due', 0, 1); #due is un-tendered amount, balance is unpaid amt
checkFld('subt', 15000, 1);

checkSubFld('items', 0, 'plu', '2');
checkSubFld('items', 0, 'lineNo', '0', 1);
checkSubFld('items', 0, 'id', $last, 1);
checkSubFld('items', 0, 'qty', '1', 1);
checkSubFld('items', 0, 'amt', 15000, 1);

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
checkSubFld('tenders', 0, 'amt', 15000, 1);
checkSubFld('tenders', 0, 'tender', 100, 1);

checkSubFld('payments', 0, 'id', $last, 1);
checkSubFld('payments', 0, 'lineNo', 0, 1);
checkSubFld('payments', 0, 'tranzDate', pop(@payTime));
checkSubFld('payments', 0, 'raId', pop(@payments), 1);
checkSubFld('payments', 0, 'amt', 769, 1);
checkSubFld('payments', 0, 'struck', 0, 1);
checkSubFld('payments', 0, 'notes', undef, 'deeply');
checkSubFld('payments', 0, 'ext', {}, 'deeply');

checkSubFld('payments', 1, 'id', $last, 1);
checkSubFld('payments', 1, 'lineNo', 1, 1);
checkSubFld('payments', 1, 'tranzDate', pop(@payTime));
checkSubFld('payments', 1, 'raId', pop(@payments), 1);
checkSubFld('payments', 1, 'amt', 14231, 1);
checkSubFld('payments', 1, 'struck', 0, 1);
checkSubFld('payments', 1, 'notes', undef, 'deeply');
checkSubFld('payments', 1, 'ext', {}, 'deeply');
