#!/usr/bin/perl -w

#obj-00locale.t
#Copyright 2003-2010 Jason Burrell.
#This file is part of L'anePOS. See the top-level COPYING for licensing info.

#$Id: obj-00locale.t 1193 2010-10-22 21:10:11Z jason $

#L'ane obj test
# - locale objects

use Test::More tests => 94;
#use Test::More 'no_plan';

BEGIN {
    use FindBin;
    use File::Spec;
    $ENV{'LaneRoot'} = File::Spec->catdir($FindBin::Bin, File::Spec->updir); #use the correct number of updirs
    require File::Spec->catfile($ENV{'LaneRoot'}, 'config', 'init.pl');
}

BEGIN { use_ok('LanePOS::Locale'); }

my $extFmtRange = 1000;

#this test uses timezones
diag("Note: The temporal tests make use of the same POSIX libaries as Locale.\nIf it's broken, these tests will be too.");
use POSIX 'strftime';
use Time::Local 'timelocal';
$ENV{'PGTZ'} = 'CST6CDT';

$ENV{'LaneLang'} = 'en-TEST';
my $lc = Locale->new();
isa_ok($lc, 'LanePOS::Locale');

#these are the only public methods
can_ok($lc, qw/
new
get
getOrDefault
clearCache
moneyFmt
timeToEpoch
nowFmt
temporalFmt
extFmt
getAllLike
/);

#basic tests
{
    pass('basic tests');
    is($lc->get('Simple String'), 'Strang Samplah', 'simple db lookup');
    is($lc->get('Multi %0 Replacement %1 String %2', 'Zero', 'One', 'Two'), 'String One w/multiple Zero replacements Two', 'lookup with replacements');
    is($lc->get('can\'t find me'), 'can\'t find me', 'simple passthrough');
    is($lc->get('me %0 either %1', 'Zero', 'One'), 'me Zero either One', 'replacement passthrough');

    is($lc->moneyFmt('1234567890'), '$12,345,678.90', 'moneyFmt() positive test');
    is($lc->moneyFmt('-9876543210'), '-$98,765,432.10', 'moneyFmt() negative test');
    is($lc->moneyFmt('0'), '$0.00', 'moneyFmt() neutral test');

    is($lc->getOrDefault('This doesn\'t exist.', 'ABC'), 'ABC', 'getOrDefault() without a match');
    is($lc->getOrDefault('This doesn\'t exist either.', 'Here %0', 'D'), 'Here D', 'getOrDefault() without a match, with replacement text');
    is($lc->getOrDefault('Simple String', 'Other thing'), 'Strang Samplah', 'getOrDefault() with a match');
    is($lc->getOrDefault('Multi %0 Replacement %1 String %2', '%0 %1 %2', 'Zero', 'One', 'Two'), 'String One w/multiple Zero replacements Two', 'getOrDefault() w/a match, w/replacements');
    is($lc->getOrDefault('Simple String2', 'Other thing2', 'Zero'), 'Strang Zero Samplah', 'getOrDefault() with a match');
    is($lc->getOrDefault('Simple String3', 'Other thing'), 'Strang Samplah3', 'getOrDefault() with a match');
    is($lc->getOrDefault('Simple String4', 'Other thing6', 'Zero'), 'Strang Zero Samplah4', 'getOrDefault() with a match');

    #check the cache directly: this could be fragile
    ok((exists $lc->{'cache'} and defined $lc->{'cache'} and
       exists $lc->{'cache'}{'Simple String'} and $lc->{'cache'}{'Simple String'} eq 'Strang Samplah'),
       'the cache exists with at least one expected item in it'
        );
    ok($lc->clearCache(), 'clearCache() call was successful');
    is_deeply($lc->{'cache'}, {}, 'make sure the cache is actually cleared');
    #verify that doesn't screw things up
    is($lc->get('Simple String'), 'Strang Samplah', 'simple db lookup');
    ok((exists $lc->{'cache'} and defined $lc->{'cache'} and
       exists $lc->{'cache'}{'Simple String'} and $lc->{'cache'}{'Simple String'} eq 'Strang Samplah'),
       'the cache exists with at least one expected item in it'
        );

    #temporal tests
    ############################
    #they're based on timeToEpoch() so we need to test it first
#    timeToEpochTest($lc, '', );
    timeToEpochTest($lc, '1970-01-01 00:00:00+00', 0);
    timeToEpochTest($lc, '1970-01-01 00:00:00-06', 21600);
    timeToEpochTest($lc, '2009-03-07 17:53:28-06', 1236470008);
    timeToEpochTest($lc, '2009-03-07 23:53:28+00', 1236470008);
    timeToEpochTest($lc, '2009-03-08 01:23:28+01:30', 1236470008);
    timeToEpochTest($lc, '2009-03-08 01:23:28.1234+01:30', 1236470008);
    #the same tests in ISO-8601 format
    timeToEpochTest($lc, '1970-01-01T00:00:00+0000', 0);
    timeToEpochTest($lc, '1970-01-01T00:00:00-0600', 21600);
    timeToEpochTest($lc, '2009-03-07T17:53:28-0600', 1236470008);
    timeToEpochTest($lc, '2009-03-07T23:53:28+0000', 1236470008);
    timeToEpochTest($lc, '2009-03-08T01:23:28.1234+0130', 1236470008);
    #short formats
    timeToEpochTest($lc, 'now', time()); #this test might fail since it's not atomic
    timeToEpochTest($lc, '1979-10-12', timelocal(0, 0, 0, 12, 10-1, 79));
    timeToEpochTest($lc, '10-12-1979', timelocal(0, 0, 0, 12, 10-1, 79));
    timeToEpochTest($lc, '10/12/1979', timelocal(0, 0, 0, 12, 10-1, 79));
    #error
    timeToEpochTest($lc, 'BLAHBLAHBLAH', 0);
    #finally, fmt tests
    is($lc->nowFmt('longTimestamp'), strftime('%A, %B %e, %Y %l:%M%p', localtime()), "nowFmt('longTimestamp')");
    is($lc->nowFmt('longTime'), strftime('%l:%M%p', localtime()), "nowFmt('longTime')");
    is($lc->nowFmt('shortTimestamp'), strftime('%m-%d-%Y %l:%M%p', localtime()), "nowFmt('shortTimestamp')");
    is($lc->nowFmt('shortTime'), strftime('%l:%M%p', localtime()), "nowFmt('shortTime')");
    is($lc->nowFmt('longDate'), strftime('%A, %B %e, %Y', localtime()), "nowFmt('longDate')");
    is($lc->nowFmt('shortDate'), strftime('%m-%d-%Y', localtime()), "nowFmt('shortDate')");
    
    is($lc->temporalFmt('longTimestamp', 'now'), strftime('%A, %B %e, %Y %l:%M%p', localtime()), "temporalFmt('longTimestamp')");
    is($lc->temporalFmt('longTime', 'now'), strftime('%l:%M%p', localtime()), "temporalFmt('longTime')");
    is($lc->temporalFmt('shortTimestamp', 'now'), strftime('%m-%d-%Y %l:%M%p', localtime()), "temporalFmt('shortTimestamp')");
    is($lc->temporalFmt('shortTime', 'now'), strftime('%l:%M%p', localtime()), "temporalFmt('shortTime')");
    is($lc->temporalFmt('longDate', 'now'), strftime('%A, %B %e, %Y', localtime()), "temporalFmt('longDate')");
    is($lc->temporalFmt('shortDate', 'now'), strftime('%m-%d-%Y', localtime()), "temporalFmt('shortDate')");
}

#default locale test
{
    pass('default locale tests');
    $ENV{'LaneLang'} = 'c';
    $lc = Locale->new();
    isa_ok($lc, 'Locale', 'new locale object');

    is($lc->moneyFmt('1234567890'), '$12 345 678.90', "\tmoneyFmt() positive test");
    is($lc->moneyFmt('-9876543210'), '-$98 765 432.10', "\tmoneyFmt() negative test");
    is($lc->moneyFmt('0'), '$0.00', "\tmoneyFmt() neutral test");

    extFmtTest(2, $extFmtRange);

    is($lc->nowFmt('longTimestamp'), strftime('%d %B %Y %H:%M', localtime()), "nowFmt('longTimestamp')");
    is($lc->nowFmt('longTime'), strftime('%H:%M', localtime()), "nowFmt('longTime')");
    is($lc->nowFmt('shortTimestamp'), strftime('%Y-%m-%d %H:%M', localtime()), "nowFmt('shortTimestamp')");
    is($lc->nowFmt('shortTime'), strftime('%H:%M', localtime()), "nowFmt('shortTime')");
    is($lc->nowFmt('longDate'), strftime('%d %B %Y', localtime()), "nowFmt('longDate')");
    is($lc->nowFmt('shortDate'), strftime('%Y-%m-%d', localtime()), "nowFmt('shortDate')");

    is($lc->temporalFmt('longTimestamp', 'now'), strftime('%d %B %Y %H:%M', localtime()), "temporalFmt('longTimestamp')");
    is($lc->temporalFmt('longTime', 'now'), strftime('%H:%M', localtime()), "temporalFmt('longTime')");
    is($lc->temporalFmt('shortTimestamp', 'now'), strftime('%Y-%m-%d %H:%M', localtime()), "temporalFmt('shortTimestamp')");
    is($lc->temporalFmt('shortTime', 'now'), strftime('%H:%M', localtime()), "temporalFmt('shortTime')");
    is($lc->temporalFmt('longDate', 'now'), strftime('%d %B %Y', localtime()), "temporalFmt('longDate')");
    is($lc->temporalFmt('shortDate', 'now'), strftime('%Y-%m-%d', localtime()), "temporalFmt('shortDate')");
}

#multilocale tests
##################
{
    $ENV{'LaneLang'} = 'en-TESTOTHER,en-TEST';
    $lc = Locale->new();
    isa_ok($lc, 'Locale');
    is($lc->get('Simple String'), 'Other\'s Simple Strang', 'multi-locale simple db lookup');
    is($lc->get('Multi %0 Replacement %1 String %2', 'Zero', 'One', 'Two'), 'String One w/multiple Zero replacements Two', 'lookup with replacements, passed through to the more basal locale');

    extFmtTest(5, $extFmtRange * 100);

    is($lc->getOrDefault('This doesn\'t exist.', 'ABC'), 'ABC', 'getOrDefault() without a match');
    is($lc->getOrDefault('This doesn\'t exist either.', 'Here %0', 'D'), 'Here D', 'getOrDefault() without a match, with replacement text');
    is($lc->getOrDefault('Simple String', 'Other thing'), 'Other\'s Simple Strang', 'getOrDefault() with a match');
    is($lc->getOrDefault('Simple String2', 'Other %0 thing2', 'Zero'), 'Other\'s Strang Zero Samplah', 'getOrDefault() with a match');
    is($lc->getOrDefault('Simple String3', 'Other thing'), 'Strang Samplah3', 'getOrDefault() with a match');
    is($lc->getOrDefault('Simple String4', 'Other thing6', 'Zero'), 'Strang Zero Samplah4', 'getOrDefault() with a match');
    is($lc->getOrDefault('Multi %0 Replacement %1 String %2', '%0 %1 %2', 'Zero', 'One', 'Two'), 'String One w/multiple Zero replacements Two', 'getOrDefault() w/a match, w/replacements');
}

#named parameters test (bug 1382)
{
    is($lc->get('%{name}', 'name' => 'Jason', 'surname' => 'Burrell'), 'Jason', '%{name} form');
    is($lc->get('%{name(20)}', 'name' => 'Jason', 'surname' => 'Burrell'), '               Jason', '%{name(20)} form');
    is($lc->get('%{name(-20)}', 'name' => 'Jason', 'surname' => 'Burrell'), 'Jason               ', '%{name(-20)} form');
    is($lc->get('%{name(-20)} %{surname}', 'name' => 'Jason', 'surname' => 'Burrell'), 'Jason                Burrell', '%{name(-20)} %{surname} form');
    is($lc->get('%{name} %{surname} %{name}', 'name' => 'Jason', 'surname' => 'Burrell'), 'Jason Burrell Jason', '%{name} %{surname} %{name} form');
}

#getAllLike tests
{
    $ENV{'LaneLang'} = 'en-AU,en-CA,en-US,en-IE,en-IN,en-NZ,en-TEST,en-TESTOTHER,en-UK,en-ZA';
    $lc = Locale->new();
    pop @{$lc->{'lang'}}; #so we don't have to check all of the c locale stuff
    my %exp = (
	'Simple String4' => 'Strang %0 Samplah4',
	'Simple String' => 'Strang Samplah',
	'Lane/Locale/Temporal/LongDate' => '%A, %B %e, %Y',
	'Multi %0 Replacement %1 String %2' => 'String %1 w/multiple %0 replacements %2',
	'Lane/Locale/Money/Suffix' => '',
	'Lane/Locale/Money/DecimalSeparator' => '.',
	'Lane/Locale/Money/CurrencyCode' => 'AUD',
	'Lane/Locale/Money/Prefix' => '$',
	'Lane/Locale/Money/GroupingDigits' => '3',
	'Lane/Locale/Money/DecimalDigits' => '2',
	'Lane/Locale/Money/GroupingSeparator' => ' ',
	'Lane/Locale/Money/Negative/Suffix' => '',
	'Lane/Locale/Money/Negative/DecimalSeparator' => '.',
	'Lane/Locale/Money/Negative/Prefix' => '-$',
	'Lane/Locale/Money/Negative/GroupingDigits' => '3',
	'Lane/Locale/Money/Negative/GroupingSeparator' => ' ',
	'Lane/Locale/Temporal/ShortTimestamp' => '%m-%d-%Y %l:%M%p',
	'Lane/Locale/Temporal/LongTime' => '%l:%M%p',
	'locale-data-name' => 'English in Australia Locale',
	'Lane/Locale/Temporal/LongTimestamp' => '%A, %B %e, %Y %l:%M%p',
	'Simple String2' => 'Strang %0 Samplah',
	'Simple String3' => 'Strang Samplah3',
	'Lane/Locale/Temporal/ShortDate' => '%m-%d-%Y',
	'Lane/Locale/Temporal/ShortTime' => '%l:%M%p',
#	'locale-data-version' => '', #svn screws w/this one
	);
    my %r = $lc->getAllLike('');
    delete $r{'locale-data-version'};
    is_deeply(\%r, \%exp, 'getAllLike() returns the expected values');
}

sub timeToEpochTest
{
    my ($lc, $t, $expected) = @_;

    cmp_ok($lc->timeToEpoch($t), '==', $expected, "timeToEpoch($t) is $expected");
}

sub extFmtTest
{
    my ($dd, $high, $low) = @_;

    $low = -$high if !defined $low;

    my $mid;
    {
        use integer;
        $mid = $high / 2 + 1;
    }
    my $lowmid;
    {
        use integer;
        $lowmid = $low / 2 + 1;
    }

    for my $v ($low, $lowmid, 0, $mid, $high)
    {
        is($lc->extFmt($v), sprintf('%.' . $dd . 'f', $v / 10 ** $dd), "extFmt() w/$dd DecimalDigits, $v input")

    }
}
