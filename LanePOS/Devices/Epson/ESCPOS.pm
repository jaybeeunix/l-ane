#LanePOS Printer Driver v0.1
#Devices/Epson/ESCPOS.pm
#LanePOS, see $LaneROOT/documentation/README

#$Id: ESCPOS.pm 1132 2010-09-19 21:36:50Z jason $

=pod

=head1 NAME

LanePOS/Devices/Epson/ESCPOS.pm - ESC/POS devices superclass

=head1 SYNOPSIS

LanePOS::Devices::Epson::ESCPOS

=head1 DESCRIPTION

C<Devices::Epson::ESCPOS> provides support for ESC/POS (an industry-supported, Epson defined standard) devices, including receipt printers, cash drawers, and pole displays. It is a child of L<Devices::GenericPrinter>.

=head1 SUPPORTED OPTIONS/COMMANDS

=over

=item Paper Handling

40-column receipts, Slip Printing, Paper-Cutting

=item Graphics

Via an immediate print mode

=item Justification

Left, center, and right

=item Character Format

Bold. Black and Red

=item Non-printer Devices

Pole Displays, Two Cash Drawers

=item ISO-8859

The entire ISO-8859-1 character set via codepage switching. The Euro from ISO-8859-15 on printers which support that codepage (the other unique characters of ISO-8859-15 are not supported by an Epson standard codepage).

=back

=head1 SUPPORTED HARDWARE

=over

Typically, this driver is not used directly. It is usually sub-classed by other ESC/POS-compliant drivers.

=back

=head1 AUTHOR

Jason Burrell

=head1 BUGS

=over

=item *

This program contains no known bugs.

=back

=head1 SEE ALSO

L<Devices::GenericPrinter>, The L'E<acirc>ne Website L<http://l-ane.net/>

=cut

package LanePOS::Devices::Epson::ESCPOS;

require 5.008;

use base 'LanePOS::Devices::GenericPrinter';

sub new
{
    my $class = shift;

    my $me = $class->SUPER::new(@_);

    $me->{'type'} = 'Printer: Receipt';
    $me->{'make'} = 'Epson et al.';
    $me->{'model'} = 'ESC/POS Standard';
    $me->{'revision'} = '0.1';
    $me->{'notes'} = 'Provides ESC/POS, Epson POS std codes';

    $me->{'prints'}{'receipt'} = '1';
    $me->{'prints'}{'graphics'} = '1';
    $me->{'codes'}{'graphicsBlockHeight'} = 8;

    $me->{'columns'} = '40';
    $me->{'linesUntilSeen'} = 9;

    $me->{'codes'}{'reset'} = "\e@";
    $me->{'codes'}{'justifyLeft'} = "\ea\x00";
    $me->{'codes'}{'justifyCenter'} = "\ea\x01";
    $me->{'codes'}{'justifyRight'} = "\ea\x02";
    $me->{'codes'}{'justifyLeftOff'} = $me->{'codes'}{'justifyLeft'};
    $me->{'codes'}{'justifyCenterOff'} = $me->{'codes'}{'justifyLeft'};
    $me->{'codes'}{'justifyRightOff'} = $me->{'codes'}{'justifyLeft'};
    $me->{'codes'}{'emphasizeOn'} = "\e!\x21";
    $me->{'codes'}{'emphasizeOff'} = "\e!\x01";
    $me->{'codes'}{'red'} = "\er\x01";
    $me->{'codes'}{'black'} = "\er\x00";
    $me->{'codes'}{'redOff'} = $me->{'codes'}{'blackOff'} = $me->{'codes'}{'black'};
    $me->{'codes'}{'srcRoll'} = "\ec0\x01\ec1\x01";
    $me->{'codes'}{'srcSlip'} = "\ec0\x04\ec1\x04";
    $me->{'codes'}{'ejectSlip'} = "\xc";
    $me->{'codes'}{'ejectReceipt'} = "\n" x 9;
    $me->{'codes'}{'switchPole'} = "\e=\x02\x0c"; #the \x0c bit clears the pole
    $me->{'codes'}{'switchPrint'} = "\e=\x01";
    $me->{'codes'}{'cut'} = "\x1dV\x01\n";
    $me->{'codes'}{'drawer1Kick'} = "\ep\x00\x19\xfa";
    $me->{'codes'}{'drawer2Kick'} = "\ep\x01\x19\xfa";

    $me->{'characters'} = {
	#these are all the latin-1 codes
	"\xa0" => ' ', #
	"\xa1" => "\eR\0\x{ad}\eR\0", #
	"\xa2" => "\eR\0\x{9b}\eR\0", #
	"\xa3" => "\eR\0\x{9c}\eR\0", #
	"\xa4" => "\eR\x{9}\x{24}\eR\0", #
	"\xa5" => "\eR\0\x{9d}\eR\0", #
	"\xa6" => "\et\x{2}\x{dd}\et\0", #
	"\xa7" => "\eR\x{1}\x{5d}\eR\0", #
	"\xa8" => "\eR\x{1}\x{7e}\eR\0", #
	"\xa9" => "\et\x{2}\x{b8}\et\0", #
	"\xaa" => "\eR\0\x{a6}\eR\0", #
	"\xab" => "\eR\0\x{ae}\eR\0", #
	"\xac" => "\eR\0\x{aa}\eR\0", #
	"\xad" => '', #soft hyphen--this will totally screw us up (changes the char spacing)
	"\xae" => "\et\x{2}\x{a9}\et\0", #
	"\xaf" => "\et\x{2}\x{ee}\et\0", #
	"\xb0" => "\eR\0\x{f8}\eR\0", #
	"\xb1" => "\eR\0\x{f1}\eR\0", #
	"\xb2" => "\eR\0\x{fd}\eR\0", #
	"\xb3" => "\et\x{2}\x{fc}\et\0", #
	"\xb4" => "\et\x{2}\x{ef}\et\0", #
	"\xb5" => "\eR\0\x{e6}\eR\0", #
	"\xb6" => "\et\x{2}\x{f4}\et\0", #
	"\xb7" => "\eR\0\x{f9}\eR\0", #
	"\xb8" => "\et\x{2}\x{f7}\et\0", #
	"\xb9" => "\et\x{2}\x{fb}\et\0", #
	"\xba" => "\eR\0\x{a7}\eR\0", #
	"\xbb" => "\eR\0\x{af}\eR\0", #
	"\xbc" => "\eR\0\x{ac}\eR\0", #
	"\xbd" => "\eR\0\x{ab}\eR\0", #
	"\xbe" => "\et\x{2}\x{f3}\et\0", #
	"\xbf" => "\eR\0\x{a8}\eR\0", #
	"\xc0" => "\et\x{2}\x{b7}\et\0", #
	"\xc1" => "\et\x{2}\x{b5}\et\0", #
	"\xc2" => "\et\x{2}\x{b6}\et\0", #
	"\xc3" => "\et\x{2}\x{c7}\et\0", #
	"\xc4" => "\eR\0\x{8e}\eR\0", #
	"\xc5" => "\eR\0\x{8f}\eR\0", #
	"\xc6" => "\eR\0\x{92}\eR\0", #
	"\xc7" => "\eR\0\x{80}\eR\0", #
	"\xc8" => "\et\x{2}\x{d4}\et\0", # 
	"\xc9" => "\eR\0\x{90}\eR\0", #
	"\xca" => "\et\x{2}\x{d2}\et\0", # 
	"\xcb" => "\et\x{2}\x{d3}\et\0", # 
	"\xcc" => "\et\x{3}\x{98}\et\0", # 
	"\xcd" => "\et\x{2}\x{d6}\et\0", # 
	"\xce" => "\et\x{2}\x{d7}\et\0", # 
	"\xcf" => "\et\x{2}\x{d8}\et\0", # 
	"\xd0" => "\et\x{2}\x{d1}\et\0", # 
	"\xd1" => "\eR\0\x{a5}\eR\0", # 
	"\xd2" => "\et\x{2}\x{e3}\et\0", # 
	"\xd3" => "\et\x{2}\x{e0}\et\0", # 
	"\xd4" => "\et\x{2}\x{e2}\et\0", # 
	"\xd5" => "\et\x{2}\x{e5}\et\0", # 
	"\xd6" => "\eR\0\x{99}\eR\0", # 
	"\xd7" => "\et\x{2}\x{9e}\et\0", # 
	"\xd8" => "\eR\x{4}\x{5c}\eR\0", #
	"\xd9" => "\et\x{2}\x{eb}\et\0", # 
	"\xda" => "\et\x{2}\x{e9}\et\0", # 
	"\xdb" => "\et\x{2}\x{ea}\et\0", # 
	"\xdc" => "\eR\0\x{9a}\eR\0", #
	"\xdd" => "\et\x{2}\x{ed}\et\0", # 
	"\xde" => "\et\x{2}\x{e8}\et\0", # 
	"\xdf" => "\eR\x{2}\x{7e}\eR\0", #
	"\xe0" => "\eR\0\x{85}\eR\0", #
	"\xe1" => "\eR\0\x{a0}\eR\0", #
	"\xe2" => "\eR\0\x{83}\eR\0", #
	"\xe3" => "\et\x{2}\x{c6}\et\0", # 
	"\xe4" => "\eR\0\x{84}\eR\0", #
	"\xe5" => "\eR\0\x{86}\eR\0", #
	"\xe6" => "\eR\0\x{91}\eR\0", #
	"\xe7" => "\eR\0\x{87}\eR\0", #
	"\xe8" => "\eR\0\x{8a}\eR\0", #
	"\xe9" => "\eR\0\x{82}\eR\0", #
	"\xea" => "\eR\0\x{88}\eR\0", #
	"\xeb" => "\eR\0\x{89}\eR\0", # 
	"\xec" => "\eR\0\x{8d}\eR\0", #
	"\xed" => "\eR\0\x{a1}\eR\0", #
	"\xee" => "\eR\0\x{8c}\eR\0", #
	"\xef" => "\eR\0\x{8b}\eR\0", #
	"\xf0" => "\et\x{2}\x{d0}\et\0", # 
	"\xf1" => "\eR\0\x{a4}\eR\0", #
	"\xf2" => "\eR\0\x{95}\eR\0", #
	"\xf3" => "\eR\0\x{a2}\eR\0", #
	"\xf4" => "\eR\0\x{93}\eR\0", #
	"\xf5" => "\et\x{2}\x{e4}\et\0", # 
	"\xf6" => "\eR\0\x{94}\eR\0", #
	"\xf7" => "\et\x{2}\x{f6}\et\0", #
	"\xf8" => "\eR\x{4}\x{7c}\eR\0", # 
	"\xf9" => "\eR\0\x{97}\eR\0", #
	"\xfa" => "\et\x{2}\x{a3}\et\0", #
	"\xfb" => "\eR\0\x{96}\eR\0", #
	"\xfc" => "\eR\0\x{81}\eR\0", #
	"\xfd" => "\et\x{2}\x{ec}\et\0", # 
	"\xfe" => "\et\x{2}\x{e7}\et\0", # 
	"\xff" => "\eR\0\x{98}\eR\0", #
	#the various characters in latin-9, that aren't in latin-1
	"\x{20ac}" => "\et\x{13}\x{d5}\et\0", # the euro sign
	"\x{160}" => "\et\x{10}\x{8a}\et\0", # 0160 LATIN CAPITAL LETTER S WITH CARON
	"\x{161}" => "\et\x{10}\x{9a}\et\0", # 0161 LATIN SMALL LETTER S WITH CARON
	"\x{17d}" => "\et\x{10}\x{8e}\et\0", # 017D LATIN CAPITAL LETTER Z WITH CARON
	"\x{17e}" => "\et\x{10}\x{9e}\et\0", # 017E LATIN SMALL LETTER Z WITH CARON
	"\x{152}" => "\et\x{10}\x{8c}\et\0", # 0152 LATIN CAPITAL LIGATURE OE
	"\x{153}" => "\et\x{10}\x{9c}\et\0", # 0153 LATIN SMALL LIGATURE OE
	"\x{178}" => "\et\x{10}\x{9f}\et\0", # LATIN CAPITAL LETTER Y WITH DIAERESIS
	#
    };

    $me->_hackForLatin9;

    bless $me, $class;

    $me->printThis($me->{'codes'}{'reset'} . $me->{'codes'}{'switchPrint'} . $me->{'codes'}{'emphasizeOff'} . $me->{'codes'}{'justifyCenter'});
    return $me;
}

sub formatGraphic
{
    my ($me, $img, $geo) = @_;
#    print STDERR "ESCPOS::formatGraphic($me, $img, $geo)\n";

    my $width;

    if($geo !~ /^(\d*)x\d*$/)
    {
	#print STDERR "ESCPOS: you didn't give me the width!\n";
	return '';
    }
    $width = $1;

    #we only print in "normal" mode (the \0 at the end)

    use integer; #we want the divides to be integers in this block
    use bytes;   #and we don't want unicode to screw with us

    #strip all but data from the string
    $img =~ s/[^01]//gs;

    #fix the width so it's a multiple of 8
    my $r = $width % 8;
    if($r)
    {
	my $add = '0' x (8 - $r);
	$img =~ s/([01]{$width})/$1$add/gs;
	$width = $width + 8 - $r;
    }

    #for convience
    my $height = length($img) / $width;

    my $blockHeight = $me->{'codes'}{'graphicsBlockHeight'};
    #pad the image w/blank rows to make height a multiple of blockHeight
    $img .= '0' x $width x ($blockHeight - $height % $blockHeight) if $height % $blockHeight;
    #the new height
    $height = length($img) / $width;

    my $d; #this is the data to return

    foreach my $rbo (0..$height / $blockHeight - 1)
    {
#	print STDERR "rbo=$rbo\n";
	$d .= "\e*" . ($blockHeight == 24 ? chr(33) : chr(0)) . chr($width % 256) . chr($width / 256);
	foreach my $x (0..$width - 1)
	{
#	    print STDERR "x=$x\n";
	    foreach my $blkAdj (0..$blockHeight / 8 - 1)
	    {
#		print STDERR "blkAdj=$blkAdj\n";
		my $bits;
		foreach my $y (0..7)
		{
#		    print STDERR "y=$y,\tbit at\t", $x + ($rbo * $blockHeight + $blkAdj * 8 + $y) * $width, "\n";
		    $bits .= substr $img, $x + ($rbo * $blockHeight + $blkAdj * 8 + $y) * $width, 1;
		}
		$d .= pack 'B8', $bits;
	    }
	}
	$d .= "\n";
    }
    return "\e3\0$d\e2";
}

sub printThis
{
    my ($me, @data) = @_;

    my $d = join('', @data);
    #check for epson specific guard characters
    $d =~ s/(?<!=\e[Rt][\0\1\2\3\4\x{10}\x{11}\x{12}\x{13}])$_(?!\e[Rt]\0)/$me->{'characters'}{$_}/xg foreach (keys %{$me->{'characters'}});
    $me->{'dev'}->print($d);
    return 1;
}

1;
