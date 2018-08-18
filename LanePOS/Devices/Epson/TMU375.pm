#LanePOS Printer Driver v0.1
#Devices/Epson/TMU375.pm
#Copyright 2001-2010 Jason Burrell
#LanePOS, see $LaneROOT/documentation/README

#$Id: TMU375.pm 1133 2010-09-19 22:45:15Z jason $

=pod

=head1 NAME

LanePOS/Devices/Epson/TMU375.pm - Epson TM-U375 and related driver

=head1 SYNOPSIS

LanePOS::Devices::Epson::TMU375

=head1 DESCRIPTION

C<Devices::Epson::TMU375> provides support for devices attached to an Epson TM-U375 receipt printers, including cash drawers, pole displays, and the printer itself. It is a child of L<Devices::Epson::ESCPOS>. The TM-T375 is a impact printer with slip support.

=head1 SUPPORTED OPTIONS/COMMANDS

=over

=item Paper Handling

Support for endorsing via the slip section of the printer

=item See L<Devices::Epson::ESCPOS>

=back

=head1 SUPPORTED HARDWARE

=over

=item Epson TM-U375

Impact printer, with slip support, RS-232c and Parallel interfaces tested

=back

=head1 AUTHOR

Jason Burrell

=head1 BUGS

=over

=item *

This program contains no known bugs.

=back

=head1 SEE ALSO

L<Devices::GenericPrinter>, L<Devices::Epson::ESCPOS>, The L'E<acirc>ne Website L<http://l-ane.net/>

=cut

package LanePOS::Devices::Epson::TMU375;

require 5.008;

use base 'LanePOS::Devices::Epson::ESCPOS';

sub new
{
    my $class = shift;

    my $me = $class->SUPER::new(@_);

    $me->{'type'} = 'Printer: Receipt w/Journal, Takeup, and Slip';
    $me->{'make'} = 'Epson';
    $me->{'model'} = 'TM-U375';
    $me->{'revision'} = '2.0';
    $me->{'notes'} = 'Utilizes ESC/POS, Epson POS std codes';

    $me->{'prints'}{'receipt'} = '1';
    $me->{'prints'}{'endorsement'} = '1';
    $me->{'prints'}{'check'} = '1';
    $me->{'prints'}{'pole'} = '1';

    $me->{'columns'} = '40';
    $me->{'linesUntilSeen'} = 9;
    $me->{'codes'}{'ejectReceipt'} = "\n" x $me->{'linesUntilSeen'};

    bless $me, $class;
    return $me;
}

1;
