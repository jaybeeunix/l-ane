#!/usr/bin/perl -w

#obj-01timeclock.t
#Copyright 2006-2010 Jason Burrell.
#This file is part of L'anePOS. See the top-level COPYING for licensing info.

#$Id: obj-01timeclock.t 1127 2010-09-18 04:26:34Z jason $

#L'ane obj test
# - timeclock

use Test::More tests => 105;

BEGIN {
    use FindBin;
    use File::Spec;
    $ENV{'LaneRoot'} = File::Spec->catdir($FindBin::Bin, File::Spec->updir); #use the correct number of updirs
    require File::Spec->catfile($ENV{'LaneRoot'}, 'config', 'init.pl');
}

BEGIN { use_ok('LanePOS::Timeclock'); }

my $tc = Timeclock->new();
isa_ok($tc, 'Timeclock');

#diag('general object methods');
can_ok($tc, qw/
new
isClockedIn
getClerksInSpan
getVoidClerksInSpan
getVoidPunchesInSpan
forcePunch
voidPunch
open
getHoursInSpan
getPunchesInSpan
getClerksClockedIn
punch
getBoundsForDate
unvoidPunch
getAllClerksInSpan
getAllPunchesInSpan
getAllPossibleClerks
getAllClerksInSpanOrderedByClockedIn
rev
openRev
/);

my @p;

#all
ok(@p = $tc->getBoundsForDate('2007-01-01'), 'getBoundsForDate()');
cmp_ok($#p, '==', '1', '    returns the correct number of elements');
cmp_ok($p[0], 'eq', '2007-01-01 00:00:00-06', '    returns the correct start');
cmp_ok($p[1], 'eq', '2007-01-02 00:00:00-06', '    returns the correct end');

ok(@p = $tc->getAllPossibleClerks(), 'getAllPossibleClerks()');
cmp_ok($#p, '==', '3', '    returns the correct number of clerks');
cmp_ok($p[0]->{'id'}, '==', '100', '    returns the correct clerk 0 id');
cmp_ok($p[0]->{'name'}, 'eq', 'Stress Test Clerk', '    returns the correct clerk 0 name');
cmp_ok($p[1]->{'id'}, '==', '20', '    returns the correct clerk 1 id');
cmp_ok($p[1]->{'name'}, 'eq', 'Timeclock Test1', '    returns the correct clerk 1 name');
cmp_ok($p[2]->{'id'}, '==', '21', '    returns the correct clerk 2 id');
cmp_ok($p[2]->{'name'}, 'eq', 'Timeclock Test2', '    returns the correct clerk 2 name');
cmp_ok($p[3]->{'id'}, '==', '22', '    returns the correct clerk 3 id');
cmp_ok($p[3]->{'name'}, 'eq', 'Timeclock Test3', '    returns the correct clerk 3 name');

ok(@p = $tc->getAllClerksInSpanOrderedByClockedIn('2007-01-01 05:00', '2007-01-02 05:00'), 'getAllClerksInSpanOrderedByClockedIn()');
cmp_ok($#p, '==', '3', '    returns the correct number of clerks');
cmp_ok($p[0]->{'id'}, '==', '20', '    returns the correct clerk 0 id');
cmp_ok($p[0]->{'name'}, 'eq', 'Timeclock Test1', '    returns the correct clerk name');
cmp_ok($p[1]->{'id'}, '==', '21', '    returns the correct clerk 1 id');
cmp_ok($p[1]->{'name'}, 'eq', 'Timeclock Test2', '    returns the correct clerk name');
cmp_ok($p[2]->{'id'}, '==', '22', '    returns the correct clerk 2 id');
cmp_ok($p[2]->{'name'}, 'eq', 'Timeclock Test3', '    returns the correct clerk name');
cmp_ok($p[3]->{'id'}, '==', '100', '    returns the correct clerk 3 id');
cmp_ok($p[3]->{'name'}, 'eq', 'Stress Test Clerk', '    returns the correct clerk name');

ok(@p = $tc->getClerksInSpan('2007-01-01 05:00', '2007-01-02 05:00'), 'getClerksInSpan()');
cmp_ok($#p, '==', '2', '    returns the correct number of clerks');
cmp_ok($p[0]->{'id'}, '==', '20', '    returns the correct clerk 0 id');
cmp_ok($p[0]->{'name'}, 'eq', 'Timeclock Test1', '    returns the correct clerk 0 name');
cmp_ok($p[1]->{'id'}, '==', '21', '    returns the correct clerk 1 id');
cmp_ok($p[1]->{'name'}, 'eq', 'Timeclock Test2', '    returns the correct clerk 1 name');
cmp_ok($p[2]->{'id'}, '==', '22', '    returns the correct clerk 2 id');
cmp_ok($p[2]->{'name'}, 'eq', 'Timeclock Test3', '    returns the correct clerk 2 name');
ok(@p = $tc->getClerksClockedIn('2007-01-01'), 'getClerksClockedIn()');
cmp_ok($#p, '==', '1', '    returns the correct number of clerks');
cmp_ok($p[0]->{'id'}, '==', '21', '    returns the correct clerk 0 id');
cmp_ok($p[0]->{'name'}, 'eq', 'Timeclock Test2', '    returns the correct clerk 0 name');
cmp_ok($p[1]->{'id'}, '==', '22', '    returns the correct clerk 1 id');
cmp_ok($p[1]->{'name'}, 'eq', 'Timeclock Test3', '    returns the correct clerk 1 name');

#20: 2 hrs, clocked out, 1 void
ok(!$tc->isClockedIn(20, '2007-01-01'), 'isClockedIn() clocked out (with voids)');
cmp_ok($tc->getHoursInSpan(20, '2007-01-01 05:00', '2007-01-02 05:00'), '==', '2', 'getHoursInSpan() (with voids)');
ok(@p = $tc->getVoidPunchesInSpan(20, '2007-01-01 05:00', '2007-01-02 05:00'), 'getVoidPunchesInSpan() returns');
cmp_ok($#p, '==', '0', '    returns the correct number of punches');
cmp_ok($p[0], 'eq', '2007-01-01 09:00:00-06', '    returns the correct timestamp');
ok($tc->open(20, $p[0]), '    open()');
cmp_ok($tc->{'clerk'}, '==', '20', '        returns the correct \'clerk\'');
cmp_ok($tc->{'punch'}, 'eq', '2007-01-01 09:00:00-06', '        returns the correct \'punch\'');
ok(!$tc->{'forced'}, '        returns the correct \'forced\'');
cmp_ok($tc->{'voidAt'}, 'eq', '2007-01-01 09:10:00-06', '        returns the correct \'voidAt\'');
cmp_ok($tc->{'voidBy'}, 'eq', 'bobbert@localhost', '        returns the correct \'voidBy\'');
cmp_ok($tc->{'created'}, 'eq', '2007-01-01 09:00:00-06', '        returns the correct \'created\'');
cmp_ok($tc->{'createdBy'}, 'eq', 'jason@localhost', '        returns the correct \'createdBy\'');
cmp_ok($tc->{'modified'}, 'eq', '2007-01-01 09:10:00-06', '        returns the correct \'modified\'');
cmp_ok($tc->{'modifiedBy'}, 'eq', 'bobbert@localhost', '        returns the correct \'modifiedBy\'');
ok(@p = $tc->getVoidClerksInSpan('2007-01-01 05:00', '2007-01-02 05:00'), 'getVoidClerksInSpan() returns');
cmp_ok($#p, '==', '0', '    returns the correct number of clerks');
cmp_ok($p[0]->{'id'}, '==', '20', '    returns the clerk id');
cmp_ok($p[0]->{'name'}, 'eq', 'Timeclock Test1', '    returns the clerk name');
ok(@p = $tc->getPunchesInSpan(20, '2007-01-01 05:00', '2007-01-02 05:00'), 'getPunchesInSpan() returns');
cmp_ok($#p, '==', '1', '    returns the correct number of punches');
cmp_ok($p[0], 'eq', '2007-01-01 08:00:00-06', '    returns the correct timestamp for 0');
cmp_ok($p[1], 'eq', '2007-01-01 10:00:00-06', '    returns the correct timestamp for 1');

#21: clocked in
ok($tc->isClockedIn(21, '2007-01-01'), 'isClockedIn() clocked in');
cmp_ok($tc->getHoursInSpan(21, '2007-01-01 05:00', '2007-01-02 05:00'), '==', '0.5', 'getHoursInSpan() completed hours');
ok($tc->forcePunch(21, '2007-01-01 09:15'), 'forcePunch()');
cmp_ok($tc->getHoursInSpan(21, '2007-01-01 05:00', '2007-01-02 05:00'), '==', '1', 'getHoursInSpan() completed hours (with a forced punch)');
ok($tc->forcePunch(21, '2007-01-01 09:30'), 'forcePunch()');
ok($tc->voidPunch(21, '2007-01-01 09:15'), 'voidPunch()');
cmp_ok($tc->getHoursInSpan(21, '2007-01-01 05:00', '2007-01-02 05:00'), '==', '1.25', 'getHoursInSpan() completed hours (with a forced punch)');
ok(!$tc->isClockedIn(21, '2007-01-01'), 'isClockedIn() clocked in');
ok($tc->unvoidPunch(21, '2007-01-01 09:15'), 'unvoidPunch()');
cmp_ok($tc->getHoursInSpan(21, '2007-01-01 05:00', '2007-01-02 05:00'), '==', '1', 'getHoursInSpan() completed hours (after unvoiding a punch)');


#22: clocked in
ok($tc->isClockedIn(22, '2007-01-01'), 'isClockedIn() clocked in');
ok($tc->punch(22), 'punch()');
my $h = $tc->getHoursInSpan(22, '2007-01-01 05:00', 'now');
cmp_ok($h, '>=', (time - 1167660000 - 60)/3600, 'getHoursInSpan() completed hours is large enough');
cmp_ok($h, '<=', (time - 1167660000 + 60)/3600, 'getHoursInSpan() completed hours is small enough');

#try to make a clerk who is completely voided out to check getAllClerksInSpan() and getAllPunchesInSpan()
@p = $tc->getPunchesInSpan(22, '2007-01-01 05:00', '2007-01-02 05:00');
foreach my $p (@p)
{
    $tc->voidPunch(22, $p);
}

ok(@p = $tc->getClerksInSpan('2007-01-01 05:00', '2007-01-02 05:00'), 'getClerksInSpan() (for comparison below)');
cmp_ok($#p, '==', '1', '    returns the correct number of clerks');
cmp_ok($p[0]->{'id'}, '==', '20', '    returns the correct clerk 0 id');
cmp_ok($p[0]->{'name'}, 'eq', 'Timeclock Test1', '    returns the correct clerk 0 name');
cmp_ok($p[1]->{'id'}, '==', '21', '    returns the correct clerk 1 id');
cmp_ok($p[1]->{'name'}, 'eq', 'Timeclock Test2', '    returns the correct clerk 1 name');

ok(@p = $tc->getAllClerksInSpan('2007-01-01 05:00', '2007-01-02 05:00'), 'getAllClerksInSpan()');
cmp_ok($#p, '==', '2', '    returns the correct number of clerks');
cmp_ok($p[0]->{'id'}, '==', '20', '    returns the correct clerk 0 id');
cmp_ok($p[0]->{'name'}, 'eq', 'Timeclock Test1', '    returns the correct clerk 0 name');
cmp_ok($p[1]->{'id'}, '==', '21', '    returns the correct clerk 1 id');
cmp_ok($p[1]->{'name'}, 'eq', 'Timeclock Test2', '    returns the correct clerk 1 name');
cmp_ok($p[2]->{'id'}, '==', '22', '    returns the correct clerk 2 id');
cmp_ok($p[2]->{'name'}, 'eq', 'Timeclock Test3', '    returns the correct clerk 2 name');

ok(@p = $tc->getAllPunchesInSpan(20, '2007-01-01 05:00', '2007-01-02 05:00'), 'getAllPunchesInSpan()');
cmp_ok($#p, '==', '2', '    returns the correct number of punches');
cmp_ok($p[0], 'eq', '2007-01-01 08:00:00-06', '    returns the correct timestamp for 0');
cmp_ok($p[1], 'eq', '2007-01-01 09:00:00-06', '    returns the correct timestamp for 1');
cmp_ok($p[2], 'eq', '2007-01-01 10:00:00-06', '    returns the correct timestamp for 2');

#make sure a voided clerk can't make regular punches
ok(!$tc->punch(12345), 'a voided clerk can\'t make regular punches');
#...but a forcedPunch will work
ok($tc->forcePunch(12345, '1776-07-04 00:00'), '    forcePunch() on a voided clerk');
ok($tc->forcePunch(12345, '1776-07-04 12:00'), '    forcePunch() on a voided clerk');
$h = $tc->getHoursInSpan(12345, '1776-07-04 00:00', 'now');
cmp_ok($h, '==', 12, '    the correct amount of time');

#rev
my @info = ('21', '2007-01-01 09:15:00-06');
my @rev = $tc->rev(@info);
my @expRev = (11, 10, 8);
is_deeply(\@rev, \@expRev, 'rev() returns the expected revisions');
ok(($tc->openRev(@info, $expRev[0]) and !$tc->isVoid), 'spot checking an older rev');
ok(($tc->openRev(@info, $expRev[1]) and $tc->isVoid), 'spot checking an older rev');
ok(($tc->openRev(@info, $expRev[2]) and !$tc->isVoid), 'spot checking an older rev');

1;
