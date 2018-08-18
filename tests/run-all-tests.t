#!/usr/bin/perl -w

#run-all-tests.t
#Copyright 2003-2010 Jason Burrell
#This file is part of L'anePOS.

#$Id: run-all-tests.t 1148 2010-09-25 22:05:28Z jason $

#run-all-tests.t, umm, runs all the tests. ;)
#...in the correct order.

BEGIN {
    use FindBin;
    use File::Spec;
    $ENV{'LaneRoot'} = File::Spec->catdir($FindBin::Bin, File::Spec->updir); #use the correct number of updirs
    #require File::Spec->catfile($ENV{'LaneRoot'}, 'config', 'init.pl');
}

#are the globs sorted?
my @tests = <{core,obj,prog,cleanup}-*.t>;

#setup everything
$ENV{'LaneDSN'} = "dbname=lanetest";
$ENV{'LaneLang'} = "en-US";

delete $ENV{'LaneSiteConf'};

#some of the tests use time comparisons, so set our timezone to America/Chicago
warn("This test suite must be run in TZ=America/Chicago (aka CST6CDT). Your C libraries and PostgreSQL must support it.\n");
$ENV{'TZ'} = 'America/Chicago';
$ENV{'PGTZ'} = 'America/Chicago';

#each module uses it's own FindBin now
#use FindBin;
#$ENV{'LaneRoot'} = "$FindBin::Bin/..";
#print '$ENV{', $_, '} = ', $ENV{$_}, "\n" foreach sort keys %ENV;
#exit;
#print "I'll run these tests:\n\t", join("\n\t", @tests), "\n";

use Test::Harness;

runtests(@tests);
