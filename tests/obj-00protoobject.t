#!/usr/bin/perl -w

#obj-00protoobject.t
#Copyright 2010 Jason Burrell.
#This file is part of L'anePOS. See the top-level COPYING for licensing info.

#$Id: obj-00protoobject.t 1132 2010-09-19 21:36:50Z jason $

#ProtoObject tests
# - namespace aliasing tests

use Test::More tests => 15;

BEGIN {
    use FindBin;
    use File::Spec;
    $ENV{'LaneRoot'} = File::Spec->catdir($FindBin::Bin, File::Spec->updir); #use the correct number of updirs
    require File::Spec->catfile($ENV{'LaneRoot'}, 'config', 'init.pl');
}

BEGIN
{
    #chose these three because
    use_ok('LanePOS::String'); #String's direct parent (GO) isa ProtoObject (one level)
    use_ok('LanePOS::SysString'); #SysString's grandparent isa ProtoObject (two levels)
    use_ok('LanePOS::Locale'); #Locale is a ProtoObject
}

sub checkIsa
{
    my ($s, $sy, $lc) = @_;

    isa_ok($s, 'String');
    isa_ok($sy, 'SysString');
    isa_ok($lc, 'Locale');
    
    isa_ok($s, 'LanePOS::String');
    isa_ok($sy, 'LanePOS::SysString');
    isa_ok($lc, 'LanePOS::Locale');
}

#short constructors
my @a;
$a[0] = String->new;
$a[1] = SysString->new;
$a[2] = Locale->new;

checkIsa(@a);

#long constructors
my @b;
$b[0] = LanePOS::String->new;
$b[1] = LanePOS::SysString->new;
$b[2] = LanePOS::Locale->new;

checkIsa(@b);
