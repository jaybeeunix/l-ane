#Perl module
#LanePOS/Timeclock.pm
#Copyright 2005-2010 Jason Burrell.
#This file is part of LanePOS, see COPYING for licensing information

#$Id: Timeclock.pm 1132 2010-09-19 21:36:50Z jason $

package LanePOS::Timeclock;

require 5.008;

use base qw/LanePOS::GenericObject LanePOS::GenericEventable/;

$::VERSION = (q$Revision: 1132 $ =~ /(\d+)/)[0];

sub new
{
    my ($class, $dal) = @_;
    $class = ref($class) || $class || 'LanePOS::Timeclock';
    my $me = $class->SUPER::new($dal);

    $me->{'table'} = 'timeclock';
    $me->{'columns'} = [
        'clerk',
        'punch',
        'forced',
        'voidAt',
        'voidBy',
        'created',
        'createdBy',
        'modified',
        'modifiedBy',
        ];
    $me->{'keys'} = ['clerk', 'punch'];
    $me->{'booleans'} = {
        'forced' => 1,
    };
    $me->{'revisioned'} = 1;

    $me->initEvents;

    return $me;
}

sub save { warn "Timeclock: save() is unsupported. Use punch(), forcePunch(), or voidPunch().\n"; return 0; }

sub punch
{
    my ($me, $clerk) = @_;

    $me->{'dal'}->trace(STDERR) if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Timeclock/;

    eval
    {
        #a voided clerk shouldn't be allowed to punch in (but allow forced punches)
        $me->{'dal'}->do('insert into timeclock (clerk, forced) select id, false from clerks where id=' . int($clerk) . ' and voidAt is null returning clerk');
    };
    if($@)
    {
        warn "Timeclock::punch($clerk): the db returned an error: $@ ($me->{'dal'}->{'dbError'})\n";
        return 0;
    }
    return 0 if $me->{'dal'}->{'tuples'} < 1;
    return 1;
}

sub isClockedIn
{
    my ($me, $clerk, $date) = @_;

    $me->{'dal'}->trace(STDERR) if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Timeclock/;

    eval
    {
        $date = 'now' if !$date;
        $me->{'dal'}->do('select count(*) % 2 as isclockedin from timeclock where clerk=' . int($clerk) . ' and voidAt is null and getBusinessDayFor(punch) = ' . $me->{'dal'}->qtAs($date, 'date'));
    };
    if($@)
    {
        warn "Timeclock: the db returned an error: $@ ($me->{'dal'}->{'dbError'})\n";
        return -1;
    }
    return ($me->{'dal'}->fetchrow)[0];
}

sub getBoundsForDate
{
    my ($me, $date) = @_;

    $me->{'dal'}->trace(STDERR) if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Timeclock/;

    eval
    {
        $me->{'dal'}->do('select (' . $me->{'dal'}->qtAs($date, 'date') . ' + data::time)::timestamp with time zone, (' . $me->{'dal'}->qtAs($date, 'date') . ' + \'1 day\'::interval + data::time)::timestamp with time zone from SysStrings where id=\'Lane/CORE/Business Day Start Time\' and voidAt is null');
    };
    if($@)
    {
        warn "Timeclock: the db returned an error: $@ ($me->{'dal'}->{'dbError'})\n";
        return ();
    }
    return $me->{'dal'}->fetchrow;
}

sub getClerksInSpan
{
    my ($me, $start, $end) = @_;

    $me->{'dal'}->trace(STDERR) if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Timeclock/;

    eval
    {
        $me->{'dal'}->do('select distinct timeclock.clerk, clerks.name from timeclock, clerks where punch >= ' . $me->{'dal'}->qtAs($start, 'timestamp') . ' and punch <= ' . $me->{'dal'}->qtAs($end, 'timestamp') . ' and clerks.id=timeclock.clerk and timeclock.voidAt is null order by clerks.name');
    };
    if($@)
    {
        warn "Timeclock: the db returned an error: $@ ($me->{'dal'}->{'dbError'})\n";
        return ();
    }
    my @r;
    foreach my $i (1..$me->{'dal'}->{'tuples'})
    {
        my %h;
        ($h{'id'}, $h{'name'}) = $me->{'dal'}->fetchrow;
        push @r, \%h;
    }
    return @r;
}

sub getAllClerksInSpanOrderedByClockedIn
{
    my ($me, $start, $end) = @_;

    $me->{'dal'}->trace(STDERR) if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Timeclock/;

    my @r;

    eval
    {
        $me->{'dal'}->do('select distinct timeclock.clerk, clerks.name from timeclock, clerks where punch >= ' . $me->{'dal'}->qtAs($start, 'timestamp') . ' and punch <= ' . $me->{'dal'}->qtAs($end, 'timestamp') . ' and clerks.id=timeclock.clerk order by clerks.name');
    };
    if($@)
    {
        warn "Timeclock: the db returned an error: $@ ($me->{'dal'}->{'dbError'})\n";
        return ();
    }
    foreach my $i (1..$me->{'dal'}->{'tuples'})
    {
        my %h;
        ($h{'id'}, $h{'name'}) = $me->{'dal'}->fetchrow;
        push @r, \%h;
    }
    eval
    {
        $me->{'dal'}->do('select clerks.id, clerks.name from clerks where clerks.id not in (select distinct timeclock.clerk from timeclock where punch >= ' . $me->{'dal'}->qtAs($start, 'timestamp') . ' and punch <= ' . $me->{'dal'}->qtAs($end, 'timestamp') . ') and voidAt is null order by clerks.name');
    };
    if($@)
    {
        warn "Timeclock: the db returned an error: $@ ($me->{'dal'}->{'dbError'})\n";
        return ();
    }
    foreach my $i (1..$me->{'dal'}->{'tuples'})
    {
        my %h;
        ($h{'id'}, $h{'name'}) = $me->{'dal'}->fetchrow;
        push @r, \%h;
    }
    return @r;
}

sub getAllPossibleClerks
{
    my ($me) = @_;

    #this function is here because in the future it will check the "able to use timeclock" ability

    $me->{'dal'}->trace(STDERR) if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Timeclock/;
    
    eval
    {
        $me->{'dal'}->do('select distinct clerks.id, clerks.name from clerks where voidAt is null order by clerks.name');
    };
    if($@)
    {
        warn "Timeclock: the db returned an error: $@ ($me->{'dal'}->{'dbError'})\n";
        return ();
    }
    my @r;
    foreach my $i (1..$me->{'dal'}->{'tuples'})
    {
        my %h;
        ($h{'id'}, $h{'name'}) = $me->{'dal'}->fetchrow;
        push @r, \%h;
    }
    return @r;   
}

sub getAllClerksInSpan
{
    my ($me, $start, $end) = @_;

    $me->{'dal'}->trace(STDERR) if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Timeclock/;

    eval
    {
        $me->{'dal'}->do('select distinct timeclock.clerk, clerks.name from timeclock, clerks where punch >= ' . $me->{'dal'}->qtAs($start, 'timestamp') . ' and punch <= ' . $me->{'dal'}->qtAs($end, 'timestamp') . ' and clerks.id=timeclock.clerk order by clerks.name');
    };
    if($@)
    {
        warn "Timeclock: the db returned an error: $@ ($me->{'dal'}->{'dbError'})\n";
        return ();
    }
    my @r;
    foreach my $i (1..$me->{'dal'}->{'tuples'})
    {
        my %h;
        ($h{'id'}, $h{'name'}) = $me->{'dal'}->fetchrow;
        push @r, \%h;
    }
    return @r;
}

sub getClerksClockedIn
{
    my ($me, $date) = @_;

    $me->{'dal'}->trace(STDERR) if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Timeclock/;

    eval
    {
        $me->{'dal'}->do('select q.clerk, clerks.name from (select count(punch) % 2 as isclockedin, clerk from timeclock where voidAt is null and getBusinessDayFor(punch) = ' . $me->{'dal'}->qtAs($date, 'date') . ' group by clerk) as q, clerks where isclockedin=1 and clerks.id=q.clerk order by clerks.name');
    };
    if($@)
    {
        warn "Timeclock: the db returned an error: $@ ($me->{'dal'}->{'dbError'})\n";
        return ();
    }
    my @r;
    foreach my $i (1..$me->{'dal'}->{'tuples'})
    {
        my %h;
        ($h{'id'}, $h{'name'}) = $me->{'dal'}->fetchrow;
        push @r, \%h;
    }
    return @r;
}

sub getVoidClerksInSpan
{
    my ($me, $start, $end) = @_;

    $me->{'dal'}->trace(STDERR) if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Timeclock/;

    eval
    {
        $me->{'dal'}->do('select distinct timeclock.clerk, clerks.name from timeclock, clerks where punch >= ' . $me->{'dal'}->qtAs($start, 'timestamp') . ' and punch <= ' . $me->{'dal'}->qtAs($end, 'timestamp') . ' and clerks.id=timeclock.clerk and timeclock.voidAt is not null order by clerks.name');
    };
    if($@)
    {
        warn "Timeclock: the db returned an error: $@ ($me->{'dal'}->{'dbError'})\n";
        return ();
    }
    my @r;
    foreach my $i (1..$me->{'dal'}->{'tuples'})
    {
        my %h;
        ($h{'id'}, $h{'name'}) = $me->{'dal'}->fetchrow;
        push @r, \%h;
    }
    return @r;
}

sub getPunchesInSpan
{
    my ($me, $clerk, $start, $end) = @_;
    $me->{'dal'}->trace(STDERR) if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Timeclock/;

    eval
    {
        $me->{'dal'}->do('select punch from timeclock where punch >= ' . $me->{'dal'}->qtAs($start, 'timestamp') . ' and punch <= ' . $me->{'dal'}->qtAs($end, 'timestamp') . ' and clerk = ' . int($clerk) . ' and voidAt is null order by punch');
    };
    if($@)
    {
        warn "Timeclock: the db returned an error: $@ ($me->{'dal'}->{'dbError'})\n";
        return ();
    }
    my @r;
    push @r, $me->{'dal'}->fetchrow foreach (1..$me->{'dal'}->{'tuples'});
    return @r;
}

sub getAllPunchesInSpan
{
    my ($me, $clerk, $start, $end) = @_;
    $me->{'dal'}->trace(STDERR) if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Timeclock/;

    eval
    {
        $me->{'dal'}->do('select punch from timeclock where punch >= ' . $me->{'dal'}->qtAs($start, 'timestamp') . ' and punch <= ' . $me->{'dal'}->qtAs($end, 'timestamp') . ' and clerk = ' . int($clerk) . ' order by punch');
    };
    if($@)
    {
        warn "Timeclock: the db returned an error: $@ ($me->{'dal'}->{'dbError'})\n";
        return ();
    }
    my @r;
    push @r, $me->{'dal'}->fetchrow foreach (1..$me->{'dal'}->{'tuples'});
    return @r;
}

sub getVoidPunchesInSpan
{
    my ($me, $clerk, $start, $end) = @_;
    $me->{'dal'}->trace(STDERR) if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Timeclock/;

    eval
    {
        $me->{'dal'}->do('select punch from timeclock where punch >= ' . $me->{'dal'}->qtAs($start, 'timestamp') . ' and punch <= ' . $me->{'dal'}->qtAs($end, 'timestamp') . ' and clerk = ' . int($clerk) . ' and voidAt is not null order by punch');
    };
    if($@)
    {
        warn "Timeclock: the db returned an error: $@ ($me->{'dal'}->{'dbError'})\n";
        return ();
    }
    my @r;
    push @r, $me->{'dal'}->fetchrow foreach (1..$me->{'dal'}->{'tuples'});
    return @r;
}

sub getHoursInSpan
{
    my ($me, $clerk, $start, $end) = @_;

    $me->{'dal'}->trace(STDERR) if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Timeclock/;

    eval
    {
        $me->{'dal'}->do('select (secondsWorkedCompleted(punch) / 3600)::numeric(15,4) as hours from (select punch from timeclock where punch >= ' . $me->{'dal'}->qtAs($start, 'timestamp') . ' and punch <= ' . $me->{'dal'}->qtAs($end, 'timestamp') . ' and clerk = ' . int($clerk) . ' and voidAt is null order by punch) as clock');
    };
    if($@)
    {
        warn "Timeclock: the db returned an error: $@ ($me->{'dal'}->{'dbError'})\n";
        return -1;
    }
    my ($h) = $me->{'dal'}->fetchrow;
    #remove the trailing zeros
    $h =~ s/\.?(0*)$//;
    return $h;
}

sub forcePunch
{
    my ($me, $clerk, $punch) = @_;

    $me->{'dal'}->trace(STDERR) if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Timeclock/;

    eval
    {
        $me->{'dal'}->do('insert into timeclock (clerk, punch, forced) values (' . int($clerk) . ', ' .  $me->{'dal'}->qtAs($punch, 'timestamp') . ', true)');
    };
    if($@)
    {
        warn "Timeclock::punch($clerk): the db returned an error: $@ ($me->{'dal'}->{'dbError'})\n";
        return 0;
    }
    return 1;
}

sub voidPunch
{
    my ($me, $clerk, $punch) = @_;

    $me->{'dal'}->trace(STDERR) if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Timeclock/;

    eval
    {
        $me->{'dal'}->do('update timeclock set voidAt=current_timestamp where clerk=' . int($clerk) . ' and punch=' .  $me->{'dal'}->qtAs($punch, 'timestamp'));
    };
    if($@)
    {
        warn "Timeclock::punch($clerk): the db returned an error: $@ ($me->{'dal'}->{'dbError'})\n";
        return 0;
    }
    return 1;
}

sub unvoidPunch
{
    my ($me, $clerk, $punch) = @_;

    $me->{'dal'}->trace(STDERR) if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Timeclock/;

    eval
    {
        $me->{'dal'}->do('update timeclock set voidAt=null, voidBy=null where clerk=' . int($clerk) . ' and punch=' .  $me->{'dal'}->qtAs($punch, 'timestamp'));
    };
    if($@)
    {
        warn "Timeclock::punch($clerk): the db returned an error: $@ ($me->{'dal'}->{'dbError'})\n";
        return 0;
    }
    return 1;
}

sub getTimestampForBusinessDayAndTime
{
    my ($me, $biz, $time) = @_;

    $me->{'dal'}->trace(STDERR) if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Timeclock/;

    eval
    {
        $me->{'dal'}->do('select case when data::time <= ' . $me->{'dal'}->qtAs($time, 'time') . ' then (' . $me->{'dal'}->qt($biz) . ' ||\' \'|| ' . $me->{'dal'}->qt($time) . ')::timestamp with time zone else ((' . $me->{'dal'}->qtAs($biz, 'date') . ' + 1) ||\' \'|| ' . $me->{'dal'}->qt($time) . ')::timestamp with time zone end from sysstrings where id like \'Lane/CORE/Business Day Start Time\'');
    };
    if($@)
    {
        warn "Timeclock: the db returned an error: $@ ($me->{'dal'}->{'dbError'})\n";
        return -1;
    }
    my ($h) = $me->{'dal'}->fetchrow;
    return $h;
}

1;
