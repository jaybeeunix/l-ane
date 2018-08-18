#Tax.pm
#Copyright 2002-2010 Jason Burrell.
#This file is part of LanePOS. See COPYING for licensing information.
#LanePOS see $LaneROOT/documentation/README
#$Id: Tax.pm 1132 2010-09-19 21:36:50Z jason $

package LanePOS::Tax;

require 5.008;

use base 'LanePOS::GenericObject';

sub new
{
    my ($class, $dal) = @_;
    $class = ref($class) || $class || 'LanePOS::Tax';
    my $me = $class->SUPER::new($dal);
    
    $me->{'table'} = 'taxes';
    $me->{'columns'} = [
        'id',
        'descr',
        'amount',
        'voidAt',
        'voidBy',
        'created',
        'createdBy',
        'modified',
        'modifiedBy',
        ];
    $me->{'keys'} = ['id'];
    $me->{'revisioned'} = 1;

    #this is a constant which allows for 16 tax rates
    #if you need more, you'll need to make changes to the db schema
    $me->{'allTaxMask'} = 32767;

    return $me;
}

sub applyTax
{			# for rounding to work, call with the total
			# of each tax rate, NOT the amt of each item
    my ($me, $amt) = @_;

    #to fix a warning
    $amt = 0 if !defined $amt;

    my $r;
    eval {
        #the following has 100 as the tax is expressed as a percent
        $me->{'dal'}->do("select (" . $me->{'dal'}->qt($amt) . "::numeric(15,0) * " . $me->{'dal'}->qt($me->{'amount'}) . " / 100)::numeric(15,0)");
        ($r) = $me->{'dal'}->fetchrow if $me->{'dal'}->{'tuples'} > 0;
    };
    if($@)
    {
        warn "Tax::applyTax() caught an exception! ($@)\n";
    }
    return $r;
}

sub applyTaxManually
{
    my ($me, $amt, $rate) = @_;

    #to fix a warning
    $amt = 0 if !defined $amt;

    my $r;

    eval {
        $me->{'dal'}->do("select (" . $me->{'dal'}->qt($amt) . "::numeric(15,0) * " . $me->{'dal'}->qt($rate) . " / 100)::numeric(15,0)");
        ($r) = $me->{'dal'}->fetchrow if $me->{'dal'}->{'tuples'} > 0;
    };
    if($@)
    {
        warn "Tax::applyTaxManually() caught an exception! ($@)\n";
    }
    return $r;
}

sub getAllTaxes
{
    my ($me) = @_;

    my @rtn;

    eval {
        $me->{'dal'}->do('select id, descr, amount from taxes where voidAt is null order by id');

        foreach (1..$me->{'dal'}->{'tuples'})
        {
            my %t;
            ($t{'id'}, $t{'descr'}, $t{'amount'}) = $me->{'dal'}->fetchrow();
            push @rtn, \%t;
        }
    };
    if($@)
    {
        warn "Tax::getAllTaxes() caught an exception! ($@)\n";
    }
    return @rtn;
}


sub getAllRates
{
    my ($me) = @_;

    my @rtn;
    eval {
        $me->{'dal'}->do('select amount from taxes where voidAt is null order by id');

        foreach (1..$me->{'dal'}->{'tuples'})
        {
            push @rtn, ($me->{'dal'}->fetchrow)[0];
        }
    };
    if($@)
    {
        warn "Tax::getAllRates() caught an exception! ($@)\n";
    }
    return @rtn;
}

sub getAllDescr
{
    my ($me) = @_;

    my @rtn;

    eval {
        $me->{'dal'}->do('select descr from taxes where voidAt is null order by id');

        foreach (1..$me->{'dal'}->{'tuples'})
        {
            push @rtn, ($me->{'dal'}->fetchrow)[0];
        }
    };
    if($@)
    {
        warn "Tax::getAllDescr() caught an exception! ($@)\n";
    }
    return @rtn;
}

1;
