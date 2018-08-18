#LanePOS Generic Printer Driver v0.2
#Devices/Ryotous/MarkupPass.pm
#LanePOS, see $LaneROOT/documentation/README

#Copyright 2004-2010 Jason Burrell
#$Id: MarkupPass.pm 1190 2010-10-22 19:27:02Z jason $

=pod

=head1 NAME

LanePOS/Devices/Ryotous/MarkupPass.pm - pass the printer-independant markup through

=head1 SYNOPSIS

LanePOS::Devices::Ryotous::MarkupPass

=head1 DESCRIPTION

C<Devices::Ryotous::MarkupPass> provides a pseudo-printer (see L<Devices::GenericPrinter>) that passes the markup through to its L<IO::Handle>. The printer tester program can convert this output back into a printer-specific format (see L</SEE ALSO>).

=head1 AUTHOR

Jason Burrell

=head1 BUGS

=over

=item *

This program contains no known bugs.

=back

=head1 SEE ALSO

The printer tester program: C<$LaneRoot/tests/printer-tester.t>, L<Devices::GenericPrinter>, The L'E<acirc>ne Website L<http://l-ane.net/>

=cut

package LanePOS::Devices::Ryotous::MarkupPass;

require 5.008;

use base 'LanePOS::Devices::GenericPrinter';

sub new
{
    my $class = shift;

    my $me = $class->SUPER::new(@_);

    $me->{'type'} = 'Printer: Pseudo-Printer';
    $me->{'make'} = 'Ryotous';
    $me->{'model'} = 'Markup Passthrough';
    $me->{'revision'} = '0.1';
    $me->{'notes'} = 'Passes the mlToprinter markup through as markup';

    $me->{'prints'}{'receipt'} = '1';
    $me->{'prints'}{'graphics'} = '1';

    $me->{'columns'} = '40';
    $me->{'linesUntilSeen'} = 9;

    #let's turn off any funky layers, so the euro can pass through
    eval { binmode($me->{'dev'}, ':raw'); };
    $me->{'codes'}{'euro'} = "\xa4";

    $me->{'codes'}->{'black'} = '<black>';
    $me->{'codes'}->{'red'} = '<red>';
    $me->{'codes'}->{'emphasizeOn'} = '<b>';
    $me->{'codes'}->{'emphasizeOff'} = '</b>';
    $me->{'codes'}->{'justifyLeft'} = '<left>';
    $me->{'codes'}->{'justifyCenter'} = '<center>';
    $me->{'codes'}->{'justifyRight'} = '<right>';
    $me->{'codes'}->{'justifyLeftOff'} = '</left>';
    $me->{'codes'}->{'justifyCenterOff'} = '</center>';
    $me->{'codes'}->{'justifyRightOff'} = '</right>';

    bless $me, $class;
    return $me;
}

sub mlToPrinter
{
    return $_[1];
}

sub formatGraphic
{
    my ($me, $img, $geo) = @_;

    return "<img geometry='$geo'>\n$img\n</img>";
}

1;
