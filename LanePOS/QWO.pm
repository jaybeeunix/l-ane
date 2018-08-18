#Perl Module for QWO info access
#part of L'ane BMS
#Copyright 1999-2010 Jason Burrell

#$Id: QWO.pm 1193 2010-10-22 21:10:11Z jason $

package LanePOS::QWO;
require 5.008;

use base 'LanePOS::GenericObject';

our @types;

our @statuses;

#this should actually be by type ("serviced", "* service call" would need to be "taken back", for example)
our @needsWorkStat = (0, 3);

our @needsCustInputStat = (1, 2, 4);

use LanePOS::Locale;

sub new
{
    my ($class, $dal) = @_;
    $class = ref($class) || $class || 'LanePOS::QWO';
    my $me = $class->SUPER::new($dal);

    $me->{'table'} = 'qwo';
    $me->{'columns'} = [
	'id', #was 'num',
	'dateIssued',
	'type',
	'customer',
	'notes',
	'make',
	'model',
	'sn',
	'counter',
	'accessories',
	'loanerMake',
	'loanerModel',
	'loanerSn',
	'loanerCounter',
	'loanerAccessories',
	'custProb',
	'tech',
	'techNotes',
	'solution',
	'status',
	'createdBy',
	'created',
	'voidAt',
	'voidBy',
	'modified',
	'modifiedBy',
     ];
    $me->{'keys'} = ['id'];
    #$me->{'disallowNullKeys'} = 1;
    $me->{'kids'} = [
        {
            'table' => 'qwoStatuses',
            'keys' => ['id', 'status'],
            'columns' => [qw/id status staff contact notes createdBy created voidAt voidBy modified modifiedBy/],
        },
        ];
    $me->{'revisioned'} = 1;

    #configure the statuses
    $me->{'lc'} = Locale->new($me->{'dal'}) if !(exists $me->{'lc'} and UNIVERSAL::isa($me->{'lc'}, 'Locale'));
    my %tmp = $me->{'lc'}->getAllLike('Lane/QWO/Type/');
    foreach my $k (keys %tmp)
    {
	my ($v) = ($k =~ m{^Lane/QWO/Type/(\d+)});
	next if $v !~ /^\d+$/;
	$types[$v] = $tmp{$k};
    }
    %tmp = $me->{'lc'}->getAllLike('Lane/QWO/Status/');
    foreach my $k (keys %tmp)
    {
	my ($v) = ($k =~ m{^Lane/QWO/Status/(\d+)});
	next if !defined($v) or $v !~ /^\d+$/;
	$statuses[$v] = $tmp{$k};
    }

    return $me;
}

sub convertType2Str
{
    my ($me, $num) = @_;
    $$num = $types[$$num];
}

sub convertStatus2Str
{
    my ($me, $num) = @_;
    $$num = $statuses[$$num];
}

sub typeIndex
{
    my ($me, $str) = @_;
    for(my $i = 0; $i <= $#types; $i++)
    {
	if($types[$i] eq $str)
	{
	    return $i;
	}
    }
    return 0;
}

sub statusesIndex
{
    my ($me, $str) = @_;

    for(my $i = 0; $i <= $#statuses; $i++)
    {
	if($statuses[$i] eq $str)
	{
	    return $i;
	}
    }
    return 0;
}

sub newStat
{
    my ($me) = @_;

    push @{$me->{'statuses'}}, {
	'id' => undef,
	'status' => '',
	'staff' => $ENV{'USER'},
	'contact' => ' ',
	'notes' => ' ',
	'createdBy' => undef,
	'created' => undef,
	'voidAt' => undef,
	'voidBy' => undef,
	'modified' => undef,
	'modifiedBy' => undef,
    };
}

sub open
{
    my $me = shift;

    my $r = $me->SUPER::open(@_);
    if($r)
    {
        foreach my $s (@{$me->{'statuses'}})
        {
            $me->convertStatus2Str(\$s->{'status'});
            foreach ('created')
            {
                next if !defined $s->{$_} or $s->{$_} eq '';
                $s->{$_} = $me->{'lc'}->temporalFmt('shortTimestamp', $s->{$_});
            }       
        }
        foreach ('dateIssued')
        {
            next if !defined $me->{$_} or $me->{$_} eq '';
            $me->{$_} = $me->{'lc'}->temporalFmt('shortDate', $me->{$_});
        }       
	$me->convertType2Str(\$me->{'type'});
	$me->convertStatus2Str(\$me->{'status'});
    }
    return $r;
}

sub save
{
    my ($me) = @_;


    #put the statuses into the expected form
    $me->{'status'} = $me->statusesIndex($me->{'status'});
    #get rid of extra whitespace at the end
    foreach my $n ($me->{'notes'}, $me->{'custProb'}, $me->{'techNotes'}, $me->{'solution'}, )
    {
	$n =~ s/\s+$//g;
    }
    foreach my $s (@{$me->{'statuses'}})
    {
        $s->{'status'} = $me->statusesIndex($s->{'status'});
        $me->{'status'} = $s->{'status'} if $s->{'status'} > $me->{'status'};
	$s->{'voidAt'} = $me->{'voidAt'} if $me->isVoid;
	$s->{'notes'} =~ s/\s+$//g;
    }

    $me->{'type'} = $me->typeIndex($me->{'type'});

    #allow GenericObject to handle the db business
    my $r = $me->SUPER::save;

    #convert things back to the expected format
    foreach my $s (@{$me->{'statuses'}})
    {
        $me->convertStatus2Str(\$s->{'status'});
        foreach ('created')
        {
            next if !defined $s->{$_} or $s->{$_} eq '';
            $s->{$_} = $me->{'lc'}->temporalFmt('shortTimestamp', $s->{$_});
        }       
    }
    $me->convertType2Str(\$me->{'type'});
    $me->convertStatus2Str(\$me->{'status'});
    return $r;
}

sub searchByCust
{
    my ($me, $id) = @_;
    my @rtn;
    $me->{'dal'}->select(
        'what' => $me->{'columns'},
        'from' => [$me->{'table'}],
        'where' => [['customer', '=', $me->{'dal'}->qtAs($id, 'not-null')],],
        'orderBy' => ['-dateIssued', '-id'],
        )->do;

    foreach my $i (1..$me->{'dal'}->{'tuples'})
    {
	my %tmp;
        my @row = $me->{'dal'}->fetchrow;
        foreach my $j (0..$#row)
        {
            $tmp{$me->{'columns'}[$j]} = $row[$j];
        }
        $me->convertType2Str(\$tmp{'type'});
        $me->convertStatus2Str(\$tmp{'status'});
        foreach ('dateIssued')
        {
            next if !defined $tmp{$_} or $tmp{$_} eq '';
            $tmp{$_} = $me->{'lc'}->temporalFmt('shortDate', $tmp{$_});
        }
	push @rtn, \%tmp;
    }
    return @rtn;
}

sub getAllNeedingOurWork
{
    my ($me) = @_;

    my @rtn;

    $me->{'dal'}->select(
        'what' => ['id'],
        'from' => ['qwo'],
        'where' => [['status', 'in', '(' . join(', ', map {int($_) || '0'} @needsWorkStat) .')'],],
        'orderBy' => ['dateIssued'],
        )->do;

    foreach my $i (1..$me->{'dal'}->{'tuples'})
    {
	push @rtn, ($me->{'dal'}->fetchrow)[0];
    }
    return @rtn;
}

sub getAllNeedingCustomerInput
{
    my ($me) = @_;

    my @rtn;

    $me->{'dal'}->select(
        'what' => ['id'],
        'from' => ['qwo'],
        'where' => [['status', 'in', '(' . join(', ', map {int($_) || '0'} @needsCustInputStat) .')'],],
        'orderBy' => ['dateIssued'],
        )->do;

    foreach my $i (1..$me->{'dal'}->{'tuples'})
    {
	push @rtn, ($me->{'dal'}->fetchrow)[0];
    }
    return @rtn;
}

1;
