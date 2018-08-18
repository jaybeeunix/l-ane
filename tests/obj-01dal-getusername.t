#!/usr/bin/perl -w

#obj-01dal-getusername.t
#Copyright 2010 Jason Burrell.
#This file is part of L'anePOS. See the top-level COPYING for licensing info.

#L'ane obj test
# - Dal::getUsername

use Test::More tests => 4;
#use Test::More 'no_plan';

BEGIN {
    use FindBin;
    use File::Spec;
    $ENV{'LaneRoot'} = File::Spec->catdir($FindBin::Bin, File::Spec->updir); #use the correct number of updirs
    require File::Spec->catfile($ENV{'LaneRoot'}, 'config', 'init.pl');
}

use Data::Dumper;

BEGIN
{
    use_ok('LanePOS::Dal');
}

my $dal = Dal->new();
isa_ok($dal, 'Dal');

my $username = $dal->getUsername();

ok($username, "username $username exists");
#currently, the test suite only working on localhost, so we can safely assume it
like($username, qr/.+\@localhost/, 'username is in the expected format');
1;
