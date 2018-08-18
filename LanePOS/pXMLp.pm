#Perl Module

#pXMLp.pm the pseudo-XML parser

#Copyright 2003-2010 Jason Burrell.
#This class is licensed under the GPL.

#created 2003-05-10 Jason Burrell
#$Id: pXMLp.pm 1132 2010-09-19 21:36:50Z jason $

#PrepXMLp.pm (Preprocess pXMLp) adds (will add) doctype, encoding, and named entity support

package pXMLp;

require 5.008; #for unicode

$VERSION = '0.7';

sub new
{
    my ($class, $debug) = @_;
    print STDERR "\$debug=$debug\n" if $debug;
    my $me = {
	'debug' => $debug,
	'capabilities' => {
	    'encoding' => 0,
	    'dtd' => 0,
	    'doctype' => 1,
	    'cdata' => 1,
	    'attributes' => 1,
	    'numericEntities' => 1,
	    'namedEntities' => 1,
	    'processingDirectives' => 1,
	    'comments' => 1,
	    #'' => ,
	},
	're' => {
	    'emptyTag' => qr{\G<([^?/<>\s]+)\s*([^<>]*)?\s*/>}s,
	    'startTag' => qr{\G<([^?/<>\s]+)\s*([^<>]*)?\s*>}s,
	    'endTag' => qr{\G</([^/<>\s]+)>}s,
	    'text' => qr{\G([^<>]+)}s,
	    #'xmlDeclaration' => qr{<\?xml\s+version="1\.0"(\s+encoding="([^"]+)")?\s*\?>},
	    #damn emacs syntax highlighting
	    'xmlDeclaration' => qr{<\?xml\s+version=(['"])1\.0\1(\s+encoding=(['"])(.+)\3)?(\s+standalone=(['"])(.+)\6)?\?>},
	    'cdata' => qr{<!\[CDATA\[(.*?)\]\]>}s,
	    'charDecEntity' => qr{&#(\d+);},
	    'charHexEntity' => qr{&#x([\dabcdefABCDEF]+);},
	    'processingDirective' => qr{\G<\?(\S+)(\s+(.*?))?\s*\?>}s,
	    #'comment' => qr{<!--\s+()\s+-->}s,
	    'comment' => qr{\G<!--\s*(.*?)\s*-->}s,
	    'doctype' => qr{<!DOCTYPE\s+(\S+)\s+SYSTEM\s+(['"])([^"']*)\2(\s+\[.*?\])?>}s,
	    'attribute' => qr{(\S+)\s*=\s*(['"])(.*?)\2}s, #'])} damn emacs
	    'leftover' => qr{.*}s,
	},
	'leftover' => '',
	'firstTime' => 1,
    };
    bless $me, $class;
    return $me;
}

sub parse
{
    #reads a chunk of xml, calling the object's various methods to handle the data
    my ($me, $xml) = @_;

    #remove the cdata's before passing through
    $xml = $me->deCdata($xml);
    #add in the leftover xml from the previous run
#    $xml .= $me->{'leftover'}; $me->{'leftover'} = '';
    my $len = length($xml) - 1;

    #xml declaration
    if($me->{'firstTime'} and $xml =~ /$me->{'re'}{'xmlDeclaration'}/gc)
    {
	print STDERR "pXMLp: XML Declaration found\n" if $me->{'debug'};
	#technically, the following isn't true since we use the std perl
	#handling routines. We SHOULD auto-promote everything into utf8.
	#only hand this class utf8, unless you want things to break.
	################
	#check the encoding
	#if($4 ne 'UTF-8')
	#{
	#    print STDERR "pXML: I only support the UTF-8 encoding, not \"$4\".\n" if $me->{'debug'};
	#    return 0;
	#}

	#ok, we've processed the xml declaration, no more firstTime stuff
	$me->{'firstTime'} = 0;
    }
    if($xml =~ /$me->{'re'}{'doctype'}/gc)
    {
	print STDERR "pXMLp->parse() matched doctype\n" if $me->{'debug'};
	$me->doctypeDeclaration($1, $3, (defined $4 ? $4 : ''));
    }

    do
    {
	print STDERR "pXMLp->parse() in the main do loop\n" if $me->{'debug'};
	#try each of the re's
	if($xml =~ /$me->{'re'}{'comment'}/gc)
	{
	    print STDERR "pXMLp->parse() matched comment\n" if $me->{'debug'};
	    $me->comment($1);
	}
	elsif($xml =~ /$me->{'re'}{'emptyTag'}/gc)
	{
	    print STDERR "pXMLp->parse() matched emptyTag [$1]\n" if $me->{'debug'};
	    #check for attributes
	    my $tag = $1;
	    if(defined $2 and $2 ne '')
	    {
		my $a = $2;
		my %a;
		while($a =~ /$me->{'re'}{'attribute'}/g)
		{
		    $a{$1} = $me->deEntity($3);
		}
		$me->startTag($tag, %a);
	    }
	    else
	    {
		$me->startTag($tag);
	    }
	    $me->endTag($tag);
	}
	elsif($xml =~ /$me->{'re'}{'startTag'}/gc)
	{
	    print STDERR "pXMLp->parse() matched startTag [$1]\n" if $me->{'debug'};
	    #check for attributes
	    my $tag = $1;
	    if(defined $2 and $2 ne '')
	    {
		print STDERR "pXMLp->parse() matched startTag[$1]: we have attributes \n" if $me->{'debug'};
		my $a = $2;
		my %a;
		while($a =~ /$me->{'re'}{'attribute'}/g)
		{
		    print STDERR "\t\tattribute $1 $3 \n" if $me->{'debug'};
		    $a{$1} = $me->deEntity($3);
		}
		$me->startTag($tag, %a);
	    }
	    else
	    {
		$me->startTag($tag);
	    }
	}
	elsif($xml =~ /$me->{'re'}{'endTag'}/gc)
	{
	    print STDERR "pXMLp->parse() matched endTag [$1]\n" if $me->{'debug'};
	    $me->endTag($1);
	}
	elsif($xml =~ /$me->{'re'}{'processingDirective'}/gc)
	{
	    print STDERR "pXMLp->parse() matched processingDirective\n" if $me->{'debug'};
	    $me->processingDirective($1, $me->deEntity($3));
	}
	elsif($xml =~ /$me->{'re'}{'text'}/gc)
	{
	    print STDERR "pXMLp->parse() matched text\n" if $me->{'debug'};
	    $me->text($me->deEntity($1));
	}
	else
	{
	    print STDERR "pXMLp->parse() error (the else condition--we shouldn't be here)\n" if $me->{'debug'};

	    #rather than erroring out, save the remainder in leftover for subsequent calls to parse()
	    print STDERR "pXMLp->parse() this is were \\G matches ", sprintf("%2.2x %d", pos($xml), pos($xml)), "\n" if $me->{'debug'};
	    $xml =~ /$me->{'re'}{'startTag'}/gc;
	    print STDERR "pXMLp->parse() this is the startTag match >$1<\n", sprintf("%2.2x", pos($xml)), "\n" if $me->{'debug'};
	    $xml =~ /$me->{'re'}{'leftover'}/gc;
	    $me->{'leftover'} = $1;
	    print STDERR "pXMLp->parse() this is left >", $me->{'leftover'}, "\n" if $me->{'debug'} and defined $me->{'leftover'};
	}
    } while pos($xml) <= $len;
    1;
}

sub deCdata
{
    $_ = $_[1];
    s/$_[0]->{'re'}{'cdata'}/$_[0]->entitify($1)/ge;
    return $_;
}

sub entitify
{
    $_ = $_[1];
    s/&/&amp;/g;
    s/'/&apos;/g; #'
    s/"/&quot;/g; #"
    s/</&lt;/g;
    s/>/&gt;/g;
    return $_;
}

sub deEntity
{
    #convert character refs to their unicode value
    $_ = $_[1];
    s/$_[0]->{'re'}{'charDecEntity'}/chr($1)/ge;
    s/$_[0]->{'re'}{'charHexEntity'}/chr(hex($1))/ge;
    s/&amp;/&/g;
    s/&apos;/'/g; #'
    s/&quot;/"/g; #"
    s/&lt;/</g;
    s/&gt;/>/g;
    return $_;
}

sub startTag
{
    my $me = shift;
    print STDERR "pXMLp->startTag(", join(", ", @_), ") undefined!\n" if $me->{'debug'};
    0;
}

sub endTag
{
    my $me = shift;
    print STDERR "pXMLp->endTag(", join(", ", @_), ") undefined!\n" if $me->{'debug'};
    0;
}

sub processingDirective
{
    my $me = shift;
    print STDERR "pXMLp->processingDirective(", join(", ", @_), ") undefined!\n" if $me->{'debug'};
    0;
}

sub doctypeDeclaration
{
    my $me = shift;
    print STDERR "pXMLp->doctypeDeclaration(", join(", ", @_), ") undefined!\n" if $me->{'debug'};
    0;
}

sub comment
{
    my $me = shift;
    print STDERR "pXMLp->comment(", join(", ", @_), ") undefined!\n" if $me->{'debug'};
    0;
}

sub text
{
    my $me = shift;
    print STDERR "pXMLp->text(", join(", ", @_), ") undefined!\n" if $me->{'debug'};
    0;
}

1;
