#!/usr/bin/perl -w

#cleanup-02site-config.t
#Copyright 2010 Jason Burrell.
#This file is part of L'anePOS. See the top-level COPYING for licensing info.

#$Id: cleanup-02site-config.t 1148 2010-09-25 22:05:28Z jason $

#cleanup L'ane tests
# - restores the previous site config

use Test::More tests => 1;

BEGIN { diag('This script must be run by a user with write access to $LaneRoot/config/'); }

BEGIN {
    use FindBin;
    use File::Spec;
    $ENV{'LaneRoot'} = File::Spec->catdir($FindBin::Bin, File::Spec->updir); #use the correct number of updirs
    #require File::Spec->catfile($ENV{'LaneRoot'}, 'config', 'init.pl');
}

use File::Copy;

my $conf = File::Spec->catfile($ENV{'LaneRoot'}, 'config', 'site.pl');
#my $testconf = File::Spec->catfile($ENV{'LaneRoot'}, 'config', 'site.pl-tests');
my $holding = File::Spec->catfile($ENV{'LaneRoot'}, 'config', 'site.pl-pre-tests');

if(-r $holding)
{
    ok(move($holding, $conf), "moving $holding back to $conf");
}
else
{
    pass("site.pl didn't exist");
}
