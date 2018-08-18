#!/usr/bin/perl -w

#obj-02qwo.t
#Copyright 2009-2010 Jason Burrell.
#This file is part of L'anePOS. See the top-level COPYING for licensing info.

#$Id: obj-02qwo.t 1165 2010-09-29 01:22:39Z jason $

#L'ane obj test
# - qwo objects

use Test::More tests => 30;
#use Test::More 'no_plan';

use Data::Dumper;

BEGIN {
    use FindBin;
    use File::Spec;
    $ENV{'LaneRoot'} = File::Spec->catdir($FindBin::Bin, File::Spec->updir); #use the correct number of updirs
    require File::Spec->catfile($ENV{'LaneRoot'}, 'config', 'init.pl');
}

BEGIN { use_ok('LanePOS::QWO'); }

my $q = QWO->new();
isa_ok($q, 'QWO');

#these are the only public methods
can_ok($q, qw/
new
open
save
void
isVoid
searchByCust
getAllNeedingOurWork
getAllNeedingCustomerInput
rev
openRev
/);

my $username = $q->{'dal'}->getUsername;

ok($username, 'getUsername');

my @ids;

my %woByCust;

my @us;
my @them;

my @expected = (
    {
        #'id' => undef,
	'dateIssued' => '01-01-2001',
	'type' => $QWO::types[2],
	'customer' => '2173424900',
	'notes' => 'this is a note',
	'make' => 'IBM',
	'model' => 'PCjr',
	'sn' => 12345,
	'counter' => 0,
	'accessories' => 'none',
	'loanerMake' => 'Sun',
	'loanerModel' => 'Ray 2',
	'loanerSn' => 6789,
	'loanerCounter' => 0,
	'loanerAccessories' => 'none',
	'custProb' => 'Stuff doesn\'t work',
	'tech' => 'Pat',
	'techNotes' => 'They didn\'t turn it on',
	'solution' => 'Cleaned and tested. No problem found.',
	'status' => $QWO::statuses[3],
	'createdBy' => $username,
	'created' => undef, #this will get set after save
	'modifiedBy' => $username,
	'modified' => undef, #this will get set after save
	'voidBy' => undef,
	'voidAt' => undef,

	'statuses' => [
            {
                #'id' => undef,
                'status' => $QWO::statuses[0],
                'staff' => substr($ENV{'USER'}, 0, 10),
                'contact' => 'Ms. Blah',
                'notes' => 'this is a note',
                'createdBy' => $username,
                'created' => undef,
                'modifiedBy' => $username,
                'modified' => undef, #this will get set after save
                'voidBy' => undef,
                'voidAt' => undef,
            },
            {
                #'id' => undef,
                'status' => $QWO::statuses[3],
                'staff' => substr($ENV{'USER'}, 0, 10),
                'contact' => 'Ms. Blah',
                'notes' => 'this is a note',
                'createdBy' => $username,
                'created' => undef,
                'modifiedBy' => $username,
                'modified' => undef, #this will get set after save
                'voidBy' => undef,
                'voidAt' => undef,
            },
            ],

    },
    {
        #'id' => undef,
	'dateIssued' => '02-03-2004',
	'type' => $QWO::types[1],
	'customer' => '',
	'notes' => 'this is a note',
	'make' => 'Sun',
	'model' => 'Ray 2',
	'sn' => 6789,
	'counter' => 0,
	'accessories' => 'none',
	'loanerMake' => '',
	'loanerModel' => '',
	'loanerSn' => '',
	'loanerCounter' => 0,
	'loanerAccessories' => '',
	'custProb' => 'Other Stuff doesn\'t work',
	'tech' => 'Jason',
	'techNotes' => 'Jasonz notes',
	'solution' => 'Magically solution',
	'status' => $QWO::statuses[2],
	'createdBy' => $username,
	'created' => undef, #this will get set after save
	'modifiedBy' => $username,
	'modified' => undef, #this will get set after save
	'voidBy' => undef,
	'voidAt' => undef,

	'statuses' => [
            {
                #'id' => undef,
                'status' => $QWO::statuses[0],
                'staff' => substr($ENV{'USER'}, 0, 10),
                'contact' => 'Ms. Blah1',
                'notes' => 'this is a note3',
                'createdBy' => $username,
                'created' => undef,
                'modifiedBy' => $username,
                'modified' => undef, #this will get set after save
                'voidBy' => undef,
                'voidAt' => undef,
            },
            {
                #'id' => undef,
                'status' => $QWO::statuses[1],
                'staff' => substr($ENV{'USER'}, 0, 10),
                'contact' => 'Ms. Blah2',
                'notes' => 'this is a note2',
                'createdBy' => $username,
                'created' => undef,
                'modifiedBy' => $username,
                'modified' => undef, #this will get set after save
                'voidBy' => undef,
                'voidAt' => undef,
            },
            {
                #'id' => undef,
                'status' => $QWO::statuses[2],
                'staff' => substr($ENV{'USER'}, 0, 10),
                'contact' => 'Ms. Blah3',
                'notes' => 'this is a note3',
                'createdBy' => $username,
                'created' => undef,
                'modifiedBy' => $username,
                'modified' => undef, #this will get set after save
                'voidBy' => undef,
                'voidAt' => undef,
            },
            ],

    },
    );

#create the new qwo record(s)
foreach my $e (@expected)
{
    $q = QWO->new();
    $q->{$_} = clone($e->{$_}) foreach keys %$e;
    ok($q->save, 'save() worked');
    my $x = QWO->new();
    ok($x->open($q->{'id'}), '    util open() worked');
    #diag(Dumper($x));
    $e->{'created'} = $x->{'created'};
    $e->{'modified'} = $x->{'modified'};
    $e->{'id'} = $q->{'id'};
    push @ids, $e->{'id'};
    #save doesn't set created
    $q->{'created'} = $x->{'created'};
    $q->{'modified'} = $x->{'modified'};
    foreach my $i (0..$#{$q->{'statuses'}})
    {
        $e->{'statuses'}[$i]{'id'} = $q->{'id'};
        $e->{'statuses'}[$i]{'created'} = $x->{'created'};
        $q->{'statuses'}[$i]{'created'} = $x->{'created'};
        $e->{'statuses'}[$i]{'modified'} = $x->{'modified'};
        $q->{'statuses'}[$i]{'modified'} = $x->{'modified'};
    }
    push @{$woByCust{$q->{'customer'}}}, $e;
    if($e->{'status'} =~ /^Awaiting Estimate|Approved$/)
    {
        push @us, $e->{'id'};
    }
    elsif($e->{'status'} =~ /^Estimate Given|Estimate Denied|Serviced$/)
    {
        push @them, $e->{'id'};
    }
    else
    {
        diag("$e->{'id'} has an unknown status!\n");
    }
    #dbi doesn't like to be cloned
    delete $q->{'dal'};
    delete $q->{'lc'};
    my $wo = clone($q);
    $q = QWO->new;
    #strip out the GenericObject things
    foreach my $d ('columns', 'keys', 'kids', 'table', 'booleans', 'exts', 'revisioned', 'hideVoidFromOpen', 'username')
    {
	delete $wo->{$d};
    }
    is_deeply($wo, $e, 'the saved item is like the expected item');
}

#searchByCust
{
    foreach my $c (keys %woByCust)
    {
        #simplify the expected value as searchByCust() only returns summary info
        my $e = clone($woByCust{$c});
        foreach my $k (@$e)
        {
            delete $k->{'statuses'};
        }
        my @r = $q->searchByCust($c);
        is($#r, $#{$woByCust{$c}}, 'searchByCust() returned the expected record(s)');
        is_deeply(\@r, $e, '    the expected data');
    }
}

#getAllNeedingOurWork
{
    my @r = $q->getAllNeedingOurWork();

    is_deeply(\@r, \@us, 'getAllNeedingOurWork() returned the expected data');
}

#getAllNeedingCustomerInput
{
    my @r = $q->getAllNeedingCustomerInput();

    is_deeply(\@r, \@them, 'getAllNeedingCustomerInput() returned the expected data');
}

#cleanup
foreach (@ids)
{
    ok(($q->open($_) and $q->void), 'void my WOs');
    ok(($q->open($_) and $q->isVoid), '   isVoid checked');
}

#rev
{
    my %expRev = (
	$ids[0] => [3, 1],
	$ids[1] => [4, 2],
	);
    foreach my $id (@ids)
    {
	my @rev = $q->rev($id);
	is_deeply(\@rev, $expRev{$id}, "$id had the expected revisions");
	ok($q->openRev($id, $expRev{$id}[0]), "   openRev($id, $expRev{$id}[0])");
	ok($q->isVoid, '   the newest isVoid');
	ok($q->openRev($id, $expRev{$id}[1]), "   openRev($id, $expRev{$id}[1])");
	ok(!$q->isVoid, '   the oldest isn\'t');
    }
}

sub clone
{
    my ($d) = @_;
    my $ref = ref($d);
    if($ref eq 'HASH' or UNIVERSAL::isa($d, 'HASH'))
    {
	$d = {%{$d}};
	foreach my $k (keys %{$d})
	{
	    next if !ref($d->{$k});
	    $d->{$k} = clone($d->{$k});
	}
	bless($d, $ref) if $ref ne 'HASH';
    }
    elsif($ref eq 'ARRAY' or UNIVERSAL::isa($d, 'ARRAY'))
    {
	$d = [@{$d}];
	foreach my $k (@{$d})
	{
	    next if !ref($k);
	    $k = clone($k);
	}
	bless($d, $ref) if $ref ne 'ARRAY';
    }
    #should we handle various other blessed types too?
    return $d;
}

1;
