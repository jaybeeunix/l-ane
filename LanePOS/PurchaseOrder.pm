#PurchaseOrder.pm
#This file is part of L'ane. Copyright 2002-2010 Jason B. Burrell.
#See COPYING for licensing terms.
#LanePOS see $LaneROOT/documentation/README

#$Id: PurchaseOrder.pm 1132 2010-09-19 21:36:50Z jason $

=pod

=head1 NAME

LanePOS::PurchaseOrder - Purchase orders for L'ane

=head1 SYNOPSIS

PurchaseOrder provides a system for creating and maintaining orders used to purchase products.

=head1 DESCRIPTION

PurchaseOrder provides the basic object for creating and maintaining purchase orders in L'ane. It interacts with L<LanePOS::Product> and L<LanePOS::Vendor> to provide vendor based ordering of product stock.

=head2 CHILDREN

Only children with an external use are documented here.

=over

=item id

The purchase order number

=item vendor

L<Vendor/id>

=item created

The timestamp when this purchase order was originally created

=item createdBy

The user name and host string (ie C<jason@localhost>) of the person who originally created this purchase order


=item modified

The timestamp when this purchase order was last modified

=item modifiedBy

The user name and host string (ie C<jason@localhost>) of the person who last modified this purchase order

=item notes

Free-form notes about the sale

=item extended

A hash which represents extended information (typically used by plugins)

=item total

The total of the purchase order (in L'ane internal format)

=item voidAt

The timestamp when this purchase order was voided, or C<undef> if non-void.

=item voidBy

The user name and host string (ie C<jason@localhost>) of the person who voided this purchase order, or C<undef> if non-void.

=item orderedAt

The timestamp when this purchase order was ordered, or C<undef> if it has not been ordered yet.

=item orderedBy

The user name and host string (ie C<jason@localhost>) of the person who ordered this purchase order, or C<undef> if it has not been ordered yet.

=item orderedVia

A description of how this order was placed. Although this field is site-specific, suggested formats include: C<fax:John Doe@217-555-1212>, C<phone:John Doe@217-555-1212>, and C<mailto:john.doe@yourvendor.com>.

=item completelyReceived

True if the order has been completely received, or false if items are still pending reception.

=item orderedItems

An array of items which represent the detail of the ordered items.

=over

=item plu

The L<Product/id> of the product ordered on this line

=item qty

The quantity of this product ordered on this line

=item amt

The extended amount of this line (in L'ane internal format)

=item voidAt

The timestamp when this line was voided, or C<undef> if non-void.

=item voidBy

The user name and host string (ie C<jason@localhost>) of the person who voided this line, or C<undef> if non-void.

=item extended

A hash which represents extended information (typically used by plugins)

=back

=item receivedItems

An array of items which represent the detail of the received items.

=over

=item plu

The L<Product/id> of the product received on this line

=item qty

The quantity of this product received on this line

=item received

The timestamp when this line was received

=item receivedBy

The user name and host string (ie C<jason@localhost>) of the person who received this line

=item voidAt

The timestamp when this line was voided, or C<undef> if non-void.

=item voidBy

The user name and host string (ie C<jason@localhost>) of the person who voided this line, or C<undef> if non-void.

=item extended

A hash which represents extended information (typically used by plugins)

=back

=back

=head2 FUNCTIONS

Only subroutines with an external use are documented here.

=over

=item getPending()

Returns a list of C<PurchaseOrder> C<'id'>s which are pending (not completely received).

=item getProductsToOrderFrom(vendor)

Returns a list of C<Product> C<'id'>s which are sold by C<Vendor> and need reordered.

=item getVendorsNeedingOrders()

Returns a list of unique C<Vendor> C<'id'>s based on the products that need reordered.

=item new([class,] dal)

See L<GenericObject/new>

=item open(id)

See L<GenericObject/open>

=item remove()

C<PurchaseOrders> can not be removed. Calling this routine will throw a fatal error.

=item save()

See L<GenericObject/save>

=back

=head1 AUTHOR

Jason Burrell

=head1 BUGS

=over

=item * 

Bug 32: the purchasing module

=back

=cut

package LanePOS::PurchaseOrder;

require 5.008;

use base 'LanePOS::GenericObject';
$::VERSION = (q$Revision: 1132 $ =~ /(\d+)/)[0];

sub new
{
    my ($class, $dal) = @_;
    $class = ref($class) || $class || 'LanePOS::PurchaseOrder';
    my $me = $class->SUPER::new($dal);
    
    $me->{'table'} = 'purchaseOrders';
    $me->{'columns'} = [
			'id',
			'vendor',
			'created', # these items are set automatically by a trigger
			'createdBy',
			'modified',
			'modifiedBy',#/these items
			'notes',
			'extended',
			'total',
			'voidAt', #setting this non-null will cause the void info to be set by a trigger

			'voidBy', #this too^
			'orderedAt',
			'orderedBy',
			'orderedVia',
			'completelyReceived',
			];
    $me->{'keys'} = ['id'];
    $me->{'booleans'} = {'completelyReceived' => 1};
    $me->{'kids'} = [
                     {
                         'table' => 'purchaseOrdersOrderedItems',
                         'keys' => [ 'id', 'lineNo' ],
                         'columns' => [ 'id', 'lineNo', 'plu', 'qty', 'amt', 'voidAt', 'voidBy', 'extended' ],
                     },
                     {
                         'table' => 'purchaseOrdersReceivedItems',
                         'keys' => [ 'id', 'lineNo' ],
                         'columns' => [ 'id', 'lineNo', 'plu', 'qty', 'received', 'receivedBy', 'voidAt', 'voidBy', 'extended' ],
                     },
                     ];
    $me->{'revisioned'} = 1;
    return $me;
}

sub getPending
{
    my ($me) = @_;

    my @rtn;

    $me->{'dal'}->trace(STDERR) if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /PurchaseOrder/;
    
    eval {
        $me->{'dal'}->do("select id from purchaseorders where completelyReceived=false and voidAt is null order by id");
    };
    if($@)
    {
        warn "PurchaseOrder::getPending(): the db returned an error: $@\n";
    }
    else
    {
        push @rtn, $me->{'dal'}->fetchrow foreach (1..$me->{'dal'}{'tuples'});
    }
    return @rtn;
}

sub getVendorsNeedingOrders
{
    my ($me) = @_;

    my @rtn;

    $me->{'dal'}->trace(STDERR) if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /PurchaseOrder/;
    
    eval {
        $me->{'dal'}->do("
select
    distinct vendor
from
    products
    left outer join
    (
     select sum(qty) as qty, plu
     from purchaseOrders as po, purchaseOrdersOrderedItems as pooi
     where po.completelyReceived=false and po.id=pooi.id and po.voidAt is null and pooi.voidAt is null
     group by pooi.plu
    ) as ordered on id=ordered.plu
    left outer join
    (
     select sum(qty) as qty, plu
     from purchaseOrders as po, purchaseOrdersReceivedItems as poor
     where po.completelyReceived=false and po.id=poor.id and po.voidAt is null and poor.voidAt is null
     group by poor.plu
    ) as rcvd on id=rcvd.plu
where
    trackQty=true
    and onHand + coalesce(ordered.qty, 0) - coalesce(rcvd.qty, 0) < minimum
order by vendor");
    };
    if($@)
    {
        warn "PurchaseOrder::getVendorsNeedingOrders(): the db returned an error: $@\n";
    }
    else
    {
        push @rtn, $me->{'dal'}->fetchrow foreach (1..$me->{'dal'}{'tuples'});
    }
    return @rtn;
}

sub getProductsToOrderFrom
{
    my ($me, $vend) = @_;

     my @rtn;

    $me->{'dal'}->trace(STDERR) if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /PurchaseOrder/;
    
    eval {
        $me->{'dal'}->do("
select
    id
from
    products
    left outer join
    (
     select sum(qty) as qty, plu
     from purchaseOrders as po, purchaseOrdersOrderedItems as pooi
     where po.completelyReceived=false and po.id=pooi.id and po.voidAt is null and pooi.voidAt is null
     group by pooi.plu
    ) as ordered on id=ordered.plu
    left outer join
    (
     select sum(qty) as qty, plu
     from purchaseOrders as po, purchaseOrdersReceivedItems as poor
     where po.completelyReceived=false and po.id=poor.id and po.voidAt is null and poor.voidAt is null
     group by poor.plu
    ) as rcvd on id=rcvd.plu
where
    vendor=" . $me->{'dal'}->qt($vend) . "
    and trackQty=true
    and onHand + coalesce(ordered.qty, 0) - coalesce(rcvd.qty, 0) < minimum
order by id");
    };
    if($@)
    {
        warn "PurchaseOrder::getProductsToOrderFrom(): the db returned an error: $@\n";
    }
    else
    {
        push @rtn, $me->{'dal'}->fetchrow foreach (1..$me->{'dal'}{'tuples'});
    }
    return @rtn;
}

1;
