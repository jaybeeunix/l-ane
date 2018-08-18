#Customer.pm
#Copyright 1999-2010 Jason Burrell.
#Perl Module for customers info access
#part of L'ane BMS

#$Id: Customer.pm 1193 2010-10-22 21:10:11Z jason $

package LanePOS::Customer;
require 5.008;

use strict;

use base 'LanePOS::GenericObject';

use LanePOS::Locale;

sub new
{
    my ($class, $dal) = @_;
    $class = ref($class) || $class || 'LanePOS::Customer';
    my $me = $class->SUPER::new($dal);
    
    $me->{'table'} = 'customers';
    $me->{'columns'} = [
	'id',
	'coName',
	'cntFirst',
	'cntLast',
	'billAddr1',
	'billAddr2',
	'billCity',
	'billSt',
	'billZip',
	'billCountry',
	'billPhone',
	'billFax',
	'shipAddr1',
	'shipAddr2',
	'shipCity',
	'shipSt',
	'shipZip',
	'shipCountry',
	'shipPhone',
	'shipFax',
	'email',
	#'custType',
	'creditLmt',
	'balance',
	'creditRmn',
	'lastSale',
	'lastPay',
	'terms',
	'taxes',
	'notes',
	'created',
	'createdBy',
	'voidAt',
	'voidBy',
	'modified',
	'modifiedBy',
	];
    $me->{'keys'} = ['id'];
    $me->{'disallowNullKeys'} = 1;
    $me->{'revisioned'} = 1;
    #$me->{'dates'} = {
    #    'lastSale' => 1,
    #    'lastPay' => 1,
    #};
    #configure the custTypes
    $me->{'lc'} = Locale->new($me->{'dal'});
    if($class =~ /Customer/)
    {
	push @{$me->{'columns'}}, 'custType';

	my %tmp = $me->{'lc'}->getAllLike('Lane/Customer/Customer Type/');
	foreach my $k (keys %tmp)
	{
	    my ($v) = ($k =~ m{^Lane/Customer/Customer Type/(\d+)});
	    next if $v !~ /^\d+$/;
	    $me->{'custTypes'}[$v] = $tmp{$k};
	}
    }

    return $me;
}

sub convertType2Str
{
    my ($me) = @_;

    return undef if ref($me) ne 'LanePOS::Customer';# or $me->{'custType'} !~ /^\d+$/;
    $me->{'custType'} = $me->{'custTypes'}[$me->{'custType'}];
}

sub custTypeIndex
{
    my ($me) = @_;

    return undef if ref($me) ne 'LanePOS::Customer';# or $me->{'custType'} =~ /^\d+$/;;
    foreach my $i (0..$#{$me->{'custTypes'}})
    {
	return $i if $me->{'custTypes'}[$i] eq $me->{'custType'};
    }
    return 0;
}

sub open
{
    my $me = shift;

    my $r = $me->SUPER::open(@_);
    if($r)
    {
        #also, put the dates into us forms
        $me->convertType2Str;
        #we want the dates to be purdy for our users: THIS ONLY WORKS IF YOUR DATES ARE IN A FOR UNDERSTOOD BY POSTGRESQL (and possibly Locale->timeToEpoch())!
        foreach ('lastPay', 'lastSale')
        {
            next if !defined $me->{$_} or $me->{$_} eq '';
            $me->{$_} = $me->{'lc'}->temporalFmt('shortDate', $me->{$_});
        }
        return $r;
    }
    return 0;
}

sub save
{
    my ($me) = @_;

    $me->{'custType'} = $me->custTypeIndex if ref($me) eq 'LanePOS::Customer';

    #is this even needed anymore?
    $me->{'lastSale'} = '' if $me->{'lastSale'} eq '-';
    $me->{'lastPay'} = '' if $me->{'lastPay'} eq '-';
    #get rid of extra whitespace at the end
    foreach my $n ($me->{'notes'})
    {
	$n =~ s/\s+$//g;
    }

    my $r = $me->SUPER::save;
    #put things back how the other code expects them
    $me->convertType2Str;
    return $r;
}

sub searchByName
{
    my ($me, $nme) = @_;

    my @found;		# this holds the search results

    eval {
	$me->{'dal'}->select(
	    'what' => $me->{'columns'},
	    'from' => [$me->{'table'}],
	    'where' => ['(',
		['lower(coName)', 'like', $me->{'dal'}->qt("%\L$nme\E%")],
		'or',
		['lower(cntLast)', 'like', $me->{'dal'}->qt("%\L$nme\E%")],
		'or',
		['lower(cntFirst)', 'like', $me->{'dal'}->qt("%\L$nme\E%")],
		')', 'and',
		['voidAt', 'is null']
	    ],
	    'orderBy' => ['coName', 'cntLast', 'cntFirst'],
	    )->do;
        foreach (1..$me->{'dal'}->{'tuples'})
        {
            my %tmp;
	    my @row = $me->{'dal'}->fetchrow;
	    foreach my $j (0..$#row)
	    {
		$tmp{$me->{'columns'}[$j]} = $row[$j];
	    }
            push @found, \%tmp; # returns the next item
        }
    };
    if($@)
    {
        warn ref($me) . "::searchByName() caught an exception! ($@)\n";
    }
    return @found;
}

sub getName
{
    my ($me) = @_;
    return undef if !defined $me->id;
    return $me->{'coName'} || $me->{'cntFirst'} . ' ' . $me->{'cntLast'};
}

sub applyToAcct
{
    my ($me, $amt) = @_;

    return $me->chargeToAcct(-$amt);
}

sub chargeToAcct
{
    my ($me, $amt) = @_;

    eval {
        #$me->{'dal'}->trace(STDERR);
        $me->{'dal'}->begin;
        #do we need to aquire a lock first?
        $me->{'dal'}->do('select balance, creditRmn from ' . $me->{'table'} . ' where voidAt is null and id=' . $me->{'dal'}->qtAs($me->{'id'}, 'not-null') . ' for update');
        $me->{'dal'}->do('update ' . $me->{'table'} . ' set balance=balance + ' . $me->{'dal'}->qtAs($amt, 'numeric') . ', creditRmn = creditRmn - ' . $me->{'dal'}->qtAs($amt, 'numeric') . ' where voidAt is null and id=' . $me->{'dal'}->qtAs($me->{'id'}, 'not-null'));
        $me->{'dal'}->do('select balance, creditRmn from ' . $me->{'table'} . ' where voidAt is null and id=' . $me->{'dal'}->qtAs($me->{'id'}, 'not-null'));
        ($me->{'balance'}, $me->{'creditRmn'}) = $me->{'dal'}->fetchrow;
        $me->{'dal'}->commit;
        #$me->{'dal'}->trace('');
    };
    if($@)
    {
        warn ref($me) . "::chargeToAcct(): the db returned an error: $@\n";
        return 0;
    }
    return 1;
}

sub isExempt
{
    my ($me) = @_;

    return 0 if $me->{'taxes'};
    return 1;
}

1;
