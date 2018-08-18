#!/usr/bin/perl -w

#cleanup-90db.t
#Copyright 2003-2010 Jason Burrell.
#This file is part of L'anePOS. See the top-level COPYING for licensing info.

#cleanup after L'ane tests
# - rm the test database

#$Id: cleanup-90db.t 1165 2010-09-29 01:22:39Z jason $

my $testDb = 'lanetest';

use Test::More tests => 3;

#BEGIN {
#    use FindBin;
#    use File::Spec;
#    $ENV{'LaneRoot'} = File::Spec->catdir($FindBin::Bin, File::Spec->updir); #use the correct number of updirs
#    require File::Spec->catfile($ENV{'LaneRoot'}, 'config', 'init.pl');
#}

BEGIN { diag('This script must be run by a user with database admin rights.'); }

BEGIN
{
    use_ok('DBI');
}

my $db = DBI->connect("dbi:Pg:db=template1");
is($db->state, '25P01', 'DBI->connect ok');
$db->do("drop database $testDb");
is($db->state, '', "Drop the database $testDb");
