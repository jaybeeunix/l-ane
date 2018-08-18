#!/usr/bin/perl -w

#obj-00clerk.t
#Copyright 2003-2010 Jason Burrell.
#This file is part of L'anePOS. See the top-level COPYING for licensing info.

#L'ane obj test
# - clerks

use Test::More tests => 33;

BEGIN {
    use FindBin;
    use File::Spec;
    $ENV{'LaneRoot'} = File::Spec->catdir($FindBin::Bin, File::Spec->updir); #use the correct number of updirs
    require File::Spec->catfile($ENV{'LaneRoot'}, 'config', 'init.pl');
}

BEGIN { use_ok('LanePOS::Clerk'); }

my $clerk = Clerk->new();
isa_ok($clerk, 'LanePOS::Clerk');

#diag('general object methods');
can_ok($clerk, qw/new open save remove authenticate/);

$clerk->{'id'} = '12345';
$clerk->{'name'} = 'obj-00clerk.t Test';
$clerk->{'passcode'} = '6789';
$clerk->{'drawer'} = '1';

ok($clerk->save(), 'save a new clerk');
ok($clerk->open('100'), 'open the sample clerk');
ok($clerk->open('12345'), 'open the saved clerk');
is($clerk->{'id'}, '12345', "    'id' matches");
is($clerk->{'name'}, 'obj-00clerk.t Test', "    'name' matches");
is($clerk->{'passcode'}, '6789', "    'passcode' matches");
is($clerk->{'drawer'}, '1', "    'drawer' matches");
ok(!$clerk->authenticate('67890'), '->authenticate() blocks the wrong passcode');
ok($clerk->authenticate('6789'), '->authenticate() allows the right passcode');
ok($clerk->remove(), 'removing the record');
#diag('remove() doesn\'t clear your object (a bug?)');
ok(($clerk->open('12345') and $clerk->{'voidAt'}), 'remove() voided the clerk');

#try the new short-hand methods
is($clerk->id, '12345', 'short-hand id get worked');
ok($clerk->id('5678'), 'trying short-hand id set');
is($clerk->{'id'}, '5678', 'short-hand id set worked');

#check the audit/rev log
#$clerk->{'dal'}->trace(STDERR);
ok($clerk->openRev('12345', 5), 'open the first version of the 12345 clerk');
is($clerk->{'id'}, '12345', "    'id' matches");
is($clerk->{'name'}, 'obj-00clerk.t Test', "    'name' matches");
is($clerk->{'passcode'}, '6789', "    'passcode' matches");
is($clerk->{'drawer'}, '1', "    'drawer' matches");
ok(!$clerk->authenticate('67890'), '->authenticate() blocks the wrong passcode');
ok($clerk->authenticate('6789'), '->authenticate() allows the right passcode');

ok($clerk->openRev('12345', 6), 'open the final version of the 12345 clerk');
ok($clerk->{'voidAt'}, 'remove() voided the clerk');
is($clerk->{'id'}, '12345', "    'id' matches");
is($clerk->{'name'}, 'obj-00clerk.t Test', "    'name' matches");
is($clerk->{'passcode'}, '6789', "    'passcode' matches");
is($clerk->{'drawer'}, '1', "    'drawer' matches");
ok(!$clerk->authenticate('67890'), '->authenticate() blocks the wrong passcode');
ok($clerk->authenticate('6789'), '->authenticate() allows the right passcode');

my @rev = $clerk->rev('12345');
is_deeply(\@rev, [6, 5], 'rev() returned the expected revisions in the expected order');

1;
