#LanePOS Printer Driver v0.1
#Devices/Epson/TMU200.pm
#Copyright 2001-2010 Jason Burrell
#LanePOS, see $LaneROOT/documentation/README

#$Id: TMU200.pm 1133 2010-09-19 22:45:15Z jason $

=pod

=head1 NAME

LanePOS/Devices/Epson/TMU200.pm - Epson TM-U200 and related driver

=head1 SYNOPSIS

LanePOS::Devices::Epson::TMU200

=head1 DESCRIPTION

C<Devices::Epson::TMU200> provides support for devices attached to an Epson TM-U200 receipt printers, including cash drawers, pole displays, and the printer itself. It is a child of L<Devices::Epson::ESCPOS>. The TM-T200 is a common impact printer. Therefore, many impact (and impact-like) printers emulate it.

=head1 SUPPORTED OPTIONS/COMMANDS

=over

See L<Devices::Epson::ESCPOS>

=back

=head1 SUPPORTED HARDWARE

=over

=item Epson TM-U200

Impact printer, with and without a cutter, RS-232c interface tested

=item Samsung SRP-270

Impact printer; with and without a cutter; RS-232c, Parallel, and USB interfaces tested

=item Samsung SRP-500c

Inkjet printer, with a cutter, RS-232c and Parallel interfaces tested

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

package LanePOS::Devices::Epson::TMU200;

require 5.008;

use base 'LanePOS::Devices::Epson::ESCPOS';

sub new
{
    my $class = shift;

    my $me = $class->SUPER::new(@_);

    $me->{'type'} = 'Printer: Receipt';
    $me->{'make'} = 'Epson';
    $me->{'model'} = 'TM-U200';
    $me->{'revision'} = '1.0';
    $me->{'notes'} = 'Utilizes ESC/POS, Epson POS std codes';

    $me->{'prints'}{'receipt'} = '1';
    $me->{'prints'}{'endorsement'} = '0';
    $me->{'prints'}{'check'} = '0';
    $me->{'prints'}{'pole'} = '1';

    $me->{'columns'} = '40';
    $me->{'linesUntilSeen'} = 10;
    $me->{'codes'}{'ejectReceipt'} = "\n" x $me->{'linesUntilSeen'};

    bless $me, $class;
    $me->printThis($me->{'codes'}{'reset'} . $me->{'codes'}{'emphasizeOff'} . $me->{'codes'}{'justifyCenter'});
    return $me;
}

1;
