#!/usr/bin/perl -w

#obj-01dal-select.t
#Copyright 2009-2010 Jason Burrell.
#This file is part of L'anePOS. See the top-level COPYING for licensing info.

#L'ane obj test
# - Dal::select

use Test::More tests => 37;
#use Test::More 'no_plan';

BEGIN {
    use FindBin;
    use File::Spec;
    $ENV{'LaneRoot'} = File::Spec->catdir($FindBin::Bin, File::Spec->updir); #use the correct number of updirs
    require File::Spec->catfile($ENV{'LaneRoot'}, 'config', 'init.pl');
}

use Data::Dumper;

BEGIN
{
    use_ok('LanePOS::Dal');
    use_ok('LanePOS::Dal::select'); #FIXME@@@@ remove this after Dal has support for helpers
    #use_ok('LanePOS::Dal::Helper'); #FIXME@@@@ remove this after Dal has support for helpers
}

my $dal = Dal->new();
isa_ok($dal, 'Dal');

my $dh = LanePOS::Dal::select->new($dal);
isa_ok($dh, 'LanePOS::Dal::Helper');

#diag('general object methods');
can_ok($dh, qw/new do sqlString/);

#sqlString tests
{
    is($dh->new($dal, what => ['current_timestamp'])->sqlString, "SELECT current_timestamp", 'simple single item select');
    is($dh->new($dal,
                what => ['current_timestamp'],
                distinct => 1,
       )->sqlString, "SELECT DISTINCT current_timestamp", 'simple single item select w/distinct');

    is($dh->new($dal,
                what => ['id', 'data'],
                from => ['sysStrings'],
                where => [[qw/id = 'obj-01sysstring.t-test'/]],
       )->sqlString, "SELECT id, data\n\tFROM sysStrings\n\tWHERE id = 'obj-01sysstring.t-test' ", 'simple two item select with a from and a where');
}
#do() tests
{
    ok($dh->new($dal,
                what => ['id', 'data'],
                from => ['sysStrings'],
                where => [[qw/id = 'obj-01sysstring.t-test'/]],
       )->do(), 'simple two item select with a from and a where');
    my @d = $dal->fetchrow;
    cmp_ok($#d, '==', 1, 'returned the correct number of elements');
    is_deeply(\@d, ['obj-01sysstring.t-test', 'The sys test data.'], 'returned the expected data');
}

#autoloaded do test
{
    pass('autoloaded do() test');
    ok($dal->select(what => ['id', 'data'],
                    from => ['sysStrings'],
                    where => [[qw/id = 'obj-01sysstring.t-test'/]],
       )->do(), 'autoloaded via Dal');
    my @d = $dal->fetchrow;
    cmp_ok($#d, '==', 1, 'returned the correct number of elements');
    is_deeply(\@d, ['obj-01sysstring.t-test', 'The sys test data.'], 'returned the expected data');
}

#order by test
{
    pass('order by');
    my @expected = (
        'Lane/Testing/Item',
        'Lane/Testing/Item ',
        'Lane/Testing/Item/',
        'Lane/Testing/Item1',
        'Lane/Testing/Item1/1',
        'Lane/Testing/Item2',
        );
    my @d;
    ok($dal->select(what => ['id'],
                    from => ['sysStrings'],
                    where => [[qw{id like 'Lane/Testing/%'}]],
                    orderBy => ['id'],
       )->do(), 'autoloaded via Dal');
    push @d, $dal->fetchrow foreach (1..$dal->{'tuples'});
    cmp_ok($#d, '==', $#expected, 'returned the correct number of elements');
    is_deeply(\@d, \@expected, 'returned the expected data');

    my @re = reverse @expected;
    @d = ();
    #$dal->trace(*STDERR);
    ok($dal->select(what => ['id'],
                    from => ['sysStrings'],
                    where => [[qw{id like 'Lane/Testing/%'}]],
                    orderBy => ['-id'],
       )->do(), 'autoloaded via Dal');
    push @d, $dal->fetchrow foreach (1..$dal->{'tuples'});
    #diag(Dumper(\@d));
    cmp_ok($#d, '==', $#re, 'returned the correct number of elements');
    is_deeply(\@d, \@re, 'returned the expected data');
}

#group by
{
    pass('group by');
    my @expected = (
        4 => 1234,
        1 => 5678,
        );
    my @d;
    ok($dal->select(what => ['count(*)', 'vendor'],
                    from => ['products'],
                    where => [[qw{voidAt is null}]],
                    groupBy => ['vendor'],
                    orderBy => ['vendor'],
       )->do(), 'autoloaded via Dal');
    push @d, $dal->fetchrow foreach (1..$dal->{'tuples'});
    cmp_ok($#d, '==', $#expected, 'returned the correct number of elements');
    is_deeply(\@d, \@expected, 'returned the expected data');

    @expected = (
        1 => 5678,
        4 => 1234,
        );
    @d = ();
    ok($dal->select(what => ['count(*)', 'vendor'],
                    from => ['products'],
                    where => [[qw{voidAt is null}]],
                    groupBy => ['vendor'],
                    orderBy => ['-vendor'],
       )->do(), 'autoloaded via Dal');
    push @d, $dal->fetchrow foreach (1..$dal->{'tuples'});
    cmp_ok($#d, '==', $#expected, 'returned the correct number of elements');
    is_deeply(\@d, \@expected, 'returned the expected data');
}

#limit
{
    pass('limit');
    my @expected = (
        'Lane/Testing/Item',
        'Lane/Testing/Item ',
        );
    #'Lane/Testing/Item/',
    #'Lane/Testing/Item1',
    #'Lane/Testing/Item1/1',
    #'Lane/Testing/Item2',
    #);
    my @d;
    ok($dal->select(what => ['id'],
                    from => ['sysStrings'],
                    where => [[qw{id like 'Lane/Testing/%'}]],
                    orderBy => ['id'],
                    limit => 2,
       )->do(), 'autoloaded via Dal');
    push @d, $dal->fetchrow foreach (1..$dal->{'tuples'});
    cmp_ok($#d, '==', $#expected, 'returned the correct number of elements');
    is_deeply(\@d, \@expected, 'returned the expected data');

}

#offset
{
    pass('offset');
    my @expected = (
        #'Lane/Testing/Item',
        'Lane/Testing/Item ',
        #'Lane/Testing/Item/',
        'Lane/Testing/Item1',
        );
    #'Lane/Testing/Item1/1',
    #'Lane/Testing/Item2',
    #);
    my @d;
    ok($dal->select(what => ['id'],
                    from => ['sysStrings'],
                    where => [
                        [qw{id like 'Lane/Testing/%'}],
                        'and',
                        [qw{id not like '%/'}],
                    ],
                    orderBy => ['id'],
                    limit => 2,
                    offset => 1,
       )->do(), 'autoloaded via Dal');
    push @d, $dal->fetchrow foreach (1..$dal->{'tuples'});
    cmp_ok($#d, '==', $#expected, 'returned the correct number of elements');
    is_deeply(\@d, \@expected, 'returned the expected data');

}
1;
