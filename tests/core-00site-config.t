#!/usr/bin/perl -w

#core-00site-config.t
#Copyright 2010 Jason Burrell.
#This file is part of L'anePOS. See the top-level COPYING for licensing info.

#$Id: core-00site-config.t 1148 2010-09-25 22:05:28Z jason $

#core L'ane tests
# - create the sample config file

use Test::More tests => 2;

BEGIN { diag('This script must be run by a user with write access to $LaneRoot/config/'); }

BEGIN {
    use FindBin;
    use File::Spec;
    $ENV{'LaneRoot'} = File::Spec->catdir($FindBin::Bin, File::Spec->updir); #use the correct number of updirs
    #require File::Spec->catfile($ENV{'LaneRoot'}, 'config', 'init.pl');
}

use File::Copy;

my $conf = File::Spec->catfile($ENV{'LaneRoot'}, 'config', 'site.pl');
my $testconf = File::Spec->catfile($ENV{'LaneRoot'}, 'config', 'site.pl-tests');
my $holding = File::Spec->catfile($ENV{'LaneRoot'}, 'config', 'site.pl-pre-tests');

#it may not exist
if(-r $conf)
{
    ok(move($conf, $holding), "temporarily moving $conf to $holding");
}
else
{
    pass("no site.pl currently exists");
}

ok(copy($testconf, $conf), "copying $testconf to $conf");
