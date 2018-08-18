#!/usr/bin/perl -w

#obj-02sale.t
#Copyright 2004-2010 Jason Burrell.
#This file is part of L'anePOS. See the top-level COPYING for licensing info.

#$Id: obj-02sale.t 1167 2010-10-05 00:24:04Z jason $

#L'ane obj test
# - sale objects

use Test::More tests => 160;

BEGIN {
    use FindBin;
    use File::Spec;
    $ENV{'LaneRoot'} = File::Spec->catdir($FindBin::Bin, File::Spec->updir); #use the correct number of updirs
    require File::Spec->catfile($ENV{'LaneRoot'}, 'config', 'init.pl');
}

BEGIN {
    use_ok('LanePOS::Sale');
    use_ok('LanePOS::Customer');
}

use Data::Dumper; #for debugging

my $s = Sale->new();
isa_ok($s, 'Sale');

#sale triggers modify customer, so make sure they work
my $c = Customer->new();

#these are the only public methods
can_ok($s, qw/
new
save
isPaid
isSuspended
isExempt
isVoid
applyToBalance
updateTotals
getNotPaidByCust
getSuspended
getByCust
getByCustAndRange
getAllCustsByRange
openReportStyle
void
rev
openRev
/);

diag('this doesn\'t test the get*() or openReportStyle() subs');

#create a new sale
#$s->{'id'} = '';
$s->{'customer'} = '1234';
$s->{'taxMask'} = '3';
#$s->{'tranzDate'} = '';
$s->{'suspended'} = 0;
$s->{'clerk'} = '100';
$s->{'terminal'} = 'localhost';
$s->{'notes'} = 'my';
#try the filtered c0 and c1 characters in notes (bug 1349)
$s->{'notes'} .= chr($_) foreach (0..0x1f,0x7f..0x9f);
$s->{'notes'} .= 'notes';
like($s->{'notes'}, qr/[[:cntrl:]]/, 'the notes contain c0 and c1 characters before save');
$s->{'items'} = [
    {
        'plu' => '1',
        'qty' => '1',
        'amt' => '6000',
        'struck' => 0,
    },
    {
        'plu' => '2',
        'qty' => '2',
        'amt', '4000',
        'struck' => 0,
    }
    ];
$s->{'tenders'} = [
    {
        'tender' => '0',
        'amt' => '10000',
        'ext' => {
            'stuff' => 'a',
            'things' => 'b',
        },
    },
    {
        'tender' => '0',
        'amt', '405',
        'ext' => {
            'misc' => '2',
            'zipcode' => '90210',
        },
    }
    ];
$s->{'total'} = '10405';
$s->{'balance'} = '0';
$s->{'due'} = '0';
$s->{'subt'} = '10000';
$s->{'taxes'} = [{'taxable' => '6000'}, {'taxable' => '6000'}];
#$s->{'change'} = '';
$s->{'allTaxes'} = '405';

#warn Dumper($s);
#$s->{'dal'}->trace(STDERR);
ok($s->save(), 'save the new sale');
my $saved = $s->{'id'}; #keep the saved sale number

ok($c->open('1234'), 'opened the customer');
is($c->{'lastSale'}, $s->{'lc'}->nowFmt('shortDate'), 'the Customer.lastSale is today');

#create a new sale
ok($s = Sale->new(), 'new sale');
#$s->{'id'} = '';
$s->{'customer'} = '1234';
$s->{'taxMask'} = '3';
#$s->{'tranzDate'} = '';
$s->{'suspended'} = 0;
$s->{'clerk'} = '100';
$s->{'server'} = '20';
$s->{'terminal'} = 'localhost';
$s->{'notes'} = "my\nnotes";
$s->{'items'} = [{'plu', '1', 'qty', '1', 'amt', '6000', 'struck', 0}, {'plu', '2', 'qty', '2', 'amt', '4000', 'struck', 0}];
$s->{'tenders'} = [{'tender', '0', 'amt', '10000'}, {'tender', '0', 'amt', '405'}];
$s->{'total'} = '10405';
$s->{'balance'} = '0';
$s->{'due'} = '0';
$s->{'subt'} = '10000';
$s->{'taxes'} = [{'taxable' => '6000'}, {'taxable' => '6000'}];
#$s->{'change'} = '';
$s->{'allTaxes'} = '405';

#warn Dumper($s);
#$s->{'dal'}->trace(STDERR);
ok($s->save(), 'save the new sale');
my $savedServer = $s->{'id'}; #keep the saved sale number

ok($s = Sale->new(), 'new sale');
ok($s->open(1), 'open an existing sale');
is($s->{'id'}, '1', "    'id' matches");
is($s->{'customer'}, '', "    'customer' matches");
cmp_ok($s->{'taxMask'}, '==', '0', "    'taxMask' matches");
#not the best idea
like($s->{'tranzDate'}, qr/^\d{4}-\d{2}-\d{2}/, "    'tranzDate' looks ok-ish");
is($s->{'clerk'}, '100', "    'clerk' matches");
is($s->{'server'}, '100', "    'server' matches");
is($s->{'terminal'}, 'localhost', "    'terminal' matches");
is($s->{'notes'}, 'note', "    'mynotes' matches");
cmp_ok($s->{'total'}, '==', '3000', "    'total' matches");
cmp_ok($s->{'balance'}, '==', '0', "    'balance' matches");
cmp_ok($s->{'due'}, '==', '0', "    'due' matches");
cmp_ok($s->{'subt'}, '==', '3000', "    'subt' matches");
cmp_ok($s->{'allTaxes'}, '==', '0', "    'allTaxes' matches");
#cmp_ok($s->{'change'}, '==', '0', "    'change' matches");
is($s->{'items'}[0]{'plu'}, '1', "    item 0 'plu' matches");
cmp_ok($s->{'items'}[0]{'qty'}, '==', '3', "    item 0 'qty' matches");
cmp_ok($s->{'items'}[0]{'amt'}, '==', '1500', "    item 0 'amt' matches");
ok(!$s->{'items'}[0]{'struck'}, "    item 'struck' matches");
is($s->{'items'}[1]{'plu'}, '1', "    item 1 'plu' matches");
cmp_ok($s->{'items'}[1]{'qty'}, '==', '2', "    item 1 'qty' matches");
cmp_ok($s->{'items'}[1]{'amt'}, '==', '1000', "    item 1 'amt' matches");
ok(!$s->{'items'}[0]{'struck'}, "    item 'struck' matches");
is($s->{'items'}[2]{'plu'}, '1', "    item 2 'plu' matches");
cmp_ok($s->{'items'}[2]{'qty'}, '==', '1', "    item 2 'qty' matches");
cmp_ok($s->{'items'}[2]{'amt'}, '==', '500', "    item 2 'amt' matches");
ok(!$s->{'items'}[2]{'struck'}, "    item 'struck' matches");
cmp_ok($s->{'tenders'}[0]{'tender'}, '==', '0', "    tender 0 'tender' matches");
cmp_ok($s->{'tenders'}[0]{'amt'}, '==', '1000', "    tender 0 'amt' matches");
cmp_ok($s->{'tenders'}[1]{'tender'}, '==', '1', "    tender 1 'tender' matches");
cmp_ok($s->{'tenders'}[1]{'amt'}, '==', '2000', "    tender 1 'amt' matches");
cmp_ok($s->{'taxes'}[0]{'taxId'}, '==', '1', "    tax 0 'taxId' matches");
cmp_ok($s->{'taxes'}[0]{'taxable'}, '==', '3000', "    tax 0 'taxable' matches");
cmp_ok($s->{'taxes'}[0]{'rate'}, '==', '6.25', "    tax 0 'rate' matches");
cmp_ok($s->{'taxes'}[0]{'tax'}, '==', '188', "    tax 0 'tax' matches");
cmp_ok($s->{'taxes'}[1]{'taxId'}, '==', '2', "    tax 1 'taxId' matches");
cmp_ok($s->{'taxes'}[1]{'taxable'}, '==', '3000', "    tax 1 'taxable' matches");
cmp_ok($s->{'taxes'}[1]{'rate'}, '==', '0.50', "    tax 1 'rate' matches");
cmp_ok($s->{'taxes'}[1]{'tax'}, '==', '15', "    tax 1 'tax' matches");
ok($s->isPaid, "    isPaid() works for true cases");
ok(!$s->isSuspended, "    isSuspended() works for false cases");
ok($s->isExempt, "    isExempt() works for true cases");
ok(!$s->isVoid, "    isVoid() works for false cases");
#kludgy
$s->{'balance'} = 1234;
$s->{'suspended'} = 1;
$s->{'taxMask'} = 0;
$s->{'voidAt'} = '1776-07-04 00:00';
ok(!$s->isPaid, "    isPaid() works for false cases");
ok($s->isSuspended, "    isSuspended() works for true cases");
ok($s->isExempt, "    isExempt() works for true cases");
ok($s->isVoid, "    isVoid() works for true cases");

ok($s->open($saved), 'open the saved sale');
cmp_ok($s->{'id'}, '==', $saved, "    'id' matches");
is($s->{'customer'}, '1234', "    'customer' matches");
cmp_ok($s->{'taxMask'}, '==', '3', "    'taxMask' matches");
#not the best idea
like($s->{'tranzDate'}, qr/^\d{4}-\d{2}-\d{2}/, "    'tranzDate' looks ok-ish");
is($s->{'clerk'}, '100', "    'clerk' matches");
is($s->{'server'}, '100', "    'server' matches");
is($s->{'terminal'}, 'localhost', "    'terminal' matches");
is($s->{'notes'}, "my\nnotes", "    'notes' matches");
cmp_ok($s->{'total'}, '==', '10405', "    'total' matches");
cmp_ok($s->{'balance'}, '==', '0', "    'balance' matches");
cmp_ok($s->{'due'}, '==', '0', "    'due' matches");
cmp_ok($s->{'subt'}, '==', '10000', "    'subt' matches");
cmp_ok($s->{'allTaxes'}, '==', '405', "    'allTaxes' matches");
#cmp_ok($s->{'change'}, '==', '0', "    'change' matches");
is($s->{'items'}[0]{'plu'}, '1', "    item 0 'plu' matches");
cmp_ok($s->{'items'}[0]{'qty'}, '==', '1', "    item 0 'qty' matches");
cmp_ok($s->{'items'}[0]{'amt'}, '==', '6000', "    item 0 'amt' matches");
ok(!$s->{'items'}[0]{'struck'}, "    item 'struck' matches");
is($s->{'items'}[1]{'plu'}, '2', "    item 1 'plu' matches");
cmp_ok($s->{'items'}[1]{'qty'}, '==', '2', "    item 1 'qty' matches");
cmp_ok($s->{'items'}[1]{'amt'}, '==', '4000', "    item 1 'amt' matches");
ok(!$s->{'items'}[1]{'struck'}, "    item 'struck' matches");
cmp_ok($s->{'tenders'}[0]{'tender'}, '==', '0', "    tender 0 'tender' matches");
cmp_ok($s->{'tenders'}[0]{'amt'}, '==', '10000', "    tender 0 'amt' matches");
is_deeply($s->{'tenders'}[0]{'ext'}, {'stuff' => 'a', 'things' => 'b'}, "    tender 0 'ext' matches ;");
cmp_ok($s->{'tenders'}[1]{'tender'}, '==', '0', "    tender 1 'tender' matches");
cmp_ok($s->{'tenders'}[1]{'amt'}, '==', '405', "    tender 1 'amt' matches");
is_deeply($s->{'tenders'}[1]{'ext'}, {'misc' => '2', 'zipcode' => '90210'}, "    tender 1 'ext' matches ;");
cmp_ok($s->{'taxes'}[0]{'taxId'}, '==', '1', "    tax 0 'taxId' matches");
cmp_ok($s->{'taxes'}[0]{'taxable'}, '==', '6000', "    tax 0 'taxable' matches");
cmp_ok($s->{'taxes'}[0]{'rate'}, '==', '6.25', "    tax 0 'rate' matches");
cmp_ok($s->{'taxes'}[0]{'tax'}, '==', '375', "    tax 0 'tax' matches");
cmp_ok($s->{'taxes'}[1]{'taxId'}, '==', '2', "    tax 1 'taxId' matches");
cmp_ok($s->{'taxes'}[1]{'taxable'}, '==', '6000', "    tax 1 'taxable' matches");
cmp_ok($s->{'taxes'}[1]{'rate'}, '==', '0.50', "    tax 1 'rate' matches");
cmp_ok($s->{'taxes'}[1]{'tax'}, '==', '30', "    tax 1 'tax' matches");
ok($s->isPaid, "    isPaid() works");
ok(!$s->isSuspended, "    isSuspended() works");
ok(!$s->isExempt, "    isExempt() works");
ok(!$s->isVoid, "    isVoid() works");

#try to void the record
ok($s->void, "    void() works");
ok($s->open($saved), 'reopen the saved sale (VOID CHECK)');
cmp_ok($s->{'id'}, '==', $saved, "    'id' matches (VOID CHECK)");
ok($s->isVoid, "    isVoid() works");

#check a sale with separate clerk and server values
ok($s->open($savedServer), 'open the saved server-different sale');
cmp_ok($s->{'id'}, '==', $savedServer, "    'id' matches");
is($s->{'customer'}, '1234', "    'customer' matches");
cmp_ok($s->{'taxMask'}, '==', '3', "    'taxMask' matches");
#not the best idea
like($s->{'tranzDate'}, qr/^\d{4}-\d{2}-\d{2}/, "    'tranzDate' looks ok-ish");
is($s->{'clerk'}, '100', "    'clerk' matches");
is($s->{'server'}, '20', "    'server' matches");
is($s->{'terminal'}, 'localhost', "    'terminal' matches");
is($s->{'notes'}, "my\nnotes", "    'notes' matches");
cmp_ok($s->{'total'}, '==', '10405', "    'total' matches");
cmp_ok($s->{'balance'}, '==', '0', "    'balance' matches");
cmp_ok($s->{'due'}, '==', '0', "    'due' matches");
cmp_ok($s->{'subt'}, '==', '10000', "    'subt' matches");
cmp_ok($s->{'allTaxes'}, '==', '405', "    'allTaxes' matches");
#cmp_ok($s->{'change'}, '==', '0', "    'change' matches");
is($s->{'items'}[0]{'plu'}, '1', "    item 0 'plu' matches");
cmp_ok($s->{'items'}[0]{'qty'}, '==', '1', "    item 0 'qty' matches");
cmp_ok($s->{'items'}[0]{'amt'}, '==', '6000', "    item 0 'amt' matches");
ok(!$s->{'items'}[0]{'struck'}, "    item 'struck' matches");
is($s->{'items'}[1]{'plu'}, '2', "    item 1 'plu' matches");
cmp_ok($s->{'items'}[1]{'qty'}, '==', '2', "    item 1 'qty' matches");
cmp_ok($s->{'items'}[1]{'amt'}, '==', '4000', "    item 1 'amt' matches");
ok(!$s->{'items'}[1]{'struck'}, "    item 'struck' matches");
cmp_ok($s->{'tenders'}[0]{'tender'}, '==', '0', "    tender 0 'tender' matches");
cmp_ok($s->{'tenders'}[0]{'amt'}, '==', '10000', "    tender 0 'amt' matches");
cmp_ok($s->{'tenders'}[1]{'tender'}, '==', '0', "    tender 1 'tender' matches");
cmp_ok($s->{'tenders'}[1]{'amt'}, '==', '405', "    tender 1 'amt' matches");
cmp_ok($s->{'taxes'}[0]{'taxId'}, '==', '1', "    tax 0 'taxId' matches");
cmp_ok($s->{'taxes'}[0]{'taxable'}, '==', '6000', "    tax 0 'taxable' matches");
cmp_ok($s->{'taxes'}[0]{'rate'}, '==', '6.25', "    tax 0 'rate' matches");
cmp_ok($s->{'taxes'}[0]{'tax'}, '==', '375', "    tax 0 'tax' matches");
cmp_ok($s->{'taxes'}[1]{'taxId'}, '==', '2', "    tax 1 'taxId' matches");
cmp_ok($s->{'taxes'}[1]{'taxable'}, '==', '6000', "    tax 1 'taxable' matches");
cmp_ok($s->{'taxes'}[1]{'rate'}, '==', '0.50', "    tax 1 'rate' matches");
cmp_ok($s->{'taxes'}[1]{'tax'}, '==', '30', "    tax 1 'tax' matches");
ok($s->isPaid, "    isPaid() works");
ok(!$s->isSuspended, "    isSuspended() works");
ok(!$s->isExempt, "    isExempt() works");
ok(!$s->isVoid, "    isVoid() works");
#try to void the record
ok($s->void, "    void() works");
ok($s->open($saved), 'reopen the saved sale (VOID CHECK)');
cmp_ok($s->{'id'}, '==', $saved, "    'id' matches (VOID CHECK)");
ok($s->isVoid, "    isVoid() works");
#check the triggers
ok($c->open('1234'), 'opened the customer');
ok(!defined $c->{'lastSale'}, 'the Customer.lastSale is empty');
#rev
my $user = $s->{'dal'}->getUsername;
ok($user, 'getUsername');

my @rev = $s->rev($saved);
my @revExp = (8, 7, 5);
is_deeply(\@rev, \@revExp, 'rev() returned the expected data');
my $revS = Sale->new();
ok($s->open($saved), 'opened the current version');
#$revS->{'dal'}->trace(STDERR);
foreach my $r (@revExp)
{
    ok($revS->openRev($saved, $r), "openRev($saved, $r) succeded");
    #remove all of the /r/s and anything else we can't compare
    foreach my $obj ($revS, @{$revS->{'items'}}, @{$revS->{'taxes'}}, @{$revS->{'tenders'}}, $s)
    {
        delete $obj->{'r'} if exists $obj->{'r'};
        delete $obj->{'modified'} if exists $obj->{'modified'};
    }
    if($r != $revExp[0])
    {
        ok(!defined $revS->{'voidAt'}, 'voidAt is as expected');
        ok(!defined $revS->{'voidBy'}, 'voidBy is as expected');
        $revS->{'voidAt'} = $s->{'voidAt'};
        $revS->{'voidBy'} = $s->{'voidBy'};
    }
    else
    {
        is($revS->{'voidAt'}, $s->{'voidAt'}, 'voidAt is as expected');
        is($revS->{'voidBy'}, $s->{'voidBy'}, 'voidBy is as expected');
    }
    is_deeply($revS, $s, "r$r matches the current (except as noted)");
}
