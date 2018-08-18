#!/usr/bin/perl -w

#prog-00register.t
#Register test suite
#Copyright 2008-2010 Jason Burrell.
#This file is part of L'ane. See COPYING for licensing information.

BEGIN {
    use FindBin;
    use File::Spec;
    $ENV{'LaneRoot'} = File::Spec->catdir($FindBin::Bin, File::Spec->updir); #use the correct number of updirs
    require File::Spec->catfile($ENV{'LaneRoot'}, 'config', 'init.pl');
}

#IDEALLY the individual modules should be able to specify how many subtests they'll run,
#but Test::More doesn't allow multiple loads
use Test::More 'no_plan';
use Test::File::Contents;

use Data::Dumper;
use Sys::Hostname ();
use File::Path 'rmtree';

use LanePOS::Dal;
use LanePOS::Sale;
our $sale = Sale->new;

my $gui = 0;

sub lastSale
{
    my ($cust) = @_;
    $cust = '' if !$cust;
    #returns the last sale id, so don't use this if more than one thing is accessing your sales table
    my $id = ($sale->getByCust($cust))[-1];
    #warn("lastSale = $id\n");
    return $id;
}

sub getUsername
{
    my ($id) = @_;
    #make a new connection -- sometimes it gets odd on us
    my $u = Dal->new()->getUsername;
    $u =~ s/([^@]+)(\@.+)/$1+$id$2/;
    return $u
}

sub checkFld
{
    my ($fld, $val, $numeric) = @_;

    if(!$numeric)
    {
        is($sale->{$fld}, $val, "the $fld is as expected");
    }
    else
    {
        cmp_ok($sale->{$fld}, '==', $val, "the $fld is as expected");
    }
}

sub checkSubFld
{
    my ($part, $n, $fld, $val, $numeric) = @_;

    if(!defined $numeric)
    {
        is($sale->{$part}[$n]{$fld}, $val, "the $part->$n->$fld is as expected");
    }
    else
    {
        if($numeric eq 'deeply')
        {
            is_deeply($sale->{$part}[$n]{$fld}, $val, "the $part->$n->$fld is as expected (deeply)");
        }
        else
        {
            cmp_ok($sale->{$part}[$n]{$fld}, '==', $val, "the $part->$n->$fld is as expected");
        }
    }
}

sub runRegister
{
    my ($file, $tmpDir) = @_;

    my @run;
    if($gui)
    {
        @run = (File::Spec->catfile($ENV{'LaneRoot'}, 'tests', 'cmd-to-xte'), $file);
    }
    else
    {
        @run = (File::Spec->catfile($ENV{'LaneRoot'}, 'register', 'tester', 'registerTester'), '--quiet', '-i', $file);
    }
    my @devs = qw/printer printer2 pole/;
    my $devFiles;
    if($tmpDir)
    {
	foreach my $d (@devs)
	{
	    $file =~ s{(.*/)([^/]+)$}{$2};
	    $devFiles{$d} = File::Spec->catfile($tmpDir, "$file-$d");
	    push @run, "--dev-$d=" . $devFiles{$d};
	    if($d eq 'pole')
	    {
		push @run, "--drv-$d=BurrellBizSys::TextInserterPole";
	    }
	    #registerTester defaults to Ryotous::MarkupPass for everything
	}
    }

    system(@run);
    my $rtn = $?;

    if($rtn == -1)
    {
        return 0;
    }

    #test the device outputs
    if($tmpDir)
    {
        foreach my $o (@devs)
        {
            #genericize the output
            system('perl', '-pi', '-we', 's/(Ticket:?\s+)(\d+)/$1ticketNo/g;', $devFiles{$o});
            system('perl', '-pi', '-we', 's/\d{2}-\d{2}-\d{4}(\s+\d{1,2}:\d{2}[AP]M)?/now/g;', $devFiles{$o});
            
            my $basename = $devFiles{$o};
	$basename =~ s{(.*/)([^/]+)$}{$2};
            file_contents_identical($devFiles{$o}, "$ENV{'LaneRoot'}/tests/register-device-output/$basename", "$basename comparison");
        }
    }

    return ($rtn >> 8 ) == 0 ? 1 : 0;
}

#lastSale();

#allow us to specify the tests to run on the cmd line
my @tests;
if($#ARGV > -1)
{
    foreach my $file (@ARGV)
    {
        push @tests, $file if -e $file;
    }
}
$gui = 1 if exists $ENV{'LaneTestDisplay'} and $ENV{'LaneTestDisplay'};
#setup the receipt output test dir, but don't use them w/gui tests
my $tmpDir;
if(!$gui)
{
    $tmpDir = File::Spec->catfile(File::Spec->tmpdir(), 'l-ane-prog-00register.t-receipts-' . time);
    mkdir $tmpDir or $tmpDir = undef;
}

@tests = <register/*.cmd> if $#tests == -1;
foreach my $t (@tests)
{
    #warn "trying $t...\n";
    runRegister($t, $tmpDir) or die "the cmd script $t failed";
    $t =~ s/\.cmd$/\.pl/;
    require $t if(-r $t and -s $t);
}

#cleanup my temp files
if($tmpDir)
{
    rmtree($tmpDir) or die "couldn't clean up!";
}
