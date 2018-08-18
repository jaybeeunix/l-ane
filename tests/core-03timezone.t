#!/usr/bin/perl -w

#core-03timezone.t
#Copyright 2010 Jason Burrell.
#This file is part of L'anePOS. See the top-level COPYING for licensing info.

#$Id: core-03timezone.t 1165 2010-09-29 01:22:39Z jason $

#core L'ane tests
# - system and postgresql timezone handling

#$Id: core-03timezone.t 1165 2010-09-29 01:22:39Z jason $

use Test::More tests => 4;

BEGIN {
    use FindBin;
    use File::Spec;
    $ENV{'LaneRoot'} = File::Spec->catdir($FindBin::Bin, File::Spec->updir); #use the correct number of updirs
    require File::Spec->catfile($ENV{'LaneRoot'}, 'config', 'init.pl');
}

BEGIN
{
    use_ok('DBI');
}

diag('If this test fails, your system or PostgreSQL timezone libraries are likely problematic.');

my $expected = '2000-12-31 18:00:00';

#check the system libraries first
my $date = `date -d '2001-01-01 00:00+00' +'%Y-%m-%d %H:%M:%S'`;
chop $date;
is($date, $expected, 'The system "date" command produced the expected output.');

#now check the db
#ok(push(@INC, $ENV{'LaneRoot'}), 'INC modifications');

my ($dbname) = $ENV{'LaneDSN'} =~ /dbname=(\S+)/;
my $db = DBI->connect("dbi:Pg:db=$dbname");
is($db->state, '25P01', 'DBI->connect() ok'); #25P01 is no_active_sql_transaction
my $st = $db->prepare("select ('2001-01-01 00:00+00'::timestamp with time zone)::timestamp");
$st->execute;
$dbDate = ($st->fetchrow_array)[0];
is($dbDate, $expected, 'the db date is as expected');
