#Tender.pm
#Copyright 2001-2010 Jason Burrell.
#LanePOS see $LaneROOT/documentation/README
#$Id: Tender.pm 1165 2010-09-29 01:22:39Z jason $

package LanePOS::Tender;

require 5.008;

use base 'LanePOS::GenericObject';

sub new
{
    my ($class, $dal) = @_;
    $class = ref($class) || $class || 'LanePOS::Tender';
    my $me = $class->SUPER::new($dal);
    
    $me->{'table'} = 'tenders';
    $me->{'columns'} = [
	'id',
	'descr',
	'allowChange',
	'mandatoryAmt',
	'openDrawer',
	'pays',
	'eprocess',
	'eauth',
	'allowZero',
	'allowNeg',
	'allowPos',
	'requireItems', #r: require items, d: do not allow items, a: items may or may not be present
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

sub _resetFlds
{
    my ($me) = @_;
    $me->SUPER::_resetFlds();
    #we don't need this anymore
    #$me->{'passcode'} = '-Don\'t Authorize-';
    $me->{$_} = 1 foreach (qw/allowZero allowNeg allowPos/);
    $me->{'requireItems'} = 'a';
}

sub getAllTenders
{
    my ($me) = @_;

    my @rtn;

    eval {
        $me->{'dal'}->do('select id, descr, allowChange, mandatoryAmt, openDrawer, pays, eprocess, eauth, allowZero, allowNeg, allowPos, requireItems, voidAt, voidBy, created, createdBy, modified, modifiedBy from tenders where voidAt is null order by id');

        foreach (1..$me->{'dal'}->{'tuples'})
        {
            my %t;
            ($t{'id'}, $t{'descr'}, $t{'allowChange'}, $t{'mandatoryAmt'}, $t{'openDrawer'}, $t{'pays'}, $t{'eprocess'}, $t{'eauth'}, $t{'allowZero'}, $t{'allowNeg'}, $t{'allowPos'}, $t{'requireItems'}, $t{'voidAt'}, $t{'voidBy'}, $t{'created'}, $t{'createdBy'}, $t{'modified'}, $t{'modifiedBy'}) = $me->{'dal'}->fetchrow;
            push @rtn, \%t;
        }
    };
    if($@)
    {
        warn "Tender::getAllTenders() caught an exception! ($@)\n";
    }
    return @rtn;
}

1;
