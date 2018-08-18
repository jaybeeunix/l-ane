#PriceTable.pm
#This file is part of L'ane. Copyright 2001-2010 Jason Burrell.
#See COPYING for licensing information.
#Copyright 2001-2010 Jason Burrell

#$Id: PriceTable.pm 1132 2010-09-19 21:36:50Z jason $

package LanePOS::PriceTable;

require 5.008;

use base 'LanePOS::GenericObject';

sub new
{
    my ($class, $dal) = @_;
    $class = ref($class) || $class || 'LanePOS::PriceTable';
    my $me = $class->SUPER::new($dal);
    
    $me->{'table'} = 'priceTables';
    $me->{'columns'} = [
	'id',
	'priceList',
        'voidAt',
        'voidBy',
        'created',
        'createdBy',
        'modified',
        'modifiedBy',
        ];
    $me->{'keys'} = ['id'];
    $me->{'revisioned'} = 1;
    return $me;
}

sub price
{
    my ($me, $e) = @_;
    die "PriceTable::price($e): This PriceTable is void!\n" if $me->isVoid;
    my @p = split /[^\d\.\-]/, $me->{'priceList'};
    return $p[$e % ($#p + 1)];
}

1;
