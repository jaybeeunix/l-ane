#SysString.pm
#This file is part of L'ane. Copyright 2001-2010 Jason B. Burrell.
#See COPYING for licensing information.

#$Id: SysString.pm 1132 2010-09-19 21:36:50Z jason $

package LanePOS::SysString;

require 5.008;

use base 'LanePOS::String';
$::VERSION = (q$Revision: 1132 $ =~ /(\d+)/)[0];

sub new
{
    my ($class, $dal) = @_;
    $class = ref($class) || $class || 'LanePOS::SysString';
    my $me = $class->SUPER::new($dal);
    $me->{'table'} = 'sysstrings';
    return $me;
}

=pod

=head1 NAME

Lane::SysString - Configuration (System) Strings for L'ane

=head1 SYNOPSIS

SysString provides a method of storing configuration data and plugins in L'ane.

=head1 DESCRIPTION

String provides configuration strings and plugins for use in L'ane. These strings are typically configured once and only modified when some aspect of the system changes.

SysString inherits from L<String>. See L<String> for usage information.

=head1 AUTHOR

Jason Burrell
=head1 BUGS

=over

=item * 

This class hasn't been thoroughly tested.

=back

=cut

1;
