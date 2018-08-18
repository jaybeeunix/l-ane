#!/usr/bin/perl -w

#obj-00term.t
#Copyright 2003-2010 Jason Burrell.
#This file is part of L'anePOS. See the top-level COPYING for licensing info.

#$Id: obj-00term.t 1127 2010-09-18 04:26:34Z jason $

#L'ane obj test
# - term

use Test::More tests => 67;

BEGIN {
    use FindBin;
    use File::Spec;
    $ENV{'LaneRoot'} = File::Spec->catdir($FindBin::Bin, File::Spec->updir); #use the correct number of updirs
    require File::Spec->catfile($ENV{'LaneRoot'}, 'config', 'init.pl');
}

BEGIN { use_ok('LanePOS::Term'); }

my $term = Term->new();
isa_ok($term, 'Term');

#diag('general object methods');
can_ok($term, qw/new open save void isVoid getAll isCurrent isDiscAble datesBefore datesFrom applyDisc applyFin/);

$term->{'id'} = 't2';
$term->{'descr'} = 'Test 2';
$term->{'dueDays'} = '20';
$term->{'finRate'} = '15';
$term->{'discDays'} = '3';
$term->{'discRate'} = '4';

ok($term->save(), 'save a new term');
ok($term->open('t1'), 'open the sample term');
is($term->{'id'}, 't1', "    'id' matches");
is($term->{'descr'}, 'Test Term One', "    'descr' matches");
is($term->{'dueDays'}, '10', "    'dueDays' matches");
cmp_ok($term->{'finRate'}, '==', '15', "    'finRate' matches");
is($term->{'discDays'}, '2', "    'discDays' matches");
cmp_ok($term->{'discRate'}, '==', '5.1234', "    'discRate' matches");
is($term->{'createdBy'}, 'installer+jason@localhost', "    'createdBy' matches");
is($term->{'created'}, '1999-05-26 00:00:00-05', "    'created' matches");
ok($term->isCurrent('2003-01-01', '2003-01-10'), '    isCurrent() works for the obvious case');
ok($term->isCurrent('2003-01-01', '2003-01-11'), '    isCurrent() works for boundry case');
ok(!$term->isCurrent('2003-01-01', '2003-01-12'), '    isCurrent() blocks for boundry case');

ok($term->isDiscAble('2003-01-01', '2003-01-02'), '    isDiscAble() works for the obvious case');
ok($term->isDiscAble('2003-01-01', '2003-01-03'), '    isDiscAble() works for boundry case');
ok(!$term->isDiscAble('2003-01-01', '2003-01-04'), '    isDiscAble() blocks for boundry case');
ok(my @d = $term->datesFrom('2003-01-01'), '    call to datesFrom() works');
is($d[0], '01-03-2003', '        disc date worked');
is($d[1], '01-11-2003', '        due date worked');
ok(@d = $term->datesBefore('2003-01-01'), '    call to datesBefore() works');
is($d[0], '12-30-2002', '        disc date worked');
is($d[1], '12-22-2002', '        due date worked');
cmp_ok($term->applyDisc(10000), '==', 512, '    applyDisc() works');
cmp_ok($term->applyFin(10000), '==', 1500, '    applyFin() works');

ok($term->open('t2'), 'open the saved term');
is($term->{'id'}, 't2', "    'id' matches");
is($term->{'descr'}, 'Test 2', "    'descr' matches");
is($term->{'dueDays'}, '20', "    'dueDays' matches");
cmp_ok($term->{'finRate'}, '==', '15', "    'finRate' matches");
is($term->{'discDays'}, '3', "    'discDays' matches");
cmp_ok($term->{'discRate'}, '==', '4', "    'discRate' matches");
is($term->{'createdBy'}, $term->{'dal'}->getUsername(), "    'createdBy' matches the expected username");
#can't easily test this
ok($term->{'created'}, "    'created' matches");
ok($term->isCurrent('2003-01-01', '2003-01-20'), '    isCurrent() works for the obvious case');
ok($term->isCurrent('2003-01-01', '2003-01-21'), '    isCurrent() works for boundry case');
ok(!$term->isCurrent('2003-01-01', '2003-01-22'), '    isCurrent() blocks for boundry case');

ok($term->isDiscAble('2003-01-01', '2003-01-03'), '    isDiscAble() works for the obvious case');
ok($term->isDiscAble('2003-01-01', '2003-01-04'), '    isDiscAble() works for boundry case');
ok(!$term->isDiscAble('2003-01-01', '2003-01-05'), '    isDiscAble() blocks for boundry case');
ok(my @dt = $term->datesFrom('2003-01-01'), '    call to datesFrom() works');
is($dt[0], '01-04-2003', '        disc date worked');
is($dt[1], '01-21-2003', '        due date worked');
ok(@dt = $term->datesBefore('2003-01-01'), '    call to datesBefore() works');
is($dt[0], '12-29-2002', '        disc date worked');
is($dt[1], '12-12-2002', '        due date worked');
cmp_ok($term->applyDisc(20000), '==', 800, '    applyDisc() works');
cmp_ok($term->applyFin(20000), '==', 3000, '    applyFin() works');

ok(my @terms = $term->getAll(), 'getAll() worked');
is($#terms, 2, '    returned the expected number of terms');
#test the actual values. we know the order as they are sorted before being returned.
is($terms[0][0], 'Cash on Delivery', '    t0\'s name matches');
is($terms[0][1], 'cod', '    t0\'s id matches');
is($terms[1][0], 'Test 2', '    t1\'s name matches');
is($terms[1][1], 't2', '    t1\'s id matches');
is($terms[2][0], 'Test Term One', '    t2\'s name matches');
is($terms[2][1], 't1', '    t2\'s id matches');

ok($term->void(), 'voiding the record');
ok(($term->open('t2') and $term->isVoid), 'the term was REALLY void');
#make sure void hides terms from getAll
@terms = $term->getAll;
cmp_ok($#terms, '==', 1, 'getAll hides void');

my @rev = $term->rev('t2');
is($#rev, 1, 'the correct number of revisions');
is_deeply(\@rev, [4, 3], 'the correct revisions');

#$term->{'dal'}->trace(STDERR);
ok($term->openRev('t2', 3), 'openRev() the old (pre void) term');
ok(!defined($term->{'voidAt'}), 'check a value that changed');
ok($term->openRev('t2', 4), 'openRev() should open a voided term');
ok(defined($term->{'voidAt'}), 'check a value that changed');
1;
