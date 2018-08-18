#!/usr/bin/perl -w

#obj-00tax.t
#Copyright 2004-2010 Jason Burrell.
#This file is part of L'anePOS. See the top-level COPYING for licensing info.

#$Id: obj-00tax.t 1127 2010-09-18 04:26:34Z jason $

#L'ane obj test
# - tax objects

use Test::More tests => 40;
#use Test::More 'no_plan';

BEGIN {
    use FindBin;
    use File::Spec;
    $ENV{'LaneRoot'} = File::Spec->catdir($FindBin::Bin, File::Spec->updir); #use the correct number of updirs
    require File::Spec->catfile($ENV{'LaneRoot'}, 'config', 'init.pl');
}

BEGIN { use_ok('LanePOS::Tax'); }

my $t = Tax->new();
isa_ok($t, 'Tax');

#these are the only public methods
can_ok($t, qw/new open save void isVoid applyTax applyTaxManually getAllRates getAllDescr/);

$t->{'id'} = '3';
$t->{'descr'} = 'Test Tax';
$t->{'amount'} = '12.34';

ok($t->save(), 'save a new tax');

ok($t->open(1), 'open the first sample tax');
is($t->{'id'}, '1', '    \'id\' matches');
is($t->{'descr'}, 'IL Sales Tax', '    \'descr\' matches');
cmp_ok($t->{'amount'}, '==', '6.25', '    \'amount\' matches');
cmp_ok($t->applyTax(152637), '==', '9540', '    applyTax() works');
cmp_ok($t->applyTaxManually(152637, $t->{'amount'}), '==', '9540', '    applyTaxManually() works');

ok($t->open(2), 'open the second sample tax');
is($t->{'id'}, '2', '    \'id\' matches');
is($t->{'descr'}, 'City Sales Tax', '    \'descr\' matches');
cmp_ok($t->{'amount'}, '==', '0.5', '    \'amount\' matches');
cmp_ok($t->applyTax(152637), '==', '763', '    applyTax() works');
cmp_ok($t->applyTaxManually(152637, $t->{'amount'}), '==', '763', '    applyTaxManually() works');

ok($t->open(3), 'open the saved tax');
is($t->{'id'}, '3', '    \'id\' matches');
is($t->{'descr'}, 'Test Tax', '    \'descr\' matches');
cmp_ok($t->{'amount'}, '==', '12.34', '    \'amount\' matches');
cmp_ok($t->applyTax(152637), '==', '18835', '    applyTax() works');
cmp_ok($t->applyTaxManually(152637, $t->{'amount'}), '==', '18835', '    applyTaxManually() works');

my @rates = $t->getAllRates();
cmp_ok($#rates, '==', '2', 'getAllRates() has the correct number of elements');
cmp_ok($rates[0], '==', '6.25', '    [0] has the correct rate');
cmp_ok($rates[1], '==', '0.5', '    [1] has the correct rate');
cmp_ok($rates[2], '==', '12.34', '    [2] has the correct rate');

my @descr = $t->getAllDescr();
cmp_ok($#descr, '==', '2', 'getAllDescr() has the correct number of elements');
is($descr[0], 'IL Sales Tax', '    [0] has the correct description');
is($descr[1], 'City Sales Tax', '    [1] has the correct description');
is($descr[2], 'Test Tax', '    [2] has the correct description');

#void tests
ok(($t->open(3) and $t->void), 'voiding the record');
ok(($t->open(3) and $t->isVoid), 'the record was REALLY voided');
@rates = $t->getAllRates();
cmp_ok($#rates, '==', 1, 'getAllRates() doesn\'t return voided taxes');
@descr = $t->getAllDescr();
cmp_ok($#descr, '==', 1, 'getAllDescr() doesn\'t return voided taxes');

my @rev = $t->rev(3);
is($#rev, 1, 'the correct number of revisions');
is_deeply(\@rev, [4, 3], 'the expected revisions');

ok($t->openRev(3, 3), 'openRev() an old revision');
ok(!defined($t->{'voidAt'}), 'check to make sure it\'s different');
ok($t->openRev(3, 4), 'openRev() should open voided taxes');
ok(defined($t->{'voidAt'}), 'check to make sure it\'s different');

1;
