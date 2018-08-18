#Locale.pm
#This file is part of L'ane. See COPYING for licensing information.
#Copyright 2002-2010 Jason Burrell.

#$Id: Locale.pm 1193 2010-10-22 21:10:11Z jason $

#this locality module uses the $LaneLang env var in the form:
# "fr-CA,fr,en-CA,en-UK,en-US,en,c" (the c is implied if not given)

package LanePOS::Locale;

require 5.008;

use base 'LanePOS::ProtoObject';
use LanePOS::Dal;

$::VERSION = (q$Revision: 1193 $ =~ /(\d+)/)[0];

sub new
{
    my ($class, $dal) = @_;

    warn "Locale::new() starting...\n" if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Locale/;

    $class = ref($class) || $class || 'LanePOS::Locale';

    $dal = Dal->new if ! UNIVERSAL::isa($dal, 'LanePOS::Dal');

    my $me = {
        'dal' => $dal,
	'cache' => {}, #the cache is a hash (i'm a poet and don't know it ;) )
	'lang' => [], #this is an array of languages in order of most desirable to least desirable
    };

    bless $me, $class;
    $me->initLang();
    return $me;
}

sub initLang
{
    my ($me) = @_;
    #this function (re)initializes the language array

    warn "Locale::initLang() starting\n" if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Locale/;
    if(!exists($ENV{'LaneLang'}))
    {
	#LaneLang isn't set, we'll use the US-ish, POSIX, kinda' ISO setup ;-)
	warn "Locale::initLang() NO \$LaneLang ENV VAR SET! ASSUMING 'c'\n" if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Locale/;
    }
    else
    {
	foreach my $l (split /[,;\s]/, $ENV{'LaneLang'})
	{
	    warn "Locale::initLang() foreach w/>$l<\n" if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Locale/;

	    next if "\L$l" eq 'c' or $l eq '';
	    push @{$me->{'lang'}}, $l;
	    warn "Locale::initLang() push'ed >$l< onto lang\n" if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Locale/;
	}
    }
    push @{$me->{'lang'}}, 'c'; #always end w/'c'
    warn "Locale::initLang() ", $#{$me->{'lang'}}, "\n" if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Locale/;

    return 1;
}

sub get
{
    my ($me, $txt, @var) = @_;

    warn "Locale::get() starting '$txt'\n" if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Locale/;
    #check the cache first
    if(exists($me->{'cache'}{$txt}))
    {
	#it's in the cache, send it back
	warn "Locale::get() in the cache\n" if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Locale/;
    }
    else
    {
	#get it from the db and put it into the cache
	$me->{'cache'}->{$txt} = $me->getDb($txt);
	warn "Locale::get() in the cache NOW\n" if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Locale/;
    }
    return $me->replaceVar($me->{'cache'}{$txt}, @var);
}

#getAllLike is like GenericObject->getTree

sub getAllLike
{
    my ($me, $key) = @_;

    my %ids;
    #load them in reverse so the preferred ones overwrite the less-preferred ones
    foreach my $l (reverse @{$me->{'lang'}})
    {
	$me->{'dal'}->select(
            'what' => ['id', 'data'],
            'from' => ['locale'],
            'where' => [['lower(lang)', '=', 'lower(' . $me->{'dal'}->qt($l) . ')'], 'and', ['id', 'like', $me->{'dal'}->qt($key . '%')]],
            'orderBy' => $me->{'keys'},
            )->do();
	foreach (1..$me->{'dal'}{'tuples'})
	{
	    my @d = $me->{'dal'}->fetchrow;
	    warn "Locale::getAllLike($key): " . join(', ', @d) . "\n" if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Locale/;
	    $ids{$d[0]} = $me->{'cache'}{$d[0]} = $d[1];
	}
    }
    return map {$_, $me->{'cache'}{$_}} keys(%ids);;
}

sub getOrDefault
{
    my ($me, $txt, $def, @var) = @_;
    my $rtn;
    $rtn = $me->get($txt, @var);
    return $me->replaceVar($def, @var) if $rtn eq $txt;
    return $rtn;
}

sub replaceVar
{
    #this replaces the variable text with the new stuff
    my ($me, $txt, @var) = @_;

    my %p;

    %p = @var if $#var % 2 == 1;
    #convert old-style positional params to the new format
    $txt =~ s/%(\d+)/%{$1}/g;
    $p{$_} = $var[$_] foreach (0..$#var);
    #new-style %{name[(n)]}
    $txt =~ s/%{(\w+)(\((-?\d+)\))?}/sprintf "%" . ($3 ? "$3." . abs($3) : "") . "s", $p{$1}/ge;

    return $txt;
}

sub clearCache
{
    #you should almost never use this function

    #this function clears the cache,
    #so it makes a big hit on the database the 
    #first time every string is accessed

    my ($me) = @_;
    $me->{'cache'} = {};
    return 1;
}

sub getDb
{
    my ($me, $txt) = @_;

    my $r;

    warn "Locale::getDb() # lang ", $#{$me->{'lang'}}, "\n" if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Locale/;
    foreach my $l (@{$me->{'lang'}})
    {
	warn "Locale::getDb() trying lang=$l\n" if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Locale/;
	#try each language, at the first match, exit
	#per RFC3066, we need to match the language code case insensitively
        eval {
            #$me->{'dal'}->trace(STDERR);
            $me->{'dal'}->do("select data from locale where lower(lang)=lower(" . $me->{'dal'}->qt($l) . ") and id=" . $me->{'dal'}->qt($txt));
            ($r) = $me->{'dal'}->fetchrow;
            warn "Locale::getDb() r=$r\n" if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Locale/;
            #$me->{'dal'}->trace('');
        };
        if($@)
        {
            warn "Locale::getDb(): the DB returned an error: $@\n";
            return undef;
        }
        return $r if $me->{'dal'}{'tuples'} > 0;
    }
    #it's not in the db, just pass the english string through
    warn "Locale::getDb() IT'S NOT IN THE DB EITHER >$txt<\n" if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Locale/;
    return $txt;
}

sub nowFmt
{
    my ($me, $fmt) = @_;

    return $me->temporalFmt($fmt, 'now');
}

sub timeToEpoch
{
    my ($me, $t) = @_;
    
    use Time::Local 'timegm_nocheck', 'timelocal';
    
    my @t;
    my $r;
    
    #we need to catch date-only inputs
    if(!defined $t or $t eq '')
    {
        #nothing, proabably null
        return undef;
    }
    elsif($t =~ /^(\d{4})-(\d{2})-(\d{2})$/) #ISO format
    {
	@t = (0, 0, 0, $3, $2 - 1, $1 - 1900);
	$r = timelocal(@t);
    }
    elsif($t =~ m*^(\d{2})[/-](\d{2})[/-](\d{4})$*) #common US format
    {
	@t = (0, 0, 0, $2, $1 - 1, $3 - 1900);
	$r = timelocal(@t);
    }
    #internal postgresql timestamps are of the form:
    #YYYY-MM-DD HH:MM:SS[.subsecs][+|-TZ]
    #TZ for example: +09, -02:30 (my GNU/Libc system)
    #this regex doesn't completely handle iso-8601 timestamps, just the common postgresql ones
    #UPDATE: it should now handle most common forms of the ISO-8601 timestamps too
    elsif($t =~ /(\d{4})-(\d{2})-(\d{2})(\s+|T)(\d{2}):(\d{2}):(\d{2})(\.\d+)?(([+-])(\d{2})(:?(\d{2}))?)?/)
    {
	#1 YYYY (2004)
	#2 MM (09)
	#3 DD (22)
        #4 space or ISO "T"
	#5 HH (14)
	#6 MM (45)
	#7 SS (34)
	#8 .subsec (.022119) [optional]
	#9 +|-TZ[:TZ] (-05[:30]) [optional]
        #10 +/- [optional]
        #11 HH of offset [optional]
	#12 :TZ (:30 minute component of TZ) [optional]
        #13 MM of offset [optional]
        my $min = $6;
        my $hr = $5;
        $hr += ($10 eq '-' ? ($11) : (-$11)) if $11;
        $min += ($10 eq '-' ? ($13) : (-$13)) if $13;
	@t = ($7, $min, $hr, $3, $2 - 1, $1 - 1900); 
	$r = timegm_nocheck(@t);
    }
    elsif($t =~ /^now$/i)
    {
        $r = time;
    }
    else
    {
	#didn't match anything, set it to zeros
        $r = 0;
    }
    
    #warn "timeToEpoch(): Perl-only epoch is $r\n" if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /xmlReporter/;
    return $r;
}

sub temporalFmt
{
    my ($me, $fmt, $v) = @_;
    
    use POSIX ();

    #check for null temporal values
    return undef if !defined $v or $v eq '';
    
    if($fmt =~ /^longTimestamp/)
    {
	$v = POSIX::strftime($me->get('Lane/Locale/Temporal/LongTimestamp'), localtime($me->timeToEpoch($v)));
    }
    elsif($fmt  =~ /^shortTimestamp/)
    {
	$v = POSIX::strftime($me->get('Lane/Locale/Temporal/ShortTimestamp'), localtime($me->timeToEpoch($v)));
    }
    elsif($fmt =~ /^longTime/)
    {
	$v = POSIX::strftime($me->get('Lane/Locale/Temporal/LongTime'), localtime($me->timeToEpoch($v)));
    }
    elsif($fmt  =~ /^shortTime/)
    {
	$v = POSIX::strftime($me->get('Lane/Locale/Temporal/ShortTime'), localtime($me->timeToEpoch($v)));
    }
    elsif($fmt  =~ /^longDate/)
    {
	$v = POSIX::strftime($me->get('Lane/Locale/Temporal/LongDate'), localtime($me->timeToEpoch($v)));
    }
    elsif($fmt  =~ /^shortDate/)
    {
	$v = POSIX::strftime($me->get('Lane/Locale/Temporal/ShortDate'), localtime($me->timeToEpoch($v)));
    }
    return $v;
}

sub moneyFmt
{
    use strict;
    my ($me, $m) = @_;
    my $r;
    my ($pre, $suf, $gd, $gs, $dd, $ds) = ($me->get('Lane/Locale/Money/Prefix'), $me->get('Lane/Locale/Money/Suffix'), $me->get('Lane/Locale/Money/GroupingDigits'), $me->get('Lane/Locale/Money/GroupingSeparator'), $me->get('Lane/Locale/Money/DecimalDigits'), $me->get('Lane/Locale/Money/DecimalSeparator')); #for ease of typing

    if($m < 0)
    {
	$m *= -1;
	($pre, $suf, $gd, $gs, $dd, $ds)
	    =
	    (
	     $me->get('Lane/Locale/Money/Negative/Prefix'),
	     $me->get('Lane/Locale/Money/Negative/Suffix'),
	     $me->get('Lane/Locale/Money/Negative/GroupingDigits'),
	     $me->get('Lane/Locale/Money/Negative/GroupingSeparator'),
	     $me->get('Lane/Locale/Money/DecimalDigits'),
	     $me->get('Lane/Locale/Money/Negative/DecimalSeparator')
	     );
    }

    #$r = sprintf '%0' . ($dd + 1) . 'd', $m;
    $r = '0' x ($dd + 1 - length($m)) . $m ;
    $r =~ s/(\d)(\d{$dd})$/$1$ds$2/; #insert the ds first
    1 while $r =~ s/(\d)(\d{$gd})(?!\d)/$1$gs$2/; #now the various gs's
    return "$pre$r$suf";
}

sub extFmt
{
    #this is here until the decimal point independant code is in place
    my ($me, $m, $debug) = @_;
    my $r;
    my $dd = $me->get('Lane/Locale/Money/DecimalDigits');
    #$r = '0' x ($dd + 1 - length($m)) . $m ;
    $r = sprintf "%" . ($dd + 1) . "." . ($dd + 1) ."d\n", $m;
    $r =~ /(-?)(\d*)(\d{$dd})$/;
    $r = "$1$2.$3"; #not exactly i18n-friendly, BUT MUCH FASTER THAN THE DB METHOD
#    s/(\d)(\d{$dd})$/$1\.$2/; #from moneyFmt
    return $r;
}

sub roundAt
{
    my ($me, $v, $prec) = @_;

    $v = 0 if $v !~ /^-?\d+\.?\d*$/;
    $prec = 0 if $prec !~ /^\d+$/;
    $me->{'dal'}->do('select ' . $v . '::numeric(15,' . $prec . ')');
    return ($me->{'dal'}->fetchrow)[0];
}

sub roundingDiv
{
    my ($me, $v, $w, $prec) = @_;

    $v = 0 if $v !~ /^-?\d+\.?\d*$/;
    $w = 0 if $w !~ /^-?\d+\.?\d*$/;
    $prec = 0 if $prec !~ /^\d+$/;
    $me->{'dal'}->do('select (' . "$v/$w" . ')::numeric(15,' . $prec . ')');
    return ($me->{'dal'}->fetchrow)[0];
}

sub roundingMulti
{
    my ($me, $v, $w, $prec) = @_;

    $v = 0 if $v !~ /^-?\d+\.?\d*$/;
    $w = 0 if $w !~ /^-?\d+\.?\d*$/;
    $prec = 0 if $prec !~ /^\d+$/;
    $me->{'dal'}->do('select (' . "$v * $w" . ')::numeric(15,' . $prec . ')');
    return ($me->{'dal'}->fetchrow)[0];
}

1;
