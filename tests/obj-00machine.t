#!/usr/bin/perl -w

#obj-00machine.t
#Copyright 2004-2010 Jason Burrell.
#This file is part of L'anePOS. See the top-level COPYING for licensing info.

#$Id: obj-00machine.t 1196 2010-10-24 18:02:54Z jason $

#L'ane obj test
# - machine objects

use Test::More tests => 60;
#use Test::More 'no_plan';

use Data::Dumper;

BEGIN {
    use FindBin;
    use File::Spec;
    $ENV{'LaneRoot'} = File::Spec->catdir($FindBin::Bin, File::Spec->updir); #use the correct number of updirs
    require File::Spec->catfile($ENV{'LaneRoot'}, 'config', 'init.pl');
}

BEGIN { use_ok('LanePOS::Machine'); }

my $mach = Machine->new();
isa_ok($mach, 'Machine');

my $user = $mach->{'dal'}->getUsername;
ok($user, 'got your db username');

#these are the only public methods
can_ok($mach, qw/
new
open
save
getAllOwned
isOnContract
findLike
getAllOnContract
void
isVoid
/);

$mach->{'make'} = 'Ryotous';
$mach->{'model'} = 'HardTester';
$mach->{'sn'} = '8675309';
$mach->{'counter'} = '98765';
$mach->{'accessories'} = 'batteries';
$mach->{'owner'} = '2173424900';
$mach->{'location'} = 'Effingham';
#$mach->{'purchased'} = '';
#$mach->{'lastService'} = '';
$mach->{'notes'} = 'my notes';
$mach->{'onContract'} = 0;

ok($mach->save(), 'save a new machine');

ok($mach->open('IBM', 'PCjr', '12345'), 'open the sample machine');
is($mach->{'make'}, 'IBM', '    \'make\' matches');
is($mach->{'model'}, 'PCjr', '    \'model\' matches');
is($mach->{'sn'}, '12345', '    \'sn\' matches');
cmp_ok($mach->{'counter'}, '==', '0', '    \'counter\' matches');
is($mach->{'accessories'}, 'none', '    \'accessories\' matches');
is($mach->{'owner'}, '', '    \'owner\' matches');
is($mach->{'location'}, 'here', '    \'location\' matches');
is($mach->{'purchased'}, '01-01-2003', '    \'purchased\' matches');
is($mach->{'lastService'}, '12-31-2003', '    \'lastService\' matches');
is($mach->{'notes'}, 'note me', '    \'notes\' matches');
#is($mach->{'onContract'}, '', '    \'onContract\' matches');
is($mach->{'contractBegins'}, '02-20-2001', '    \'contractBegins\' matches');
is($mach->{'contractEnds'}, '02-12-2005', '    \'contractEnds\' matches');
is($mach->{'createdBy'}, 'installer+jason@localhost', '    \'createdBy\' matches');
is($mach->{'created'}, '2004-01-02 19:04:00-06', '    \'created\' matches');
ok($mach->isOnContract(), '    isOnContract succeeds');

ok($mach = Machine->new, 'create a new machine');
$mach->{'make'} = 'Ryotous';
$mach->{'model'} = 'OtherTester';
$mach->{'sn'} = '12345';
$mach->{'counter'} = '98765';
$mach->{'accessories'} = 'batteries';
$mach->{'owner'} = '2173424900';
$mach->{'location'} = 'Effingham';
#$mach->{'purchased'} = '';
#$mach->{'lastService'} = '';
$mach->{'notes'} = 'my notes';
$mach->{'onContract'} = 1;
$mach->{'contractBegins'} = '01-01-2009';
$mach->{'contractEnds'} = '12-31-2009';

ok($mach->save(), 'save a new machine');
my @date;
my @mod;

ok($mach->open('Ryotous', 'HardTester', '8675309'), 'open the saved machine');
is($mach->{'make'}, 'Ryotous', '    \'make\' matches');
is($mach->{'model'}, 'HardTester', '    \'model\' matches');
is($mach->{'sn'}, '8675309', '    \'sn\' matches');
cmp_ok($mach->{'counter'}, '==', '98765', '    \'counter\' matches');
is($mach->{'accessories'}, 'batteries', '    \'accessories\' matches');
is($mach->{'owner'}, '2173424900', '    \'owner\' matches');
is($mach->{'location'}, 'Effingham', '    \'location\' matches');
is($mach->{'purchased'}, undef, '    \'purchased\' matches');
is($mach->{'lastService'}, undef, '    \'lastService\' matches');
is($mach->{'notes'}, 'my notes', '    \'notes\' matches');
#is($mach->{'onContract'}, '', '    \'onContract\' matches');
is($mach->{'contractBegins'}, undef, '    \'contractBegins\' matches');
is($mach->{'contractEnds'}, undef, '    \'contractEnds\' matches');
is($mach->{'createdBy'}, $user, '    \'createdBy\' matches');
#is($mach->{'created'}, '2004-01-02 19:04:00-06', '    \'created\' matches');
$date[0] = $mach->{'created'} || 'FAIL';
$mod[0] = $mach->{'modified'} || 'FAIL';
ok($mach->{'created'}, '    \'created\' seems good');
ok(!$mach->isOnContract(), '    isOnContract succeeds');

#needed below
ok($mach->open('Ryotous', 'OtherTester', '12345'), 'open the other saved machine');
$date[1] = $mach->{'created'} || 'FAIL';
$mod[1] = $mach->{'modified'} || 'FAIL';

my @machs = $mach->getAllOwned('2173424900');
my @expected = (
    {
        'make' => 'Ryotous',
        'model' => 'HardTester',
        'sn' => '8675309',
        'contractBegins' => undef,
        'owner' => '2173424900',
        'createdBy' => $user,
        'created' => $date[0],
        'location' => 'Effingham',
        'accessories' => 'batteries',
        'lastService' => undef,
        'notes' => 'my notes',
        'contractEnds' => undef,
        'onContract' => 0,
        'counter' => 98765,
        'purchased' => undef,
        'voidAt' => undef,
        'voidBy' => undef,
        'modifiedBy' => $user,
        'modified' => $mod[0],
    },
    {
        'make' => 'Ryotous',
        'model' => 'OtherTester',
        'sn' => '12345',
        'contractBegins' => '2009-01-01',
        'owner' => '2173424900',
        'createdBy' => $user,
        'location' => 'Effingham',
        'accessories' => 'batteries',
        'lastService' => undef,
        'created' => $date[1],
        'notes' => 'my notes',
        'contractEnds' => '2009-12-31',
        'onContract' => 1,
        'counter' => 98765,
        'purchased' => undef,
        'voidAt' => undef,
        'voidBy' => undef,
        'modifiedBy' => $user,
        'modified' => $mod[1],
    },
#    { 'make' => 'Ryotous', 'model' => 'HardTester', 'sn' => '8675309'},
#    { 'make' => 'Ryotous', 'model' => 'OtherTester', 'sn' => '12345'},
    );
#diag(Dumper(\@machs));
cmp_ok($#machs, '==', $#expected, 'getAllOwned by \'2173424900\'');
is_deeply(\@machs, \@expected, 'getAllOwned by \'2173424900\' returned the expected data');

@machs = $mach->findLike('ibm', '', '');
is($machs[0]{'sn'}, '12345', 'findLike with Make works');

@machs = $mach->findLike('', 'pcJR', '');
is($machs[0]{'sn'}, '12345', 'findLike with model works');

@machs = $mach->findLike('', '', '12345');
#diag(Dumper(\@machs));
is($machs[0]{'make'}, 'IBM', 'findLike with sn works');

@machs = $mach->getAllOnContract();
@expected = (
    {
        'make' => 'IBM',
        'model' => 'PCjr',
        'sn' => '12345',
    },
    {
        'make' => 'Sun',
        'model' => 'Ray 2',
        'sn' => '6789',
    },
    {
        'make' => 'Ryotous',
        'model' => 'OtherTester',
        'sn' => '12345',
    },
);
#diag(Dumper(\@machs));
is_deeply(\@machs, \@expected, 'getAllOnContract() returned the expected data');

ok(($mach->open('Ryotous', 'HardTester', '8675309') and $mach->void), 'voiding the record');
ok(($mach->open('Ryotous', 'HardTester', '8675309') and $mach->isVoid), 'the record was REALLY void');

ok(($mach->open('Ryotous', 'OtherTester', '12345') and $mach->void), 'voiding the record');
ok(($mach->open('Ryotous', 'OtherTester', '12345') and $mach->isVoid), 'the record was REALLY void');

#rev
my @rev = $mach->rev('Ryotous', 'HardTester', '8675309');
my @expR = (5, 3);
is_deeply(\@rev, \@expR, 'rev() returned the expected data');
my $revM = Machine->new($mach->{'dal'});
ok($mach->open('Ryotous', 'HardTester', '8675309'), 'opened the current version');
#$revM->{'dal'}->trace(STDERR);
foreach my $r (@expR)
{
    ok($revM->openRev('Ryotous', 'HardTester', '8675309', $r), "openRev(..., $r) succeded");
    #remove all of the /r/s and anything else we can't compare
    foreach my $obj ($revM, $mach)
    {
        delete $obj->{'r'} if exists $obj->{'r'};
        delete $obj->{'modified'} if exists $obj->{'modified'};
        delete $obj->{'lc'};
    }
    if($r != $expR[0])
    {
        ok(!defined $revM->{'voidAt'}, 'voidAt is as expected');
        ok(!defined $revM->{'voidBy'}, 'voidBy is as expected');
        $revM->{'voidAt'} = $mach->{'voidAt'};
        $revM->{'voidBy'} = $mach->{'voidBy'};
    }
    else
    {
        is($revM->{'voidAt'}, $mach->{'voidAt'}, 'voidAt is as expected');
        is($revM->{'voidBy'}, $mach->{'voidBy'}, 'voidBy is as expected');
    }
    is_deeply($revM, $mach, "r$r matches the current (except as noted)");
}
1;
