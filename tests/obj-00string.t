#!/usr/bin/perl -w

#obj-00string.t
#Copyright 2003-2010 Jason Burrell.
#This file is part of L'anePOS. See the top-level COPYING for licensing info.

#$Id: obj-00string.t 1190 2010-10-22 19:27:02Z jason $

#L'ane obj test
# - string

use Test::More tests => 37;
#use Test::More 'no_plan';

BEGIN {
    use FindBin;
    use File::Spec;
    $ENV{'LaneRoot'} = File::Spec->catdir($FindBin::Bin, File::Spec->updir); #use the correct number of updirs
    require File::Spec->catfile($ENV{'LaneRoot'}, 'config', 'init.pl');
}

BEGIN { use_ok('LanePOS::String'); }

my $string = String->new();
isa_ok($string, 'String');

#diag('general object methods');
can_ok($string, qw/new open save void isVoid/);

$string->{'id'} = 'my test';
$string->{'data'} = 'my data';
ok($string->save(), 'save a new string');

ok($string->open('obj-00string.t-test'), 'open the sample string');
is($string->{'id'}, 'obj-00string.t-test', '    \'id\' matches');
is($string->{'data'}, 'The test data.', '    \'data\' matches');
$string->{'data'} = 'new test';
ok($string->save(), 'update a string via save()');

ok($string->open('my test'), 'open the saved string');
is($string->{'id'}, 'my test', '    \'id\' matches');
is($string->{'data'}, 'my data', '    \'data\' matches');

ok($string->open('obj-00string.t-test'), 'open the sample string');
is($string->{'id'}, 'obj-00string.t-test', '    \'id\' matches');
is($string->{'data'}, 'new test', '    \'data\' matches');
$string->{'data'} = 'The test data.';
ok($string->save(), 'update a string via save()');

ok($string->open('my test'), 'open the saved string');
is($string->{'id'}, 'my test', '    \'id\' matches');
is($string->{'data'}, 'my data', '    \'data\' matches');
ok($string->void, 'void the record');
#diag('remove() doesn\'t clear your object (a bug?)');
ok(!$string->open('my test'), 'the string was REALLY void');

#try to access the version info too
my @rev;
@rev = $string->rev('obj-00string.t-test');
is($#rev, 2, 'the rev');
my @expected = (9, 8, 1);
is_deeply(\@rev, \@expected, 'the expected revisions exist');
ok($string->openRev('obj-00string.t-test', $expected[0]), "rev $expected[0] opened");
my %exp = (
    'id' => 'obj-00string.t-test',
    'data' => 'The test data.',
    'r' => $expected[0],
    );
my ($k, $v);
while(($k, $v) = each %exp)
{
    is($string->{$k}, $v, "    '$k' matches");
}

ok($string->openRev('obj-00string.t-test', $expected[1]), "rev $expected[1] opened");
%exp = (
    'id' => 'obj-00string.t-test',
    'data' => 'new test',
    'r' => $expected[1],
    );
while(($k, $v) = each %exp)
{
    is($string->{$k}, $v, "    '$k' matches");
}

ok($string->openRev('obj-00string.t-test', $expected[2]), "rev $expected[2] opened");
%exp = (
    'id' => 'obj-00string.t-test',
    'data' => 'The test data.',
    'r' => $expected[2],
    );
while(($k, $v) = each %exp)
{
    is($string->{$k}, $v, "    '$k' matches");
}

#check the void-type data
@rev = $string->rev('my test');
@expected = (10, 7);
%exp = (
    'id' => 'my test',
    'data' => 'my data',
);
is_deeply(\@rev, \@expected, 'rev returned info about all (incl voided) revisions');
ok($string->openRev('my test', $expected[0]), 'openRev the voided revision');
ok(defined $string->{'voidAt'}, 'voidAt is defined');
