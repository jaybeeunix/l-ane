#!/usr/bin/perl -w

#obj-03purchaseorder.t
#Copyright 2007-2010 Jason Burrell.
#This file is part of L'anePOS. See the top-level COPYING for licensing info.

#$Id: obj-03purchaseorder.t 1127 2010-09-18 04:26:34Z jason $

#L'ane obj test
# - purchaseorder

use Test::More tests => 107;
#use Test::More 'no_plan';

BEGIN {
    use FindBin;
    use File::Spec;
    $ENV{'LaneRoot'} = File::Spec->catdir($FindBin::Bin, File::Spec->updir); #use the correct number of updirs
    require File::Spec->catfile($ENV{'LaneRoot'}, 'config', 'init.pl');
}

BEGIN { use_ok('LanePOS::PurchaseOrder'); }

#for debugging
use Data::Dumper;

my $po = PurchaseOrder->new();
isa_ok($po, 'PurchaseOrder');

#diag('general object methods');
can_ok($po, qw/
new
open
save
getPending
void
getVendorsNeedingOrders
getProductsToOrderFrom
openRev
rev
/);

#create a new po
$po->{'vendor'} = '1234';
$po->{'notes'} = 'first test';
$po->{'total'} = 10025;
$po->{'completelyReceived'} = 0;

$po->{'orderedItems'}[0]{'plu'} = '1';
$po->{'orderedItems'}[0]{'qty'} = 10;
$po->{'orderedItems'}[0]{'amt'} = 10000;

$po->{'orderedItems'}[1]{'plu'} = '2';
$po->{'orderedItems'}[1]{'qty'} = 25;
$po->{'orderedItems'}[1]{'amt'} = 25;

$po->{'receivedItems'}[0]{'plu'} = '1';
$po->{'receivedItems'}[0]{'qty'} = 5;
#$po->{'receivedItems'}[0]{'amt'} = 5000;

#$po->{'orderedItems'}[]{'plu'} = '';
#$po->{'orderedItems'}[]{'qty'} = ;
#$po->{'orderedItems'}[]{'amt'} = ;
#$po->{'receivedItems'}[]{'plu'} = '';
#$po->{'receivedItems'}[]{'qty'} = ;
#$po->{'receivedItems'}[]{'amt'} = ;
#$po->{''} = '';

ok($po->save(), 'save a new purchase order');
my $id = $po->{'id'};
ok($po->open(1), 'open an existing po');
is($po->{'id'}, '1', '    \'id\' matches');
is($po->{'vendor'}, '5678', '    \'vendor\' matches');
is($po->{'created'}, '2007-06-02 13:40:09.889234-05', '    \'created\' matches');
is($po->{'createdBy'}, 'jason@localhost', '    \'createdBy\' matches');
is($po->{'modified'}, '2007-06-02 13:40:09.889234-05', '    \'modified\' matches');
is($po->{'modifiedBy'}, 'jason@localhost', '    \'modifiedBy\' matches');
is($po->{'notes'}, 'first test', '    \'notes\' matches');
is($po->{'extended'}, undef, '    \'extended\' matches');
is($po->{'total'}, '9999', '    \'total\' matches');
is($po->{'voidAt'}, undef, '    \'voidAt\' matches');
is($po->{'voidBy'}, undef, '    \'voidBy\' matches');
is($po->{'orderedAt'}, undef, '    \'orderedAt\' matches');
is($po->{'orderedBy'}, undef, '    \'orderedBy\' matches');
is($po->{'orderedVia'}, undef, '    \'orderedVia\' matches');
ok(!$po->{'completelyReceived'}, '    \'completelyReceived\' matches');

my $oi = {
    'id' => '1',
    'lineNo' => '0',
    'plu' => '3',
    'qty' => 10, #this should be a numeric comparison
    'amt' => 9900, #this should be a numeric comparison
    'voidAt' => undef,
    'voidBy' => undef,
    'extended' => undef,
};
orderedItems($po->{'orderedItems'}[0], $oi, 'lineNo 0');
$oi = {
    'id' => '1',
    'lineNo' => '1',
    'plu' => '2',
    'qty' => 1, #this should be a numeric comparison
    'amt' => 99, #this should be a numeric comparison
    'voidAt' => undef,
    'voidBy' => undef,
    'extended' => undef,
};
orderedItems($po->{'orderedItems'}[1], $oi, 'lineNo 1');
$oi = {
    'id' => '1',
    'lineNo' => '0',
    'plu' => '3',
    'qty' => 5,
    'received' => '2007-06-02 13:40:09.889234-05',
    'receivedBy' => 'jason@localhost',
    'voidAt' => undef,
    'voidBy' => undef,
    'extended' => undef,
};
receivedItems($po->{'receivedItems'}[0], $oi, 'lineNo 0');

ok($po->open($id), "open the created po ($id)");
is($po->{'id'}, $id, '    \'id\' matches');
is($po->{'vendor'}, '1234', '    \'vendor\' matches');
ok($po->{'created'}, '    \'created\' EXISTS');
ok($po->{'createdBy'}, '    \'createdBy\' EXISTS');
ok($po->{'modified'}, '    \'modified\' EXISTS');
ok($po->{'modifiedBy'}, '    \'modifiedBy\' EXISTS');
is($po->{'notes'}, 'first test', '    \'notes\' matches');
is($po->{'extended'}, undef, '    \'extended\' matches');
ok($po->{'total'} == 10025, '    \'total\' matches');
is($po->{'voidAt'}, undef, '    \'voidAt\' matches');
is($po->{'voidBy'}, undef, '    \'voidBy\' matches');
is($po->{'orderedAt'}, undef, '    \'orderedAt\' matches');
is($po->{'orderedBy'}, undef, '    \'orderedBy\' matches');
is($po->{'orderedVia'}, undef, '    \'orderedVia\' matches');
ok(!$po->{'completelyReceived'}, '    \'completelyReceived\' matches');
$oi = {
    'id' => $id,
    'lineNo' => '0',
    'plu' => '1',
    'qty' => 10,
    'amt' => 10000,
    'voidAt' => undef,
    'voidBy' => undef,
    'extended' => undef,    
};
orderedItems($po->{'orderedItems'}[0], $oi, 'lineNo 0');
$oi = {
    'id' => $id,
    'lineNo' => '1',
    'plu' => '2',
    'qty' => 25,
    'amt' => 25,
    'voidAt' => undef,
    'voidBy' => undef,
    'extended' => undef,    
};
orderedItems($po->{'orderedItems'}[1], $oi, 'lineNo 1');
$oi = {
    'id' => $id,
    'lineNo' => '0',
    'plu' => '1',
    'qty' => 5,
    'received' => $po->{'receivedItems'}[0]{'received'} ? $po->{'receivedItems'}[0]{'received'} : undef, #these aren't really tested
    'receivedBy' => $po->{'receivedItems'}[0]{'receivedBy'} ? $po->{'receivedItems'}[0]{'receivedBy'} : undef, #these aren't really tested
    'voidAt' => undef,
    'voidBy' => undef,
    'extended' => undef,
};
receivedItems($po->{'receivedItems'}[0], $oi, 'lineNo 0');

#PurchaseOrder-specific sub tests
my @v;
my @vExpected = (1, $id);
ok(@v = $po->getPending(), 'getPending() returns values');
cmp_ok($#v, '==', $#vExpected, '    returned the correct number of orders');
is_deeply(\@v, \@vExpected, '    the data is as expected');
#warn Dumper(\@v);
ok(@v = $po->getVendorsNeedingOrders(), 'getVendorsNeedingOrders() returns values');
is($#v, 1, '    returned the correct number of vendors');
is($v[0], '1234', '    [0] element is correct');
is($v[1], '5678', '    [1] element is correct');
#now check the items suggested for each vendor
my %i = (
    '1234' => [3, 4], #2 has a large number of outstanding things on order, 3 has outstanding items on order, but not enough to bring it up to the minimum, 4 has no orders pending
    '5678' => [5] #product needs ordered, nothing outstanding on orders
    );

foreach my $v (@v)
{
    #this test section is flawed in that it only allows each vendor to have a single item to reorder
    my @j;
    ok(@j = $po->getProductsToOrderFrom($v), "getProductsToOrderFrom($v) returns values");
    is($#j, $#{$i{$v}}, '    returned the correct number of items');
    #warn Dumper(\@j);
    foreach (0..$#j)
    {
        is($j[$_], $i{$v}->[$_], "    [$_] element is correct");
    }
}

#check void
ok(($po->open($id) and $po->void), 'open and void worked');
ok($po->open($id), 'open worked again');
ok((defined($po->{'voidAt'}) and $po->{'voidAt'} ne ''), "    voidAt is not empty ($po->{'voidAt'})");
ok((defined($po->{'voidBy'}) and $po->{'voidBy'} ne ''), "    voidBy is not empty ($po->{'voidBy'})");

#rev
my @rev = $po->rev($id);
my @expRev = (3, 2);

is_deeply(\@rev, \@expRev, 'rev() returns the expected revisions');
ok(($po->openRev($id, $expRev[1]) and !$po->isVoid), 'spot checking an older rev');
ok(($po->openRev($id, $expRev[0]) and $po->isVoid), 'spot checking an older rev');

sub orderedItems
{
    #this compares orderedItems
    my ($in, $oi, $nme) = @_;
    
    ok($in->{'id'} == $oi->{'id'}, "$nme 'orderedItems' 'id' matches");
    ok($in->{'lineNo'} == $oi->{'lineNo'}, '    \'orderedItems\' \'lineNo\' matches');
    is($in->{'plu'}, $oi->{'plu'}, '    \'orderedItems\' \'plu\' matches');
    ok($in->{'qty'} == $oi->{'qty'}, '    \'orderedItems\' \'qty\' matches');
    ok($in->{'amt'} == $oi->{'amt'}, '    \'orderedItems\' \'amt\' matches');
    is($in->{'voidAt'}, $oi->{'voidAt'}, '    \'orderedItems\' \'voidAt\' matches');
    is($in->{'voidBy'}, $oi->{'voidBy'}, '    \'orderedItems\' \'voidBy\' matches');
    is($in->{'extended'}, $oi->{'extended'}, '    \'orderedItems\' \'extended\' matches');
}

sub receivedItems
{
    #this compares receivedItems
    my ($in, $oi, $nme) = @_;
    
    ok($in->{'id'} == $oi->{'id'}, "$nme 'receivedItems' 'id' matches");
    ok($in->{'lineNo'} == $oi->{'lineNo'}, '    \'receivedItems\' \'lineNo\' matches');
    is($in->{'plu'}, $oi->{'plu'}, '    \'receivedItems\' \'plu\' matches');
    ok($in->{'qty'} == $oi->{'qty'}, '    \'receivedItems\' \'qty\' matches');
    is($in->{'receivedAt'}, $oi->{'receivedAt'}, '    \'receivedItems\' \'receivedAt\' matches');
    is($in->{'receivedBy'}, $oi->{'receivedBy'}, '    \'receivedItems\' \'receivedBy\' matches');
    is($in->{'voidAt'}, $oi->{'voidAt'}, '    \'receivedItems\' \'voidAt\' matches');
    is($in->{'voidBy'}, $oi->{'voidBy'}, '    \'receivedItems\' \'voidBy\' matches');
    is($in->{'extended'}, $oi->{'extended'}, '    \'receivedItems\' \'extended\' matches');
}
