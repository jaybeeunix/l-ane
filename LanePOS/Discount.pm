#Discount.pm
#LanePOS
#Copyright 2001-2010 Jason Burrell

#$Id: Discount.pm 1165 2010-09-29 01:22:39Z jason $

package LanePOS::Discount;

require 5.008;

use base LanePOS::GenericObject;

use LanePOS::Locale;

sub new
{
    my ($class, $dal) = @_;
    $class = ref($class) || $class || 'LanePOS::Discount';
    my $me = $class->SUPER::new($dal);
    
    $me->{'table'} = 'discounts';
    $me->{'columns'} = [
        'id',
        'descr',
        'preset',
        'per',
        'amt',
        'sale',
        'voidAt',
        'voidBy',
        'created',
        'createdBy',
        'modified',
        'modifiedBy',
        ];
    $me->{'keys'} = ['id'];
    $me->{'revisioned'} = 1;

    $me->{'lc'} = Locale->new($me->{'dal'});

    return $me;
}

sub isSaleDisc
{
    my ($me) = @_;

    return $me->{'sale'};
}

sub isPercentDisc
{
    my ($me) = @_;

    return $me->{'per'};
}

sub isPresetDisc
{
    my ($me) = @_;

    return $me->{'preset'};
}

sub giveDisc
{			          # returns a dollar amt
    my ($me, $rate, $amt) = @_; # rate is the override discount amt,
				  # amt is the $ amt to apply the disc to

    die "Discount::giveDisc(): This discount is void!\n" if $me->isVoid;

    $rate = $me->{'amt'} if $me->isPresetDisc;
    $rate =~ s/\.// if $me->isPresetDisc and !$me->isPercentDisc;
    return $rate if !$me->isPercentDisc;
    #$amt *= $rate;
    $me->{'dal'}->trace(STDERR) if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Discount/;
    
    eval {
        $me->{'dal'}->do("select ((" . $me->{'dal'}->qtAs($amt, 'numeric') . ' * ' . $me->{'dal'}->qtAs($rate, 'numeric') . ")::numeric(15,0)/100)::numeric(15,0)");
    };
    if($@)
    {
        warn "Sale: the db returned an error: $@\n";
        return ();
    }

    return $me->{'dal'}->fetchrow();
}

1;
