#!/usr/bin/perl -w

#obj-00dal.t
#Copyright 2009-2010 Jason Burrell.
#This file is part of L'anePOS. See the top-level COPYING for licensing info.

#L'ane obj test
# - Dal

use utf8;

#make sure our filehandles are utf8'ed
binmode(STDOUT, ':encoding(utf8)');
binmode(STDERR, ':encoding(utf8)');

use Test::More tests => 108;
#use Test::More 'no_plan';

BEGIN {
    use FindBin;
    use File::Spec;
    $ENV{'LaneRoot'} = File::Spec->catdir($FindBin::Bin, File::Spec->updir); #use the correct number of updirs
    require File::Spec->catfile($ENV{'LaneRoot'}, 'config', 'init.pl');
}

use Data::Dumper;

BEGIN { use_ok('LanePOS::Dal'); }

my $dal = Dal->new();
isa_ok($dal, 'Dal');

#diag('general object methods');
can_ok($dal, qw/new begin commit rollback abort do fetchrow qt qtAs dsnUrlParse trace reconnect fetchAllRows/);

#try a simple select
{
    ok($dal->do('select id, coName, terms from customers where id=\'\''), 'simple select on customers');
    my @v = $dal->fetchrow;
    #diag(Dumper(\@v));
    cmp_ok($#v, '==', 2, 'returned the correct number of rows');
    is($v[0], '', '    element 0 is as expected');
    is($v[1], 'Cash', '    element 1 is as expected');
    is($v[2], 'cod', '    element 2 is as expected');
}

#try a simple select in a transaction
{
    ok($dal->begin, 'begin transaction');
    ok($dal->do('select id, coName, terms from customers where id=\'\''), 'simple select on customers');
    my @v = $dal->fetchrow;
    #diag(Dumper(\@v));
    cmp_ok($#v, '==', 2, 'returned the correct number of rows');
    is($v[0], '', '    element 0 is as expected');
    is($v[1], 'Cash', '    element 1 is as expected');
    is($v[2], 'cod', '    element 2 is as expected');
    ok($dal->do('select id, coName, terms from customers where id=\'\''), 'simple select on customers');
    @v = $dal->fetchrow;
    #diag(Dumper(\@v));
    cmp_ok($#v, '==', 2, 'returned the correct number of rows');
    is($v[0], '', '    element 0 is as expected');
    is($v[1], 'Cash', '    element 1 is as expected');
    is($v[2], 'cod', '    element 2 is as expected');
    ok($dal->commit, 'commit');
}

#try a insert in a transaction
{
    ok($dal->begin, 'begin transaction');
    ok($dal->do('insert into strings (id, data) values (\'TESTING/obj-00dal.t\', 123)'), 'updating the test string');
    ok($dal->do('select data from strings where id=\'TESTING/obj-00dal.t\''), 'simple select on strings');
    my $v = $dal->fetchrow;
    is($v, '123', 'the data is as expected');
    ok($dal->commit, 'commit');
}

#try an update in a rolled-back transaction
{
    ok($dal->begin, 'begin transaction');
    ok($dal->do('update strings set data=789 where id=\'TESTING/obj-00dal.t\''), 'updating the test string');
    ok($dal->do('select data from strings where id=\'TESTING/obj-00dal.t\''), 'simple select on strings');
    my $v = $dal->fetchrow;
    is($v, '789', 'the data is as expected');
    ok($dal->rollback, 'rollback;');
    #make sure we can't see it
    ok($dal->do('select data from strings where id=\'TESTING/obj-00dal.t\''), 'simple select on strings');
    $v = $dal->fetchrow;
    is($v, '123', 'the data is as expected');
}

#try an update in a rolled-back transaction
{
    ok($dal->begin, 'begin transaction');
    ok($dal->do('update strings set data=789 where id=\'TESTING/obj-00dal.t\''), 'updating the test string');
    ok($dal->do('select data from strings where id=\'TESTING/obj-00dal.t\''), 'simple select on strings');
    my $v = $dal->fetchrow;
    is($v, '789', 'the data is as expected');
    ok($dal->abort, 'abort');
    #make sure we can't see it
    ok($dal->do('select data from strings where id=\'TESTING/obj-00dal.t\''), 'simple select on strings');
    $v = $dal->fetchrow;
    is($v, '123', 'the data is as expected');
}

#since strings is now versioned, you can't delete its rows
##remove
#{
#    ok($dal->do('delete from strings where id=\'TESTING/obj-00dal.t\''), 'simple select on strings');
#    #make sure we can't see it
#    ok($dal->do('select data from strings where id=\'TESTING/obj-00dal.t\''), 'simple select on strings');
#    $v = $dal->fetchrow;
#    is($v, undef, 'the data is gone');
#}

#try some quotes
{
    is($dal->qt('me'), "'me'", 'quote me');
    is($dal->qt('\''), "''''", 'quote \'\'');
    is($dal->qt('\\'), "'\\\\'", 'quote \\');

    #qtAs
    my @o = (
        #regular text
        ['me', 'text', "'me'"],
        ['me', 'char', "'me'"],
        ['me', 'character', "'me'"],
        ['me', '', "'me'"],
        #empty text
        ['', '', "null"],
        ['', 'text', "null"],
        ['', 'not-null', "''"],
        [undef, '', "null"],
        [undef, 'text', "null"],
        [undef, 'not-null', "''"],
        #numeric types
        [123, 'numeric', "123"],
        [123.345, 'numeric', "123.345"],
        ['edc', 'numeric', 0],
        ['ed12rf', 'numeric', 0],
        [123, 'integer', "123"],
        [123.45, 'integer', "123"],
        [123.99, 'integer', "123"],
        ['edc', 'integer', 0],
        ['ed12rf', 'integer', 0],
        [123, 'serial', "123"],
        [123.45, 'serial', "123"],
        [123.99, 'serial', "123"],
        ['edc', 'serial', 0],
        ['ed12rf', 'serial', 0],
        #boolean
        ['true', 'bool', "'t'"],
        ['false', 'bool', "'f'"],
        ['t', 'bool', "'t'"],
        ['f', 'bool', "'f'"],
        ['y', 'bool', "'t'"],
        ['n', 'bool', "'f'"],
        ['T', 'bool', "'t'"],
        ['F', 'bool', "'f'"],
        ['Y', 'bool', "'t'"],
        ['N', 'bool', "'f'"],
        [1, 'bool', "'t'"],
        [0, 'bool', "'f'"],
        ['stuff', 'bool', "'t'"],
        [undef, 'bool', "'f'"],

        ['true', 'boolean', "'t'"],
        ['false', 'boolean', "'f'"],
        ['t', 'boolean', "'t'"],
        ['f', 'boolean', "'f'"],
        ['y', 'boolean', "'t'"],
        ['n', 'boolean', "'f'"],
        ['T', 'boolean', "'t'"],
        ['F', 'boolean', "'f'"],
        ['Y', 'boolean', "'t'"],
        ['N', 'boolean', "'f'"],
        [1, 'boolean', "'t'"],
        [0, 'boolean', "'f'"],
        ['stuff', 'boolean', "'t'"],
        [undef, 'boolean', "'f'"],
        #['', '', "''"],
        );
    foreach my $o (@o)
    {
        is($dal->qtAs(@{$o}[0,1]), $o->[2], "qtAs(" . ($o->[0] ? $o->[0] : '') . ", " . $o->[1] . ") = $o->[2]");
    }
}

#fetchAllRows
{
    #try both the singular things and multiple things

    ok($dal->do('select id from customers where id in (\'1234\', \'12345\') order by id'), 'simple select on customers');
    my @v = $dal->fetchAllRows;
    my @expected = ('1234', '12345');
    is_deeply(\@v, \@expected, 'singular items reduced to a simple list correctly');
}
{
    ok($dal->do('select id, coName from customers where id in (\'1234\', \'12345\') order by id'), 'simple select on customers');
    my @v = $dal->fetchAllRows;
    #my @expected = (
    #    {'id' => '1234', 'coName' => 'Test Customer'},
    #    {'id' => '1234', 'coName' => 'nontax Customer'},
    #    );
    my @expected = (
        ['1234', 'Test Customer'],
        ['12345', 'nontax Customer'],
        );
    is_deeply(\@v, \@expected, 'multiple items left intact');
}

#try the utf8 stuff
{
    #$dal->trace(10);
    #read an existing utf8 string
    #open Blah, '>:encoding(UTF-8)', 'rawout.txt';
    #write a new utf8 string
    #diag('is dal->pg_...utf8 set? ' . ($dal->{'db'}->{'pg_enable_utf8'} ? "yes" : "no"));
    my $r = 'L’âne';
    ok($dal->do('select data from sysstrings where id=\'daltest\''), 'select a utf8 string');
    my @v = $dal->fetchAllRows;
    my @expected = ($r);
    #diag('r is_utf8: ' . (utf8::is_utf8($r) ? "yes" : "no"));
    #diag('expected is_utf8: ' . (utf8::is_utf8($expected[0]) ? "yes" : "no"));
    #diag('v is_utf8: ' . (utf8::is_utf8($v[0]) ? "yes" : "no"));
    #print Blah "expected is $expected[0]\n";
    #print Blah "v is $v[0]\n";
    is_deeply(\@v, \@expected, 'simple latin-esque select string');

    ok($dal->do('insert into sysstrings (id, data) values (\'daltest2\', \'' . $r . '\')'), 'insert a utf8 string');
    ok($dal->do('select data from sysstrings where id=\'daltest2\''), 'select a utf8 string');
    @v = $dal->fetchAllRows;
    @expected = ('L’âne');
    #diag('r is_utf8: ' . (utf8::is_utf8($r) ? "yes" : "no"));
    #diag('expected is_utf8: ' . (utf8::is_utf8($expected[0]) ? "yes" : "no"));
    #diag('v is_utf8: ' . (utf8::is_utf8($v[0]) ? "yes" : "no"));
    #print Blah "expected is $expected[0]\n";
    #print Blah "v is $v[0]\n";
    is_deeply(\@v, \@expected, 'latin-esque utf-8 string db-round trip');

    $r = 'ロバは"ムー"と言います。';
    ok($dal->do('insert into sysstrings (id, data) values (\'daltest3\', \'' . $r . '\')'), 'insert a japanese utf-8 string');
    ok($dal->do('select data from sysstrings where id=\'daltest3\''), 'select a utf8 string');
    @v = $dal->fetchAllRows;
    @expected = ($r);
    #diag('r is_utf8: ' . (utf8::is_utf8($r) ? "yes" : "no"));
    #diag('expected is_utf8: ' . (utf8::is_utf8($expected[0]) ? "yes" : "no"));
    #diag('v is_utf8: ' . (utf8::is_utf8($v[0]) ? "yes" : "no"));
    #print Blah "expected is $expected[0]\n";
    #print Blah "v is $v[0]\n";
    is_deeply(\@v, \@expected, 'japanese utf-8 string db-round trip');
    

    {
	#use bytes;
	#write a new utf8 string
	#diag('is dal->pg_...utf8 set? ' . ($dal->{'db'}->{'pg_enable_utf8'} ? "yes" : "no"));
	$r = 'L’âne';
	ok($dal->do('select \'' . $r . '\''), 'select a utf8 string');
	@v = $dal->fetchAllRows;
	@expected = ($r);
	#diag('r is_utf8: ' . (utf8::is_utf8($r) ? "yes" : "no"));
	#diag('expected is_utf8: ' . (utf8::is_utf8($expected[0]) ? "yes" : "no"));
	#diag('v is_utf8: ' . (utf8::is_utf8($v[0]) ? "yes" : "no"));
	#print Blah "expected is $expected[0]\n";
	#print Blah "v is $v[0]\n";
	TODO: {
	    local $TODO = 'Selecting a utf-8 constant appears to be broken';
	    is_deeply(\@v, \@expected, 'simple latin-esque string');
	}
    }
    #check the written one
    
}

diag ("The following methods are not tested: dsnUrlParse trace reconnect");
1;
