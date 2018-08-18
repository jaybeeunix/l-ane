#!/usr/bin/perl -w

#core-02db.t
#Copyright 2003-2010 Jason Burrell.
#This file is part of L'anePOS. See the top-level COPYING for licensing info.

#$Id: core-02db.t 1165 2010-09-29 01:22:39Z jason $

#core L'ane tests
# - database connectivity

my $testDb = 'lanetest';

use Test::More tests => 5;

BEGIN { diag('This script must be run by a user with database creation rights.'); }

BEGIN {
    use FindBin;
    use File::Spec;
    $ENV{'LaneRoot'} = File::Spec->catdir($FindBin::Bin, File::Spec->updir); #use the correct number of updirs
    #require File::Spec->catfile($ENV{'LaneRoot'}, 'config', 'init.pl');
}

BEGIN
{
    use_ok('DBI');
}

open Sql, '<', File::Spec->catfile($ENV{'LaneRoot'}, 'tests', 'db.sql');

my $createSql;

$createSql .= $_ while <Sql>;

#load the schema from this file
$SIG{'PIPE'} = sub {1;}; #ignore pipe problems
system("createdb $testDb >/dev/null 2>&1");
ok(open(PsqlPipe, "|psql $testDb 2> $ENV{HOME}/lane-test-errss > $ENV{HOME}/lane-test-errs"), 'Pipe to the psql command');
print PsqlPipe $createSql;
close PsqlPipe;
is($? >> 8, 0, 'Load the test database');
my $db = DBI->connect("dbi:Pg:db=$testDb");
is($db->state, '25P01', 'DBI->connect() ok'); #25P01 is no_active_sql_transaction
$db->do('select * from customers where id=\'\'');
is($db->state, '', 'Check loaded data');
