#!/usr/bin/perl -w

#obj-00tender.t
#Copyright 2004-2010 Jason Burrell.
#This file is part of L'anePOS. See the top-level COPYING for licensing info.

#$Id: obj-00tender.t 1165 2010-09-29 01:22:39Z jason $

#L'ane obj test
# - tender objects

use Test::More tests => 87;

BEGIN {
    use FindBin;
    use File::Spec;
    $ENV{'LaneRoot'} = File::Spec->catdir($FindBin::Bin, File::Spec->updir); #use the correct number of updirs
    require File::Spec->catfile($ENV{'LaneRoot'}, 'config', 'init.pl');
}

BEGIN { use_ok('LanePOS::Tender'); }

my $expectedTenders = [
    {
        'requireItems' => 'a',
        'allowZero' => 1,
        'eauth' => 0,
        'mandatoryAmt' => 0,
        'descr' => 'Cash',
        'allowPos' => 1,
        'openDrawer' => 1,
        'eprocess' => 0,
        'id' => '0',
        'allowChange' => 1,
        'allowNeg' => 1,
        'pays' => 1,
        'voidAt' => undef,
        'voidBy' => undef,
        'created' => '2010-08-29 00:00:00-05',
        'createdBy' => 'installer@localhost',
        'modified' => '2010-08-29 00:00:00-05',
        'modifiedBy' => 'installer@localhost',
    },
    {
        'requireItems' => 'a',
        'allowZero' => 1,
        'eauth' => 0,
        'mandatoryAmt' => 0,
        'descr' => 'Check',
        'allowPos' => 1,
        'openDrawer' => 1,
        'eprocess' => 0,
        'id' => '1',
        'allowChange' => 0,
        'allowNeg' => 1,
        'pays' => 1,
        'voidAt' => undef,
        'voidBy' => undef,
        'created' => '2010-08-29 00:00:00-05',
        'createdBy' => 'installer@localhost',
        'modified' => '2010-08-29 00:00:00-05',
        'modifiedBy' => 'installer@localhost',
    },
    {
        'requireItems' => 'r',
        'allowZero' => 0,
        'eauth' => 0,
        'mandatoryAmt' => 0,
        'descr' => 'Testing',
        'allowPos' => 1,
        'openDrawer' => 1,
        'eprocess' => 0,
        'id' => '2',
        'allowChange' => 1,
        'allowNeg' => 1,
        'pays' => 1,
        'voidAt' => undef,
        'voidBy' => undef,
        'created' => '2010-08-29 00:00:00-05',
        'createdBy' => 'installer@localhost',
        'modified' => '2010-08-29 00:00:00-05',
        'modifiedBy' => 'installer@localhost',
    },
    {
        'requireItems' => 'd',
        'allowZero' => 1,
        'eauth' => 0,
        'mandatoryAmt' => 0,
        'descr' => 'Testing',
        'allowPos' => 1,
        'openDrawer' => 1,
        'eprocess' => 0,
        'id' => '3',
        'allowChange' => 1,
        'allowNeg' => 0,
        'pays' => 1,
        'voidAt' => undef,
        'voidBy' => undef,
        'created' => '2010-08-29 00:00:00-05',
        'createdBy' => 'installer@localhost',
        'modified' => '2010-08-29 00:00:00-05',
        'modifiedBy' => 'installer@localhost',
    },
    {
        'requireItems' => 'r',
        'allowZero' => 1,
        'eauth' => 0,
        'mandatoryAmt' => 0,
        'descr' => 'Testing',
        'allowPos' => 0,
        'openDrawer' => 1,
        'eprocess' => 0,
        'id' => '4',
        'allowChange' => 1,
        'allowNeg' => 1,
        'pays' => 1,
        'voidAt' => undef,
        'voidBy' => undef,
        'created' => '2010-08-29 00:00:00-05',
        'createdBy' => 'installer@localhost',
        'modified' => '2010-08-29 00:00:00-05',
        'modifiedBy' => 'installer@localhost',
    },
    {
        'requireItems' => 'a',
        'allowZero' => 1,
        'eauth' => 0,
        'mandatoryAmt' => 0,
        'descr' => 'House',
        'allowPos' => 1,
        'openDrawer' => 1,
        'eprocess' => 0,
        'id' => '100',
        'allowChange' => 1,
        'allowNeg' => 1,
        'pays' => 0,
        'voidAt' => undef,
        'voidBy' => undef,
        'created' => '2010-08-29 00:00:00-05',
        'createdBy' => 'installer@localhost',
        'modified' => '2010-08-29 00:00:00-05',
        'modifiedBy' => 'installer@localhost',
    },
    ];

my $t = Tender->new();
isa_ok($t, 'Tender');

my $laneusername = $t->{'dal'}->getUsername();
ok($laneusername, 'Dal->getUsername() is non-null');

#these are the only public methods
can_ok($t, qw/new open save void isVoid allowChange mandatoryAmt openDrawer pays eprocess eauth allowZero allowNeg allowPos getAllTenders openRev rev/);

$t->{'id'} = '10';
$t->{'descr'} = 'Test Tend';
$t->{'allowChange'} = 0;
$t->{'mandatoryAmt'} = 1;
$t->{'openDrawer'} = 0;
$t->{'pays'} = 0;
$t->{'eprocess'} = 1;
$t->{'eauth'} = 1;
$t->{'allowZero'} = 0;
$t->{'allowNeg'} = 0;
$t->{'allowPos'} = 0;
$t->{'requireItems'} = 'd';

ok($t->save(), 'save a new tender');

ok($t->open('0'), 'open the sample tender');
is($t->{'id'}, '0', '    \'id\' matches');
is($t->{'descr'}, 'Cash', '    \'descr\' matches');
ok($t->allowChange(), '    allowChange() works for true cases');
ok(!$t->mandatoryAmt(), '    mandatoryAmt() works for false cases');
ok($t->openDrawer(), '    openDrawer() works for true cases');
ok($t->pays(), '    pays() works for true cases');
ok(!$t->eprocess(), '    eprocess() works for false cases');
ok(!$t->eauth(), '    eauth() works for false cases');
ok($t->allowZero(), '    allowZero() works for true cases');
ok($t->allowNeg(), '    allowNeg() works for true cases');
ok($t->allowPos(), '    allowPos() works for true cases');
is($t->{'requireItems'}, 'a', '    \'requireItems\' matches');

ok($t->open(10), 'open the sample tender');
is($t->{'id'}, '10', '    \'id\' matches');
is($t->{'descr'}, 'Test Tend', '    \'descr\' matches');
ok(!$t->allowChange(), '    allowChange() works for false cases');
ok($t->mandatoryAmt(), '    mandatoryAmt() works for true cases');
ok(!$t->openDrawer(), '    openDrawer() works for false cases');
ok(!$t->pays(), '    pays() works for false cases');
ok($t->eprocess(), '    eprocess() works for true cases');
ok($t->eauth(), '    eauth() works for true cases');
ok(!$t->allowZero(), '    allowZero() works for false cases');
ok(!$t->allowNeg(), '    allowNeg() works for false cases');
ok(!$t->allowPos(), '    allowPos() works for false cases');
is($t->{'requireItems'}, 'd', '    \'requireItems\' matches');

ok($t->open(2), 'open the sample tender 2');
is($t->{'id'}, '2', '    \'id\' matches');
ok(!$t->allowZero(), '    allowZero() works');
ok($t->allowNeg(), '    allowNeg() works');
ok($t->allowPos(), '    allowPos() works');
is($t->{'requireItems'}, 'r', '    \'requireItems\' matches');
ok($t->open(3), 'open the sample tender 3');
is($t->{'id'}, '3', '    \'id\' matches');
ok($t->allowZero(), '    allowZero() works');
ok(!$t->allowNeg(), '    allowNeg() works');
ok($t->allowPos(), '    allowPos() works');
is($t->{'requireItems'}, 'd', '    \'requireItems\' matches');
ok($t->open(4), 'open the sample tender 4');
is($t->{'id'}, '4', '    \'id\' matches');
ok($t->allowZero(), '    allowZero() works');
ok($t->allowNeg(), '    allowNeg() works');
ok(!$t->allowPos(), '    allowPos() works');
is($t->{'requireItems'}, 'r', '    \'requireItems\' matches');

ok(($t->open(10) and $t->void), 'voiding the record');
ok(($t->open(10) and $t->isVoid), 'the record was REALLY voided');

my @tenders = $t->getAllTenders();
cmp_ok($#tenders, '==', $#{$expectedTenders}, 'getAllTenders() returned the expected number of elements');
is_deeply(\@tenders, $expectedTenders, 'getAllTenders() returned the expected data');

my $tid = 10;
my @rev = $t->rev($tid);
my @expected_rev = (8, 7);
my %expected_data = (
    #list the various parts you want to check
    8 => {
        'id' => $tid,
        'descr' => 'Test Tend',
        'allowChange' => 0,
        'mandatoryAmt' => 1,
        'openDrawer' => 0,
        'pays' => 0,
        'eprocess' => 1,
        'eauth' => 1,
        'allowZero' => 0,
        'allowNeg' => 0,
        'allowPos' => 0,
        'requireItems' => 'd',
        #'voidAt' => '',
        'voidBy' => $laneusername,
        #'created' => '',
        'createdBy' => $laneusername,
        #'modified' => '',
        'modifiedBy' => $laneusername,
    },
    7 => {
        'id' => $tid,
        'descr' => 'Test Tend',
        'allowChange' => 0,
        'mandatoryAmt' => 1,
        'openDrawer' => 0,
        'pays' => 0,
        'eprocess' => 1,
        'eauth' => 1,
        'allowZero' => 0,
        'allowNeg' => 0,
        'allowPos' => 0,
        'requireItems' => 'd',
        'voidAt' => undef,
        'voidBy' => undef,
        #'created' => '',
        'createdBy' => $laneusername,
        #'modified' => '',
        'modifiedBy' => $laneusername,
    },
);
is_deeply(\@rev, \@expected_rev, 'returned the expected revisions in the correct order');
foreach my $i (@expected_rev)
{
    ok($t->openRev($tid, $i), 'opening expected rev ' . $i);
    foreach my $key (keys %{$expected_data{$i}})
    {
        is($t->{$key}, $expected_data{$i}->{$key}, "    $key was as expected");
    }
}

1;


