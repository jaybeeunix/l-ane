#select.pm
#This file is part of L'ane. Copyright 2009-2010 Jason B. Burrell.
#See COPYING for licensing information.

#$Id: select.pm 1132 2010-09-19 21:36:50Z jason $

=pod

=head1 NAME

Lane::Dal::select - select helper class for Dal

=head1 SYNOPSIS

C<$dal-E<gt>select(what => ['a', 'b'], from => ['tbl'], where => [[qw/a = b/], 'and', ['a', 'is not null']])->do();>

=head1 DESCRIPTION

C<select> is a Dal Helper which provides a select SQL statement builder for Dal which is autoloaded when called.

=head2 FUNCTIONS

Only subroutines with an external use are documented here.

C<new(dal, opts...)>

Creates a new select object and returns a reference to the object. The method is typically automatically called by Dal

=head3 Options

L</new> accepts hash-like (key => value) options to describe the query.

=over

=item distinct

A boolean which enables the DISTINCT operation

=item what

An array ref of items which are selected.

=item from

An array ref of items FROM which the query is selected.

=item where

An array ref of items where each element represents a conjuction or an array ref representing a condition (the SQL WHERE clause).

=item groupBy

An array ref of items which the query uses for GROUP BY.

=item having

Passed through as a HAVING clause.

=item orderBy

An array ref of items which the query is ORDERED BY. Prepending an item with C<-> makes it a DESC order.

=item limit

A LIMIT number

=item offset

An OFFSET number

=back

C<sqlString>

Returns the SQL string based on the data input via L</new>

C<do>

Executes the SQL query described by the options passed to L</new> in the current transaction.

=head1 AUTHOR

Jason Burrell

=head1 BUGS

=over

=item * 

While not really a bug, it doesn't really do anything special with the L</what> or L</having> input.

=back

=cut

#use Data::Dumper;

package LanePOS::Dal::select;

require 5.008;

$::VERSION = (q$Revision: 1132 $ =~ /(\d+)/)[0];

use base 'LanePOS::Dal::Helper';

sub new
{
    my ($class, $dal, %opts) = @_;

    $class = ref($class) || $class || 'LanePOS::Dal::select';
    my $me = $class->SUPER::new($dal, %opts);

#    %opts = (
#        'distinct' => 0, #the default
#        'what' => ['a', 'b'],
#        'from' => ['tbl1'],
#        'where' => [[qw/a > b/], 'and', ['a', 'is not null']],
#        'groupBy' => ['c'],
#        'having' => [],
#        #joins go here
#        'orderBy' => ['-a', 'b'],
#        'limit' => 20,
#        'offset' => 1,
#        );
    #warn "select::new(): ", Dumper($me);
    return $me;
}

sub do
{
    my ($me) = @_;

    return $me->{'dal'}->do($me->sqlString);
}

sub sqlString
{
    my ($me) = @_;

    $me->validate;

    my $s = 'SELECT ';
    $s .= 'DISTINCT ' if exists $me->{'distinct'} and $me->{'distinct'};
    my @tmpW;
    foreach my $w (@{$me->{'what'}})
    {
        if(UNIVERSAL::isa($w, 'ARRAY'))
        {
            push @tmpW, @$w;
        }
        elsif (UNIVERSAL::isa($w, 'SCALAR'))
        {
            push @tmpW, $$w;
        }
        else
        {
            push @tmpW, scalar($w);
        }
    }
    $s .= join(', ', @tmpW);
    
    $s .= "\n\tFROM " . join(', ', @{$me->{'from'}}) if exists $me->{'from'} and UNIVERSAL::isa($me->{'from'}, 'ARRAY') and $#{$me->{'from'}} >= 0;
    if(exists $me->{'where'} and UNIVERSAL::isa($me->{'where'}, 'ARRAY') and $#{$me->{'where'}} >= 0)
    {
        #subject, verb, object
        $s .= "\n\tWHERE ";
        #we're punting on this for the moment
        foreach my $w (@{$me->{'where'}})
        {
            if(UNIVERSAL::isa($w, 'ARRAY'))
            {
                $s .= join(' ', @$w) . ' ';
            }
            elsif (UNIVERSAL::isa($w, 'SCALAR'))
            {
                $s .= $$w . ' ';
            }
            else
            {
                $s .= scalar($w) . ' ';
            }
        }
    }
    $s .= "\n\tGROUP BY " . join(', ', @{$me->{'groupBy'}}) if exists $me->{'groupBy'} and UNIVERSAL::isa($me->{'groupBy'}, 'ARRAY') and $#{$me->{'groupBy'}} >= 0;
    $s .= "\n\tHAVING " . join(', ', @{$me->{'having'}}) if exists $me->{'having'} and UNIVERSAL::isa($me->{'having'}, 'ARRAY') and $#{$me->{'having'}} >= 0;
    if(exists $me->{'orderBy'} and UNIVERSAL::isa($me->{'orderBy'}, 'ARRAY') and $#{$me->{'orderBy'}} >= 0)
    {
        $s .= "\n\tORDER BY ";
        my @order;
        foreach my $e (@{$me->{'orderBy'}})
        {
            my $nme;
            my $direction = ''; #ascending is default
            $direction = ' DESC' if ($nme) = $e =~ /^-(.*)/;
            $nme ||= $e;
            push @order, "$nme$direction";
        }
        $s .= join(', ', @order);
    }
    $s .= "\n\tLIMIT " . scalar($me->{'limit'}) if exists $me->{'limit'} and scalar($me->{'limit'}) and scalar($me->{'limit'}) ne '';
    $s .= "\n\tOFFSET " . scalar($me->{'offset'}) if exists $me->{'offset'} and scalar($me->{'offset'}) and scalar($me->{'offset'}) ne '';

    #warn "$s\n";
    return $s;
}

sub validate
{
    my ($me) = @_;

    #warn "validate: ", Dumper($me);

    my $dieString = 'LanePOS::Dal::select::validate';

    #all selects need a what
    die "$dieString: Your object doesn't pass validation! exists \n" if !exists $me->{'what'};
    die "$dieString: Your object doesn't pass validation! array\n" if ref($me->{'what'}) ne 'ARRAY';
    die "$dieString: Your object doesn't pass validation! elements\n" if $#{$me->{'what'}} < 0;
    
    return 1;
}

1;
