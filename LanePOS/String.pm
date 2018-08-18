#String.pm
#This file is part of L'ane. Copyright 2001-2010 Jason B. Burrell.
#See COPYING for licensing information.


#$Id: String.pm 1132 2010-09-19 21:36:50Z jason $

=pod

=head1 NAME

Lane::String - Message Strings for L'ane

=head1 SYNOPSIS

String provides a method of storing user-modifiable strings in the database.

=head1 DESCRIPTION

String provides user-modifiable strings for use in L'ane. These strings are typically used for information presented to the customer, like receipt headers.

=head2 CHILDREN

Only children with an external use are documented here.

C<'id'>

The identifier of the string. This item must be unique.

C<'data'>

The data string associated with C<'id'>.

=head2 FUNCTIONS

Only subroutines with an external use are documented here.

C<new([class,] dal)>

Creates a new String object, where C<'dal'> is a reference to a Dal object
Returns a reference to the String object if successful or false if failed.

=cut

package LanePOS::String;
require 5.008;
use base 'LanePOS::GenericObject';
$::VERSION = (q$Revision: 1132 $ =~ /(\d+)/)[0];

sub new
{
    my ($class, $dal) = @_;
    $class = ref($class) || $class || 'LanePOS::String';
    my $me = $class->SUPER::new($dal);
    
    $me->{'table'} = 'strings';
    $me->{'columns'} = [
        'id',
        'data',
        'voidAt',
        'voidBy',
        'created',
        'createdBy',
        'modified',
        'modifiedBy',
        ];
    $me->{'keys'} = ['id'];
    $me->{'revisioned'} = 1;
    $me->{'hideVoidFromOpen'} = 1;
    return $me;
}

=pod

C<open(id)>

Populates the String object with the data for the String C<'id'> if successful, or false if String was unable to open the String.

C<save()>

Saves the String object to the database, returning true if successful or false if String was unable to save the string.

C<remove()>

Removes the String from the database, returning true if successful or false if String was unable to remove the String.

C<getTree(s,...)>

Returns an array (suitable for creating a hash) of all of the elements in the database "tree" whose keys begin with the strings C<s, ...>. It does not return objects and is typically used to return configuration parameters

=cut

sub getTree
{
    my ($me, $id) = @_;

    return $me->SUPER::getTree([qw/id data/], $id);
}

=pod

=head1 AUTHOR

Jason Burrell

=head1 BUGS

=over

=item * 

This was/is the first class to switch to the new style setup, so bugs are likely to appear here first.

=back

=cut

1;
