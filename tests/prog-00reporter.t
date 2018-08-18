#!/usr/bin/perl -w

#prog-00reporter.t
#Copyright 2004-2010 Jason Burrell.
#This file is part of L'anePOS. See the top-level COPYING for licensing info.

#$Id: prog-00reporter.t 1092 2010-02-17 14:44:51Z jason $

#reporter (aka XML Reporter) tests

use Test::More tests => 21;
#use Test::More 'no_plan';

BEGIN {
    use FindBin;
    use File::Spec;
    $ENV{'LaneRoot'} = File::Spec->catdir($FindBin::Bin, File::Spec->updir); #use the correct number of updirs
    require File::Spec->catfile($ENV{'LaneRoot'}, 'config', 'init.pl');
}

#reporter's location
my $reporter = File::Spec->catfile($ENV{'LaneRoot'}, 'backOffice', 'xmlReporter', 'reporter');

#set the language to US English, so the formats match the input files
$ENV{'LaneLang'} = 'en-TEST';

#the files to test
ok(chdir(File::Spec->catdir($ENV{'LaneRoot'}, 'tests', 'reporter')), 'chdir() to the "reporter" test files dir');
my @input = <*.xml>;

$SIG{'PIPE'} = sub {1;}; #ignore pipe problems

foreach my $inFile (@input)
{
    ok(open(Reporter, "$reporter $inFile 2>" . File::Spec->devnull() . ' |'), "Open the pipe from reporter for $inFile");
    binmode(Reporter, ':utf8');
    my ($in, $out);
    ok(open(Expected, "< $inFile.expected"), "Open $inFile.expected for comparison");
    binmode(Expected, ':utf8');
    $in .= $_ while(<Reporter>);
    is($? >> 8, 0, 'reporter returned successfully');
    $out .= $_ while(<Expected>);
    cmp_ok($in, 'eq', $out, "$inFile is as expected");
}
