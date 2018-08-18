#!/usr/bin/perl -w

#obj-00product.t
#Copyright 2003-2010 Jason Burrell.
#This file is part of L'anePOS. See the top-level COPYING for licensing info.

#L'ane obj test
# - product

#$Id: obj-00product.t 1165 2010-09-29 01:22:39Z jason $

use Test::More tests => 72;
#use Test::More 'no_plan';

BEGIN {
    use FindBin;
    use File::Spec;
    $ENV{'LaneRoot'} = File::Spec->catdir($FindBin::Bin, File::Spec->updir); #use the correct number of updirs
    require File::Spec->catfile($ENV{'LaneRoot'}, 'config', 'init.pl');
}

BEGIN { use_ok('LanePOS::Product'); }

#for debugging
use Data::Dumper;

my $product = Product->new();
isa_ok($product, 'Product');

#diag('general object methods');
can_ok($product, qw/
new
open
save
searchByDescr
trackQty
consumeUnits
receiveUnits
getUnderstocked
getUnderstockedByVendor
getAllUnderstockedVendors
void
isVoid
/);

#bug 1342
my $searchExpected = [
    {
        'minimum' => '2.000',
        'taxes' => '0',
        'trackQty' => 1,
        'id' => '2',
        'category' => 'test',
        'cost' => undef,
        'caseId' => undef,
        'descr' => 'Misc Non-Taxable',
        'caseQty' => '0.000',
        'type' => 'o',
        'price' => '0.000',
        'reorderId' => undef,
        'onHand' => '1.000',
        'reorder' => '5.000',
        'vendor' => '1234',
        'extended' => {}
    },
    {
        'minimum' => '0.000',
        'taxes' => '3',
        'trackQty' => 0,
        'id' => '1',
        'category' => 'test',
        'cost' => undef,
        'caseId' => undef,
        'descr' => 'Misc Taxable',
        'caseQty' => '0.000',
        'type' => 'o',
        'price' => '0.000',
        'reorderId' => undef,
        'onHand' => '0.000',
        'reorder' => '0.000',
        'vendor' => '1234',
        'extended' => {}
    },
    {
        'minimum' => '8.000',
        'taxes' => '3',
        'trackQty' => 1,
        'id' => '3',
        'category' => 'test',
        'cost' => undef,
        'caseId' => undef,
        'descr' => 'Test',
        'caseQty' => '0.000',
        'type' => 'o',
        'price' => '0.000',
        'reorderId' => undef,
        'onHand' => '2.000',
        'reorder' => '10.000',
        'vendor' => '1234',
        'extended' => {}
    },
    {
        'minimum' => '3.000',
        'taxes' => '4',
        'trackQty' => 1,
        'id' => '4',
        'category' => 'test',
        'cost' => undef,
        'caseId' => undef,
        'descr' => 'Test PO',
        'caseQty' => '0.000',
        'type' => 'p',
        'price' => '1.000',
        'reorderId' => undef,
        'onHand' => '1.000',
        'reorder' => '5.000',
        'vendor' => '1234',
        'extended' => {}
    },
    {
        'minimum' => '3.000',
        'taxes' => '4',
        'trackQty' => 1,
        'id' => '5',
        'category' => 'test',
        'cost' => undef,
        'caseId' => undef,
        'descr' => 'Test Prod',
        'caseQty' => '0.000',
        'type' => 'p',
        'price' => '1.000',
        'reorderId' => undef,
        'onHand' => '1.000',
        'reorder' => '5.000',
        'vendor' => '5678',
        'extended' => {}
    }
    ];
is_deeply([$product->searchByDescr('e')], $searchExpected, 'searchByDescr() returned the expected data');

$product->{'id'} = '6789';
$product->{'descr'} = 'Test Product Case';
$product->{'price'} = '15.67';
$product->{'category'} = 'test';
$product->{'taxes'} = '1';
$product->{'type'} = 'P';
$product->{'trackQty'} = 'y';
$product->{'onHand'} = '5';
$product->{'minimum'} = '1';
$product->{'reorder'} = '10';
$product->{'vendor'} = '1234';
$product->{'caseQty'} = '0';
$product->{'caseId'} = '';
$product->{'extended'} = {};
$product->{'cost'} = '10.98';
$product->{'reorderId'} = 'retwo';
ok($product->save(), 'save a new product (case item)');

$product = Product->new;
$product->{'id'} = '12345';
$product->{'descr'} = 'Test Product 2';
$product->{'price'} = '1.23';
$product->{'category'} = 'test';
$product->{'taxes'} = '1';
$product->{'type'} = 'P';
$product->{'trackQty'} = 'y';
$product->{'onHand'} = '3';
$product->{'minimum'} = '1';
$product->{'reorder'} = '5';
$product->{'vendor'} = '1234';
$product->{'caseQty'} = '5';
$product->{'caseId'} = '6789';
my %p12345Extended = ('a' => 1, 'b' => 2);
$product->{'extended'} = {%p12345Extended};
$product->{'cost'} = '0.75';
$product->{'reorderId'} = 're123';
ok($product->save(), 'save a new product (unit item)');

#ok($product->open('100'), 'open the sample product');
ok($product->open('12345'), 'open the saved product');
is($product->{'id'}, '12345', "    'id' matches");
is($product->{'descr'}, 'Test Product 2', '    \'descr\' matches');
cmp_ok($product->{'price'}, '==', '1.23', '    \'price\' matches');
is($product->{'category'}, 'test', '    \'category\' matches');
cmp_ok($product->{'taxes'}, '==', '1', '    \'taxes\' matches');
is($product->{'trackQty'}, 1, '    \'trackQty\' matches');
cmp_ok($product->{'onHand'}, '==', '3', '    \'onHand\' matches');
cmp_ok($product->{'minimum'}, '==', '1', '    \'minimum\' matches');
cmp_ok($product->{'reorder'}, '==', '5', '    \'reorder\' matches');
is($product->{'vendor'}, '1234', '    \'vendor\' matches');
cmp_ok($product->{'caseQty'}, '==', '5', '    \'caseQty\' matches');
is($product->{'caseId'}, '6789', '    \'caseId\' matches');
isa_ok($product->{'extended'}, 'HASH', '    \'extended\'');
is_deeply($product->{'extended'}, \%p12345Extended, '    \'extended\' contains the expected info');
cmp_ok($product->{'cost'}, '==', '0.75', '    \'cost\' matches');
is($product->{'reorderId'}, 're123', '    \'reorderId\' matches');

ok($product->open('6789'), 'open the other saved product');
is($product->{'id'}, '6789', "    'id' matches");
is($product->{'descr'}, 'Test Product Case', '    \'descr\' matches');
cmp_ok($product->{'price'}, '==', '15.67', '    \'price\' matches');
is($product->{'category'}, 'test', '    \'category\' matches');
cmp_ok($product->{'taxes'}, '==', '1', '    \'taxes\' matches');
is($product->{'trackQty'}, 1, '    \'trackQty\' matches');
cmp_ok($product->{'onHand'}, '==', '5', '    \'onHand\' matches');
cmp_ok($product->{'minimum'}, '==', '1', '    \'minimum\' matches');
cmp_ok($product->{'reorder'}, '==', '10', '    \'reorder\' matches');
is($product->{'vendor'}, '1234', '    \'vendor\' matches');
cmp_ok($product->{'caseQty'}, '==', '0', '    \'caseQty\' matches');
is($product->{'caseId'}, undef, '    \'caseId\' matches');
isa_ok($product->{'extended'}, 'HASH', '    \'extended\' is a hash');
cmp_ok($product->{'cost'}, '==', '10.98', '    \'cost\' matches');
is($product->{'reorderId'}, 'retwo', '    \'reorderId\' matches');

#test the qty business
ok($product->open('12345'), 'opening the product for qty tests');
ok($product->consumeUnits('7'), '    consumeUnits() works');
cmp_ok($product->{'onHand'}, '==', '1', '    the correct number of items appear in the unit product');
ok($product->open('6789'), '    opening the other product for verification');
cmp_ok($product->{'onHand'}, '==', '4', '    the correct number of items appear in the case product');


ok(($product->open('12345') and $product->void), 'voiding the record');
ok(($product->open('12345') and $product->isVoid), 'the product was REALLY void');
ok($product->open('6789'), 'open the other saved product');
ok($product->void, 'voiding the other record');
ok(($product->open('6789') and $product->isVoid), 'the other product was REALLY voided');

#test the various get*Understocked* things
#getUnderstocked()
my @uExpected = (2, 3, 4, 5);
my @u = $product->getUnderstocked();
cmp_ok($#u, '==', $#uExpected, 'getUnderstocked() returned the expected number of products');
#warn Dumper(\@u, \@uExpected);
is_deeply(\@u, \@uExpected, 'getUnderstocked() returned the expected data');
#getAllUnderstockedVendors()
my @vExpected = ('1234', '5678');
my @v = $product->getAllUnderstockedVendors();
cmp_ok($#v, '==', $#vExpected, 'getAllUnderstockedVendors() returned the expected number of vendors');
is_deeply(\@v, \@vExpected, 'getAllUnderstockedVendors() returned the expected data');
#getUnderstockedByVendor()
my %pExpected = (
    '1234' => [2, 3, 4],
    '5678' => [5],
    );
foreach my $v (@vExpected)
{
    my @p = $product->getUnderstockedByVendor($v);
    cmp_ok($#p, '==', $#{$pExpected{$v}}, "getUnderstockedByVendor($v) returned the expected number of products");
    is_deeply(\@p, $pExpected{$v}, "getUnderstockedByVendor($v) returned the expected products");
}

#check the revision stuff
my @rev = $product->rev('12345');
my @expRev = (11, 10, 8, 7);
my $user = $product->{'dal'}->getUsername;

is_deeply(\@rev, \@expRev, '12345 has the expected revisions');

ok($product->openRev('12345', 7), 'openRev works');
cmp_ok($product->{'onHand'}, '==', 3, '    onHand is as expected');
is($product->{'modifiedBy'}, $user, '    modifiedBy is the expected user');

ok($product->openRev('12345', 8), 'openRev works');
cmp_ok($product->{'onHand'}, '==', 8, '    onHand is as expected');
is($product->{'modifiedBy'}, $user, '    modifiedBy is the expected user');

ok($product->openRev('12345', 10), 'openRev works');
cmp_ok($product->{'onHand'}, '==', 1, '    onHand is as expected');
is($product->{'modifiedBy'}, $user, '    modifiedBy is the expected user');

ok($product->openRev('12345', 11), 'openRev works');
cmp_ok($product->{'onHand'}, '==', 1, '    onHand is as expected');
is($product->{'modifiedBy'}, $user, '    modifiedBy is the expected user');
ok($product->isVoid, '    isVoid');
is($product->{'voidBy'}, $user, '    modifiedBy is the expected user');
