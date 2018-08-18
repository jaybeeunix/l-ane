#!/usr/bin/perl -w

#obj-00pricetable.t
#Copyright 2004-2010 Jason Burrell.
#This file is part of L'anePOS. See the top-level COPYING for licensing info.

#$Id: obj-00pricetable.t 1127 2010-09-18 04:26:34Z jason $

#L'ane obj test
# - pricetable objects

use Test::More tests => 35;

BEGIN {
    use FindBin;
    use File::Spec;
    $ENV{'LaneRoot'} = File::Spec->catdir($FindBin::Bin, File::Spec->updir); #use the correct number of updirs
    require File::Spec->catfile($ENV{'LaneRoot'}, 'config', 'init.pl');
}

BEGIN { use_ok('LanePOS::PriceTable'); }

my $pt = PriceTable->new();
isa_ok($pt, 'PriceTable');

#these are the only public methods
can_ok($pt, qw/new open save void isVoid price/);

$pt->{'id'} = '3';
$pt->{'priceList'} = '2.00 0.00';

ok($pt->save(), 'save a new pricetable');

ok($pt->open('1'), 'open the sample pricetable');
is($pt->{'id'}, '1', '    \'id\' matches');
is($pt->{'priceList'}, '0.34 0.33 0.22', '    \'priceList\' matches');
my @prices = (0.34, 0.33, 0.22);
cmp_ok($pt->price($_), '==', $prices[$_ % ($#prices + 1)], "    price($_) matches") foreach (0..5);

ok($pt->open('2'), 'open the second sample pricetable');
is($pt->{'id'}, '2', '    \'id\' matches');
is($pt->{'priceList'}, '0.34 0.33 0.33', '    \'priceList\' matches');
@prices = (0.34, 0.33, 0.33);
cmp_ok($pt->price($_), '==', $prices[$_ % ($#prices + 1)], "    price($_) matches") foreach (0..5);

ok($pt->open('3'), 'open the saved pricetable');
is($pt->{'id'}, '3', '    \'id\' matches');
is($pt->{'priceList'}, '2.00 0.00', '    \'priceList\' matches');
@prices = (2.00, 0.00);
cmp_ok($pt->price($_), '==', $prices[$_ % ($#prices + 1)], "    price($_) matches") foreach (0..3);

ok(($pt->open(3) and $pt->void), 'voidng the record');
ok(($pt->open(3) and $pt->isVoid), 'the record was REALLY voided');

#revision
my @rev = $pt->rev(3);
my @exp = (4, 3);

ok($pt->openRev(3, 3), 'open the first r');
ok(!$pt->isVoid, '    it isn\'t void');

ok($pt->openRev(3, 4), 'open the second r');
ok($pt->isVoid, '    it isVoid');
