#LanePOS Generic Printer Driver v0.2
#Devices/GenericPrinter.pm
#LanePOS, see $LaneROOT/documentation/README

#Copyright 2001-2010 Jason Burrell
#$Id: GenericPrinter.pm 1193 2010-10-22 21:10:11Z jason $

#This is an object-oriented replacement for the old style of printer drivers.
#All printer (and like) drivers should inherit this class' attributes and functions
#2003-10-15 jb: the printer driver now uses an IO::Handle object rather than a filehandle/glob as the device handle

#this is adapted from the following drivers/files: Epson/TMU375.pm, Common.pm

=pod

=head1 NAME

LanePOS/Devices/GenericPrinter.pm - The printer superclass

=head1 SYNOPSIS

LanePOS::Devices::GenericPrinter

=head1 DESCRIPTION

C<GenericPrinter> provides the basic object structure for the C<Register>'s printer (and related) devices. All printers, cash drawers, and pole displays should be a sub class of this class.

=head1 USAGE

Typically, printer driver initialization is handled by L<LanePOS::Register>'s initMachine mechanism. Inside of that system, something along the lines of the following binds an IO::Handle to the printer driver:

=over

use IO::File;

$ioh = new IO::File '/dev/ttyS0', 'w';

use LanePOS::Devices::GenericPrinter;

$printer = GenericPrinter->new($ioh);

=back

=head1 PROPERTIES

=over

=item type

A human-readable type of device (for example "Printer: Generic Printer Driver")

=item make

The target device's make (ie Epson)

=item model

The target device's major model (ie TM-U200)

=item revision

This driver's revision

=item notes

Human-readable notes about the device

=back

=head1 SUBROUTINES

=over

=item new()

Returns a new GenericPrinter object

=item printPole(text)

Prints C<text> to the pole display

=item openDrawer(n)

Opens drawer C<n>

=item formatGraphic(imageData, geometry)

Converts the imageData bound by geometry into print-specific image data. This subroutine must be overridden in printers supporting on-demand images.

=item beginReceipt()

"Begins" a receipt

=item finishReceipt()

"Finishes" a receipt (usually, this subroutine cuts the paper and ejects the receipt)

=item writeCheck(payee, amount, date, memo)

Prints the front of a (customer's) check

=item endorse(endorsement)

Endorses a check

=item printFormatted(text)

Prints C<text> after converting the various meta-language tags into their printer-native format.

=back

=head2 Printer Meta-Language Tags

=over

=item <b></b>

Emboldens the contents (usually with double-width)

=item <center></center>

Centers the contents

=item <right></right>

Right-justifies the contents

=item <left></left>

Left-justifies the contents

=item <black></black>

Prints the contents in the first color (usually black) [default]

=item <red></red>

Prints the contents in the second color (usually red)

=item <br>

Inserts a linefeed

=item <img geometry='widthxheight'></img> EXPERIMENTAL

[FIXME] Prints the images described by the '01' description of the contents

=back

=over

=item printHeader(text)

Prints C<text> as the header

=item printFooter(text)

Prints C<text> as the footer

=item printItem(plu, description, quantity, amount)

Prints a single item

=item printDiscount(description, amount)

Prints a single discount

=item printTender(tenderDescription, amount)

Prints a single tender item

=item printSummary(subt, total, taxes, txdescr, custinfo, terms, discDate, dueDate) DEPRICATED

Prints the summary information at the bottom of the receipt. This functionality will be integrated into L</printFooter()> in the future.

=back

=head1 AUTHOR

Jason Burrell

=head1 BUGS

=over

=item *

This program contains no known bugs.

=back

=head1 SEE ALSO

The L'E<acirc>ne Website L<http://l-ane.net/>

=cut

package LanePOS::Devices::GenericPrinter;

require 5.008;

use base 'LanePOS::ProtoObject';

use LanePOS::Locale; #for the moneyFmt routines
use XML::SAX; #SaxyPrinter specific

sub new
{
    my ($class, $device, $lc) = @_;
    $lc = Locale->new if !UNIVERSAL::isa($lc, 'LanePOS::Locale');
    my $me = {        
	'lc' => $lc,
	'type' => 'Printer: Generic Printer Driver',
	'make' => 'N/A',
	'model' => 'N/A',
	'revision' => '',
	'notes' => 'This is the base printer class',
	'prints' => {
	    'receipt' => 1,
	    'endorsement' => 0,
	    'check' => 0,
	    'pole' => 0,
	    'graphics' => 0,
	},
	'columns' => '40',
	'dev' => $device,	# this should be a ref to an IO::Handle object
	'linesUntilSeen' => 2,
	'characters' => {},
	'codes' => {
	    'reset' => "",
	    'justifyLeft' => "",
	    'justifyCenter' => "",
	    'justifyRight' => "",
	    'justifyLeftOff' => "",
	    'justifyCenterOff' => "",
	    'justifyRightOff' => "",
	    'emphasizeOn' => "",
	    'emphasizeOff' => "",
	    'srcRoll' => "",
	    'srcSlip' => "",
	    'ejectReceipt' => "",
	    'ejectSlip' => "",
	    'switchPole' => "",
	    'switchPrint' => "",
	    'drawer1Kick' => "",
	    'drawer2Kick' => "",
	    'cut' => "",
	    'black' => "",
	    'red' => "",
#	    '' => "",
	},
#	'' => undef,
    };
    $me->{'codes'}{'ejectReceipt'} = "\n" x $me->{'linesUntilSeen'};

    #SaxyPrinter specific
    $me->{'saxy'} = SaxyPrinter->new;
    $me->{'xmlsax'} = XML::SAX::ParserFactory->parser(Handler => $me->{'saxy'});
#    $me->{'xmlsax'}->parse_string('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
#<ignore:root xmlns:ignore="http://l-ane.net/l-ane-xml/xmlPrinter0">');

    bless $me, $class;
    #can't do this here, do it in the individual printer drivers
    #$me->printThis($me->{'codes'}{'reset'} . $me->{'codes'}{'emphasizeOff'} . $me->{'codes'}{'justifyCenter'});
    return $me;
}

sub formatGraphic
{
    my ($me, $img, $geometry) = @_;

    return 0;
}

sub printPole
{
    my ($me, $s) = @_;

    if($me->{'prints'}{'pole'} == 1)
    {
	#BAD BAD BAD: HARDCODED CONSTANTS, pole # chars
	$me->printDirectly($me->{'codes'}{'switchPole'}, sprintf("%-40.40s", $s), "\r", $me->{'codes'}{'switchPrint'});
    }
    else
    {
#	print STDERR $me->{'make'}, " ", $me->{'model'}, " ", $me->{'revision'}, "::printPole() is not implimented\n";
    }
    return 1;
}

sub openDrawer
{
    my ($me, $n) = @_;

    $me->printDirectly($me->{'codes'}{'drawer1Kick'}) if $n & 1;
    $me->printDirectly($me->{'codes'}{'drawer2Kick'}) if $n & 2;
    return 1;
}

sub printThis
{
    my ($me, @data) = @_;

    my $d = join('', map {if($_){$_}else{;}} @data);
    #THIS WON'T WORK IF YOUR REPLACEMENT CHARACTERS CONTAIN REPLACEABLE CHARACTERS!
    #see Epson/ESCPOS.pm for practical use
    $d =~ s/$_/$me->{'characters'}{$_}/xg foreach (keys %{$me->{'characters'}});
    $me->printDirectly($d);
    return 1;
}

sub printDirectly
{
    my ($me, @d) = @_;
    return $me->{'dev'}->print(@d);
}

sub printFormatted
{
    my ($me, $text) = @_;
    $me->printThis($me->mlToPrinter($text));
    return 1;
}

sub printXmlFormatted
{
    my ($me, $text) = @_;
    $me->printThis($me->xmlToPrinter($text));
    return 1;
}

sub printHeader
{
    my ($me, $header) = @_;

    $me->printThis($me->mlToPrinter($header));
    return 1;
}

sub printItem
{
    my ($me, $plu, $descr, $qty, $amt) = @_;
    my $tmp = $me->lc->moneyFmt($amt);

    if($qty < 0)
    {
	$me->printDirectly($me->{'codes'}{'red'});
	$me->printThis($me->lc->get('Lane/Printer/Format/Item', 'qty' => $qty, 'plu' => $plu, 'amt' => $tmp, 'descr' => $descr));
	$me->printDirectly($me->{'codes'}{'black'});
    }
    else
    {
	$me->printThis($me->lc->get('Lane/Printer/Format/Item', 'qty' => $qty, 'plu' => $plu, 'amt' => $tmp, 'descr' => $descr));
    }
    return 1;
}

sub printDiscount
{
    my ($me, $descr, $amt) = @_; # $amt must be preformated (ie $######.## or ####.##%)

    $me->printDirectly($me->{'codes'}{'red'});
    $me->printThis($me->lc->get('Lane/Printer/Format/Discount', 'amt' => $amt, 'descr' => $descr));
    $me->printDirectly($me->{'codes'}{'black'});
    return 1;
}

sub printTender
{
    my ($me, $tend, $amt) = @_;

    $me->printDirectly($me->{'codes'}{'emphasizeOn'});
    $me->printThis($me->lc->get('Lane/Printer/Format/Tender', 'amt' => $me->lc->moneyFmt($amt), 'descr' => $tend));
    $me->printDirectly($me->{'codes'}{'emphasizeOff'});
    return 1;
}

sub printSummary
{
    my ($me, $subt, $total, $taxes, $txdescr, $custinfo, $terms, $discDate, $dueDate) = @_;

    $me->printThis($custinfo, $me->lc->get('Lane/Printer/Format/Subtotal', 'amt' => $me->lc->moneyFmt($subt), 'descr' => $me->lc->get('Subtotal')));

    for(my $i = 0; $i <= $#{$taxes}; $i++)
    {
        $me->printThis($me->lc->get('Lane/Printer/Format/Tax', 'amt' => $me->lc->moneyFmt($taxes->[$i]), 'descr' => $txdescr->[$i])) if $taxes->[$i] > 0;
    }
    $me->printDirectly($me->{'codes'}{'emphasizeOn'});
    $me->printThis($me->lc->get('Lane/Printer/Format/Total', 'amt' => $me->lc->moneyFmt($total), 'descr' => $me->lc->get('Total')));
    $me->printDirectly($me->{'codes'}{'emphasizeOff'});

    #print the terms stuff
    $me->printThis($me->lc->get('Lane/Printer/Format/Terms', 'termsTitle' => $me->lc->get('Terms'), 'terms' => $terms, 'discDateTitle' =>  $me->lc->get('Discount Date'), 'discDate' => $discDate, 'dueDateTitle' =>  $me->lc->get('Due Date'), 'dueDate' => $dueDate)) if $discDate ne $dueDate;

    return 1;
}

sub beginReceipt
{
    my ($me) = @_;

    $me->printDirectly($me->{'codes'}{'srcRoll'});
    return 1;
}

sub finishReceipt
{
    my ($me) = @_;

    $me->printDirectly($me->{'codes'}{'ejectReceipt'} . $me->{'codes'}{'cut'});
    return 1;
}

sub printFooter
{
    my ($me, $footer) = @_;
    $me->printThis($me->mlToPrinter($footer));
    return 1;
}

sub writeCheck
{
    my ($me, $payee, $amt, $date, $memo) = @_;

    print STDERR $me->{'make'}, ' ', $me->{'model'}, ' ', $me->{'revision'}, ' ::writeCheck is not implemented.\n';
    return 0;
}

sub endorse
{
    my ($me, $endorsement) = @_;

    if(!$me->{'prints'}{'endorsement'})
    {
	print STDERR $me->{'make'}, ' ', $me->{'model'}, ' ', $me->{'revision'}, ' ::endorse is not implemented.\n';
	return 0;
    }
    $me->printDirectly($me->{'codes'}{'srcSlip'}, "\r");
    $me->printFormatted($endorsement);
    $me->printDirectly($me->{'codes'}{'ejectSlip'}, $me->{'codes'}{'srcRoll'}, "\r");
    return 1;
}

sub mlToPrinter
{
    my ($me, $data) = @_;

    $data =~ s/<b>/$me->{'codes'}{'emphasizeOn'}/ig;
    $data =~ s/<\/b>/$me->{'codes'}{'emphasizeOff'}/ig;
    $data =~ s/<center>/$me->{'codes'}{'justifyCenter'}/ig;
    $data =~ s/<\/center>/$me->{'codes'}{'justifyCenterOff'}/ig;
    $data =~ s/<right>/$me->{'codes'}{'justifyRight'}/ig;
    $data =~ s/<\/right>/$me->{'codes'}{'justifyRightOff'}/ig;
    $data =~ s/<left>/$me->{'codes'}{'justifyLeft'}/ig;
    $data =~ s/<\/left>/$me->{'codes'}{'justifyLeftOff'}/ig;
    $data =~ s/<black>/$me->{'codes'}{'black'}/ig;
    $data =~ s/<\/black>/$me->{'codes'}{'blackOff'}/ig;
    $data =~ s/<red>/$me->{'codes'}{'red'}/ig;
    $data =~ s/<\/red>/$me->{'codes'}{'redOff'}/ig;
#    $data =~ s/<>/$me->{'codes'}{''}/eig;
#    $data =~ s/<\/>/$me->{'codes'}{''}/eig;
    $data =~ s/<br>/\n/g;

    $data =~ s/<img geometry=((['"])([^"']*)\2)>([01\s]*)<\/img>/$me->formatGraphic($4, $3)/eig; #"'

    return $data;
}

sub _hackForLatin9
{
    #this is a hack that "fixes" the latin 1 code points with their latin 9 values
    my ($me) = @_;
    return 1 if !(exists $ENV{'PGCLIENTENCODING'} and $ENV{'PGCLIENTENCODING'} =~ /^(latin[90]|unicode)$/i);
    $me->{'characters'}{"\xa4"} = $me->{'characters'}{"\x{20ac}"} if exists $me->{'characters'}{"\x{20ac}"};
    $me->{'characters'}{"\xa6"} = $me->{'characters'}{"\x{160}"} if exists $me->{'characters'}{"\x{160}"};
    $me->{'characters'}{"\xa8"} = $me->{'characters'}{"\x{161}"} if exists $me->{'characters'}{"\x{161}"};
    $me->{'characters'}{"\xb4"} = $me->{'characters'}{"\x{17d}"} if exists $me->{'characters'}{"\x{17d}"};
    $me->{'characters'}{"\xb8"} = $me->{'characters'}{"\x{17e}"} if exists $me->{'characters'}{"\x{17e}"};
    $me->{'characters'}{"\xbc"} = $me->{'characters'}{"\x{152}"} if exists $me->{'characters'}{"\x{152}"};
    $me->{'characters'}{"\xbd"} = $me->{'characters'}{"\x{153}"} if exists $me->{'characters'}{"\x{153}"};
    $me->{'characters'}{"\xbe"} = $me->{'characters'}{"\x{178}"} if exists $me->{'characters'}{"\x{178}"};
    return 1;
}

sub xmlToPrinter
{
    my ($me, $xml) = @_;
    $me->{'xmlsax'}->parse_string($xml);
    return $me->mlToPrinter($me->{'saxy'}->getAndResetBuffer);
}

package SaxyPrinter;

use base 'XML::SAX::Base';

sub new
{
    my ($class) = @_;
    my $me = {
	'myNamespace' => 'http://l-ane.net/l-ane-xml/xmlPrinter0',
	'data' => '',
    };
    bless $me, $class;
    return $me;
}

sub start_element
{
    my ($me, $e) = @_;
    $me->{'data'} .= $me->reconstituteE($e) if($e->{'NamespaceURI'} ne $me->{'myNamespace'});
}

sub end_element
{
    my ($me, $e) = @_;
    #ignore </br>
    return 1 if $e->{'NamespaceURI'} eq $me->{'myNamespace'} or $e->{'LocalName'} eq 'br';
    $me->{'data'} .= '</'. $e->{'Name'} . '>';
}

sub ignoreable_whitespace
{
    my ($me, $e) = @_;
    $me->{'data'} .= $e->{'Data'};
}

sub characters
{
    my ($me, $e) = @_;
    $me->{'data'} .= $e->{'Data'};
}

#ignore these
sub processing_instruction { 1; }
sub comment { 1; }
sub start_document {1;}
sub end_document {1;}

#utils
sub reconstituteE
{
    my ($me, $e) = @_;
    print STDERR "$0: reconstitute($e)\n" if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /xmlReporter/;
    my $r = '<' . $e->{'Name'};

    #attributes here
    foreach my $a (keys %{$e->{'Attributes'}})
    {
	#drop my namespace declaration
	next if $e->{'Attributes'}{$a}{'Prefix'} eq 'xmlns' and $e->{'Attributes'}{$a}{'Value'} eq $me->{'myNamespace'};
	
	$r .= ' ' . $e->{'Attributes'}{$a}{'Name'} . '=\'' . $me->escAttr($e->{'Attributes'}{$a}{'Value'}) . '\'';
    }
    $r .= '>';
    return $r;
}

sub escAttr
{
    my ($me, $v) = @_;
    print STDERR "$0: escAttr($v)\n" if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /xmlReporter/;
    $v =~ s/([<>"&])/'&#' . ord($1) . ';'/ge; #"]); damn emacs
    return $v;
}

#local stuff
sub resetBuffer {$_[0]->{'data'} = '';}
sub getAndResetBuffer {my $d = $_[0]->{'data'}; $_[0]->{'data'} = ''; return $d;}

1;
