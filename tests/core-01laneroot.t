#!/usr/bin/perl -w

#core-01laneroot.t
#Copyright 2003-2010 Jason Burrell.
#This file is part of L'anePOS. See the top-level COPYING for licensing info.

#core L'ane tests
# - Filesystem checks

#$Id: core-01laneroot.t 1128 2010-09-18 15:52:24Z jason $

use Test::More tests => 2;

BEGIN {
    use FindBin;
    use File::Spec;
    $ENV{'LaneRoot'} = File::Spec->catdir($FindBin::Bin, File::Spec->updir); #use the correct number of updirs
    require File::Spec->catfile($ENV{'LaneRoot'}, 'config', 'init.pl');
}

#this is already tested by init.pl, but we'll put it here too
ok(-r $ENV{'LaneRoot'}, 'LaneRoot read access');
ok(-x $ENV{'LaneRoot'}, 'LaneRoot execute access');
