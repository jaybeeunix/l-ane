#LanePOS PrintAtOnce Device
#Devices/BurrellBizSys/PrintAtOnce.pm
#Copyright 2005-2010 Jason Burrell
#LanePOS, see $LaneROOT/documentation/README

#$Id: PrintAtOnce.pm 1133 2010-09-19 22:45:15Z jason $

=pod

=head1 NAME

LanePOS/Devices/BurrellBizSys/PrintAtOnce.pm - Buffer the receipt and only print it when the entire receipt is ready

=head1 SYNOPSIS

LanePOS::Devices::BurrellBizSys::PrintAtOnce

=head1 DESCRIPTION

C<Devices::BurrellBizSys::PrintAtOnce> provides a buffering mechanism for printing receipts.

=head1 USAGE

Typically, printer driver initialization is handled by L<LanePOS::Register>'s initMachine mechanism. Inside of that system, something along the lines of the following binds an IO::Handle to the printer driver:

=over

use LanePOS::Devices::BurrellBizSys::PrintAtOnce;

$ioh = PrintAtOnce->new('>', '/dev/ttyS0');

use LanePOS::Devices::Epson::TMT88;

$printer = TMT88->new($ioh, $dal);

$ioh->setTrigger($printer->{'codes'}{'cut'});

=back

=head1 SUBROUTINES

=over

=item new(mode, file)

Returns a new PrintAtOnce object. The C<mode> and C<file> parameters are Perl L<open|perlfunc/open> parameters. This object should be used in place of an IO::Handle object.

=item setTrigger(s)

Sets the string, C<s>, which triggers the class to actually print the data. As above, one would typically set this to the printer's cut code. PrintAtOnce will ingnore any attempts to set the trigger to only whitespace.

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

package LanePOS::Devices::BurrellBizSys::PrintAtOnce;

require 5.008;

use base 'LanePOS::ProtoObject';

use IO::File;

sub new
{
    my ($class, $mode, $expr) = @_; #MODE and EXPR are "perlfunc -f open"'s names for those
    my $me = {
	'io' => IO::File->new,
	'mode' => $mode,
	'expr' => $expr,
	'buffer' => '',
	'trigger' => "\0" x 20, #set it to null for the moment
    };

    $me->{'type'} = 'Printer: pseudo printer';
    $me->{'make'} = 'Burrell Business Systems';
    $me->{'model'} = 'PrintAtOnce';
    
    $me->{'io'}->open($expr, $mode),

    bless $me, $class;

    return $me;
}

sub setTrigger
{
    my ($me, $trigger) = @_;

    return 0 if $trigger =~ /^\s*$/; #don't change it to only white space

    $me->{'trigger'} = $trigger;
}

sub reopen
{
    my ($me) = @_;

    return ($me->{'io'}->close and $me->{'io'}->open($me->{'expr'}, $me->{'mode'}));
}

sub print
{
    my ($me, @x) = @_;
    foreach my $x (@x)
    {
	my ($before, $after) = ($x, '');
	if($x =~ /$me->{'trigger'}/)
	{
	    $me->{'buffer'} .= $` . $me->{'trigger'};
	    $me->{'io'}->print($me->{'buffer'});
	    $me->{'buffer'} = defined $' ? $' : '';
	    $me->reopen;
	}
	else
	{
	    $me->{'buffer'} .= $x;
	}
    }
}

sub AUTOLOAD
{
    my ($me, @x) = @_;

    #ignore destroy
    return 0 if $AUTOLOAD =~ /::DESTROY$/;

    #strip the package name off
    $AUTOLOAD =~ s/.*:://;

    return eval { $me->{'io'}->$AUTOLOAD(@x); };
}

1;
