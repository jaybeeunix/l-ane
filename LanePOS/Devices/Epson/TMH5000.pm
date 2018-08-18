#LanePOS Printer Driver v0.1
#Devices/Epson/TMH5000.pm
#Copyright 2001-2010 Jason Burrell
#LanePOS, see $LaneROOT/documentation/README

#$Id: TMH5000.pm 1133 2010-09-19 22:45:15Z jason $

=pod

=head1 NAME

LanePOS/Devices/Epson/TMH5000.pm - Epson TM-H5000 and related driver

=head1 SYNOPSIS

LanePOS::Devices::Epson::TMH5000

=head1 DESCRIPTION

C<Devices::Epson::TMH5000> provides support for devices attached to an Epson TM-T88 receipt printers, including cash drawers, pole displays, and the printers themselves. It is a child of L<Devices::Epson::TMT88>. The TM-H5000 family contains a TM-T88-like printer on top of an A4 width (well, nearly) impact printer.

=head1 SUPPORTED OPTIONS/COMMANDS

=over

=item Paper Handling

Support for endorsing via the slip section of the printer

=item See L<Devices::Epson::TMT88>

=back

=head1 SUPPORTED HARDWARE

=over

=item Epson TM-H5000

Thermal printer with a cutter and impact slip, RS-232c interface tested

=back

=head1 AUTHOR

Jason Burrell

=head1 BUGS

=over

=item *

This program contains no known bugs.

=back

=head1 SEE ALSO

L<Devices::GenericPrinter>, L<Devices::Epson::TMT88>, The L'E<acirc>ne Website L<http://l-ane.net/>

=cut

package LanePOS::Devices::Epson::TMH5000;

require 5.008;

use base 'LanePOS::Devices::Epson::TMT88';

sub new
{
    my $class = shift;

    my $me = $class->SUPER::new(@_);

    $me->{'type'} = 'Printer: Thermal Receipt with Slip';
    $me->{'make'} = 'Epson';
    $me->{'model'} = 'TM-H5000';
    $me->{'revision'} = '0.1';
    $me->{'notes'} = 'Utilizes ESC/POS, Epson POS std codes';

    $me->{'prints'}{'receipt'} = '1';
    $me->{'prints'}{'endorsement'} = '1';
    $me->{'prints'}{'check'} = '1';
    $me->{'prints'}{'pole'} = '1';

    $me->{'columns'} = '40';
    $me->{'linesUntilSeen'} = 9;
    $me->{'codes'}{'srcSlip'} .= "\ee\x03"; #this printer prints too far down, reverse feed a few lines before printing
    $me->{'codes'}{'ejectReceipt'} = "\n" x $me->{'linesUntilSeen'};
    $me->{'codes'}{'emphasizeOn-thermal'} = $me->{'codes'}{'emphasizeOn'}; #since we're a tmt88 child
    $me->{'codes'}{'emphasizeOff-thermal'} = $me->{'codes'}{'emphasizeOff'};#see above
    $me->{'codes'}{'emphasizeOn-slip'} = "\e!\x21";
    $me->{'codes'}{'emphasizeOff-slip'} = "\e!\x01";

    bless $me, $class;
    return $me;
}

#we need to override endorse
sub endorse
{
    my ($me, $e) = @_;
    #we need to switch the font to the standard size print for the slip
    $me->{'codes'}{'emphasizeOn'} = $me->{'codes'}{'emphasizeOn-slip'};
    $me->{'codes'}{'emphasizeOff'} = $me->{'codes'}{'emphasizeOff-slip'};
    #also, set the left margin in and set the 
    $me->{'codes'}{'srcSlip'} .= "\x1dL\xef\x01"; #set the left margin in a bit
    $me->{'codes'}{'ejectSlip'} .= "\x1dL\0\0"; #clear the left margin set by the slip
    my $r = $me->SUPER::endorse($e);
    #switch them back
    $me->{'codes'}{'emphasizeOn'} = $me->{'codes'}{'emphasizeOn-thermal'};
    $me->{'codes'}{'emphasizeOff'} = $me->{'codes'}{'emphasizeOff-thermal'};
    return 1;
}
1;
