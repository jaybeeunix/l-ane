#LanePOS Cash Drawer Driver
#Devices/Ryotous/DirectDrawer.pm
#LanePOS, see $LaneROOT/documentation/README
#This file is part of L'ane. Copyright 2006 Jason B. Burrell.

#Copyright 2006-2010 Jason Burrell
#$Id: DirectDrawer.pm 1132 2010-09-19 21:36:50Z jason $

=pod

=head1 NAME

LanePOS/Devices/Ryotous/DirectDrawer.pm - a "printer" which only opens a drawer

=head1 SYNOPSIS

LanePOS::Devices::Ryotous::DirectDrawer

=head1 DESCRIPTION

C<Devices::Ryotous::DirectDrawer> provides a cash drawer interface to output simple drawers. 

=head1 USAGE

See L<Devices::GenericPrinter>

=head1 SUBROUTINES

=over

=item setDrawer1Kick(code)

Sets the kick code for drawer one to C<code>.

=item setDrawer2Kick(code)

Sets the kick code for drawer two to C<code>.

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

package LanePOS::Devices::Ryotous::DirectDrawer;

require 5.008;

use base 'LanePOS::Devices::GenericPrinter';

sub new
{
    my $class = shift;
    
    my $me = $class->SUPER::new(@_);
    
    $me->{'type'} = 'Drawer: Direct Drawer';
    $me->{'make'} = 'Jason Burrell Consulting / Ryotous.com';
    $me->{'model'} = 'N/A';
    $me->{'revision'} = '';
    $me->{'notes'} = 'This is a simple cash drawer interface';
    $me->{'prints'}{'receipt'} = 0;
    $me->{'prints'}{'endorsement'} = 0;
    $me->{'prints'}{'check'} = 0;
    $me->{'prints'}{'pole'} = 0;
    
    $me->{'codes'}{'drawer1Kick'} = "\ep";
    $me->{'codes'}{'drawer2Kick'} = "\ep";
    bless $me, $class;
    return $me;
}

sub setDrawer1Kick
{
    my ($me, $code) = @_;

    $me->{'codes'}{'drawer1Kick'} = $code;
}

sub setDrawer2Kick
{
    my ($me, $code) = @_;

    $me->{'codes'}{'drawer2Kick'} = $code;
}

1;
