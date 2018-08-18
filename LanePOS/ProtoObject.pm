#ProtoObject.pm
#This file is part of L'ane. Copyright 2010 Jason B. Burrell.
#See COPYING for licensing information.

#$Id: ProtoObject.pm 1193 2010-10-22 21:10:11Z jason $

=pod

=head1 NAME

LanePOS::ProtoObject - pre-Basic Object Class for L'ane

=head1 SYNOPSIS

ProtoObject provides basic, non-dataset object primatives

=head1 DESCRIPTION

ProtoObject provides a generic ancestor class the implements the common object operations which do not use the database

=head2 FUNCTIONS

Only subroutines with an external use are documented here.

C<import>

Creates the traditional "short" names. For example, LanePOS::Register becomes Register.

C<shortname[(val)]>

If called with an argument, sets C<$me-E<gt>{shortname}> to that value. Returns the value of C<$me-E<gt>{shortname}>

=head1 AUTHOR

Jason Burrell

=head1 BUGS

=over

=item *

No known bugs.

=back

=cut

package LanePOS::ProtoObject;
require 5.008;
$::VERSION = (q$Revision: 1193 $ =~ /(\d+)/)[0];

sub import
{
    my ($me) = @_;

    #warn "ProtoObject->import($me) starting\n";
    return 0 if ref($me);
    #my $caller = (caller)[0];
    #force our way into caller's namespace
    my $ima = $me;
    #get the short version
    $ima =~ s/.*:://;
    #warn "ProtoObject->import($me) trying main::" . "$ima" . ':: and ' . "$me" . '::' . "\n";
    #*{"$caller" . '::' . "$ima" . '::'} = *{"$me" . '::'};
    *{"main" . '::' . "$ima" . '::'} = *{"$me" . '::'};
}

sub can
{
    my ($me, $method) = @_;

    my @src = keys %{$me};
    push @src, @{$me->{'columns'}} if exists $me->{'columns'} and UNIVERSAL::isa($me->{'columns'}, 'ARRAY');
    foreach my $k (@src)
    {
	return 1 if $method eq $k;
    }
    return $me->SUPER::can($method);
}

sub AUTOLOAD
{
    my ($me, @x) = @_;

    my $method = $AUTOLOAD;
    $method =~ s/.*:://;

    #ignore destroy
    return 0 if $AUTOLOAD =~ /::DESTROY/;

    die "ProtoObject::AUTOLOAD: (" . ref($me) . ") I don't know what $method is!\n" if !exists $me->{$method};
    if($#x == 0)
    {
	$me->{$method} = $x[0];
    }
    return $me->{$method};
}

1;
