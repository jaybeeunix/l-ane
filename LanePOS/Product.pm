#Product.pm
#Copyright 2001-2010 Jason Burrell.
#LanePOS see $LaneROOT/documentation/README
#$Id: Product.pm 1165 2010-09-29 01:22:39Z jason $

package LanePOS::Product;

require 5.008;
use base 'LanePOS::GenericObject';

sub new
{
    my ($class, $dal) = @_;
    $class = ref($class) || $class || 'LanePOS::Product';
    my $me = $class->SUPER::new($dal);
    
    $me->{'table'} = 'products';
    $me->{'columns'} = [
	'id',
	'descr',
	'price',
	'category',
	'taxes',
	'type',
	'trackQty',
	'onHand',
	'minimum',
	'reorder',
	'vendor',
	'caseQty',
	'caseId',
	'extended',
	'cost',
	'reorderId',
        'voidAt',
        'voidBy',
        'created',
        'createdBy',
        'modified',
        'modifiedBy',
        ];
    $me->{'keys'} = ['id'];
    $me->{'exts'} = {'extended' => 1};
    $me->{'revisioned'} = 1;

    $me->_resetFlds;
    return $me;
}

sub searchByDescr
{
    my ($me, $nme) = @_;
    my @found;		# this holds the search results

    eval {
        $me->{'dal'}->do('select id, descr, price, category, taxes, type, trackQty, onHand, minimum, reorder, vendor, caseQty, caseId, extended, cost, reorderId from products where voidAt is null and lower(descr) like lower(' . $me->{'dal'}->qt('%' . $nme . '%') . ') order by descr');

        foreach (1..$me->{'dal'}->{'tuples'}) # put everything into an array
        {
            my %tmp;
            my $ext;
            ($tmp{'id'}, $tmp{'descr'}, $tmp{'price'}, $tmp{'category'}, $tmp{'taxes'}, $tmp{'type'}, $tmp{'trackQty'}, $tmp{'onHand'}, $tmp{'minimum'}, $tmp{'reorder'}, $tmp{'vendor'}, $tmp{'caseQty'}, $tmp{'caseId'}, $ext, $tmp{'cost'}, $tmp{'reorderId'}) = $me->{'dal'}->fetchrow;
            $tmp{'extended'} = $me->parseExt($ext);
            push @found, \%tmp; # returns the next item
        }
    };
    if($@)
    {
        warn "Product::searchByDescr($nme) caught a DB error ($@)!\n";
    }

    return @found;		# everything went ok (prob ;) )
}

sub consumeUnits
{
    #this "consumes/uses" a given number of units. it adjusts the case items accordingly

    #this sub isn't multiuser friendly--i fixed some of those problems

    my ($me, $n) = @_;

    return 1 if !$me->trackQty or $me->isVoid; # don't track, but fool it
    #we also check the voidAt in the sql in case it was changed in the db since last open

    eval {
        $me->{'dal'}->begin;
        #check to determine # of cases to break
        if ($me->{'onHand'} < $n) # need to break a case
        {
            my $case = $me->new($me->{'dal'});
            if($case->open($me->{'caseId'}))
            {
                while($me->{'onHand'} < $n and $case->{'onHand'} >= 1)
                {
                    #$me->{'onHand'} += $me->{'caseQty'};
                    $me->receiveUnits($me->{'caseQty'});
                    #$case->{'onHand'}--;
                    $case->consumeUnits(1); # allows cascading
                }
            }
        }
        $me->{'dal'}->do('select * from products where voidAt is null and id=' . $me->{'dal'}->qt($me->{'id'}) . ' for update');
        $me->{'dal'}->do('update products set onHand=onHand - ' . $me->{'dal'}->qtAs($n, 'numeric') . ' where voidAt is null and id=' . $me->{'dal'}->qt($me->{'id'}));
        
        $me->{'dal'}->commit;
        $me->{'dal'}->do("select onHand from products where voidAt is null and id=" . $me->{'dal'}->qt($me->{'id'}));
        if($me->{'dal'}->{'tuples'} > 0)
        {
            ($me->{'onHand'}) = $me->{'dal'}->fetchrow;
        }
        else
        {
            warn "Product::consumeUnits() couldn't reopen your item!\n";
        }
    };
    if($@)
    {
        warn "Product::consumeUnits() caught a DB error! ($@)\n";
    }
    return 1;			# consumed $n units
}

sub receiveUnits
{
    my ($me, $n) = @_;

    return $me->consumeUnits(-$n);
}

sub getUnderstocked
{
    my ($me) = @_;

    my @rtn;
    eval {
        $me->{'dal'}->do('select id from products where voidAt is null and onHand < minimum order by id');
        foreach(1..$me->{'dal'}->{'tuples'})
        {
            push @rtn, $me->{'dal'}->fetchrow;
        }
    };
    if($@)
    {
        warn "Product::getUnderstocked() caught a DB error! ($@)\n";
    }
    return @rtn;
}

sub getUnderstockedByVendor
{
    my ($me, $vend) = @_;

    my @rtn;
    eval {
        $me->{'dal'}->do('select id from products where voidAt is null and onHand < minimum and vendor=' . $me->{'dal'}->qt($vend) . ' order by id');

	foreach (1..$me->{'dal'}->{'tuples'})
	{
	    push @rtn, $me->{'dal'}->fetchrow;
	}
    };
    if($@)
    {
        warn "Product::getUnderstockedByVendor() caught a DB error! ($@)\n";
    }
    
    return @rtn;
}

sub getAllUnderstockedVendors
{
    my ($me) = @_;

    my @rtn;
    eval {
        $me->{'dal'}->do('select distinct vendor from products where voidAt is null and onHand < minimum order by vendor');

	foreach (1..$me->{'dal'}->{'tuples'})
	{
	    push @rtn, $me->{'dal'}->fetchrow;
	}
    };
    if($@)
    {
        warn "Product::getUnderstockedVendors() caught a DB error! ($@)\n";
    }
    
    return @rtn;
}

1;
