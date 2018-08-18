#LanePOS Virtual Pole Display/Text Inserter Driver
#Devices/BurrellBizSys/TextInserterPole.pm
#LanePOS, see $LaneROOT/documentation/README
#Copyright 2002-2010 Jason Burrell

#created by jason@BurrellBizSys.com 2002-01-29
#$Id: TextInserterPole.pm 1134 2010-09-20 00:48:38Z jason $

#this basically echos out the pole stuff to the device, it was originally designed for text
#inserters (devices that print what a clerk is ringing on a security video tape)
#BurrellBizSys has a customer that uses those

=pod

=head1 NAME

LanePOS/Devices/BurrellBizSys/TextInserterPole.pm - output pole display information in a generic, text-only format

=head1 SYNOPSIS

LanePOS::Devices::BurrellBizSys::TextInserterPole

=head1 DESCRIPTION

C<Devices::BurrellBizSys::TextInserterPole> provides a pole display interface to output generic, text-only output. It is often used by video monitoring text-inserters (hence the name) with L<Devices::BurrellBizSys::Multiplexer>.

=head1 USAGE

See L<Devices::BurrellBizSys::Multiplexer>

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

package LanePOS::Devices::BurrellBizSys::TextInserterPole;

require 5.008;

use base 'LanePOS::Devices::GenericPrinter';

sub new
{
    my $class = shift;

    my $me = $class->SUPER::new(@_);

    $me->{'type'} = 'Pole: TextInserterPole';
    $me->{'make'} = 'Burrell Business Systems';
    $me->{'model'} = 'N/A';
    $me->{'revision'} = '';
    $me->{'notes'} = 'This is a virtual pole display/text inserter';
    $me->{'prints'}{'receipt'} = 0;
    $me->{'prints'}{'endorsement'} = 0;
    $me->{'prints'}{'check'} = 0;
    $me->{'prints'}{'pole'} = 1;

    bless $me, $class;
    return $me;
}

1;
