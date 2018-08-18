#GenericObject.pm
#This file is part of L'ane. Copyright 2000-2010 Jason B. Burrell.
#See COPYING for licensing information.

#$Id: GenericObject.pm 1132 2010-09-19 21:36:50Z jason $

=pod

=head1 NAME

Lane::GenericObject - Basic Object Class for L'ane

=head1 SYNOPSIS

GenericObject provides a generic ancestor class for L'ane's other classes.

=head1 DESCRIPTION

GenericObject provides a generic ancestor class the implements the most common object/database operations.

=head2 CHILDREN

Only children with an external use are documented here.

C<'dal'>

A reference to the Dal object (a database handle).

C<'lc'>

A reference to the Locale object. FIXME@@@@: This code is disabled, as C<Locale::timeToEpoch> needs to support the reverse of it first.

C<'table'>

The name of the primary table associated with this object.

C<'kids'>

An array of the secondary tables associated with this object. At present, GenericObject only supports a single generation of children. Each element of this array includes a C<'table'>, a C<'keys'>, a C<'columns'>, and possibly a C<'disallowNullKeys'> element.

C<'columns'>

An array of the column names. Note: ONLY COLUMNS LISTED HERE WILL BE MANIPULATED!

C<'keys'>

An array of the primary key column names.

C<'booleans'>

A hash of the field names which contain boolean values and should be converted to Perl-style in L</open(@ids)>).

C<'exts'>

A hash of the field names which contain ext values and should be converted to Perl-style in L</open(@ids)>).

C<'dates'>

A hash of the field names which contain date values and should be converted to local-style in L</open(@ids)>).

C<'datetimess'>

A hash of the field names which contain datetime values and should be converted to local-style in L</open(@ids)>).

C<'disallowNullKeys'>

Null keys are disabled (what would be converted to null is converted to the empty string).
While this should be the default, it breaks objects which use serialized GenericObject assigned keys (like L<Sale>).
It should be set for any objects which require empty-string keys, noteably L<Customer>.

C<'revisioned'>

This object class is revisioned. It allows the access to the revision data by use of subroutines like C<rev()> and C<openRev()>.
The actual revisioning is handled by the database.

C<'hideVoidFromOpen'>

Hide void objects from C<open()>. This option is primarily so simple classes can be easily migrated to revisioning.

=head2 FUNCTIONS

Only subroutines with an external use are documented here.

C<new([class,] dal)>

Creates a new GenericObject object, where C<'dal'> is a reference to a Dal object
Returns a reference to the GenericObject object if successful or false if failed.

=cut


package LanePOS::GenericObject;

require 5.008;

use base 'LanePOS::ProtoObject';

use LanePOS::Dal; #the new database stuff

$::VERSION = (q$Revision: 1132 $ =~ /(\d+)/)[0];

sub new
{
    my ($class, $dal) = @_;
    $class = ref($class) || $class || 'LanePOS::GenericObject';
    $dal = Dal->new if ! UNIVERSAL::isa($dal, 'LanePOS::Dal');
    my $me = {
	'dal' => $dal,
        #'lc' => Locale->new($dal),
	'table' => '',
	'keys' => [],
	'columns' => [],
	'kids' => [],
        'booleans' => {},
        'exts' => {},
        #'disallowNullKeys' => 0, #this SHOULD be default, but anything which expects auto serialized ids breaks on this
        #these might make sense, but Locale will need to be able to support the conversion of the locale'd version back to an epoch
        #'dates' => {},
        #'timestamps' => {},
        #'times' => {},

        'revisioned' => 0,
        'hideVoidFromOpen' => 0,
    };
    bless $me, $class;

    #@@@@ the following breaks the abstraction
    $me->{'dal'}{'db'}->trace(STDERR) if exists($ENV{'LaneDebug'}) and $ENV{'LaneDebug'} =~ /GenericObject/;

    return $me;
}

sub listColumns
{
    my ($me, $cols) = @_;
    
    my $r = '';
    $r .= "$_," foreach (@{$cols});
    chop $r; #remove the last comma
    return $r;
}

sub subtableName
{
    my ($me, $o) = @_;
    my $name;
    my $parentname = $me->{'table'};
    $parentname =~ s/_rev$//;
    $name = ($o->{'table'} =~ /^($parentname)(.+)$/)[1]; #remove the parent's name
    if($name) #rid ourselves of "Use of uninitialized value in substitution" errors
    {
        $name =~ s/_rev$//;
        #lc the first letter
        $name =~ s/^(.)/\L$1\E/;
    }
    return $name;
}

sub listValues
{
    my ($me, $o, $d) = @_;

    my $r;
    foreach my $i (@{$o->{'columns'}})
    {
        #keys can't be null, so make them ''
        if(exists $o->{'disallowNullKeys'} and $o->{'disallowNullKeys'} and scalar(grep {$_ eq $i} @{$o->{'keys'}}))
        {
            $r .= $me->{'dal'}->qtAs(
                (exists $o->{'exts'} and exists $o->{'exts'}{$i}) ? $me->deParseExt($d->{$i}) : $d->{$i},
                'not-null') . ",";
        }
        else
        {
            $r .= $me->{'dal'}->qt(
                (exists $o->{'exts'} and exists $o->{'exts'}{$i}) ? $me->deParseExt($d->{$i}) : $d->{$i}
                ) . ",";
        }
    }
    chop $r;
    return $r;
}

=pod
    
C<rev(@ids)>
    
Returns a list of revision numbers of the object specified by C<'@ids'> in order from newest to oldest.
    
=cut
    
sub rev
{
    my $me = shift;
    #select r from ${table}_rev where $wh order by r desc;
    my @r;

    #build the "where" part of the query
    my $wh = '';
    my @wh;
    foreach (@{$me->{'keys'}}) #we only want to select the main keys, so no $o->{'keys'}
    {
        push @wh, "$_=" . ((exists $o->{'disallowNullKeys'} and $o->{'disallowNullKeys'}) ? $me->{'dal'}->qtAs(shift, 'not-null') : $me->{'dal'}->qt(shift) );
    }
    $wh = join(' and ', @wh);
    
    $me->{'dal'}->do('select r from ' . $me->{'table'} . "_rev where $wh order by r desc");
    
    if($me->{'dal'}{'tuples'})	# store the vals, if ok
    {
        @r = $me->{'dal'}->fetchAllRows;
    }
    return @r;
}
    
=pod
    
C<openRev(@ids, $r)>

Populates the object with the data for the object associated with C<'@ids'> at revision C<'$r'> and returns true if successful, or false if GenericObject was unable to open the object.
    
=cut
    
sub openRev
{
    my $me = shift;

    my $hide = $me->{'hideVoidFromOpen'};
    #rev should always open (simple things wouldn't use openRev(), so there's no utility in hiding it)
    $me->{'hideVoidFromOpen'} = 0;
    #try to reuse as much as possible
    foreach $o ($me, @{$me->{'kids'}})
    {
        $o->{'table'} .= '_rev';
        push @{$o->{'columns'}}, 'r';
        push @{$o->{'keys'}}, 'r';
    }
    my $r = $me->open(@_);
    foreach $o ($me, @{$me->{'kids'}})
    {
        $o->{'table'} =~ s/_rev$//;
        pop @{$o->{'columns'}};
        pop @{$o->{'keys'}};
    }
    $me->{'hideVoidFromOpen'} = $hide;
    return $r;
}

=pod
    
C<open(@ids)>
    
Populates the object with the data for the object associated with C<'@ids'> and returns true if successful, or false if GenericObject was unable to open the object.
    
=cut
    
sub open
{
    my ($me, @ids) = @_;
    
    #reset the fields
    $me->_resetFlds;

    #get our kiddies
    $r = 1;
    $r &&= $me->openFrom($me, @ids);
    #don't zero it out if some of the children don't exist -- they may just not exist
    #$r &&= $me->openFrom($_, @_) foreach (@{$me->{'kids'}});
    $me->openFrom($_, @ids) foreach (@{$me->{'kids'}});

    #hide void objects, unless they are requesting it by rev number explicitly
    if(!$me->{'r'} and $me->{'hideVoidFromOpen'} and $me->{'voidAt'})
    {
        #warn "GenericObject: hiding void from open!\n";
        $me->_resetFlds;
        return undef;
    }

    return $r;
}

sub _resetFlds
{
    my ($me) = @_;

    #reset all of the data fields
    foreach my $k (@{$me->{'kids'}})
    {
        my $s = $me->subtableName($k);
        $me->{$s} = [];
    }
    foreach my $c (@{$me->{'columns'}})
    {
        $me->{$c} = undef;
    }
    delete $me->{'r'} if exists $me->{'r'};
}

sub openFrom
{
    my ($me, $o, @ids) = @_;
    
    #if this is a sub-table, get the name
    my $subtable = $me->subtableName($o);
    
    #build the "where" part of the query
    my $wh = '';
    my @wh;
    foreach (@{$me->{'keys'}}) #we only want to select the main keys, so no $o->{'keys'}
    {
        push @wh, "$_=" . ((exists $o->{'disallowNullKeys'} and $o->{'disallowNullKeys'}) ? $me->{'dal'}->qtAs((shift @ids), 'not-null') : $me->{'dal'}->qt((shift @ids)) );
    }
    $wh = join(' and ', @wh);
    
    $me->{'dal'}->do("select " . $me->listColumns($o->{'columns'}) . " from " . $o->{'table'} . " where $wh order by " . $me->listColumns($o->{'keys'}));
    
    if($me->{'dal'}{'tuples'})	# store the vals, if ok
    {
	if($me eq $o) #special case, because only a single row should match on the main table
	{
	    @r = $me->{'dal'}->fetchrow;
	    foreach (@{$o->{'columns'}})
            {
                $o->{$_} = shift @r;
                $o->{$_} =~ tr/tfTF/1010/ if exists $o->{'booleans'} and exists $o->{'booleans'}{$_} and $o->{'booleans'}{$_};
                if(exists $o->{'exts'} and exists $o->{'exts'}{$_} and $o->{'exts'}{$_})
                {
                    my $ext;
                    $ext = $me->parseExt($o->{$_});
                    $o->{$_} = $ext;
                }
                #disabled as we're waiting for support in Locale->timeToEpoch()
                #if(exists $o->{'dates'} and exists $o->{'dates'}{$_} and $o->{'dates'}{$_})
                #{
                #    $o->{$_} = $me->{'lc'}->temporalFmt('shortDate', $o->{$_});
                #}
                #if(exists $o->{'times'} and exists $o->{'times'}{$_} and $o->{'times'}{$_})
                #{
                #    $o->{$_} = $me->{'lc'}->temporalFmt('shortTime', $o->{$_});
                #}
                #if(exists $o->{'timestamps'} and exists $o->{'timestamps'}{$_} and $o->{'timestamps'}{$_})
                #{
                #    $o->{$_} = $me->{'lc'}->temporalFmt('shortTimestamp', $o->{$_});
                #}
            }
	}
	else
	{
	    while (my @r = $me->{'dal'}->fetchrow)
	    {
		my %h;
                foreach (@{$o->{'columns'}})
                {
                    $h{$_} = shift @r;
                    $h{$_} =~ tr/tfTF/1010/ if exists $o->{'booleans'} and exists $o->{'booleans'}{$_} and $o->{'booleans'}{$_};
                    if(exists $o->{'exts'} and exists $o->{'exts'}{$_} and $o->{'exts'}{$_})
                    {
                        my $ext;
                        $ext = $me->parseExt($h{$_});
                        $h{$_} = $ext;
                    }
                    #disabled as we're waiting for support in Locale->timeToEpoch()
                    #if(exists $o->{'dates'} and exists $o->{'dates'}{$_} and $o->{'dates'}{$_})
                    #{
                    #    $o->{$_} = $me->{'lc'}->temporalFmt('shortDate', $o->{$_});
                    #}
                    #if(exists $o->{'times'} and exists $o->{'times'}{$_} and $o->{'times'}{$_})
                    #{
                    #    $o->{$_} = $me->{'lc'}->temporalFmt('shortTime', $o->{$_});
                    #}
                    #if(exists $o->{'timestamps'} and exists $o->{'timestamps'}{$_} and $o->{'timestamps'}{$_})
                    #{
                    #    $o->{$_} = $me->{'lc'}->temporalFmt('shortTimestamp', $o->{$_});
                    #}
                }
		#$h{$_} = shift @r foreach (@{$o->{'columns'}});

		#let's make this compatible w/the old style
		#ie the pointer to the kids is in $me
		#
		#newer style
		#push @{$o}, \%h;
		#
		#old style
		#push $me->{$o->{'table'}}, \%h;
		
		#even newer style ;)
#		$h{'table'} = $o; #this lets listValues() get everything it needs, since the data and structure of child tables are kept in two separate parts of the $me-tree
		push @{$me->{$subtable}}, \%h;
	    }
	}
    }
    else
    {
	return 0;		# didn't find it
    }
    return 1;			# everything went ok (prob ;) )
}

=pod

C<save()>

Populates the database with the object and returns true if successful, or false if GenericObject was unable to save the object.

=cut

sub save
{
    my ($me) = @_;

    #start a db transaction
    $me->{'dal'}->begin;
    $me->saveFrom($me, $me);

    foreach my $k (@{$me->{'kids'}})
    {
        my $s = $me->subtableName($k);
        foreach my $i (0..$#{$me->{$s}})
        {
            #fix any id, lineNo columns
            $me->{$s}[$i]{'id'} = $me->{'id'} if exists $me->{'id'} and $me->{'id'};
            $me->{$s}[$i]{'lineNo'} = $i if scalar(grep {$_ eq 'lineNo'} @{$k->{'keys'}});
            
            $me->saveFrom($k, $me->{$s}[$i]);
        }
    }
    $me->{'dal'}->commit;
    return 1;
}

sub saveFrom
{
    my ($me, $o, $d) = @_;

    my $wh = '';
    my @wh;
    push @wh, "$_=" . ((exists $o->{'disallowNullKeys'} and $o->{'disallowNullKeys'}) ? $me->{'dal'}->qtAs($d->{$_}, 'not-null') : $me->{'dal'}->qt($d->{$_})) foreach (@{$o->{'keys'}});
    $wh = join(' and ', @wh);

    #this sub should be in a single transaction

    $me->{'dal'}->begin;
    #check to see if it exists
    #build the "where" part of the query
    $me->{'dal'}->do("select " . $me->listColumns($o->{'columns'}) . " from " . $o->{'table'} . " where $wh order by " . $me->listColumns($o->{'keys'}));
    
    if($me->{'dal'}{'tuples'})
    {
        my @vals;
        foreach my $c (@{$o->{'columns'}})
        {
            if(scalar(grep {$_ eq $c} @{$o->{'keys'}}))
            {
                #this makes it so keys can't be ext fields
                push @vals, "$c=" . ((exists $o->{'disallowNullKeys'} and $o->{'disallowNullKeys'}) ? $me->{'dal'}->qtAs($d->{$c}, 'not-null') : $me->{'dal'}->qt($d->{$c}));
            }
            else
            {
                push @vals, "$c=" . $me->{'dal'}->qt((exists $o->{'exts'} and exists $o->{'exts'}{$c}) ? $me->deParseExt($d->{$c}) : $d->{$c});
            }
        }
        $me->{'dal'}->do("update " . $o->{'table'} . " set " . join(', ', @vals) . " where $wh");
    }
    else
    {
        #check for a missing "id" key -- one which the db should assign
        if($o->{'keys'}[0] eq 'id' and !defined $d->{'id'}) #this needs to be generalized
        {
            $me->{'dal'}->do('select nextval(' . $me->{'dal'}->qt($o->{'table'} . '_id_seq') . ')');
            #^ is how postgresql names the auto-created sequences
            ($d->{'id'}) = $me->{'dal'}->fetchrow if $me->{'dal'}{'tuples'};
        }
        $me->{'dal'}->do("insert into " . $o->{'table'} . " (" . $me->listColumns($o->{'columns'}) . ") values (" . $me->listValues($o, $d) . ")");
    }
    $me->{'dal'}->commit;
    return 1;
}

=pod

C<remove()>

Removes the GenericObject from the database, returning true if successful or false if GenericObject was unable to remove the GenericObject.

=cut

sub remove
{
    my ($me) = @_;
    my $r = 1;
    #delete them in reverse order for fun, and in case we ever add foreign key restraints to the db
    #start a db transaction
    $me->{'dal'}->begin;
    if(!$me->{'revisioned'})
    {
        $r &&= $me->removeFrom($_) foreach (@{$me->{'kids'}});
        $r &&= $me->removeFrom($me);
    }
    else
    {
        $me->void;
    }
    return $r ? $me->{'dal'}->commit : $me->{'dal'}->rollback;
}

sub removeFrom
{
    my ($me, $o) = @_;

    my $wh = '';
    my @wh;
    push @wh, "$_=" . ((exists $o->{'disallowNullKeys'} and $o->{'disallowNullKeys'}) ? $me->{'dal'}->qtAs($o->{$_}, 'not-null') : $me->{'dal'}->qt($o->{$_})) foreach (@{$o->{'keys'}});

    $wh = join(' and ', @wh);

    $me->{'dal'}->do("delete from " . $o->{'table'} . " where $wh");
    return 1;
}

=pod

C<void()>

Marks the specific GenericObject as void in the database, returning true if successful or false if GenericObject was unable to void the GenericObject.

=cut

sub void
{
    my ($me) = @_;
    $me->{'voidAt'} = '1776-07-04'; #the db's trigger will change this to the actual value
    return $me->save;
}

=pod

C<isVoid()>

Returns true if this object is void.

=cut

sub isVoid
{
    my ($me) = @_;

    die "GenericObject::isVoid: voidAt doesn\'t exist!\n" if !exists $me->{'voidAt'};
    return 1 if defined $me->{'voidAt'} and $me->{'voidAt'};
    return 0;
}

sub deParseExt
{
    my ($me, $ext) = @_;

    #allow null things too
    $ext = {} if !$ext;

    my $caller = join(', ', (caller)[0,2]);
    die 'GenericObject->deParseExt($ext): The provided value isn\'t a hashref! (' . $caller . ")" if ref($ext) ne 'HASH';

    my $r = '';
    foreach my $k (keys %{$ext})
    {
	next if $k =~ /^_dontsave_/;
	$r .= "$k\t$ext->{$k}\n";
    }

    return $r;
}

sub parseExt
{
    my ($me, $ext) = @_;
    my %r;

    my $caller = join(', ', (caller)[0,2]);
    die 'GenericObject->parseExt($ext): The provided value string is a hashref! (' . $caller . ')' if ref($ext) eq 'HASH';

    if(defined $ext)
    {
        my @i = split /\n/, $ext;
        foreach my $i (@i)
        {
            my ($k, $v) = split /\t/, $i;
            next if $k eq '';
            $r{$k} = $v;
        }
    }
    return \%r;
}

=pod
    
C<clone($o)>
    
Clones the object specified by C<'$o'>.
    
=cut
    
sub clone
{
    my ($me, $d) = @_;
    my $ref = ref($d);
    if($ref eq 'HASH' or UNIVERSAL::isa($d, 'HASH'))
    {
	$d = {%{$d}};
	foreach my $k (keys %{$d})
	{
	    next if !ref($d->{$k});
	    $d->{$k} = $me->clone($d->{$k});
	}
	bless($d, $ref) if $ref ne 'HASH';
    }
    elsif($ref eq 'ARRAY' or UNIVERSAL($d, 'ARRAY'))
    {
	$d = [@{$d}];
	foreach my $k (@{$d})
	{
	    next if !ref($k);
	    $k = $me->clone($k);
	}
	bless($d, $ref) if $ref ne 'ARRAY';
    }
    elsif($ref eq 'SCALAR' or UNIVERSAL::isa($d, 'SCALAR'))
    {
	$d = \${$d};
	bless($d, $ref) if $ref ne 'SCALAR';
    }
    #should we handle various other blessed types too?
    return $d;
}

=pod

C<getTree(s,...)>

Returns an array (suitable for creating a hash) of all of the elements in the database "tree" whose keys begin with the strings C<s, ...>. It does not return objects and is typically used to return configuration parameters

=cut

sub getTree
{
    my ($me, $cols) = (shift, shift);

    my @rtn;
    my $i = 0;
    my $whereKeys = [map {$me->{'keys'}[$i++], 'like', $me->{'dal'}->qt($_ . '%')} @_];

    $me->{'dal'}->trace(STDERR) if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /GenericObject/;

    eval {
        #$me->{'dal'}->do("select " . $me->listColumns($me->{'columns'}) . " from " . $me->{'table'} . " where id like " . $me->{'dal'}->qt($id . '%') . " order by id");
        #this is a special case, so we don't need to use listColumns
        $me->{'dal'}->select(
            'what' => $cols,
            'from' => [$me->{'table'}],
            'where' => [$whereKeys, 'and', ['voidAt', 'is null']],
            'orderBy' => $me->{'keys'},
            )->do();
    };
    if($@)
    {
        warn "GenericObject::getTree($id): the db returned an error: $@\n";
    }
    else
    {
        foreach (1..$me->{'dal'}{'tuples'})
        {
            my @d = $me->{'dal'}->fetchrow;
            warn "GenericObject::getTree($id): " . join(', ', @d) . "\n" if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /GenericObject/;
            push @rtn, @d;
        }
    }
    warn "GenericObject::getTree($id): returning: (", join(', ', @rtn), ")\n" if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /GenericObject/;
    return @rtn;
}


=pod

=head1 AUTHOR

Jason Burrell

=head1 BUGS

=over

=item * 

No I<known> bugs.

=back

=cut

1;
