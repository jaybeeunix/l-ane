#!/usr/bin/perl -w

#obj-01customer.t
#Copyright 2004-2010 Jason Burrell.
#This file is part of L'anePOS. See the top-level COPYING for licensing info.

#$Id: obj-01customer.t 1197 2010-10-24 18:23:51Z jason $

#L'ane obj test
# - customer objects

use Test::More tests => 131;

BEGIN {
    use FindBin;
    use File::Spec;
    $ENV{'LaneRoot'} = File::Spec->catdir($FindBin::Bin, File::Spec->updir); #use the correct number of updirs
    require File::Spec->catfile($ENV{'LaneRoot'}, 'config', 'init.pl');
}
BEGIN { use_ok('LanePOS::Customer'); }

my $c = Customer->new();
isa_ok($c, 'Customer');

my $username = $c->{'dal'}->getUsername;
like($username, qr/\@/, 'getUsername returned data in the expected form');

#these are the only public methods
can_ok($c, qw/new open save void isVoid searchByName getName applyToAcct chargeToAcct isExempt openRev rev/);

$c->{'id'} = 'test';
$c->{'coName'} = 'The Testing Company';
$c->{'cntFirst'} = 'Tester';
$c->{'cntLast'} = 'Testerosa';
$c->{'billAddr1'} = '666 Hellacious Way';
$c->{'billAddr2'} = '';
$c->{'billCity'} = 'Malebolge';
$c->{'billSt'} = 'KY';
$c->{'billZip'} = '12345-0000';
$c->{'billCountry'} = 'uk';
$c->{'billPhone'} = '011-123456';
$c->{'billFax'} = '011-789012';
$c->{'shipAddr1'} = '11 Heavenly Court';
$c->{'shipAddr2'} = 'Main Gate';
$c->{'shipCity'} = 'Ciel';
$c->{'shipSt'} = 'MA';
$c->{'shipZip'} = '01234-9999';
$c->{'shipCountry'} = 'be';
$c->{'shipPhone'} = '011-867-5309';
$c->{'shipFax'} = '011-903-5768';
$c->{'email'} = 'god@heaven.int';
$c->{'custType'} = 'Web Only';
$c->{'creditLmt'} = '50000';
$c->{'balance'} = '2.99';
$c->{'creditRmn'} = '49997.01';
$c->{'lastSale'} = '01-01-1999';
$c->{'lastPay'} = '01-02-1999';
$c->{'terms'} = 't1';
$c->{'taxes'} = 32767;
$c->{'notes'} = 'Be nice';

#$c->{'dal'}->trace(STDERR);

ok($c->save(), 'save a new customer');

ok($c->open(''), 'open the \'Cash\' customer');
is($c->{'id'}, '', '    \'id\' matches');
is($c->{'coName'}, 'Cash', '    \'coName\' matches');
is($c->{'cntFirst'}, '', '    \'cntFirst\' matches');
is($c->{'cntLast'}, '', '    \'cntLast\' matches');
is($c->{'billAddr1'}, '', '    \'billAddr1\' matches');
is($c->{'billAddr2'}, '', '    \'billAddr2\' matches');
is($c->{'billCity'}, '', '    \'billCity\' matches');
is($c->{'billSt'}, '', '    \'billSt\' matches');
is($c->{'billZip'}, '', '    \'billZip\' matches');
is($c->{'billCountry'}, 'us', '    \'billCountry\' matches');
is($c->{'billPhone'}, '', '    \'billPhone\' matches');
is($c->{'billFax'}, '', '    \'billFax\' matches');
is($c->{'shipAddr1'}, '', '    \'shipAddr1\' matches');
is($c->{'shipAddr2'}, '', '    \'shipAddr2\' matches');
is($c->{'shipCity'}, '', '    \'shipCity\' matches');
is($c->{'shipSt'}, '', '    \'shipSt\' matches');
is($c->{'shipZip'}, '', '    \'shipZip\' matches');
is($c->{'shipCountry'}, 'us', '    \'shipCountry\' matches');
is($c->{'shipPhone'}, '', '    \'shipPhone\' matches');
is($c->{'shipFax'}, '', '    \'shipFax\' matches');
is($c->{'email'}, '', '    \'email\' matches');
is($c->{'custType'}, 'Company', '    \'custType\' matches');
cmp_ok($c->{'creditLmt'}, '==', '0.00', '    \'creditLmt\' matches');
cmp_ok($c->{'balance'}, '==', '0.00', '    \'balance\' matches');
cmp_ok($c->{'creditRmn'}, '==', '0.00', '    \'creditRmn\' matches');
is($c->{'lastSale'}, undef, '    \'lastSale\' matches');
is($c->{'lastPay'}, undef, '    \'lastPay\' matches');
is($c->{'terms'}, 'cod', '    \'terms\' matches');
cmp_ok($c->{'taxes'}, '==', 32767, '    \'taxes\' matches');
is($c->{'notes'}, '', '    \'notes\' matches');
is($c->{'createdBy'}, 'installer@localhost', '    \'createdBy\' matches');
is($c->{'created'}, '2001-01-15 00:00:00-06', '    \'created\' matches');
ok(!$c->isExempt(), '    isExempt() works for false cases');

ok($c->open('1234'), 'open the sample customer');
is($c->{'id'}, '1234', '    \'id\' matches');
is($c->{'coName'}, 'Test Customer', '    \'coName\' matches');
is($c->{'cntFirst'}, 'John', '    \'cntFirst\' matches');
is($c->{'cntLast'}, 'Doe', '    \'cntLast\' matches');
is($c->{'billAddr1'}, '123 N. Main', '    \'billAddr1\' matches');
is($c->{'billAddr2'}, 'Apt 3', '    \'billAddr2\' matches');
is($c->{'billCity'}, 'Yourtown', '    \'billCity\' matches');
is($c->{'billSt'}, 'IL', '    \'billSt\' matches');
is($c->{'billZip'}, '62401', '    \'billZip\' matches');
is($c->{'billCountry'}, 'us', '    \'billCountry\' matches');
is($c->{'billPhone'}, '1-217-555-1212', '    \'billPhone\' matches');
is($c->{'billFax'}, '1-217-555-1213', '    \'billFax\' matches');
is($c->{'shipAddr1'}, '490 Sussex Drive', '    \'shipAddr1\' matches');
is($c->{'shipAddr2'}, 'First Floor', '    \'shipAddr2\' matches');
is($c->{'shipCity'}, 'Ottawa', '    \'shipCity\' matches');
is($c->{'shipSt'}, 'ON', '    \'shipSt\' matches');
is($c->{'shipZip'}, 'K1N 1G8', '    \'shipZip\' matches');
is($c->{'shipCountry'}, 'ca', '    \'shipCountry\' matches');
is($c->{'shipPhone'}, '1-613-238-5335', '    \'shipPhone\' matches');
is($c->{'shipFax'}, '1-613-688-3097', '    \'shipFax\' matches');
is($c->{'email'}, 'nobody@nowhere.com', '    \'email\' matches');
is($c->{'custType'}, 'Individual', '    \'custType\' matches');
cmp_ok($c->{'creditLmt'}, '==', '5000.00', '    \'creditLmt\' matches');
cmp_ok($c->{'balance'}, '==', '200.00', '    \'balance\' matches');
cmp_ok($c->{'creditRmn'}, '==', '4800.00', '    \'creditRmn\' matches');
is($c->{'lastSale'}, undef, '    \'lastSale\' matches');
is($c->{'lastPay'}, undef, '    \'lastPay\' matches');
is($c->{'terms'}, 't1', '    \'terms\' matches');
cmp_ok($c->{'taxes'}, '==', 0, '    \'taxes\' matches');
is($c->{'notes'}, '', '    \'notes\' matches');
is($c->{'createdBy'}, 'installer@localhost', '    \'createdBy\' matches');
is($c->{'created'}, '2004-01-03 14:24:20-06', '    \'created\' matches');
ok($c->isExempt(), '    isExempt() works for true cases');

ok($c->open('test'), 'open the saved customer');
is($c->{'id'}, 'test', '    \'id\' matches');
is($c->{'coName'}, 'The Testing Company', '    \'coName\' matches');
is($c->{'cntFirst'}, 'Tester', '    \'cntFirst\' matches');
is($c->{'cntLast'}, 'Testerosa', '    \'cntLast\' matches');
is($c->{'billAddr1'}, '666 Hellacious Way', '    \'billAddr1\' matches');
ok(!defined $c->{'billAddr2'}, '    \'billAddr2\' matches');
is($c->{'billCity'}, 'Malebolge', '    \'billCity\' matches');
is($c->{'billSt'}, 'KY', '    \'billSt\' matches');
is($c->{'billZip'}, '12345-0000', '    \'billZip\' matches');
is($c->{'billCountry'}, 'uk', '    \'billCountry\' matches');
is($c->{'billPhone'}, '011-123456', '    \'billPhone\' matches');
is($c->{'billFax'}, '011-789012', '    \'billFax\' matches');
is($c->{'shipAddr1'}, '11 Heavenly Court', '    \'shipAddr1\' matches');
is($c->{'shipAddr2'}, 'Main Gate', '    \'shipAddr2\' matches');
is($c->{'shipCity'}, 'Ciel', '    \'shipCity\' matches');
is($c->{'shipSt'}, 'MA', '    \'shipSt\' matches');
is($c->{'shipZip'}, '01234-9999', '    \'shipZip\' matches');
is($c->{'shipCountry'}, 'be', '    \'shipCountry\' matches');
is($c->{'shipPhone'}, '011-867-5309', '    \'shipPhone\' matches');
is($c->{'shipFax'}, '011-903-5768', '    \'shipFax\' matches');
is($c->{'email'}, 'god@heaven.int', '    \'email\' matches');
is($c->{'custType'}, 'Web Only', '    \'custType\' matches');
cmp_ok($c->{'creditLmt'}, '==', '50000', '    \'creditLmt\' matches');
cmp_ok($c->{'balance'}, '==', '2.99', '    \'balance\' matches');
cmp_ok($c->{'creditRmn'}, '==', '49997.01', '    \'creditRmn\' matches');
is($c->{'lastSale'}, '01-01-1999', '    \'lastSale\' matches');
is($c->{'lastPay'}, '01-02-1999', '    \'lastPay\' matches');
is($c->{'terms'}, 't1', '    \'terms\' matches');
cmp_ok($c->{'taxes'}, '==', 32767, '    \'taxes\' matches');
is($c->{'notes'}, 'Be nice', '    \'notes\' matches');
is($c->{'createdBy'}, $username, '    \'createdBy\' matches');
ok($c->{'created'}, '    \'created\' exists');
ok(!$c->isExempt(), '    isExempt() works for false cases');

ok($c->open(''), 'cleansing the palate');
my @found = $c->searchByName('test');
cmp_ok($#found, '==', '1', 'searchByName returns the correct number of customers');
is($found[0]{'id'}, '1234', '    [0] id is correct');
is($found[1]{'id'}, 'test', '    [1] id is correct');

ok(($c->open('1234') and $c->chargeToAcct(99.74)), 'chargeToAcct() returns correctly');
cmp_ok($c->{'creditLmt'}, '==', '5000.00', '    \'creditLmt\'');
cmp_ok($c->{'balance'}, '==', '299.74', '    \'balance\'');
cmp_ok($c->{'creditRmn'}, '==', '4700.26', '    \'creditRmn\'');
#reverse it
ok($c->applyToAcct(99.74), 'applyToAcct() returns correctly');
cmp_ok($c->{'creditLmt'}, '==', '5000.00', '    \'creditLmt\'');
cmp_ok($c->{'balance'}, '==', '200', '    \'balance\'');
cmp_ok($c->{'creditRmn'}, '==', '4800', '    \'creditRmn\'');

ok(($c->open('test') and $c->applyToAcct(6453.21)), 'applyToAcct() returns correctly');
cmp_ok($c->{'creditLmt'}, '==', '50000.00', '    \'creditLmt\'');
cmp_ok($c->{'balance'}, '==', '-6450.22', '    \'balance\'');
cmp_ok($c->{'creditRmn'}, '==', '56450.22', '    \'creditRmn\'');
#reverse it
ok($c->chargeToAcct(6453.21), 'chargeToAcct() returns correctly');
cmp_ok($c->{'creditLmt'}, '==', '50000.00', '    \'creditLmt\'');
cmp_ok($c->{'balance'}, '==', '2.99', '    \'balance\'');
cmp_ok($c->{'creditRmn'}, '==', '49997.01', '    \'creditRmn\'');

ok(($c->open('test') and $c->void), 'voiding the record');
ok(($c->open('test') and $c->isVoid), 'the record isVoid');

my @rev = $c->rev('test');
my @expRev = (12, 11, 10, 7);
is_deeply(\@rev, \@expRev, 'rev() returns the expected revisions');
ok(($c->openRev('test', $expRev[1]) and !$c->isVoid), 'spot checking an older rev');
