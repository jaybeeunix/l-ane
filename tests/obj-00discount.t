#!/usr/bin/perl -w

#obj-00discount.t
#Copyright 2004-2010 Jason Burrell.
#This file is part of L'anePOS. See the top-level COPYING for licensing info.

#$Id: obj-00discount.t 1165 2010-09-29 01:22:39Z jason $

#L'ane obj test
# - discount objects

use Test::More tests => 35;

BEGIN {
    use FindBin;
    use File::Spec;
    $ENV{'LaneRoot'} = File::Spec->catdir($FindBin::Bin, File::Spec->updir); #use the correct number of updirs
    require File::Spec->catfile($ENV{'LaneRoot'}, 'config', 'init.pl');
}
BEGIN { use_ok('LanePOS::Discount'); }

my $d = Discount->new();
isa_ok($d, 'Discount');

#these are the only public methods
can_ok($d, qw/new open save void isVoid isSaleDisc isPercentDisc isPresetDisc giveDisc rev openRev/);

$d->{'id'} = '2';
$d->{'descr'} = 'Test Two';
$d->{'preset'} = 0;
$d->{'per'} = 0;
$d->{'amt'} = '4.56';
$d->{'sale'} = 1;

ok($d->save(), 'save a new discount');

ok($d->open('1'), 'open the sample discount');
is($d->{'id'}, '1', '    \'id\' matches');
is($d->{'descr'}, 'Test Disc', '    \'descr\' matches');
cmp_ok($d->{'amt'}, '==', '23', '    \'amt\' matches');
ok(!$d->isSaleDisc(), '    isSaleDisc() works for false cases');
ok($d->isPresetDisc(), '    isPresetDisc() works for true cases');
ok($d->isPercentDisc(), '    isPercentDisc() works for true cases');
cmp_ok($d->giveDisc(9999, 5678), '==', '1306', '    giveDisc() worked');
cmp_ok($d->giveDisc(101010, 5678), '==', '1306', '    giveDisc() worked with overriding junk');
#this is kludgy
$d->{'preset'} = 0;
cmp_ok($d->giveDisc(9999, 5678), '==', '567743', '    giveDisc() worked [preset false]');
cmp_ok($d->giveDisc(101010, 5678), '==', '5735348', '    giveDisc() worked with overriding junk [preset false]');

ok($d->open('2'), 'open the saved discount');
is($d->{'id'}, '2', '    \'id\' matches');
is($d->{'descr'}, 'Test Two', '    \'descr\' matches');
cmp_ok($d->{'amt'}, '==', '4.56', '    \'amt\' matches');
ok($d->isSaleDisc(), '    isSaleDisc() works for true cases');
ok(!$d->isPresetDisc(), '    isPresetDisc() works for false cases');
ok(!$d->isPercentDisc(), '    isPercentDisc() works for false cases');
cmp_ok($d->giveDisc(9876, 1234), '==', '9876', '    giveDisc() worked');
cmp_ok($d->giveDisc(1728, 1234), '==', '1728', '    giveDisc() worked with overriding junk');
#this is kludgy
$d->{'preset'} = 1;
cmp_ok($d->giveDisc(9999, 1234), '==', '456', '    giveDisc() worked [preset true]');
cmp_ok($d->giveDisc(101010, 1234), '==', '456', '    giveDisc() worked with overriding junk [preset true]');


#$d->{'dal'}->trace(STDERR);
ok(($d->open(2) and $d->void()), 'voiding the record');
ok($d->open(1), 'cleanse the palate');
ok(($d->open(2) and $d->isVoid), 'the record was REALLY void');

eval {
    cmp_ok($d->giveDisc(101010, 1234), '<', '456', '    giveDisc() shouldn\'t work');
};
ok($@, 'giveDisc() should die when the disc is void');

my @rev = $d->rev(2);
is_deeply(\@rev, [6, 5], 'the expected revisions');
ok($d->openRev(2, 5), 'open the old revision');
ok(!defined $d->{'voidAt'}, 'the discount isn\'t void');
ok($d->openRev(2, 6), 'open the current revision');
ok(defined $d->{'voidAt'}, 'the discount is void');
1;
