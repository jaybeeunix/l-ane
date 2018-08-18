#Perl Module for Machines info access
#Copyright 1999-2010 Jason Burrell.
#This file is part of L'ane. See COPYING for licensing information.

#$Id: Machine.pm 1196 2010-10-24 18:02:54Z jason $

package LanePOS::Machine;
require 5.008;

#lbms
use base 'LanePOS::GenericObject';

use LanePOS::Locale;

sub new
{
    my ($class, $dal) = @_;
    $class = ref($class) || $class || 'LanePOS::Machine';
    my $me = $class->SUPER::new($dal);
    
    $me->{'table'} = 'machines';
    $me->{'columns'} = [
	'make',
	'model',
	'sn',
	'counter',
	'accessories',
	'owner',
	'location',
	'purchased',
	'lastService',
	'notes',
	'onContract',
	'contractBegins',
	'contractEnds',
        'createdBy',
        'created',
        'voidAt',
        'voidBy',
        'modified',
        'modifiedBy',
        ];
    $me->{'keys'} = [qw/make model sn/];
    $me->{'disallowNullKeys'} = 1;
    $me->{'revisioned'} = 1;
    $me->{'booleans'} = {
        'onContract' => 1,
    };

    $me->{'lc'} = Locale->new($me->{'dal'}) if !(exists $me->{'lc'} and UNIVERSAL::isa($me->{'lc'}, 'LanePOS::Locale'));

    return $me;
}

sub open
{
    my ($me, @x) = @_;

    my $r = $me->SUPER::open(@x);
    if($r)
    {
        foreach ('purchased', 'lastService', 'contractBegins', 'contractEnds')
        {
            next if !defined $me->{$_} or $me->{$_} eq '';
            $me->{$_} = $me->{'lc'}->temporalFmt('shortDate', $me->{$_});
        }

    }
    return $r;
}

sub save
{
    my $me = shift;

    $me->{'purchased'} = '' if $me->{'purchased'} and $me->{'purchased'} eq '-';
    $me->{'lastService'} = '' if $me->{'lastService'} and $me->{'lastService'} eq '-';
    $me->{'contractBegins'} = '' if $me->{'contractBegins'} and $me->{'contractBegins'} eq '-';
    $me->{'contractEnds'} = '' if $me->{'contractEnds'} and $me->{'contractEnds'} eq '-';

    return $me->SUPER::save;
}

sub getAllOwned
{		# returns an array, or an empty string
    my ($me, $id) = @_;

    my @rtn;

    $me->{'dal'}->select(
        'what' => $me->{'columns'},
        'from' => [$me->{'table'}],
        'where' => [['owner', '=', $me->{'dal'}->qtAs($id, 'not-null')], 'and', ['voidAt', 'is null']],
        'orderBy' => ['make', 'model', 'sn'],
        )->do;

    foreach my $i (1..$me->{'dal'}->{'tuples'})
    {
	my %tmp;
        my @row = $me->{'dal'}->fetchrow;
        foreach my $j (0..$#row)
        {
            $tmp{$me->{'columns'}[$j]} = $row[$j];
        }
	push @rtn, \%tmp;
    }
    #this should probably be removed
    if($#rtn == -1)
    {
	return '';	      # didn't find any machines owned by $id
    }

    return @rtn;
}

sub isOnContract
{
    my ($me) = @_;

    return $me->{'onContract'};
}

sub findLike
{			# finds machines like the given
    my ($me, $mk, $mdl, $sn) = @_;
    my @found;
    my @where = ([qw/voidAt is null/]);

    if($mk)
    {
	push @where, 'and';
        push @where, [qw/make ilike/, $me->{'dal'}->qt("%$mk%")];
    }
    if($mdl)
    {
	push @where, 'and';
        push @where, [qw/model ilike/, $me->{'dal'}->qt("%$mdl%")];
    }
    if($sn)
    {
	push @where, 'and';
        push @where, [qw/sn ilike/, $me->{'dal'}->qt("%$sn%")];
    }

    $me->{'dal'}->select(
        'what' => $me->{'columns'},
        'from' => [$me->{'table'}],
        'where' => \@where,
        'orderBy' => ['make', 'model', 'sn'],
        )->do;

    foreach my $i (1..$me->{'dal'}->{'tuples'})
    {
	my %tmp;
        my @row = $me->{'dal'}->fetchrow;
        foreach my $j (0..$#row)
        {
            $tmp{$me->{'columns'}[$j]} = $row[$j];
        }
	push @found, \%tmp;
    }
    if($#found == -1)
    {
	return '';		# didn't find anything like those
    }
    return @found;		# everything went ok (prob ;) )
}

sub getAllOnContract
{
    my ($me) = @_;

    my @r;
    $me->{'dal'}->select(
        'what' => [$me->{'keys'}],
        'from' => [$me->{'table'}],
        'where' => [['onContract', 'is true'], 'and', ['voidAt', 'is null']],
        'orderBy' => ['contractEnds', @{$me->{'keys'}}],
        )->do;
    foreach my $i (1..$me->{'dal'}->{'tuples'})
    {
        my %tmp;
        my @row = $me->{'dal'}->fetchrow;
        foreach my $j (0..$#row)
        {
            $tmp{$me->{'keys'}[$j]} = $row[$j];
        }
	push @r, \%tmp;
    }
    return @r;
}

1;
