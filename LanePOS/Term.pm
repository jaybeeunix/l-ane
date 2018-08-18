#Perl Module for Terms info access
#part of L'ane BMS
#Copyright 2001-2010 Jason Burrell

#$Id: Term.pm 1193 2010-10-22 21:10:11Z jason $

package LanePOS::Term;

require 5.008;

use base 'LanePOS::GenericObject';

use LanePOS::Locale;

sub new
{
    my ($class, $dal) = @_;
    $class = ref($class) || $class || 'LanePOS::Term';
    my $me = $class->SUPER::new($dal);
    
    $me->{'table'} = 'terms';
    $me->{'columns'} = [
	'id',
	'descr',
	'dueDays',
	'finRate',
	'discDays',
	'discRate',
	'created',
	'createdBy',
	'voidAt',
	'voidBy',
	'modified',
	'modifiedBy',
        ];
    $me->{'keys'} = ['id'];
    $me->{'revisioned'} = 1;
    return $me;
}

sub save
{
    my ($me) = @_;

    #can't do unsigned in pg so:
    $me->{'dueDays'} = abs $me->{'dueDays'};
    $me->{'finRate'} = abs $me->{'finRate'};
    $me->{'discDays'} = abs $me->{'discDays'};
    $me->{'discRate'} = abs $me->{'discRate'};

    return $me->SUPER::save;
}

sub getAll
{
    # this returns an array ref
    # [x][0] = name, [x][1] = id
    my ($me) = @_;

    my @rtn;

    eval {
        $me->{'dal'}->do('select descr, id from terms where voidAt is null order by descr');

        foreach (1..$me->{'dal'}->{'tuples'})
        {
            my @t = $me->{'dal'}->fetchrow();
            push @rtn, \@t;
        }
    };
    if($@)
    {
        warn "Terms::getAll() caught an exception! ($@)\n";
    }
    return @rtn;
}

sub datesBefore
{
    #similar to datesFrom(), but subtracted instead of added to the provided date
    my ($me, $d) = @_;

    my @t = (0,0,0,0,0,0);
    if($d =~ /(\d{4})-(\d{2})-(\d{2})/)
    {
	$t[5] = $1 - 1900;
	$t[4] = $2 - 1;
	$t[3] = $3;
    }
    elsif($d =~ /(\d{2})-(\d{2})-(\d{4})/)
    {
	$t[5] = $3 - 1900;
	$t[4] = $1 - 1;
	$t[3] = $2;
    }
    use Time::Local 'timelocal_nocheck';
    use POSIX 'strftime';
    my @r;
    #change these to a less US-specific style (and fix everything dependent on them)
    $t[3] -= $me->{'discDays'};
    $r[0] = strftime('%m-%d-%Y', localtime(timelocal_nocheck(@t)));
    $t[3] -= $me->{'dueDays'} - $me->{'discDays'};
    $r[1] = strftime('%m-%d-%Y', localtime(timelocal_nocheck(@t)));

    return @r;
}

sub datesFrom
{
    my ($me, $d) = @_;

    #datesFrom() needs to handle the date "now" as Register calls it w/that date
    if($d =~ /now/i)
    {
	#this is a wee trick
	local $ENV{'LaneLocale'} = 'c'; #force the iso style date/time
	my $lc = Locale->new($me->{'dal'});
	$d = $lc->nowFmt('shortTimestamp');
	$d =~ s/([^T])+(T.*)/$1/;
    }

    my @t = (0,0,0,0,0,0);
    if($d =~ /(\d{4})-(\d{2})-(\d{2})/)
    {
	$t[5] = $1 - 1900;
	$t[4] = $2 - 1;
	$t[3] = $3;
    }
    elsif($d =~ /(\d{2})-(\d{2})-(\d{4})/)
    {
	$t[5] = $3 - 1900;
	$t[4] = $1 - 1;
	$t[3] = $2;
    }
    use Time::Local 'timelocal_nocheck';
    use POSIX 'strftime';
    my @r;
    #change these to a less US-specific style (and fix everything dependent on them)
    $t[3] += $me->{'discDays'};
    $r[0] = strftime('%m-%d-%Y', localtime(timelocal_nocheck(@t)));
    $t[3] += $me->{'dueDays'} - $me->{'discDays'};
    $r[1] = strftime('%m-%d-%Y', localtime(timelocal_nocheck(@t)));

    return @r;
}

sub isCurrent
{
    my ($me, $baseDate, $checkDate) = @_;

    my $r;

    eval {
        $me->{'dal'}->do('select (' . $me->{'dal'}->qtAs($baseDate, 'date') . ' + terms.dueDays ) >= ' . $me->{'dal'}->qt($checkDate) . ' from terms where voidAt is null and terms.id=' . $me->{'dal'}->qt($me->{'id'}));
        ($r) = $me->{'dal'}->fetchrow if $me->{'dal'}->{'tuples'} > 0;
    };
    if($@)
    {
        warn "Terms::isCurrent() caught an exception! ($@)\n";
    }

    $r =~ tr/ft/01/;		# translate from pg to perl-ish

    return $r;
}

sub isDiscAble
{
    my ($me, $baseDate, $checkDate) = @_;

    return 0 if $me->{'discDays'} == 0;
    my $r;

    eval {
        $me->{'dal'}->do('select (' . $me->{'dal'}->qtAs($baseDate, 'date') . ' + terms.discDays ) >= ' . $me->{'dal'}->qt($checkDate) . ' from terms where voidAt is null and terms.id=' . $me->{'dal'}->qt($me->{'id'}));
        ($r) = $me->{'dal'}->fetchrow if $me->{'dal'}->{'tuples'} > 0;
    };
    if($@)
    {
        warn "Terms::isDiscAble() caught an exception! ($@)\n";
    }

    $r =~ tr/ft/01/;		# translate from pg to perl-ish

    return $r;
}

sub applyDisc
{			# returns the discount amt only!
    my ($me, $amt) = @_;

    my $r;
    eval {
        #the following has 100 as the tax is expressed as a percent
        $me->{'dal'}->do('select (' . $me->{'dal'}->qtAs($amt, 'numeric') . '::numeric(15,0) * discrate / 100)::numeric(15,0) from terms where voidAt is null and id=' . $me->{'dal'}->qt($me->{'id'}));
        ($r) = $me->{'dal'}->fetchrow if $me->{'dal'}->{'tuples'} > 0;
    };
    if($@)
    {
        warn "Term::applyDisc() caught an exception! ($@)\n";
    }
    return $r;
}

sub applyFin
{			# returns the finance charge only!
    my ($me, $amt) = @_;

    my $r;
    eval {
        #the following has 100 as the tax is expressed as a percent
        $me->{'dal'}->do('select (' . $me->{'dal'}->qtAs($amt, 'numeric') . '::numeric(15,0) * finrate / 100)::numeric(15,0) from terms where voidAt is null and id=' . $me->{'dal'}->qt($me->{'id'}));
        ($r) = $me->{'dal'}->fetchrow if $me->{'dal'}->{'tuples'} > 0;
    };
    if($@)
    {
        warn "Term::applyFin() caught an exception! ($@)\n";
    }
    return $r;
}
1;


