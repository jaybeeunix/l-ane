#Perl Module

#Tk::Bitcheckbutton Copyright 2005 Jason Burrell.
#creates a bit list similar to L'anePOS's "products" tax list
#see the screenshots on the L'ane website http://l-ane.net/

require 5.006;

package Tk::Bitcheckbutton;
$Tk::Bitcheckbutton::VERSION = '0.1';

use Tk::widgets 'Frame', 'Checkbutton';
use base 'Tk::Derived', 'Tk::Frame';
use strict;
Construct Tk::Widget 'Bitcheckbutton';

sub ClassInit
{
    my ($class, $top) = @_;

    $class->SUPER::ClassInit($top);
}

sub Populate
{
    my ($me, $args) = @_;

    #get my options, "bititems" and "variable"

    #per-widget stuff
    my @bit;

    my ($variable, $bititems) = ($args->{'-variable'}, $args->{'-bititems'});
    #can i access ->cget('-variable') after the following method calls?
    $me->SUPER::Populate($args);
    $me->ConfigSpecs(
		     -variable => ['PASSIVE'],
		     -bititems => ['PASSIVE'],
		     'DEFAULT' => [['DESCENDANTS', 'SELF']],
		     );
    #it seems i can't

    #create the list
    foreach my $i (0..$#{$bititems})
    {
	#set the initial value of the bit
	$$variable = 0 if ! defined $$variable;
	$bit[$i] = 1 if $$variable & (1 << $i);

	my $b = $me->Component(
			       'Checkbutton' => "bit$i",
			       -text => $bititems->[$i], #$bititems->[$i],
			       -variable => \$bit[$i],
			       -command => sub {
				   if($bit[$i]) #it's set
				   {
				       $$variable |= 1 << $i;
				   }
				   else #it's unset
				   {
				       $$variable &= ~(1 << $i);
				   }
			       },
			       )->pack(-anchor => 'w');
	
    }

    #we need to update the buttons when someone changes the variable
    #fix me fix me!
}

sub updateButtons
{
    my ($me) = @_;
    foreach my $i (0..$#{$me->{'Configure'}{'-bititems'}})
    {
	${$me->Subwidget("bit$i")->cget('-variable')} = (${$me->{'Configure'}{'-variable'}} & (1 << $i)) ? 1 : 0;
    }
}

1;
