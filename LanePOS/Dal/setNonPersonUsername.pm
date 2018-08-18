#setNonPersonUsername.pm
#This file is part of L'ane. Copyright 2010 Jason B. Burrell.
#See COPYING for licensing information.

#$Id: setNonPersonUsername.pm 1132 2010-09-19 21:36:50Z jason $

=pod

=head1 NAME

Lane::Dal::setNonPersonUsername - setNonPersonUsername helper class for Dal

=head1 SYNOPSIS

C<$dal-E<gt>setNonPersonUsernamedo();>

=head1 DESCRIPTION

C<setNonPersonUsername> is a Dal Helper which sets the current user's extended database name.

=head2 FUNCTIONS

Only subroutines with an external use are documented here.

C<new(dal)>

Sets the extended username when non-persons are modifying the database. This method is typically automatically called by Dal.

=head1 AUTHOR

Jason Burrell

=cut

#use Data::Dumper;

package LanePOS::Dal::setNonPersonUsername;

require 5.008;
$::VERSION = (q$Revision: 1132 $ =~ /(\d+)/)[0];

use base 'LanePOS::Dal::Helper';

sub new
{
    my ($class, $dal, $user) = @_;

    $class = ref($class) || $class || 'LanePOS::Dal::setNonPersonUsername';
    my $me = $class->SUPER::new($dal);

    #warn "select::new(): ", Dumper($me);
    $me->{'dal'}->do('select setNonPersonUsername(' . $me->{'dal'}->qtAs($user, 'text') . ');');
    return ($me->{'dal'}->fetchrow)[0];
}

1;
