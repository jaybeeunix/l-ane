#!/usr/bin/perl -w

#obj-99device-tests.t
#Copyright 2010 Jason Burrell.
#This file is part of L'anePOS. See the top-level COPYING for licensing info.

#$Id: obj-99device-tests.t 1135 2010-09-20 00:50:20Z jason $

#Device tests
# - namespace aliasing tests

use Test::More tests => 22;

BEGIN {
    use FindBin;
    use File::Spec;
    $ENV{'LaneRoot'} = File::Spec->catdir($FindBin::Bin, File::Spec->updir); #use the correct number of updirs
    require File::Spec->catfile($ENV{'LaneRoot'}, 'config', 'init.pl');
}

my @objs;

#from find2perl:
use strict;
use File::Find ();
use IO::File;

# Set the variable $File::Find::dont_use_nlink if you're using AFS,
# since AFS cheats.

# for the convenience of &wanted calls, including -eval statements:
use vars qw/*name *dir *prune/;
*name   = *File::Find::name;
*dir    = *File::Find::dir;
*prune  = *File::Find::prune;

sub wanted {
    /^.*\.pm\z/s
    && push @objs, $name;
    #&& print("$name\n");
}

my $cwd = File::Spec->curdir;

chdir $ENV{'LaneRoot'};
# Traverse desired filesystems
File::Find::find({wanted => \&wanted}, 'LanePOS/Devices');

my $dev = IO::File->new('/dev/null', 'w');
foreach my $o (sort @objs)
{
    my $nme = $o;
    $nme =~ s{/}{::}g;
    $nme =~ s/\.pm$//;
    use_ok($nme);
    my $d = $nme eq 'LanePOS::Devices::BurrellBizSys::PrintAtOnce' ? $nme->new('w', '/dev/null') : $nme->new($dev);
    isa_ok($d, $nme);
}

chdir($cwd);
