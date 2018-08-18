#!/usr/bin/perl -w

#obj-02vendor.t
#Copyright 2004-2010 Jason Burrell.
#This file is part of L'anePOS. See the top-level COPYING for licensing info.

#$Id: obj-02vendor.t 1127 2010-09-18 04:26:34Z jason $

#L'ane obj test
# - vendor objects

use Test::More tests => 95;

BEGIN {
    use FindBin;
    use File::Spec;
    $ENV{'LaneRoot'} = File::Spec->catdir($FindBin::Bin, File::Spec->updir); #use the correct number of updirs
    require File::Spec->catfile($ENV{'LaneRoot'}, 'config', 'init.pl');
}

BEGIN { use_ok('LanePOS::Vendor'); }

my $v = Vendor->new();
isa_ok($v, 'Vendor');

my $username = $v->{'dal'}->getUsername;
like($username, qr/\@/, 'getUsername returned data in the expected form');

#these are the only public methods
can_ok($v, qw/new open save void isVoid searchByName getName applyToAcct chargeToAcct isExempt openRev rev/);

$v->{'id'} = 'test';
$v->{'coName'} = 'The Testing Company';
$v->{'cntFirst'} = 'Tester';
$v->{'cntLast'} = 'Testerosa';
$v->{'billAddr1'} = '666 Hellacious Way';
$v->{'billAddr2'} = 'Suite 2';
$v->{'billCity'} = 'Malebolge';
$v->{'billSt'} = 'KY';
$v->{'billZip'} = '12345-0000';
$v->{'billCountry'} = 'uk';
$v->{'billPhone'} = '011-123456';
$v->{'billFax'} = '011-789012';
$v->{'shipAddr1'} = '11 Heavenly Court';
$v->{'shipAddr2'} = 'Main Gate';
$v->{'shipCity'} = 'Ciel';
$v->{'shipSt'} = 'MA';
$v->{'shipZip'} = '01234-9999';
$v->{'shipCountry'} = 'be';
$v->{'shipPhone'} = '011-867-5309';
$v->{'shipFax'} = '011-903-5768';
$v->{'email'} = 'god@heaven.int';
$v->{'creditLmt'} = '50000';
$v->{'balance'} = '2.99';
$v->{'creditRmn'} = '49997.01';
$v->{'lastSale'} = '01-01-1999';
$v->{'lastPay'} = '01-02-1999';
$v->{'terms'} = 't1';
$v->{'taxes'} = '32767';
$v->{'notes'} = 'Be nice';

ok($v->save(), 'save a new vendor');

ok($v->open('1234'), 'open the sample vendor');
is($v->{'id'}, '1234', '    \'id\' matches');
is($v->{'coName'}, 'Test Vendor', '    \'coName\' matches');
is($v->{'cntFirst'}, 'John', '    \'cntFirst\' matches');
is($v->{'cntLast'}, 'Doe', '    \'cntLast\' matches');
is($v->{'billAddr1'}, '123 N. Main', '    \'billAddr1\' matches');
is($v->{'billAddr2'}, 'Apt 3', '    \'billAddr2\' matches');
is($v->{'billCity'}, 'Yourtown', '    \'billCity\' matches');
is($v->{'billSt'}, 'IL', '    \'billSt\' matches');
is($v->{'billZip'}, '62401', '    \'billZip\' matches');
is($v->{'billCountry'}, 'us', '    \'billCountry\' matches');
is($v->{'billPhone'}, '1-217-555-1212', '    \'billPhone\' matches');
is($v->{'billFax'}, '1-217-555-1213', '    \'billFax\' matches');
is($v->{'shipAddr1'}, '490 Sussex Drive', '    \'shipAddr1\' matches');
is($v->{'shipAddr2'}, 'First Floor', '    \'shipAddr2\' matches');
is($v->{'shipCity'}, 'Ottawa', '    \'shipCity\' matches');
is($v->{'shipSt'}, 'ON', '    \'shipSt\' matches');
is($v->{'shipZip'}, 'K1N 1G8', '    \'shipZip\' matches');
is($v->{'shipCountry'}, 'ca', '    \'shipCountry\' matches');
is($v->{'shipPhone'}, '1-613-238-5335', '    \'shipPhone\' matches');
is($v->{'shipFax'}, '1-613-688-3097', '    \'shipFax\' matches');
is($v->{'email'}, 'nobody@nowhere.com', '    \'email\' matches');
cmp_ok($v->{'creditLmt'}, '==', '5000.00', '    \'creditLmt\' matches');
cmp_ok($v->{'balance'}, '==', '200.00', '    \'balance\' matches');
cmp_ok($v->{'creditRmn'}, '==', '4800.00', '    \'creditRmn\' matches');
is($v->{'lastSale'}, undef, '    \'lastSale\' matches');
is($v->{'lastPay'}, undef, '    \'lastPay\' matches');
is($v->{'terms'}, 't1', '    \'terms\' matches');
cmp_ok($v->{'taxes'}, '==', '0', '    \'taxes\' matches');
is($v->{'notes'}, '', '    \'notes\' matches');
is($v->{'createdBy'}, 'installer@localhost', '    \'createdBy\' matches');
is($v->{'created'}, '2004-01-03 14:24:20-06', '    \'created\' matches');
ok($v->isExempt(), '    isExempt() works for true cases');

ok($v->open('test'), 'open the saved vendor');
is($v->{'id'}, 'test', '    \'id\' matches');
is($v->{'coName'}, 'The Testing Company', '    \'coName\' matches');
is($v->{'cntFirst'}, 'Tester', '    \'cntFirst\' matches');
is($v->{'cntLast'}, 'Testerosa', '    \'cntLast\' matches');
is($v->{'billAddr1'}, '666 Hellacious Way', '    \'billAddr1\' matches');
is($v->{'billAddr2'}, 'Suite 2', '    \'billAddr2\' matches');
is($v->{'billCity'}, 'Malebolge', '    \'billCity\' matches');
is($v->{'billSt'}, 'KY', '    \'billSt\' matches');
is($v->{'billZip'}, '12345-0000', '    \'billZip\' matches');
is($v->{'billCountry'}, 'uk', '    \'billCountry\' matches');
is($v->{'billPhone'}, '011-123456', '    \'billPhone\' matches');
is($v->{'billFax'}, '011-789012', '    \'billFax\' matches');
is($v->{'shipAddr1'}, '11 Heavenly Court', '    \'shipAddr1\' matches');
is($v->{'shipAddr2'}, 'Main Gate', '    \'shipAddr2\' matches');
is($v->{'shipCity'}, 'Ciel', '    \'shipCity\' matches');
is($v->{'shipSt'}, 'MA', '    \'shipSt\' matches');
is($v->{'shipZip'}, '01234-9999', '    \'shipZip\' matches');
is($v->{'shipCountry'}, 'be', '    \'shipCountry\' matches');
is($v->{'shipPhone'}, '011-867-5309', '    \'shipPhone\' matches');
is($v->{'shipFax'}, '011-903-5768', '    \'shipFax\' matches');
is($v->{'email'}, 'god@heaven.int', '    \'email\' matches');
cmp_ok($v->{'creditLmt'}, '==', '50000', '    \'creditLmt\' matches');
cmp_ok($v->{'balance'}, '==', '2.99', '    \'balance\' matches');
cmp_ok($v->{'creditRmn'}, '==', '49997.01', '    \'creditRmn\' matches');
is($v->{'lastSale'}, '01-01-1999', '    \'lastSale\' matches');
is($v->{'lastPay'}, '01-02-1999', '    \'lastPay\' matches');
is($v->{'terms'}, 't1', '    \'terms\' matches');
cmp_ok($v->{'taxes'}, '==', '32767', '    \'taxes\' matches');
is($v->{'notes'}, 'Be nice', '    \'notes\' matches');
is($v->{'createdBy'}, $username, '    \'createdBy\' matches');
ok($v->{'created'}, '    \'created\' exists');
ok(!$v->isExempt(), '    isExempt() works for false cases');

my @found = $v->searchByName('test');
cmp_ok($#found, '==', '2', 'searchByName returns the correct number of vendors');
is($found[0]{'id'}, '1234', '    [0] id is correct');
is($found[1]{'id'}, '5678', '    [1] id is correct');
is($found[2]{'id'}, 'test', '    [2] id is correct');

ok(($v->open('1234') and $v->chargeToAcct(99.74)), 'chargeToAcct() returns correctly');
cmp_ok($v->{'creditLmt'}, '==', '5000.00', '    \'creditLmt\'');
cmp_ok($v->{'balance'}, '==', '299.74', '    \'balance\'');
cmp_ok($v->{'creditRmn'}, '==', '4700.26', '    \'creditRmn\'');
#reverse it
ok($v->applyToAcct(99.74), 'applyToAcct() returns correctly');
cmp_ok($v->{'creditLmt'}, '==', '5000.00', '    \'creditLmt\'');
cmp_ok($v->{'balance'}, '==', '200', '    \'balance\'');
cmp_ok($v->{'creditRmn'}, '==', '4800', '    \'creditRmn\'');

ok(($v->open('test') and $v->applyToAcct(6453.21)), 'applyToAcct() returns correctly');
cmp_ok($v->{'creditLmt'}, '==', '50000.00', '    \'creditLmt\'');
cmp_ok($v->{'balance'}, '==', '-6450.22', '    \'balance\'');
cmp_ok($v->{'creditRmn'}, '==', '56450.22', '    \'creditRmn\'');
#reverse it
ok($v->chargeToAcct(6453.21), 'chargeToAcct() returns correctly');
cmp_ok($v->{'creditLmt'}, '==', '50000.00', '    \'creditLmt\'');
cmp_ok($v->{'balance'}, '==', '2.99', '    \'balance\'');
cmp_ok($v->{'creditRmn'}, '==', '49997.01', '    \'creditRmn\'');

ok(($v->open('test') and $v->void), 'voiding the record');
ok(($v->open('test') and $v->isVoid), 'the record isVoid');

my @rev = $v->rev('test');
my @expRev = (8, 7, 6, 3);
is_deeply(\@rev, \@expRev, 'rev() returns the expected revisions');
ok(($v->openRev('test', $expRev[1]) and !$v->isVoid), 'spot checking an older rev');
