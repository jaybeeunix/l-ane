#LanePOS Multiplexer Pseudo-Driver
#Devices/BurrellBizSys/Multiplexer.pm
#Copyright 2002-2010 Jason Burrell
#LanePOS, see $LaneROOT/documentation/README

#created by jason@BurrellBizSys.com 2002-01-29
#$Id: Multiplexer.pm 1133 2010-09-19 22:45:15Z jason $

#this basically calls the same method/values on multiple device objs

=pod

=head1 NAME

LanePOS/Devices/BurrellBizSys/Multiplexer.pm - multiplex object calls

=head1 SYNOPSIS

LanePOS::Devices::BurrellBizSys::Multiplexer

=head1 DESCRIPTION

C<Devices::BurrellBizSys::Multiplexer> multiplexes object calls to multiple objects. It is often used to connect multiple L'ane devices (think printers) to a single object (think C<Register>'s default printer).

=head1 USAGE

Typically, printer driver initialization is handled by L<LanePOS::Register>'s initMachine mechanism. Inside of that system, something along the lines of the following binds an IO::Handle to the printer driver:

=over

use LanePOS::Devices::Epson::ESCPOS

$printer0 = GenericPrinter->new($ioh1, $dal);

$printer1 = GenericPrinter->new($ioh2, $dal);

use LanePOS::Devices::BurrellBizSys::Multiplexer;

$printer = Multiplexer->new($printer0, $printer1);

=back

=head1 AUTHOR

Jason Burrell

=head1 BUGS

=over

=item *

This program contains no known bugs.

=back

=head1 SEE ALSO

L<Devices::GenericPrinter>, The L'E<acirc>ne Website L<http://l-ane.net/>

=cut


package LanePOS::Devices::BurrellBizSys::Multiplexer;

use base 'LanePOS::ProtoObject';

require 5.008;

sub new {
    my $class = shift;
    my $me = {
	'type' => 'Other: Multiplexer',
	'make' => 'Burrell Business Systems',
	'model' => 'N/A',
	'revision' => '',
	'notes' => 'This is a virtual device that calls the same method/value on multiple objects',
	'dev' => undef,
    };

    bless $me, $class;

    foreach my $i (@_)
    {
	push @{$me->{'dev'}}, $i;
    }

    return $me;
}

sub AUTOLOAD
{
    my ($me, @x) = @_;

    my $method = $AUTOLOAD;

    #ignore destroy
    return 0 if $AUTOLOAD =~ /Multiplexer::DESTROY/;

    #strip the package name off
    $AUTOLOAD =~ s/.*:://;

    foreach my $i (@{$me->{'dev'}})
    {
	eval { $i->$AUTOLOAD(@x); };
    }
    return 1;
}
