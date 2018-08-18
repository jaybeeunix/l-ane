#!/usr/bin/perl -w

#obj-01genericeventable.t
#Copyright 2008-2010 Jason Burrell.
#This file is part of L'anePOS. See the top-level COPYING for licensing info.

#$Id: obj-01genericeventable.t 1207 2011-04-06 00:44:39Z jason $

#L'ane obj test
# - genericeventable

BEGIN {
    use FindBin;
    use File::Spec;
    $ENV{'LaneRoot'} = File::Spec->catdir($FindBin::Bin, File::Spec->updir); #use the correct number of updirs
    require File::Spec->catfile($ENV{'LaneRoot'}, 'config', 'init.pl');
}

package TestEvent;

use base 'LanePOS::GenericEventable';

sub new
{
    my ($class) = @_;

    my $me = {
        
    };

    bless $me, $class;
    $me->initEvents;
    return $me;
}

package main;

use Test::More tests => 22;
#use Test::More 'no_plan';

use File::Copy ();

sub changeDsn
{
    my ($new) = @_;

    use IO::File;

    my $f = IO::File->new(File::Spec->catfile($ENV{'LaneRoot'}, 'config', 'site.pl'), 'w');

    $f->print('$ENV{\'LaneDSN\'} = \'dbname=' , $new, '\';', "\n");
    $f->close;
}

my $t = TestEvent->new;

isa_ok($t, 'LanePOS::GenericEventable');

can_ok($t, qw/initEvents triggerEvent registerEvent preregisterEvent/);

#is($ENV{'LaneDSN'}, 'dbname=', 'check $ENV{\'LaneDSN\'}');
is($ENV{'LaneDSN'}, 'dbname=lanetest', 'check $ENV{\'LaneDSN\'} initial setting');

#save the old site.pl
ok(File::Copy::move(File::Spec->catfile($ENV{'LaneRoot'}, 'config', 'site.pl'), File::Spec->catfile($ENV{'LaneRoot'}, 'config', 'site.pl.pre-tests')), 'saved the old site.pl');

ok(changeDsn('otherthing'), 'change $ENV{\'LaneDSN\'}');
ok(kill('HUP', $$), 'trigger a reload');
sleep(3);
is($ENV{'LaneDSN'}, 'dbname=otherthing', 'check $ENV{\'LaneDSN\'} changed');

ok(changeDsn('lanetest'), 'change $ENV{\'LaneDSN\'}');
ok(kill('HUP', $$), 'trigger a reload');
sleep(3);
is($ENV{'LaneDSN'}, 'dbname=lanetest', 'check $ENV{\'LaneDSN\'} changed');

ok(unlink(File::Spec->catfile($ENV{'LaneRoot'}, 'config', 'site.pl')), 'unlink the file');

#restore the old site.pl
ok(File::Copy::move(File::Spec->catfile($ENV{'LaneRoot'}, 'config', 'site.pl.pre-tests'), File::Spec->catfile($ENV{'LaneRoot'}, 'config', 'site.pl')), 'saved the old site.pl');

#test bug 1363: multiple objects registering HUP events
my ($t1Ran, $t2Ran) = (0, 0);
{
    my $t1 = TestEvent->new;
    my $t2 = TestEvent->new;
    isa_ok($t1, 'LanePOS::GenericEventable');
    can_ok($t1, qw/initEvents triggerEvent registerEvent preregisterEvent/);
    isa_ok($t2, 'LanePOS::GenericEventable');
    can_ok($t2, qw/initEvents triggerEvent registerEvent preregisterEvent/);
    
    ok($t1->registerEvent('Lane/CORE/Reload Config', sub { $t1Ran++; }), 'register an additional event for t1');
    ok($t2->registerEvent('Lane/CORE/Reload Config', sub { $t2Ran++; }), 'register an additional event for t2');
    ok(kill('HUP', $$), 'trigger a reload');
    sleep(3);
    cmp_ok($t1Ran, '==', 1, 't1\'s trigger bit ran once');
    cmp_ok($t2Ran, '==', 1, 't2\'s trigger bit ran once');
}

#test bug 1405: 
diag('the following should generate a "WARNING: GenericEventable::triggerEvent(This event does not exist): no such event exists!" warning');
ok(!$t->triggerEvent('This event does not exist'), 'the non-existent event failed');
