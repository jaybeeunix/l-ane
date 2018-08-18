#Sale.pm
#This file is part of LanePOS see COPYING for licensing information
#Copyright 2001-2010 Jason Burrell.
#$Id: Sale.pm 1193 2010-10-22 21:10:11Z jason $

package LanePOS::Sale;

require 5.008;

use base 'LanePOS::GenericObject';

use LanePOS::Locale;
use LanePOS::Tax;
use LanePOS::Tender;

$::VERSION = (q$Revision: 1193 $ =~ /(\d+)/)[0];

sub new
{
    my ($class, $dal) = @_;
    $class = ref($class) || $class || 'LanePOS::Sale';
    my $me = $class->SUPER::new($dal);

    $me->{'table'} = 'sales';
    $me->{'columns'} = [
        'id',
        'customer',
	'tranzDate',
	'suspended',
	'clerk',
	'terminal',
        'taxMask',
	'total',
	'balance',
	'notes',
        'voidAt',
        'voidBy',
        'created',
        'createdBy',
        'modified',
        'modifiedBy',
        'server',
        ];
    $me->{'keys'} = ['id'];
    $me->{'revisioned'} = 1;
    $me->{'booleans'} = {
        'suspended' => 1,
    };
    $me->{'kids'} = [
        {
            'table' => 'salesItems',
            'keys' => ['id', 'lineNo'],
            'columns' => ['id', 'lineNo', 'plu', 'qty', 'amt', 'struck'],
        },
        {
            'table' => 'salesTaxes',
            'keys' => ['id', 'taxId'],
            'columns' => ['id', 'taxId', 'taxable', 'rate', 'tax'],
        },
        {
            'table' => 'salesTenders',
            'keys' => ['id', 'lineNo'],
            'columns' => ['id', 'lineNo', 'tender', 'amt', 'ext'],
            'exts' => {'ext' => 1},
        },
        {
            'table' => 'salesPayments',
            'keys' => ['id', 'lineNo'],
            'columns' => ['id', 'lineNo', 'tranzDate', 'raId', 'amt', 'struck', 'notes', 'ext'],
            'exts' => {'ext' => 1},
        },
        ];

    #things outside of GenericObject
    $me->{'due'} = 
	$me->{'subt'} = 
	$me->{'allTaxes'} =
	$me->{'taxMask'} =
	$me->{'change'} = 0;
    $me->{'suspended'} = 0;

    #load the default tax rates
    my $tx = Tax->new($me->{'dal'});
    my @all = $tx->getAllRates;
    my $i;
    for($i = 0; $i <= $#all; $i++)
    {
        $tx->open($i + 1);
        $me->{'taxes'}[$i]{'rate'} = $tx->{'amount'};
        $me->{'taxes'}[$i]{'taxId'} = $i + 1;
        $me->{'taxes'}[$i]{'tax'} = 0;
        $me->{'taxes'}[$i]{'taxable'} = 0;
    }

    $me->{'lc'} = Locale->new($me->{'dal'});

    #this breaks Register, among other things
    #$me->_resetFlds;
    return $me;
}

sub open
{
    my $me = shift;

    $me->{'dal'}->trace(STDERR) if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Sale/;

    $me->SUPER::open(@_) or return 0;

    $me->{'ratranz'} = 0;
    foreach my $i (@{$me->{'items'}})
    {
        #strip the trailing zeros from amt:
        $i->{'qty'} =~ s/\.?(0*)$//;
        #hackish for reports!
        $me->{'ratranz'} = 1 if $i->{'plu'} eq 'RA-TRANZ';
    }

    #convert some things from Psql to Perl
    $me->updateTaxes;
    $me->{'subt'} = $me->{'total'} - $me->{'allTaxes'};
    $me->{'due'} = $me->{'balance'}; # this isn't really true, but...

    $me->updateTotals;

    return 1;			# everything went ok (prob ;) )
}

sub save
{
    my ($me) = @_;

    $me->updateTotals;
    $me->{'tranzDate'} = 'now' if !defined $me->{'tranzDate'} or !$me->{'tranzDate'};
    #if there isn't currently a server defined, set it to "clerk"
    $me->{'server'} = $me->{'clerk'} if !exists $me->{'server'} or !$me->{'server'};
    $me->{'dal'}->trace(STDERR) if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Sale/;
    #remove control characters from notes
    $me->{'notes'} =~ s/[\x{00}-\x{09}\x{0b}-\x{1f}\x{7f}-\x{9f}]//g if defined $me->{'notes'};
    $me->SUPER::save() or return 0;
    #set my tranzDate, since it's often passed here as "now": ugh, this is messy
    $me->_setTranzDate($me->{'id'});
    return 1;			# everything went ok (prob ;) )
}

sub _setTranzDate
{
    my ($me, $id) = @_;
    $me->{'dal'}->do('select tranzDate from sales where id=' . $me->{'dal'}->qtAs($id, 'integer'));
    ($me->{'tranzDate'}) = $me->{'dal'}->fetchrow;
    return 1;
}

sub isPaid
{
    my ($me) = @_;
    
    return 1 if $me->{'balance'} == 0;
    return 0;
}

sub isSuspended
{
    my ($me) = @_;

    return $me->{'suspended'};
}

sub isExempt
{
    my ($me) = @_;

    return !($me->{'taxMask'} and 1);
}

sub updateTaxes
{
    my ($me) = @_;

    my $tx = Tax->new($me->{'dal'});
    my @all = $tx->getAllRates;
    for(my $i = 0; $i <= $#all; $i++)
    {
        $me->{'taxes'}[$i]{'rate'} = $all[$i];
        $me->{'taxes'}[$i]{'taxId'} = $i + 1;
    }
    #recalculate the taxes
    $me->{'allTaxes'} = 0;
    foreach my $t (@{$me->{'taxes'}})
    {
        my $o = (1 << ($t->{'taxId'} - 1));
        $t->{'tax'} = $tx->applyTaxManually($t->{'taxable'}, $t->{'rate'});
        $me->{'allTaxes'} += $t->{'tax'} if $o & $me->{'taxMask'};
    }
    return 1;
}

sub updateTotals
{ 
    my ($me) = @_;

    #allTaxes replaces the old taxes
    $me->updateTaxes;

    $me->{'total'} = $me->{'subt'} + $me->{'allTaxes'};
    $me->{'balance'} = 0;
    $me->{'due'} = $me->{'total'};
    my $i;
    foreach $i (@{$me->{'tenders'}})
    {
	$me->{'due'} -= $i->{'amt'};
    }
    #update balance
    my $td = Tender->new($me->{'dal'});
    foreach $i (@{$me->{'tenders'}})
    {
	if($td->open($i->{'tender'}))
	{  
	    $me->{'balance'} += $i->{'amt'} if !$td->pays;
            #also set sale->tender->pays, as it's used by the register
            $i->{'pays'} = $td->pays;
	}
    }
    foreach $i (@{$me->{'payments'}})
    {
	#remove amounts that have already been paid
	$me->{'balance'} -= $i->{'amt'};
    }
    $me->{'balance'} = 0 if $me->{'balance'} < 0;
    return 1;
}

sub applyToBalance
{
    my ($me, $b, $raId, $tranzDate, $notes, $ext) = @_;
    $me->{'dal'}->trace(STDERR) if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Sale/;

    die "Sale::applyToBalance: void sales cannot be modified.\n" if $me->isVoid;
    die "Sale::applyToBalance(amt, raId, tranzDate, notes, ext): missing required information\n" if !$b or !$raId;

    eval {
        $me->{'dal'}->begin;
        $me->{'dal'}->do('select * from sales where id=' . int($me->{'id'}) . ' and voidAt is null for update');
        $me->{'dal'}->do('update sales set balance=balance - ' . int($b) . ' where voidAt is null and id=' . int($me->{'id'}));
        $me->{'dal'}->do('select balance from sales where voidAt is null and id=' . int($me->{'id'}));
        ($me->{'balance'}) = $me->{'dal'}->fetchrow;

        #add the new salesPayment rows
        $notes =~ s/[\x{00}-\x{09}\x{0b}-\x{1f}\x{7f}-\x{9f}]//g if defined $notes;
        push @{$me->{'payments'}}, {
            #id, lineNo are set by GenericObject
            'tranzDate' => $tranzDate || 'now',
            'raId' => $raId,
            'amt' => $b,
            'struck' => 0,
            'notes' => $notes,
            'ext' => $ext,
        };
        $me->save;
        $me->{'dal'}->commit;
    };
    if($@)
    {
        warn "Sale::applyToBalance(): the db returned an error: $@\n";
        return 0;
    }
    return 1;
}

sub lastUnstruckItem
{
    my ($me) = @_;

    my $t;
    if(exists $me->{'items'})
    {
        foreach my $i (reverse @{$me->{'items'}})
        {
            if(!$i->{'struck'})
            {
                $t = $i;
                last;
            }
        }
    }
    return $t;
}

sub getNotPaidByCust
{
    my ($me, $custid) = @_;

    my @rtn;

    $me->{'dal'}->trace(STDERR) if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Sale/;
    
    eval {
        $me->{'dal'}->do('select id from sales where customer=' . $me->{'dal'}->qt($custid, 'not-null') . ' and balance > 0 and suspended=false and voidAt is null');
    };
    if($@)
    {
        warn "Sale::getNotPaidByCust(): the db returned an error: $@\n";
        return ();
    }
    push @rtn, $me->{'dal'}->fetchrow foreach (1..$me->{'dal'}{'tuples'});
    return @rtn;
}

sub getAllNotPaid
{
    my ($me) = @_;

    my @rtn;

    $me->{'dal'}->trace(STDERR) if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Sale/;
    
    eval {
        $me->{'dal'}->do('select id from sales where balance > 0 and voidAt is null and suspended=false order by id');
    };
    if($@)
    {
        warn "Sale: the db returned an error: $@\n";
        return ();
    }
    push @rtn, $me->{'dal'}->fetchrow foreach (1..$me->{'dal'}{'tuples'});
    return @rtn;
}

sub getSuspended
{
    my ($me) = @_;

    my @rtn;

    $me->{'dal'}->trace(STDERR) if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Sale/;
    
    eval {
        $me->{'dal'}->do('select id from sales where suspended=true and voidAt is null order by id');
    };
    if($@)
    {
        warn "Sale: the db returned an error: $@\n";
        return ();
    }
    push @rtn, $me->{'dal'}->fetchrow foreach (1..$me->{'dal'}{'tuples'});
    return @rtn;
}

sub getByCust
{
    my ($me, $custid) = @_;

    my @rtn;

    $me->{'dal'}->trace(STDERR) if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Sale/;
    
    eval {
        $me->{'dal'}->do('select id from sales where customer=' . $me->{'dal'}->qtAs($custid, 'not-null') . ' order by tranzDate');
    };
    if($@)
    {
        warn "Sale: the db returned an error: $@\n";
        return ();
    }
    push @rtn, $me->{'dal'}->fetchrow foreach (1..$me->{'dal'}{'tuples'});
    return @rtn;
}

sub getByCustAndRange
{
    my ($me, $custid, $start, $end) = @_;

    my @rtn;

    $me->{'dal'}->trace(STDERR) if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Sale/;
    
    eval {
        $me->{'dal'}->do('select id from sales where customer=' . $me->{'dal'}->qtAs($custid, 'not-null') . ' and getBusinessDayFor(tranzDate) >= ' . $me->{'dal'}->qtAs($start, 'date') . ' and getBusinessDayFor(tranzDate) <= ' . $me->{'dal'}->qtAs($end, 'date') . ' order by tranzDate');
    };
    if($@)
    {
        warn "Sale: the db returned an error: $@\n";
        return ();
    }
    push @rtn, $me->{'dal'}->fetchrow foreach (1..$me->{'dal'}{'tuples'});
    return @rtn;
}

sub getAllCustsByRange
{
    my ($me, $start, $end) = @_;

    my @rtn;

    $me->{'dal'}->trace(STDERR) if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Sale/;
    
    eval {
        $me->{'dal'}->do('select distinct customer from sales where getBusinessDayFor(tranzDate) >= ' . $me->{'dal'}->qtAs($start, 'date') . ' and getBusinessDayFor(tranzDate) <= ' . $me->{'dal'}->qtAs($end, 'date') . ' order by customer');
    };
    if($@)
    {
        warn "Sale: the db returned an error: $@\n";
        return ();
    }
    push @rtn, $me->{'dal'}->fetchrow foreach (1..$me->{'dal'}{'tuples'});
    return @rtn;
}

sub getCustBalanceByRange
{
    my ($me, $cust, $start, $end) = @_;

    my @rtn;

    $me->{'dal'}->trace(STDERR) if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Sale/;
    
    eval {
        $me->{'dal'}->do('select sum(balance) from sales where customer=' . $me->{'dal'}->qtAs($cust, 'not-null') . ' getBusinessDayFor(tranzDate) >= ' . $me->{'dal'}->qtAs($start, 'date') . ' and getBusinessDayFor(tranzDate) <= ' . $me->{'dal'}->qtAs($end, 'date') . ' and suspended=false and voidAt is null and balance > 0');
    };
    if($@)
    {
        warn "Sale: the db returned an error: $@\n";
        return ();
    }
    push @rtn, $me->{'dal'}->fetchrow foreach (1..$me->{'dal'}{'tuples'});
    return @rtn;
}

sub getByCustAndOpenOrDate
{
    my ($me, $cust, $date) = @_;

    my @rtn;

    $me->{'dal'}->trace(STDERR) if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Sale/;
    
    eval {
        $me->{'dal'}->do('select id from sales where customer=' . $me->{'dal'}->qtAs($cust, 'not-null') . ' and (getBusinessDayFor(tranzDate) >= ' . $me->{'dal'}->qtAs($date, 'date') . ' or balance > 0)  and suspended=false and voidAt is null order by tranzDate');
    };
    if($@)
    {
        warn "Sale: the db returned an error: $@\n";
        return ();
    }
    push @rtn, $me->{'dal'}->fetchrow foreach (1..$me->{'dal'}{'tuples'});
    return @rtn;
}

sub getAllByRange
{
    my ($me, $start, $end) = @_;

    my @rtn;

    $me->{'dal'}->trace(STDERR) if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Sale/;
    
    eval {
        $me->{'dal'}->do('select id from sales where getBusinessDayFor(tranzDate) >= ' . $me->{'dal'}->qtAs($start, 'date') . ' and getBusinessDayFor(tranzDate) <= ' . $me->{'dal'}->qtAs($end, 'date') . ' order by tranzDate');
    };
    if($@)
    {
        warn "Sale: the db returned an error: $@\n";
        return ();
    }
    push @rtn, $me->{'dal'}->fetchrow foreach (1..$me->{'dal'}{'tuples'});
    return @rtn;
}

sub summarizeFinancialsByRange
{
    my ($me, $start, $end) = @_;
    my %h;

    $me->{'dal'}->trace(STDERR) if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Sale/;
    
    eval {
        #(num|money)Tickets
        $me->{'dal'}->do('select count(sales.id) as qty, sum(sales.total) as amt from sales where tranzDate >= ' . $me->{'dal'}->qtAs($start, 'timestamp') . ' and tranzDate <= ' . $me->{'dal'}->qtAs($end, 'timestamp') . ' and suspended=false and voidAt is null');
        ($h{'numTickets'}, $h{'moneyTickets'}) = $me->{'dal'}->fetchrow if $me->{'dal'}{'tuples'};
        #(num|money)Sales
        $me->{'dal'}->do('select count(sales.id) as qty, sum(sales.total) as amt from sales, salesItems where tranzDate >= ' . $me->{'dal'}->qtAs($start, 'timestamp') . ' and tranzDate <= ' . $me->{'dal'}->qtAs($end, 'timestamp') . ' and suspended=false and voidAt is null and struck=false and salesItems.lineNo = 0 and salesItems.plu <> \'RA-TRANZ\' and sales.id=salesItems.id');
        ($h{'numSales'}, $h{'moneySales'}) = $me->{'dal'}->fetchrow if $me->{'dal'}{'tuples'};
        #(num|money)Products
        $me->{'dal'}->do('select sum(salesItems.qty) as qty, sum(salesItems.amt) as amt from sales, salesItems where tranzDate >= ' . $me->{'dal'}->qtAs($start, 'timestamp') . ' and tranzDate <= ' . $me->{'dal'}->qtAs($end, 'timestamp') . ' and suspended=false and voidAt is null and struck=false and (salesItems.plu <> \'RA-TRANZ\' and salesItems.plu not like \':%\' and salesItems.plu not like \'#%\') and salesItems.id=sales.id');
        ($h{'numProducts'}, $h{'moneyProducts'}) = $me->{'dal'}->fetchrow if $me->{'dal'}{'tuples'};
        $h{'numProducts'} =~ s/\.?(0*)$//; #strip trailing zeros
        #(num|money)Ra
        $me->{'dal'}->do('select count(sales.id) as qty, sum(sales.total) as amt from sales, salesItems where tranzDate >= ' . $me->{'dal'}->qtAs($start, 'timestamp') . ' and tranzDate <= ' . $me->{'dal'}->qtAs($end, 'timestamp') . ' and suspended=false and voidAt is null and struck=false and salesItems.plu = \'RA-TRANZ\' and salesItems.lineNo = 0 and sales.id=salesItems.id');
        ($h{'numRa'}, $h{'moneyRa'}) = $me->{'dal'}->fetchrow if $me->{'dal'}{'tuples'};
    };
    if($@)
    {
        warn "Sale: the db returned an error: $@\n";
        %h = ();
    }
    return \%h;
}

sub summarizeTaxesByRange
{
    my ($me, $start, $end) = @_;

    $me->{'dal'}->trace(STDERR) if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Sale/;

    my @r;
    eval {
        $me->{'dal'}->do('select salesTaxes.taxid, taxes.descr, sum(salesTaxes.taxable) as taxable, sum(salesTaxes.taxes / 10 ^ ' . int($me->{'lc'}->get('Lane/Locale/Money/DecimalDigits')) . ' * salesTaxes.rate)::numeric(15, 0) as taxColl from salesTaxes, sales, taxes where tranzDate >= ' . $me->{'dal'}->qtAs($start, 'timestamp') . ' and tranzDate <= ' . $me->{'dal'}->qtAs($end, 'timestamp') . ' and suspended=false and voidAt is null and sales.id=salesTaxes.id and salesTaxes.taxid=taxes.id group by salesTaxes.taxid, taxes.descr order by salesTaxes.taxid');
        foreach my $i (1..$me->{'dal'}{'tuples'})
        {
            my %h;
            ($h{'id'}, $h{'descr'}, $h{'taxable'}, $h{'taxCollected'}) = $me->{'dal'}->fetchrow;
            push @r, \%h;
        }
    };
    if($@)
    {
        warn "Sale: the db returned an error: $@\n";
        @r = ();
    }
    return @r;
}

sub summarizeTendersByRange
{
    my ($me, $start, $end) = @_;

    $me->{'dal'}->trace(STDERR) if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Sale/;

    my @r;
    eval {
        $me->{'dal'}->do('
select
    tenders.descr,
    sum(salesTenders.amt) as amt
from
    salesTenders, sales, tenders
where
    tranzDate >= ' . $me->{'dal'}->qtAs($start, 'timestamp') .
  ' and tranzDate <= ' . $me->{'dal'}->qtAs($end, 'timestamp') .
  ' and suspended=false and voidAt is null and
    sales.id=salesTenders.id and salesTenders.tender=tenders.id
group by salesTenders.tender, tenders.descr order by salesTenders.tender'
);
        foreach my $i (1..$me->{'dal'}{'tuples'})
        {
            my %h;
            ($h{'descr'}, $h{'amt'}) = $me->{'dal'}->fetchrow;
            push @r, \%h;
        }
    };
    if($@)
    {
        warn "Sale: the db returned an error: $@\n";
        @r = ();
    }
    return @r;
}

sub summarizeCategoriesByRange
{
    my ($me, $start, $end) = @_;


    $me->{'dal'}->trace(STDERR) if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Sale/;

    my @r;
    eval {
        $me->{'dal'}->do('
select
    products.category,
    sum(salesItems.qty) as qty,
    sum(salesItems.amt) as amt
from
    salesItems, sales, products
where
    tranzDate >= ' . $me->{'dal'}->qtAs($start, 'timestamp') .
  ' and tranzDate <= ' . $me->{'dal'}->qtAs($end, 'timestamp') .
  ' and suspended=false and voidAt is null and struck=false and
    sales.id=salesItems.id and salesItems.plu=products.id and salesItems.plu not like \':%\' and salesItems.plu <> \'RA-TRANZ\' and salesItems.plu not like \'#%\'
group by products.category order by products.category'
);
        foreach my $i (1..$me->{'dal'}{'tuples'})
        {
            my %h;
	    ($h{'category'}, $h{'qty'}, $h{'amt'}) = $me->{'dal'}->fetchrow;
            push @r, \%h;
        }
    };
    if($@)
    {
        warn "Sale: the db returned an error: $@\n";
        @r = ();
    }
    return @r;
}

sub summarizeProductsByRange
{
    my ($me, $start, $end) = @_;


    $me->{'dal'}->trace(STDERR) if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Sale/;

    my @r;
    eval {
        $me->{'dal'}->do('
select
    products.id,
    products.descr,
    sum(salesItems.qty) as qty,
    sum(salesItems.amt) as amt
from
    salesItems, sales, products
where
    tranzDate >= ' . $me->{'dal'}->qtAs($start, 'timestamp') .
  ' and tranzDate <= ' . $me->{'dal'}->qtAs($end, 'timestamp') .
  ' and suspended=false and voidAt is null and struck=false and
    sales.id=salesItems.id and salesItems.plu=products.id and salesItems.plu not like \':%\' and salesItems.plu <> \'RA-TRANZ\' and salesItems.plu not like \'#%\'
group by products.id, products.descr order by products.descr'
);
        foreach my $i (1..$me->{'dal'}{'tuples'})
        {
            my %h;
	    ($h{'id'}, $h{'descr'}, $h{'qty'}, $h{'amt'}) = $me->{'dal'}->fetchrow;
            push @r, \%h;
        }
    };
    if($@)
    {
        warn "Sale: the db returned an error: $@\n";
        @r = ();
    }
    return @r;
}

sub summarizeDiscountsByRange
{
    my ($me, $start, $end) = @_;


    $me->{'dal'}->trace(STDERR) if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Sale/;

    my @r;
    eval {
        $me->{'dal'}->do('
select
    discounts.id,
    discounts.descr,
    sum(salesItems.qty::integer) as qty,
    sum(salesItems.amt) as amt
from
    salesItems, sales, discounts
where
    tranzDate >= ' . $me->{'dal'}->qtAs($start, 'timestamp') .
  ' and tranzDate <= ' . $me->{'dal'}->qtAs($end, 'timestamp') .
  ' and suspended=false and voidAt is null and struck=false and
    sales.id=salesItems.id and salesItems.plu=(\':\' || discounts.id) and salesItems.plu <> \'RA-TRANZ\' and salesItems.plu not like \'#%\'
group by discounts.id, discounts.descr order by discounts.descr'
);
        foreach my $i (1..$me->{'dal'}{'tuples'})
        {
            my %h;
	    ($h{'id'}, $h{'descr'}, $h{'qty'}, $h{'amt'}) = $me->{'dal'}->fetchrow;
            push @r, \%h;
        }
    };
    if($@)
    {
        warn "Sale: the db returned an error: $@\n";
        @r = ();
    }
    return @r;
}

sub openReportStyle
{
    die "Sale::openReportStyle() is obsolete. Use an alternative form.\n";
}

sub void
{
    my ($me) = @_;

    return 0 if !defined $me->{'id'} or !$me->{'id'};

    $me->{'dal'}->trace(STDERR) if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Sale/;
    #the sale must be saved before calling the db void
    $me->save or return 0;
    
    my @rtn;

    eval {
        $me->{'dal'}->do('select voidSale(' . int($me->{'id'}) . ')');
    };
    if($@)
    {
        warn "Sale::void(): the db returned an error: $@\n";
        return 0;
    }
    else
    {
        return ($me->{'dal'}->fetchrow)[0];
    }
}

1;
