#!/usr/bin/perl -w

#obj-01sysstring.t
#Copyright 2003 Jason Burrell.
#This file is part of L'anePOS. See the top-level COPYING for licensing info.

#$Id: obj-01sysstring.t 1040 2009-03-08 21:16:17Z jason $

#L'ane obj test
# - sysstring

use Test::More tests => 26;

BEGIN {
    use FindBin;
    use File::Spec;
    $ENV{'LaneRoot'} = File::Spec->catdir($FindBin::Bin, File::Spec->updir); #use the correct number of updirs
    require File::Spec->catfile($ENV{'LaneRoot'}, 'config', 'init.pl');
}

BEGIN { use_ok('LanePOS::SysString'); }

my $sysstring = SysString->new();
isa_ok($sysstring, 'SysString');

#diag('general object methods');
can_ok($sysstring, qw/new open save remove getTree/);

$sysstring->{'id'} = 'my test';
$sysstring->{'data'} = 'my data';

ok($sysstring->save(), 'save a new sysstring');
ok($sysstring->open('obj-01sysstring.t-test'), 'open the sample sysstring');
is($sysstring->{'id'}, 'obj-01sysstring.t-test', '    \'id\' matches');
is($sysstring->{'data'}, 'The sys test data.', '    \'data\' matches');
ok($sysstring->open('my test'), 'open the saved sysstring');
is($sysstring->{'id'}, 'my test', '    \'id\' matches');
is($sysstring->{'data'}, 'my data', '    \'data\' matches');

ok($sysstring->remove(), 'removing the record');
#diag('remove() doesn\'t clear your object (a bug?)');
ok(!$sysstring->open('my test'), 'the sysstring was REALLY removed');

#test the new getTree() code
my %t;
ok(%t = ($sysstring->getTree('Lane/Testing/Item')), 'getTree()');
is(keys(%t), '6', '    returned the correct number of sysStrings');
ok(exists $t{'Lane/Testing/Item'}, '    \'Lane/Testing/Item\' exists');
is($t{'Lane/Testing/Item'}, '0', '        value is correct');
ok(exists $t{'Lane/Testing/Item '}, '    \'Lane/Testing/Item \' exists');
is($t{'Lane/Testing/Item '}, 'space', '        value is correct');
ok(exists $t{'Lane/Testing/Item/'}, '    \'Lane/Testing/Item/\' exists');
is($t{'Lane/Testing/Item/'}, 'slash', '        value is correct');
ok(exists $t{'Lane/Testing/Item1'}, '    \'Lane/Testing/Item1\' exists');
is($t{'Lane/Testing/Item1'}, '1', '        value is correct');
ok(exists $t{'Lane/Testing/Item1/1'}, '    \'Lane/Testing/Item1/1\' exists');
is($t{'Lane/Testing/Item1/1'}, '1/1', '        value is correct');
ok(exists $t{'Lane/Testing/Item2'}, '    \'Lane/Testing/Item2\' exists');
is($t{'Lane/Testing/Item2'}, '2', '        value is correct');
