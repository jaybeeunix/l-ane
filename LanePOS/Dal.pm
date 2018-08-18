#Dal.pm
#This file is part of L'ane. Copyright 2000-2010 Jason B. Burrell.
#See COPYING for licensing information.

#$Id: Dal.pm 1207 2011-04-06 00:44:39Z jason $

#Dal provides the Database Abstraction Layer, primarily for object-spanning transactions

#we should have a DESTROY that checks for a non-committed transaction and commit it
####
#NO!!! if the caller didn't commit it, we can't assume he or she wanted it committed

=pod

=head1 NAME

Lane::Dal - Database Abstraction Layer for L'ane

=head1 SYNOPSIS

Provides a layer of database abstraction for L'ane programs. This abstraction is primarily used for object-spanning database transactions.

=head1 DESCRIPTION

Dal provides L'ane's database access functions. Whenever one needs to access the database, he or she should use the Dal module. Even though PostgreSQL doesn't support nested transactions, object classes should be written as if it does. This assumption will insure a transaction is used when it should be used.

Since Dal provides a single, persistent database handle, database operations across L'ane should be faster than the isolated-transaction L'anePOS/BMS.

Please note: unless a transaction is specifically started (with C<begin()>), PostgreSQL defaults to statement-level transactions.

Since moving to L<DBI>, failures at the DB level C<die> rather than return an error.

=head2 CHILDREN

Only children with an external use are documented here.

C<'tuples'>

The number of tuples returned from a "select" query.

=head2 FUNCTIONS

Only subroutines with an external use are documented here.

C<new([class])>

Creates a new Dal object.
Returns a reference to the Dal object

Supported Protocals:

=over

=item pg

The DBD::Pg module's protocol (the recommended Perl->PostgreSQL library).

=back

C<begin()>

Starts a database transaction. PostgreSQL does not support nested transactions, so calling this inside of an existing transaction will have no effect on the transaction. Returns C<1> if successful.

C<commit()>
    
Commits a database transaction. Returns C<1> if successful.

C<rollback()>

Rollsback a database transaction. Returns C<1> if successful. This subroutine does NOT automatically start another transaction. One should call C<begin()> if he or she would like another multi-statement transaction. (Rollback doesn't support nested transactions, everything up to the begining of the outtermost transaction is killed.)

C<abort()>

Calls C<rollback()>. Used as a synonym of C<rollback()> for historic reasons.

C<do(sql)>

Executes the SQL query I<sql> in the current transaction. Do B<NOT> use this routine to send transaction commands (begin, commit, rollback, etc.) directly to the database. In the future, C<do()> will filter these commands out of the sql query.

C<fetchrow>

Returns a single tuple from the query as a list of elements. Multiple calls iterate over the result list.

C<fetchAllRows>

Returns a list of single elements (for selects with one item) or of references to sub-arrays of elements (for selects with multiple items) from the query. A single call returns the entire result list.

C<qt(s)>

Returns a PostgreSQL safe string by quoting and escaping the special characters in C<s>. If C<s> is C<undef>, C<00-00-0000>, or C<0000-00-00>, returns the bare word C<null>.

C<qtAs(s, t)>

Returns a PostgreSQL safe string by quoting and escaping the special characters in C<s>, considering it is of type C<t>. In some cases, the data is preserved and may not be acceptable to PostgreSQL.

C<dsnUrlParse(u)>

Returns a hash of options and connection attributes from the new-style URL-based DSN "u".
For example, what was previously written as I<host=server.example.com dbname=lanedemo> is now written as I<pg://server.example.com/lanedemo>.
Extended options can be given in HTTP GET fashion: I<pg://username:passwd@server.example.com:5432/lanedemo?option=123&opt2=456> . Unix domain sockets (TCP-less) connections are now officially supported with a host-less url: I<pg:///lanedemo> . The most interesting extended option is I<encoding> , as it specifies the PostgreSQL-style client encoding by overriding the I<PGCLIENTENCODING> environment variable. For example, I<pg://server/lanedemo?encoding=unicode> (the client encoding is SQL-case insensitive) sets the client encoding (L'ane's encoding) to UTF-8.

C<trace(i)>

Turns DB tracing on to level C<i>.

C<setDsn>

Resets the various DB-specific DSNs from C<$ENV{LaneDSN}>. This method should be called to update the DSN caches if your C<LaneDSN> environment variable changes.

C<reconnect[(force)]>

Reconnects to the DB if you are not in a transaction. Supply a true value to force a reconnection.

=head1 AUTHOR

Jason Burrell

=head1 BUGS

=over

=item * 

There are no known bugs in this class.

=back

=cut

package LanePOS::Dal;

require 5.008;

use strict;
use DBI;

use base 'LanePOS::ProtoObject';

our $AUTOLOAD;

$::VERSION = (q$Revision: 1207 $ =~ /(\d+)/)[0];

sub new
{
    my ($class) = @_;
    my $me = {
	'dsn' => '',
	'dbDsn' => '',
	'urlDsn' => '', #set below
	'inTransaction' => 0, #this is actually a counter
        'db' => '',
	'st' => undef,
	'tuples' => 0,
        'dbError' => undef,
	'trace' => 4,
	'untrace' => 0,
	'states' => {
	    'connection_exception' => qr/^08...$/, #DBD::Pg's manual says S8006 too, but i think that's a typo: 08.{3} is a "Connection Exception"
	    'successful_completion' => qr/^$/,
	},
    };
    bless $me, $class;

    $me->setDsn; #this calls reconnect() itself

    return $me; 
}

sub inTransaction
{
    my ($me) = @_;

    return $me->{'inTransaction'};
}

sub isState
{
    my ($me, $state) = @_;

    return 1 if $me->{'db'}->state =~ /$me->{'states'}{$state}/;
    return 0;
}

sub reconnect
{
    my ($me, $force) = @_;

    #die if we try to do this inside a transaction
    die "Dal::reconnect: I can't reconnect inside of an existing transaction!\n" if $me->inTransaction and !$force;

    $me->{'db'} = DBI->connect($me->{'dbDsn'}, $me->{'dsn'}{'username'}, $me->{'dsn'}{'password'},
			       {
				   AutoCommit => 1,
				   RaiseError => 1,
				   PrintError => 0,
				   pg_enable_utf8 => 1,
			       });
#    warn "Dal::new: db is ", $me->{'db'}, " (DSN was $me->{'dbDsn'})\n" if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Dal/;
    $me->{'db'}->trace($me->{'trace'}) if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Dal/;
    die "Dal::reconnect(): bad connection (", $me->{'db'}->state, ", ", $me->{'db'}->errstr, ")\n" if $me->isState('connection_exception');
    return 1;
}

sub setDsn
{
    my ($me) = @_;

    $me->{'urlDsn'} = $ENV{'LaneDSN'};

    #check for an old-style dsn
    if($me->{'urlDsn'} =~ m{://}) #we assume :// is a new-style (url-style) dsn
    {
        warn "Dal::setDsn: new-style url\n" if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Dal/;
        #parse the url-LaneDSN
        $me->{'dsn'} = $me->dsnUrlParse($me->{'urlDsn'});
        if($me->{'dsn'}{'protocol'} =~ /^pg$/i)
        {
            #the 'pg' protocol
            ;
            #if you add a protocol, describe it in the pod above!!!
        }
        else
        {
            die 'Dal::setDsn: Unsupported protocol "' . $me->{'dsn'}{'protocol'} . "\"\n";
        }
    }
    else
    {
        warn "Dal::setDsn: old-style dsn\n" if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Dal/;
        $me->{'dsn'} = {'protocol' => 'Pg',};
        foreach my $e (split /\s+/, $me->{'urlDsn'})
        {
            next if $e =~ /^\s*$/;
            my ($k, $v) = split /=/, $e;#/;
            $k = 'db' if $k eq 'dbname';
            $me->{'dsn'}{$k} = $v;
        }
    }
    $me->setDbDsn;
    return $me->reconnect;
}

sub setDbDsn
{
    my ($me) = @_;
    $me->{'dsn'}{'protocol'} = 'Pg' if $me->{'dsn'}{'protocol'} =~ /^pg$/i;
    $me->{'dbDsn'} = 'dbi:' . $me->{'dsn'}{'protocol'} . ':';
    while (my ($k, $v) = each %{$me->{'dsn'}})
    {
	next if $k eq 'protocol';
	$me->{'dbDsn'} .= "$k=$v;";
    }
    $me->{'dbDsn'} =~ s/;$//;
    return 1;
}

sub begin
{
    my ($me) = @_;

    #return 'ERROR: Dal::begin(): already in a transaction (nested transactions are not supported)' if $me->{'inTransaction'};
    
    #support nested transactions (well, let them pass through)
    if($me->{'inTransaction'})
    {
	$me->{'inTransaction'}++;
	return 1;
    }
    #this is the first transaction
    $me->{'db'}->{'AutoCommit'} = 0;
    #$me->{'st'} = $me->{'db'}->begin_work;
    $me->{'inTransaction'} = 1;
    return 1;
}

sub commit
{
    my ($me) = @_;

    if(!$me->{'inTransaction'})
    {
        warn "Dal::commit(): WARNING: no transaction in progress, operation ignored\n";
        return 1;
    }

    if($me->{'inTransaction'} > 1) #we're in a nested xaction, don't REALLY commit
    {
	$me->{'inTransaction'}--;
	return 1;
    }
    $me->{'st'} = $me->{'db'}->commit;
    $me->{'db'}->{'AutoCommit'} = 1;
    $me->{'inTransaction'} = 0;
    return 1;
}

sub rollback
{
    my ($me) = @_;

    if(!$me->{'inTransaction'})
    {
        warn "Dal::rollback(): WARNING: no transaction in progress, operation ignored\n";
        return 1;
    }
    if($me->{'inTransaction'} > 1) #we're in a nested xaction, don't REALLY commit
    {
	$me->{'inTransaction'}--;
	return 1;
    }
    $me->{'st'} = $me->{'db'}->rollback;
    $me->{'db'}->{'AutoCommit'} = 1;
    $me->{'inTransaction'} = 0;
    return 1;
}

sub abort
{
    my ($me) = @_;

    return $me->rollback();
}

sub do
{
    my ($me, $todo) = @_;

    #check our connection's state
    if($me->isState('connection_exception'))
    {
        #first, try to reconnect, which will call die if it can't
        if(!$me->{'inTransaction'})
        {
            $me->reconnect;
        }
        else
        {
            #we're basically screwed until the transaction ends
            die "Dal::do($todo): bad connection (", $me->{'db'}->state, ", ", $me->{'db'}->errstr, ") AND you're in a transaction, so I can't even try to reconnect until you finish it.\n" if $me->isState('connection_exception');
        }
    }

    $me->{'st'} = $me->{'db'}->prepare($todo);
    $me->{'st'}->execute;
    $me->{'tuples'} = 0; #reset the tuple-counter

    if($me->isState('successful_completion'))
    {
	$me->{'tuples'} = $me->{'st'}->rows;
        $me->{'dbError'} = undef;
	return 1;
    }
    else
    {
        $me->{'dbError'} = $me->{'db'}->errstr;
	die "Dal::do(): " . $me->{'dbError'} . "\n";
    }
}

sub fetchrow
{
    return $_[0]->{'st'}->fetchrow_array; #wtf, you can't do that here--we have STYLE ;)
}

sub fetchAllRows
{
    my @r;
    #my @t;
    while (my @t = $_[0]->{'st'}->fetchrow_array)
    {
        #if they only have singular things, put them directly into the array
        push @r, ($#t == 0 ? $t[0] : \@t);
    }
    return @r;
}

sub qt
{
    my ($me, $s) = @_;
    
    return "null" if !defined($s) or $s eq '' or $s eq '00-00-0000' or $s eq '0000-00-00';
    $s =~ s/\'/\'\'/g;
    $s =~ s/\\/\\\\/g;
    $s = "'$s'";
    return $s;
}

sub qtAs
{
    my ($me, $i, $t) = @_;

    #convert to __DB__ format and quote, if nec'y
    if($t =~ /^integer|serial$/)
    {
	#integral types
	return 0 if $i !~ /^-?\d*.?\d+$/;
	return int($i);
    }
    elsif($t =~ /^numeric$/)
    {
	#numeric types, no quoting or conversion needed
	return 0 if $i !~ /^-?\d*.?\d+$/;
	return $i;
    }
    elsif($t =~ /^char|character|text$/)
    {
	#text types need quoted
	return $me->qt($i);
    }
    elsif($t =~ /^timestamp$/)
    {
	#allows for odd things, ie yesterday, now, tomorrow
	return $me->qt($i) . "::timestamp";
    }
    elsif($t =~ /^date$/)	# don't want to catch the old datetime type
    {
	#allows for odd things, ie yesterday, now, tomorrow
	return $me->qt($i) . "::date";
    }
    elsif($t =~ /^time$/)
    {
	return $me->qt($i) . "::time";
    }
    elsif($t =~ /^bool(ean)?$/)
    {
        #these are ordered to reduce warnings 
	return $me->qt('f') if !$i;
	return $me->qt('t') if $i =~ /y|t/i;
	return $me->qt('f') if $i =~ /n|f/i;
	return $me->qt('t') if $i == 1;
	return $me->qt('f') if $i == 0;
    }
    elsif($t =~ /^not-null$/)
    {
	#text types need quoted
        my $r = $me->qt($i);
        $r = '\'\'' if $r eq 'null';
	return $r;
    }
    else
    {
	#not sure what it is, quote it anyway
        warn "Dal::qtAs($i, $t): unknown type \"$t\", assuming \"text\"\n" if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Dal/;
	return $me->qt($i);
    }
}

sub dsnUrlParse
{
    my ($me, $u) = @_;
    my $dsn = {};

    #$u =~ /^(pg):\/\/(.*)\/([^\?]*)\??(.*)/;
    $u =~ /^([^:]*):\/\/(.*)\/([^\?]*)\??(.*)/;
    $dsn->{'protocol'} = $1;
    $dsn->{'db'} = $3;
    $dsn->{'ext'} = $4;
	
    $dsn->{'username'} = $2;
    $dsn->{'host'} = $2;
    $dsn->{'port'} = $2;

    if($dsn->{'username'} =~ /([^\@:]*):?([^\@:]*)@/)
    {
	$dsn->{'username'} = $1;
	$dsn->{'password'} = $2;
    }
    else
    {
	$dsn->{'username'} = $dsn->{'password'} = '';
    }

    $dsn->{'host'} =~ s/[^@]*@//;
    if($dsn->{'host'} =~ /([^:]*):?(\d*)/)
    {
	$dsn->{'host'} = $1;
	$dsn->{'port'} = $2;
    }
    else
    {
	$dsn->{'host'} = $dsn->{'port'} = '';
    }

    #very hack-ish, but i don't see any other EASY wasy of doing this
    #recognize the "encoding" option, and set the PGCLIENTENCODING env var
    $main::ENV{'PGCLIENTENCODING'} = $2 if $dsn->{'ext'} =~ s/(encoding=)([^\&]*)//g;
    
    foreach my $i (split /\&/, $dsn->{'ext'})
    {
	my ($k, $v) = split /=/, $i; #/
	#ignoring http encoded chars at the moment
	$dsn->{$k} = $v;
    }

    return $dsn;
}

sub trace
{
    my ($me, $i) = @_;
    if($i eq *main::STDERR or $i eq *main::STDIN)
    {
	$i = $me->{'trace'};
    }
    elsif($i =~ /^\d+$/)
    {
	#allow it through unmolested
	;
    }
    else
    {
	$i = $me->{'untrace'};
    }
    return $me->{'db'}->trace($i);
}

sub DESTROY
{
    my $me = shift;

    $me->SUPER::DESTROY(@_);
    return 1;
}

#Helper AUTOLOAD
sub AUTOLOAD
{
    my ($me, @x) = @_;

    my $method = $AUTOLOAD;
    $method =~ s/.*:://;
    $method = 'LanePOS::Dal::' . $method;

    #try a helper
    my $r = eval {
        eval "require $method";
        return $method->new($me, @x);
    };
    if($@)
    {
        warn "Dal::AUTOLOAD: eval of $method failed $@\n";
    }
    return $r;
}

1;
