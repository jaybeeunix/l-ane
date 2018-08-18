#LanePOS Printer Driver v0.1
#Devices/Epson/TMT88.pm
#Copyright 2001-2010 Jason Burrell
#LanePOS, see $LaneROOT/documentation/README

#$Id: TMT88.pm 1132 2010-09-19 21:36:50Z jason $

=pod

=head1 NAME

LanePOS/Devices/Epson/TMT88.pm - Epson TM-T88 and related driver

=head1 SYNOPSIS

LanePOS::Devices::Epson::TMT88

=head1 DESCRIPTION

C<Devices::Epson::TMU200> provides support for devices attached to an Epson TM-T88 receipt printers, including cash drawers, pole displays, and the printer itself. It is a child of L<Devices::Epson::ESCPOS>. The TM-T88 family (it spans multiple generations) is a common thermal printer family.

=head1 SUPPORTED OPTIONS/COMMANDS

=over

See L<Devices::Epson::ESCPOS>

=back

=head1 SUPPORTED HARDWARE

=over

=item Epson TM-T88 (multiple generations)

Thermal printer, with a cutter, RS-232c interface tested

=item Samsung SRP-350

Thermal printer, with a cutter, RS-232c, Parallel, and USB interfaces tested

=back

=head1 AUTHOR

Jason Burrell

=head1 BUGS

=over

=item *

This program contains no known bugs.

=back

=head1 SEE ALSO

L<Devices::Epson::ESCPOS>, The L'E<acirc>ne Website L<http://l-ane.net/>

=cut

package LanePOS::Devices::Epson::TMT88;

require 5.008;

use base 'LanePOS::Devices::Epson::ESCPOS';

sub new
{
    my $class = shift;

    my $me = $class->SUPER::new(@_);

    $me->{'type'} = 'Printer: Thermal Receipt';
    $me->{'make'} = 'Epson';
    $me->{'model'} = 'TM-T88';
    $me->{'revision'} = '1.0';
    $me->{'notes'} = 'Utilizes ESC/POS, Epson POS std codes';

    $me->{'prints'}{'receipt'} = '1';
    $me->{'prints'}{'endorsement'} = '0';
#    $me->{'prints'}{'check'} = '0';
#    $me->{'prints'}{'pole'} = '1';

    $me->{'columns'} = '40';
    $me->{'linesUntilSeen'} = 9;
    $me->{'codes'}{'graphicsBlockHeight'} = 24;
    $me->{'codes'}{'cut'} = "\x1dV0\n";
    $me->{'codes'}{'ejectReceipt'} = "\n" x $me->{'linesUntilSeen'};

    #use the larger font by default on the tmt88
    $me->{'codes'}{'emphasizeOn'} = "\e!\x20";
    $me->{'codes'}{'emphasizeOff'} = "\e!\x0";

    bless $me, $class;
    $me->printThis($me->{'codes'}{'reset'} . $me->{'codes'}{'emphasizeOff'} . $me->{'codes'}{'justifyCenter'});
    return $me;
}

1;
