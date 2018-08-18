#!/usr/bin/perl -w

#printer-tester.t
#Copyright 2004 Jason Burrell.
#This file is part of L'anePOS. See the top-level COPYING for licensing info.

#$Id: printer-tester.t 1040 2009-03-08 21:16:17Z jason $

#It takes the data from STDIN and prints it to STDOUT via the driver specified
#as the first arguement. Normally, one would use it like:
#
#   ./printer-tester.t Epson::TMT88 < my-test-file > /dev/lp0
#
#where "my-test-file" includes text and GenericPrinter-style markup and
#"/dev/lp0" is the device file where the printer is attached.

BEGIN {
    use FindBin;
    use File::Spec;
    $ENV{'LaneRoot'} = File::Spec->catdir($FindBin::Bin, File::Spec->updir); #use the correct number of updirs
    require File::Spec->catfile($ENV{'LaneRoot'}, 'config', 'init.pl');
}

if($#ARGV != 0)
{
    print STDERR "$0: usage: $0 Driver::Name\n";
    exit 0;
}

my $drv = 'LanePOS::Devices::' . $ARGV[0];

eval "require $drv;" or die "couldn't load the driver (eval says: $@)";
$drv =~ s/.*:://; #i really need to fix the package names of everything under LanePOS/
my $p = eval "$drv->new(*STDOUT);";
die "couldn't create a new instance of $drv (eval says: $@)" if !$p;
my $d;
$d .= $_ while(<STDIN>);
$p->printFormatted($d);
