#!/usr/bin/perl -w

#core-01env.t
#Copyright 2003 Jason Burrell.
#This file is part of L'anePOS. See the top-level COPYING for licensing info.

#$Id: core-01env.t 1148 2010-09-25 22:05:28Z jason $

#core L'ane tests
# - Env correctly configured
# - 

use Test::More tests => 2;

BEGIN {
    use FindBin;
    use File::Spec;
    $ENV{'LaneRoot'} = File::Spec->catdir($FindBin::Bin, File::Spec->updir); #use the correct number of updirs
    require File::Spec->catfile($ENV{'LaneRoot'}, 'config', 'init.pl');
}

#diag('%ENV tests');
ok($ENV{'LaneRoot'}, '$ENV{\'LaneRoot\'} is defined');
ok($ENV{'LaneDSN'}, '$ENV{\'LaneDSN\'} is defined');

