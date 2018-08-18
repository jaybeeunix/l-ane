#getUsername.pm
#This file is part of L'ane. Copyright 2010 Jason B. Burrell.
#See COPYING for licensing information.

#$Id: getUsername.pm 1132 2010-09-19 21:36:50Z jason $

=pod

=head1 NAME

Lane::Dal::getUsername - getUsername helper class for Dal

=head1 SYNOPSIS

C<$dal-E<gt>getUsernamedo();>

=head1 DESCRIPTION

C<getUsername> is a Dal Helper which provides the current user's database name.

=head2 FUNCTIONS

Only subroutines with an external use are documented here.

C<new(dal)>

Queries the database and returns the current database username. This method is typically automatically called by Dal.

=head1 AUTHOR

Jason Burrell

=cut

#use Data::Dumper;

package LanePOS::Dal::getUsername;

require 5.008;
$::VERSION = (q$Revision: 1132 $ =~ /(\d+)/)[0];

use base 'LanePOS::Dal::Helper';

sub new
{
    my ($class, $dal, %opts) = @_;

    $class = ref($class) || $class || 'LanePOS::Dal::getUsername';
    my $me = $class->SUPER::new($dal, %opts);

    #warn "select::new(): ", Dumper($me);
    $me->{'dal'}->do('select laneusername()');
    return ($me->{'dal'}->fetchrow)[0];
}

1;
