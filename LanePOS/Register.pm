#L'anePOS Perl Module
#Register.pm, the o-o register component of LanePOS
#Copyright 2003-2010 Jason Burrell, portions Copyright 2000-2002 Burrell Business Systems
#See ../COPYING for licensing information

################################################################
#jason@BurrellBizSys.com - Started 2001 Apr 22 (this file)
#This is based on register/register (the unified setup)
#$Id: Register.pm 1207 2011-04-06 00:44:39Z jason $
################################################################
=pod

=head1 NAME

LanePOS/Register.pm - LE<8217>E<acirc>neE<8217>s Register class

=head1 SYNOPSIS

LanePOS::Register

=head1 DESCRIPTION

B<Register> provides the basic abstractions and E<8220>glueE<8221> which unites the various LE<8217>E<acirc>ne objects into a coherent store-front (cash register) system. This one class is used by the various user-interface E<8220>front-endsE<8221> to provide business logic and other-object integration.

=head1 USAGE

B<Register> is used soley by front-end programs. These front-ends define the user (clerk) interface and must provide the following in their C<main::> package:

=head2 Variables

=over

=item %slashFuncts

A hash containing the names of common functions as keys and subroutine references as their values. They have evolved into method calls by C<Register>, so they must accept C<$main::reg> as their first argument. These are also the names of the various mapped key functions: See L</register-keymap>. They include:

=over

=item subt

Displays the amount due in the current sale.

=item cust

Opens the customer give before pressing the button

=item cancel

Cancels the sale

=item errCorrect

Corrects (voids) the last item off the sale

=item ra

Receives money on a house Account

=item tender

Links to C<Register>E<8217>s tender processing code

=item disc

Links to C<Register>E<8217>s discount processing code

=item priceCheck

Displays the productE<8217>s description and price, without adding it to the current sale

=item suspend

Links to C<Register>E<8217>s sale suspending code which allows a sale to be saved without tendering it. L</suspend>ed sales are not finalized until they are L</resume>d and tendered.

=item resume

Links to C<Register>E<8217>s sale resuming code which allows a suspened sale to be opened. L</suspend>ed sale is are not finalized until they are L</resume>d and tendered.

=back

=item @idleTasks

An array of subroutine references which are called in sucession by L</idleUpdate>.

=item $thisIsAnXInterface

Used by plugins to determine if they are in a modal (curses) or modeless (X11) interface

=item $useResetCode

This boolean determines if the C<$resetCode> is evalE<8217>ed. See L</register-initMachine-default>.

=item $resetCode

Perl code that is used to E<8220>resetE<8221> the register in C<newTranz()>. This allows plugins to clean themselves up per-sale. See L</register-initMachine-default>.

=item $useTaxCode

This boolean determines if the C<$taxCode> is evalE<8217>ed. See L</register-initMachine-default>.

=item $taxCode

Perl code that is evalE<8217>ed inside of the tax-calculating loop. See L</register-initMachine-default>.

=item $useExtProductCode

This boolean determines if the C<$extProductCode> is evalE<8217>ed. See L</register-initMachine-default>.

=item $extProductCode

Perl code that is evalE<8217>ed inside of each call to C<itemProcess()>. Returning false aborts this itemProcess. This code is the product plugin hook. See L</register-initMachine-default>.

=item $printer

The primary L<GenericPrinter> derived printer device. See L</register-initMachine-default>.

=item $printer2

The secondary L<GenericPrinter> derived printer device.  See L</register-initMachine-default>.

=item $pole

The L<GenericPrinter> derived customer pole display device. See L</register-initMachine-default>.

=item $drawer

The L<GenericPrinter> derived cash drawer device. See L</register-initMachine-default>.

=back

=head2 Subroutines

=over

=item evalThis(x)

L<eval|perlfunc/eval>s its one string arguement I<x> in the package C<main::>.

=item initIdleTasks

Initialize the L</@idleTasks> array

=item idleUpdate

Called periodically to update various elements when the system is idle, for example, redrawing the screen.

=item copyright

Prints the LE<8217>E<acirc>ne copyright and (basic) licensing information.

=item writeStatusBar

Writes the status bar information (clerk name, current date and time)

=item writeSummaryArea

Writes the summary area information (amount due, subtotal, taxes, total, terms, due dates, customer info).

=item clearSummary

Clears the summary area.

=item clearEntry

Clears the input entry field.

=item infoPrint(x)

Prints the message I<x> in the info area.

=item receiptPrint(x)

Prints the information I<x> in the on-screen receipt

=item getResponses(@q)

For each string in I<@q>, displays the message and collects the clerks response. After all responses have been stored, this routine returns them all in an array.

=item mainInputLoop

Starts the interface by activating its primary input loop

=item byeBye

Cleans up the display system and exits

=item beep

Sounds the systemE<8217>s beep (it may actually flash the screen in some interfaces).

=item mapKey(k, f)

B<OPTIONAL> Maps keycode I<k> to function I<f>. See L</register-keymap>.

=item clearReceipt

Clears the on-screen receipt.

=back

=head1 PROPERTIES

=over

=item version

The build version of the Register class.

=item hostname

The system's hostname, as provided by L<Sys::Hostname::hostname>.

=item lastSaleId

If true, the C<Sale.id> of the last sale.

=item ratranz

True if the register is currently processing a Received-on-Account transaction.

=back

=head1 SUBROUTINES

Only methods with external use are documented here.

=over

=item new

Creates a new Register object.

=item initPostDisplay

Further initialization to the hardware, post-display startup.

=item reprintProcess

Reprints the receipt.

=back

=head1 EVENTS

B<Register> generates events when various events occur. By default, the B<Register> loads code to emulate is past behavior into the applicable events. Events handlers are added with L</registerEvent> and L</preregisterEvent>. L</triggerEvent> makes the actual event handler calls. To stop subsequent event handlers from firing, L<die|perlfunc/die>. See L<LanePOS::GenericEventable>.

=head2 Names

=over

=item Lane/CORE/ClockTickMinute

This core event occurs once a minute (approximately).

=item Lane/CORE/Die

Destroying the object

=item Lane/CORE/Initialize

Initializing the object. See L</new>.

=item Lane/CORE/Initialize/User Interface

Initializing the interface.

=item Lane/CORE/Initialize/Machine

Initializing the Hardware/Peripherals/Machine.

=item Lane/Register/Clerk/Signin

A new clerk is signing into the register.

=item Lane/Register/Clerk/Signout

The current clerk is signing out of the register.

=item Lane/Register/Customer

Opening and processing a customer.

=item Lane/Register/Customer/Receive on Account

Receiving an amount to the customerE<8217>s account.

=item Lane/Register/Discount

Processing a discount.

=item Lane/Register/Printer/Print/Footer

Print the receipt footer.

=item Lane/Register/Printer/Print/Header

Print the receipt header.

=item Lane/Register/Printer/Print/Summary

Print the receipt summary.

=item Lane/Register/Printer/Reprint

Reprinting the paper receipt.

=item Lane/Register/Product

Processing a product.

=item Lane/Register/Product/Check Price

Checking the price of a product.

=item Lane/Register/Sale/Cancel

Canceling the entire sale.

=item Lane/Register/Sale/Error Correct

Error correcting the previous item.

=item Lane/Register/Sale/New

Creating a new sale.

=item Lane/Register/Sale/Resume

Resuming a sale.

=item Lane/Register/Sale/Subtotal

Calculating and displaying the subtotal.

=item Lane/Register/Sale/Suspend

Suspending the current sale.

=item Lane/Register/Sale/Void by ID

Void a previous sale, selected by that sale's id.

=item Lane/Register/Tax/Calculate

Calculate the given tax. This event replaces the previous C<taxCode> system.

=item Lane/Register/Tax/Exempt

Exempting this sale from the given tax.

=item Lane/Register/Tax/Enable

Enabling this sale for the given tax.

=item Lane/Register/UserInterface/Lock

In systems with a modeless interface, entering a modal-period. (This event is triggered by the user-interface code.)

=item Lane/Register/UserInterface/Unlock

In systems with a modeless interface, exiting a modal-period. (This event is triggered by the user-interface code.)

=item Lane/Register/Tender

Processing a tender.

=back

=head1 PARAMETERS

Like most portions of LE<8217>E<acirc>ne, B<Register> uses C<Strings> and C<SysStrings> to store configurable parameters.

=head2 Strings

=over

=item custdisp-idle

The text to print on the pole display when the register is idle.

=item receipt-header

The header to print on the standard receipt.

=item receiptN-header

The header to print on the second receipt. This header is used when the C<SysString> C<register-printSecond-N> is specified and the sale contains some amount tendered with tender I<N>.

=item receipt-footer

The footer to print on the standard receipt.

=item receiptN-footer

The footer to print on the second receipt. This footer is used when the C<SysString> C<register-printSecond-N> is specified and the sale contains some amount tendered with tender I<N>.

=item register-touch-menuesetup

On interfaces supporting the notebook menu, this sysstring defines the pages and their buttons for the pages after I<Functions>.

=back

=head2 SysStrings

=over

=item register-clerkLoginEachSale

Set to C<0> to keep the clerk logged in after each sale. The default C<1> requires the clerk to log in at the begining of each sale.

=item register-clearReceipt

Set to C<0> to keep the data in the on screen receipt always. Set to C<-1> to keep the data until the first item of the next sale is entered. The default C<1> clears this data at the end of the sale.

=item register-initMachine-default

Perl code to initialize the various devices and plugins. It is evaluated by the B<font-end> (aka the C<main::> package), not the C<Register> class. Thus, the C<Register> object is C<$main::reg> or C<$reg>, but not C<$me>. At a minimum, this sysstring must define C<$printer>, C<$printer2>, C<$pole>, and C<$drawer> which should be L<GenericPrinter> (or one of its subclasses). All of those objects can be set to the same object.

=item register-keymap

The keyboard mapping code, in the form C<KeyName=function>. For the Tk interfaces, the C<xev> program will print the X11 keynames. See L</%slashFuncts>.

=item register-eauth-N

Perl code to determine if the tender I<N> can be used. This code is often used for electronic authorization (for example credit card authorization). If this code returns C<false>, the tender is not allowed.

=item register-eprocess-N

Perl code to actually process a payment of tender I<N>. This code is only run after the entire sale has been tendered.

=item register-ecancel-N

Perl code to cancel the authorization.

=item earlypay-disc-id

The discount id of the discount in which E<8220>early payE<8221> discounts are recorded.

=item earlypay-disc-tender

The tender id of the tender in which E<8220>early payE<8221> discounts are recorded (for post-sale discounts only).

=item register-printSecond-N

Tender I<N> causes a second receipt to be printed.

=item Lane/Register/UserInterface/HidePointer

Set to C<0> if the front-end should try to display the (mouse) pointer. The default, C<1>, hides the pointer.

=item Lane/Register/Clerk/Auto Logout Timeout

Set to the number of idle minutes the system should wait before automatically logging out the clerk. The default, C<0>, disables the auto-logout.

=item register-touch-functionpagesetup

On interfaces supporting the notebook menu, this sysstring defines the buttons for the I<Functions> page.

=back

=head1 AUTHOR

Jason Burrell

=head1 BUGS

=over

=item *

There are no known bugs in this object.

=back

=head1 SEE ALSO

The LE<8217>E<acirc>ne Website L<http://l-ane.net/>

L<LanePOS::GenericEventable>

=cut

package LanePOS::Register;

require 5.008;

$Register::VERSION = (q$Revision: 1207 $ =~ /(\d+)/)[0];

use base 'LanePOS::GenericEventable', 'LanePOS::ProtoObject';

use LanePOS::Dal;
use LanePOS::Customer;
use LanePOS::Clerk;
use LanePOS::Sale;
use LanePOS::Product;
use LanePOS::Tender;
use LanePOS::Discount;
use LanePOS::String;
use LanePOS::SysString;
use LanePOS::Tax;
use LanePOS::Term;
use LanePOS::Locale;

#for exit
use POSIX;

#for the moved-to-here devices
use IO::File;
use LanePOS::Devices::Ryotous::MarkupPass;
use LanePOS::Devices::BurrellBizSys::TextInserterPole;

sub new
{
    my ($class, $dal) = @_;

    $dal = Dal->new if ! UNIVERSAL::isa($dal, 'LanePOS::Dal');

    my $me = {
	'version' => $Register::VERSION,

	#all of the db-configurable options are stored here
	'config' => undef,

	'loginEachSale' => 1,
	'clearReceipt' => 1,
	#'hostname' => undef, #replaced with a more standard form
	'hostname' => 'localhost',
	'lastSaleId' => '',

	#these are all the things that were "loose"
	#lane objects
	'dal' => $dal,
	'cust' => Customer->new($dal),
	'clerk' => Clerk->new($dal),
	'sale' => Sale->new($dal),
	'prod' => Product->new($dal),
	'tend' => Tender->new($dal),
	'disc' => Discount->new($dal),
	'string' => String->new($dal),
	'sysStr' => SysString->new($dal),
	'tax' => Tax->new($dal),
	'term' => Term->new($dal),
	'lc' => Locale->new($dal),
	#globalReset
	'globalReset' => 0,		# used by subs to reset their private vars
	'ratranz' => 0,
	'headerPrinted' => 0,
	#globals
	#for signal handling
	'signals' => {'names' => [], 'dieWhenConvient' => 0},

	'ui' => {
	    'slashFuncts' => undef,
	},
	'dev' => {
	    'printer' => MarkupPass->new(IO::File->new('/dev/null', 'w')),
	    'printer2' => MarkupPass->new(IO::File->new('/dev/null', 'w')),
	    'pole' => TextInserterPole->new(IO::File->new('/dev/null', 'w')),
	    'drawer' => MarkupPass->new(IO::File->new('/dev/null', 'w')),
	},
    };

    #reset some basic items so perl doesn't complain about "Name xyz used only once: possible typo"

    #configuration options
    my %config = $me->{'sysStr'}->getTree('Lane/Register');
    $me->{'config'} = \%config;

    bless $me, $class;		# bless is here so we can call other obj methods
    #initialization stuff
    #signal handling stuff
    push @{$me->{'signals'}{'names'}}, qw/TERM INT QUIT ILL ABRT FPE SEGV PIPE USR1 USR2/; #these are the POSIX sigs
    #ALRM was moved for the event code (see below)
    push @{$me->{'signals'}{'names'}}, qw/BUS POLL PROF SYS TRAP VTALRM XCPU XFSZ/; #sysV
    push @{$me->{'signals'}{'names'}}, qw/IOT STKFLT IO PWR UNUSED/; #misc
    push @{$me->{'signals'}{'names'}}, qw/LOST/ if !exists (({'linux' => 1})->{$^O}); #perl says these aren't defined, but the eval{} below should handle it

    local *handler;
    #try queuing the signals for later processing
    #updated: we're only concerned about aboring signals,
    #so we only need a single value
    *handler = sub {
	warn "Register: we're blocking the signal handler\n" if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /signals/;
	$me->{'signals'}{'dieWhenConvient'} = 1;
    };
    eval {$SIG{$_} = *handler} foreach (@{$me->{'signals'}{'names'}});

    #the following line replaces the `hostname` stuff from the initMachine sysString with a platform independent Perl-method
    eval
    {
	use Sys::Hostname ();
	$me->{'hostname'} = Sys::Hostname::hostname();
    };

    if($me->{'sysStr'}->open('register-clerkLoginEachSale') and !$me->{'sysStr'}->isVoid)
    {
	$me->{'loginEachSale'} = $me->{'sysStr'}{'data'};
    }

    if($me->{'sysStr'}->open('register-clearReceipt') and !$me->{'sysStr'}->isVoid)
    {
	$me->{'clearReceipt'} = $me->{'sysStr'}{'data'};
    }
    
    $me->{'slashFuncts'} = {
	'copyright' => sub {},
	'license' => sub {},
	#'shutDown' => ,
	'subt' => sub { $me->subtProcess(@_); },
	'cust' => sub { $me->custProcess(@_); },
	'cancel' => sub { $me->cancelProcess(@_); },
	'errCorrect' => sub { $me->errCorrectProcess(@_); },
	'exempt' => sub { $me->exemptProcess(@_); },
	'taxable' => sub { $me->exemptReverse(@_); },
	'ra' => sub { $me->raProcess(@_); },
	#'endorse' => (@_); },
	#'reprint' => (@_); },
	#'clockIn' => (@_); },
	'tender' => sub { $me->tenderProcess(@_); },
	'disc' => sub { $me->discProcess(@_); },
	'priceCheck' => sub { $me->priceCheckProcess(@_); },
	'suspend' => sub { $me->suspendProcess(@_); },
	'resume' => sub { $me->resumeProcess(@_); },
	'voidById' => sub
	{
	    my ($cmdNum, $str) = @_;
	    return $me->triggerEvent('Lane/Register/Sale/Void by ID', $str);
	},
	
    };

    #ok, start the event system now
    $me->initEvents;
    $me->triggerEvent('Lane/CORE/Initialize/Machine');
    return $me;
}

###################################################
# Subroutines
###################################################
sub initEvents
{
    my ($me) = @_;

    my $r = $me->SUPER::initEvents;

    #register the CORE events
    $me->registerEvent('Lane/CORE/ClockTickMinute', sub {$me->triggerEvent('Lane/Register/UserInterface/Update Status Bar')});
    #now trigger it when...
    $SIG{'ALRM'} = sub { $me->triggerEvent('Lane/CORE/ClockTickMinute'); alarm 60; };
    alarm 60;

    #other basic events
    #REMEMBER TO DROP THE "my ($me)" BIT AS THAT IS HANDLED BY THE EVENT SYSTEM!
    $me->registerEvent('Lane/Register/Sale/Void by ID',
                       sub
                       {
                           my ($id) = @_;
                           my $cust = Customer->new($me->{'dal'});
                           my $sale = Sale->new($me->{'dal'});
                           if(!$sale->open($id))
                           {
                               $me->triggerEvent('Lane/Register/UserInterface/Print Info', $me->lc->get("There is no ticket %0.", $id));
                               die 'No such ticket';
                           }
                           if($sale->isVoid)
                           {
                               $me->triggerEvent('Lane/Register/UserInterface/Print Info', $me->lc->get("The sale %0 is void.", $amt));
                               die 'Already void';
                           }
                           if(!$cust->open($sale->{'customer'}) or $cust->isVoid)
			   {
			       $sale->{'customer'} = '';
			       $cust->open(''); #an error here is non-fatal
			   }
                           if(($me->triggerEvent('Lane/Register/UserInterface/Get Responses', 'show', $me->lc->get('Lane/Register/Sale/Void by ID/Confirmation', $id, $cust->getName, $me->lc->moneyFmt($sale->{'total'}))))[0] eq 'y')
                           {
                               if(!eval{$sale->void})
                               {
                                   warn "Lane/Register/Sale/Void by ID: an error occurred: $sale->{'dal'}->{'dbError'}\n";
                                   $me->triggerEvent('Lane/Register/UserInterface/Print Info', $sale->{'dal'}->{'dbError'});
                                   die 'disallowed';
                               }
                               #put some info on the screen/printer here
                               $me->triggerEvent('Lane/Register/UserInterface/Print Info', $me->lc->get('Lane/Register/Sale/Void by ID/Success', $id));
                           }
                       }
        );
    $me->registerEvent('Lane/Register/Clerk/Signout',
                       sub
                       {
                           $me->{'dal'}->clearNonPersonUsername();
                       }
        );
    $me->registerEvent('Lane/Register/Clerk/Signin',
                       sub
                       {
                           #this was clerkSignin()
                           # clerk sign-in, gets clerk id and passcode
                           # blocks until authorized
                           my $notAuth = 1;
                           my $shown = 0;
                           die 'couldn\'t signout' if !$me->triggerEvent('Lane/Register/Clerk/Signout');
                           $me->{'clerk'} = Clerk->new($me->{'dal'});
                           $me->triggerEvent('Lane/Register/UserInterface/Update Status Bar');
                           while($notAuth)
                           {
                               my $id = "";
                               my $code = "";
                               unless($shown)
                               {
                                   if($me->{'string'}->open('custdisp-idle') and !$me->{'string'}->isVoid)
                                   {
                                       $me->{'dev'}->{'pole'}->printPole($me->{'string'}->{'data'});
                                       $shown = 1;
                                   }
                               }
                               ($id) = $me->triggerEvent('Lane/Register/UserInterface/Get Responses', 'show', $me->lc->get('Enter your clerk ID'));
                               ($code) = $me->triggerEvent('Lane/Register/UserInterface/Get Responses', 'hide', $me->lc->get('Enter your clerk Passcode'));
                               $me->triggerEvent('Lane/Register/UserInterface/Print Info', '');
                               if($me->{'clerk'}->open($id) and !$me->{'clerk'}->isVoid)
                               {
                                   if($me->{'clerk'}->authenticate($code))
                                   {
                                       $notAuth = 0;
                                   }
                                   else
                                   {
                                       #clear the thing if not found
                                       $me->{'clerk'} = Clerk->new($me->{'dal'});
                                   }
                               }
                           }
                           $me->triggerEvent('Lane/Register/UserInterface/Update Status Bar');
                           $me->{'sale'}->{'clerk'} = $me->{'clerk'}->{'id'};
                           $me->{'dev'}->{'pole'}->printPole("");
                           $me->{'dal'}->setNonPersonUsername($me->{'clerk'}->{'id'});
                           return 1;
                       }
        );
    $me->registerEvent('Lane/Register/Sale/Cancel',
                       sub
                       {
                           #back everything out
                           #reverse all of the item sales :)
                           my $i;
                           my $t;
                           foreach $i (@{$me->{'sale'}->{'items'}})
                           {
                               #if it is a discount, ignore it
                               next if substr($i->{'plu'}, 0, 1) eq ':';
                               #if it is a ra, ignore it
                               next if $i->{'plu'} eq 'RA-TRANZ';
                               #if it's already struck, ignore it
                               next if $i->{'struck'};
                               $t = Product->new($me->{'dal'});
                               if($t->open($i->{'plu'}) and !$t->isVoid)
                               {
                                   $t->receiveUnits($i->{'qty'});
                               }
                           }
                           #cancel the eauth'ed/eprocessed tenders
                           my $tend = Tender->new($me->{'dal'});
                           foreach $i (@{$me->{'sale'}->{'tenders'}})
                           {
                               next if !$tend->open($i->{'tender'}) or !$tend->isVoid;
                               next if !$tend->eprocess;
                               #we should return the value of the eval to tell if the trans went
                               my %ext = %{$i->{'ext'}}; #so it's like tenderProcess()
                               eval $me->tenderCode('cancel', $tend, $i->{'amt'});
                               $i->{'ext'} = \%ext;
                               #process is now only handled when the sale is completed
                           }
                           
                           $me->{'sale'}->save;
                           $me->{'sale'}->void;
                           
                           $me->{'dev'}->{'printer'}->printFormatted("<b>" . $me->lc->get("CANCELED") . "</B>\n") if !$me->{'signals'}{'dieWhenConvient'};
                           $me->triggerEvent('Lane/Register/UserInterface/Print Receipt', $me->lc->get("CANCELED")) if !$me->{'signals'}{'dieWhenConvient'};
                           $me->{'dev'}->{'pole'}->printPole($me->lc->get("CANCELED")) if !$me->{'signals'}{'dieWhenConvient'};
                           $me->printFooter('') if !$me->{'signals'}{'dieWhenConvient'};
                           #don't start a new transaction if we are dying
                           $me->newTranz() if !$me->{'signals'}{'dieWhenConvient'};
                       }
        );
    $me->registerEvent('Lane/Register/Sale/Error Correct',
                       sub
                       {                           
                           #remove the specified or last item
                           #at the moment, this doesn't "undo" the last thing (it only works for things in $me->{'sale'}->{'items'}
                           my ($lineNo) = @_;

                           my $t;
                           my $objtmp;

                           if(ref($lineNo) eq 'HASH')
                           {
                               #they specified the line directly
                               $t = $lineNo if exists $lineNo->{'plu'} and defined $lineNo->{'plu'} and exists $lineNo->{'amt'} and $lineNo->{'amt'};
                           }
                           elsif(!defined $lineNo or $lineNo eq '')
                           {
                               $t = $me->{'sale'}->lastUnstruckItem;
                           }
                           else
                           {
                               $t = $me->{'sale'}{'items'}[$lineNo] if $lineNo =~ /^-?\d+$/ and $lineNo >= 0 and $lineNo <= $#{$me->{'sale'}{'items'}};
                           }
                           die 'the specified item is already struck' if $t->{'struck'};
                           #make sure there's something in ->{'items'}
                           die 'no items left' if !defined $t;

                           my $amtStr = $me->lc->moneyFmt($t->{'amt'});
                           #determine if it is an item or a disc
                           if(substr($t->{'plu'}, 0, 1) eq ':')		# it's a discount
                           {
                               $objtmp = Discount->new($me->{'dal'});
                               die 'can\'t open or use the discount' if !$objtmp->open(substr($t->{'plu'}, 1)) and $objtmp->isVoid;
                               #we have to work backward from the discount to "undo" it
                               $me->{'sale'}->{'subt'} += $t->{'amt'};
                               $me->{'sale'}->updateTotals;
                               $me->triggerEvent('Lane/Register/UserInterface/Update Summary Area');
                               $me->triggerEvent('Lane/Register/UserInterface/Print Receipt', sprintf("%-40.40s", $me->lc->get('CANCELED')) . $me->reduceNl($me->lc->get('Lane/Printer/Format/Discount', 'amt' => $amtStr, 'descr' => $objtmp->{'descr'})));
                               $me->{'dev'}->{'pole'}->printPole(sprintf("%-20.20s%20.20s", $objtmp->{'descr'}, $amtStr));
                               $me->{'dev'}->{'printer'}->printDiscount($objtmp->{'descr'}, $amtStr);
                           }
                           elsif($t->{'plu'} eq 'RA-TRANZ') # it's a ra
                           {
                               $me->{'sale'}->{'subt'} -= $t->{'amt'};
                               $me->{'sale'}->updateTotals;
                               $me->triggerEvent('Lane/Register/UserInterface/Update Summary Area');
                               $me->triggerEvent('Lane/Register/UserInterface/Print Receipt', ' ' x 20 . $me->lc->get('Lane/Printer/Format/Tender', 'descr' => $me->lc->get('Cancel R/A'), 'amt' => $amtStr));
                               $me->{'dev'}->{'pole'}->printPole(sprintf("%-20.20s%20.20s", $me->lc->get("Cancel R/A"), $amtStr));
                               $me->{'dev'}->{'printer'}->printFormatted('<b>' . $me->lc->get('Lane/Printer/Format/Tender', 'descr' => $me->lc->get('Cancel R/A'), 'amt' => $amtStr) . '</b>');
                           }
                           else			# it's an item
                           {
                               #now, run the thing back through itemProcess() so the itemCode is eval'ed from the db
                               $me->itemProcess(-$t->{'qty'}, $me->lc->roundingDiv($t->{'amt'}, $t->{'qty'},0), $t->{'plu'});
                               pop @{$me->{'sale'}{'items'}};
                           }
                           $t->{'struck'} = 1;
                       }
        );
    $me->registerEvent('Lane/Register/Product/Check Price',
                       sub
                       {
                           my $id = "";
                           $me->triggerEvent('Lane/Register/UserInterface/Print Info', $me->lc->get('Enter or scan the item to check'));
                           $me->triggerEvent('Lane/Register/UserInterface/Clear Entry');
                           ($id) = $me->triggerEvent('Lane/Register/UserInterface/Get Responses', 'show', '');
                           
                           if($me->{'prod'}->open($id) and !$me->{'prod'}->isVoid)
                           {
                               $me->triggerEvent('Lane/Register/UserInterface/Print Info', $me->lc->get("Price Check") . ":\n    " . $me->{'prod'}->{'descr'} .  " " . $me->lc->moneyFmt($me->{'prod'}->{'price'} * 10 ** $me->lc->get('Lane/Locale/Money/DecimalDigits')));
                               $me->{'dev'}->{'pole'}->printPole(sprintf("%-20.20s%20.20s", $me->{'prod'}->{'descr'}, $me->lc->moneyFmt($me->{'prod'}->{'price'} * 10 ** $me->lc->get('Lane/Locale/Money/DecimalDigits'))));
                           }
                           else
                           {
                               $me->triggerEvent('Lane/Register/UserInterface/Print Info', $me->lc->get('Unknown Product', $id));
                           }
                           
                       }
        );
    $me->registerEvent('Lane/Register/Discount',
                       sub
                       {
                           my ($id, $amt) = @_;	# see tenderProcess()
                           # $amt gets reused as soon as one purpose is done, so BE CAREFUL!

                           my %disc;
                           my $amtStr;
                           
                           if($me->{'ratranz'})
                           {
                               # can't process discounts in a ra transaction
                               $me->triggerEvent('Lane/Register/UserInterface/Print Info', $me->lc->get('Lane/Register/Discount/RA Transaction'));
                               die 'can\'t discount in a R/A tranz';
                           }
                           
                           if(!$me->{'disc'}->open($id) or $me->{'disc'}->isVoid)
                           {
                               $me->triggerEvent('Lane/Register/UserInterface/Beep');
                               die 'can\'t open or use the discount';
                           }

                           #print the header, if this is the first "item"
                           $me->printHeader('') if $#{$me->{'sale'}->{'items'}} == -1;
                           
                           $disc{'plu'} = ":$id";	# NOTE: THE COLON REPRESENTS A DISCOUNT!!!!
                           $disc{'qty'} = 1;		# only one disc at a time
                           $disc{'struck'} = 0;
                           if($me->{'disc'}->isPresetDisc)	# it's preset, ignore the clerk entered amt
                           {
                               $amt = $me->{'disc'}->{'amt'} * 10 ** $me->lc->get('Lane/Locale/Money/DecimalDigits');	# this may still be a percent
                               $amt /= 10 ** $me->lc->get('Lane/Locale/Money/DecimalDigits') if $me->{'disc'}->isPercentDisc;
                           }
                           if($me->{'disc'}->isSaleDisc)	# apply the disc to the sale
                           {
                               #how should all of this interact with taxes?
                               $amt = $me->{'disc'}->giveDisc($amt, $me->{'sale'}->{'total'});
                               $amtStr = $me->lc->moneyFmt(-$amt);
                               $me->{'sale'}->{'subt'} -= $amt;
                               $me->{'sale'}->updateTotals;
                           }
                           else			# apply the disc to the previous item
                           {
                               #this only works if the previous item was an item (ie not a disc)
                               $amt = $me->{'disc'}->giveDisc($amt, $me->{'sale'}->{'items'}[-1]{'amt'});
                               $amtStr = $me->lc->moneyFmt(-$amt);
                               #fix the taxes. take the tax only on the post-discounted amt if it is a percent discount
                               my $prev = $me->{'sale'}->lastUnstruckItem;
                               die 'can\'t open or use the previous item' if !$prev or !$me->{'prod'}->open($prev) or $me->{'prod'}->isVoid;
                               if($me->{'disc'}->isPercentDisc)
                               {
                                   my $t = 1;
                                   my $tx = Tax->new($me->{'dal'});
                                   for(my $i = 0; 2 ** $i <= $me->{'prod'}->{'taxes'}; $i++, $t <<= 1)
                                   {
                                       next unless $t & $me->{'prod'}->{'taxes'};
                                       $tx->open($i + 1);
                                       next if $tx->isVoid;
                                       #remove taxes from taxable
                                       eval $main::taxCode if $main::useTaxCode;
                                       $me->{'sale'}->{'taxes'}[$i]{'taxable'} -= $amt; #remove the difference
                                       $me->{'sale'}->{'taxes'}[$i]{'tax'} = $tx->applyTaxManually($me->{'sale'}->{'taxes'}[$i]{'taxable'}, $me->{'sale'}->{'taxes'}[$i]{'rate'});
                                   }
                               }
                               $me->{'sale'}->{'subt'} -= $amt;
                               $me->{'sale'}->updateTotals;
                           }
                           $disc{'amt'} = $amt;
                           #now, print the stuff on the terminal and the printer
                           $me->triggerEvent('Lane/Register/UserInterface/Print Receipt', $me->reduceNl($me->lc->get('Lane/Printer/Format/Discount', 'amt' => $amtStr, 'descr' => $me->{'disc'}->{'descr'})));
                           $me->{'dev'}->{'pole'}->printPole(sprintf("%-20.20s%20.20s", $me->{'disc'}->{'descr'}, $amtStr));
                           
                           #this print item needs changed to reflect disc instead of item
                           $me->{'dev'}->{'printer'}->printDiscount($me->{'disc'}->{'descr'}, $amtStr);
                           
                           push @{$me->{'sale'}->{'items'}}, \%disc;
                           
                           $me->triggerEvent('Lane/Register/UserInterface/Update Summary Area');
		       }
        );
    $me->registerEvent('Lane/Register/Sale/New',
                       sub
                       {
                           #this was newTranz()
                           # starts a new transaction
                           my ($info) = @_;
                           
                           #$info allows us to pass a flag 'first' that will force a clerkSignin even if loginEachSale is set to off
                           
                           $me->triggerEvent('Lane/Register/UserInterface/Clear Summary Area');
                           
                           #reset the plugin-globals
                           if($main::useResetCode)
                           {
                               eval $main::resetCode;
                               warn "newTranz(): the resetCode eval'ed to $@\n" if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Register/;
                           }
                           
                           $me->{'lastSaleId'} = $me->{'sale'}{'id'};
                           $me->{'sale'} = Sale->new($me->{'dal'});
                           $me->custProcess('',''); #clear the customer specific stuff
                           
                           $me->{'globalReset'} = 1;		# mainInputLoop recognizes this and resets its private vars
                           $me->{'ratranz'} = 0;
                           $me->{'headerPrinted'} = 0;
                           $me->clerkSignin if ($me->{'loginEachSale'} or $info =~ /first/i);
                           $me->{'sale'}->{'clerk'} = $me->{'clerk'}->{'id'};
                           $me->{'sale'}->{'terminal'} = $ENV{'LaneTerminal'} ? $me->{'hostname'} . "/$ENV{'LaneTerminal'}" : $me->{'hostname'};
                           
                           #clear the on screen receipt
                           if($me->{'clearReceipt'})
                           {
                               $me->triggerEvent('Lane/Register/UserInterface/Clear Receipt');
                           }
                           else
                           {
                               $me->triggerEvent('Lane/Register/UserInterface/Print Receipt', "\n" . ("=" x 40) . "\n");
                           }
#    $me->triggerEvent('Lane/Register/UserInterface/Print Info', 'Enter a product ID, or press a function key');
                           $me->triggerEvent('Lane/Register/UserInterface/Print Info', $me->lc->get('Enter a product ID, or press a function key'));
                           return 1;
                       }
        );
    $me->registerEvent('Lane/Register/Sale/Resume',
                       sub
                       {
                           #we only use $me, $amt (that's the # the clerk entered right before pressing the button)
                           my ($qty, $amt, $id) = @_;
                           
                           #make sure we aren't in the middle of anything
                           warn "resumeProcess(): items = ", $#{$me->{'sale'}->{'items'}}, "\n" if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Register/;
                           if($#{$me->{'sale'}->{'items'}} != -1)
                           {
                               $me->triggerEvent('Lane/Register/UserInterface/Print Info', $me->lc->get("A suspended sale can not be resumed inside another transaction."));
                               die 'A suspended sale can not be resumed inside another transaction.';
                           }
                           
                           #open the sale, check to make sure it was suspended
                           ($amt) = $me->{'sale'}->getSuspended() if !$amt; #if unspecified, resume the oldest
                           if($amt eq '')
                           {
                               $me->triggerEvent('Lane/Register/UserInterface/Print Info', $me->lc->get("There are no suspended tickets."));
                               die 'There are no suspended tickets.';	
                           }
                           if(!$me->{'sale'}->open($amt))
                           {
                               $me->triggerEvent('Lane/Register/UserInterface/Print Info', $me->lc->get("There is no ticket %0.", $amt));
                               die 'The ticket number specified doesn\'t exist.';
                           }
                           if($me->{'sale'}->isVoid)
                           {
                               $me->triggerEvent('Lane/Register/UserInterface/Print Info', $me->lc->get("The sale %0 is void.", $amt));
                               die 'The sale specified is void.';
                           }
                           if(!$me->{'sale'}->isSuspended)
                           {
                               $me->triggerEvent('Lane/Register/UserInterface/Print Info', $me->lc->get("The ticket %0 was not suspended (it is finalized).", $amt));
                               $me->{'sale'} = Sale->new($me->{'dal'});
                               #we don't need to call newTranz() because this is the first item
                               die 'The specified sale is finalized.';
                           }
                           #change the clerk to the current clerk
                           $me->{'sale'}{'clerk'} = $me->{'clerk'}{'id'};
                           $me->{'sale'}->{'terminal'} = $ENV{'LaneTerminal'} ? $me->{'hostname'} . "/$ENV{'LaneTerminal'}" : $me->{'hostname'};
                           
                           $me->{'sale'}->updateTotals;
                           
                           $me->triggerEvent('Lane/Register/UserInterface/Clear Receipt');
                           $me->triggerEvent('Lane/Register/UserInterface/Print Receipt', " * " . $me->lc->get("RESUMED") . " * \n");
                           $me->custProcess('', $me->{'sale'}->{'customer'});
                           
                           #print the sale again
                           $me->printHeader('');
                           #print the items
                           foreach $i (@{$me->{'sale'}->{'items'}})
                           {
                               next if $i->{'struck'};
                               #determine item type, and print it
                               if($i->{'plu'} eq 'RA-TRANZ') # ra
                               {
                                   $me->{'dev'}->{'printer'}->printFormatted('<b>' . $me->lc->get('Lane/Printer/Format/Tender', 'descr' => $me->lc->get('Lane/Register/RA'), 'amt' => $me->lc->moneyFmt($i->{'amt'})) . '</b>');
                                   $me->triggerEvent('Lane/Register/UserInterface/Print Receipt', ' ' x 20 . $me->reduceNl($me->lc->get('Lane/Printer/Format/Tender', 'descr' => $me->lc->get('Lane/Register/RA'), 'amt' => $me->lc->moneyFmt($i->{'amt'}))));
                               }
                               elsif($i->{'plu'} =~ /^:/) # discount
                               {
                                   $obj = Discount->new($me->{'dal'});
                                   next if !$obj->open(substr($i->{'plu'}, 1)) or $obj->isVoid;
                                   my $amtStr = $me->lc->moneyFmt(-$i->{'amt'});
                                   $me->{'dev'}->{'printer'}->printDiscount($obj->{'descr'}, $amtStr);
                                   $me->triggerEvent('Lane/Register/UserInterface/Print Receipt', $me->reduceNl($me->lc->get('Lane/Printer/Format/Discount', 'amt' => $amtStr, 'descr' => $obj->{'descr'}, 'id' => $me->{'disc'}->{'id'})));
                               }
                               else			# item
                               {
                                   $obj = Product->new($me->{'dal'});
                                   next if !$obj->open($i->{'plu'}) or $obj->isVoid;
                                   $me->{'dev'}->{'printer'}->printItem($i->{'plu'}, $obj->{'descr'}, $i->{'qty'}, $i->{'amt'});
                                   $me->triggerEvent('Lane/Register/UserInterface/Print Receipt', $me->reduceNl($me->get('Lane/Printer/Format/Item', 'descr' => $obj->{'descr'}, 'amt' => $me->lc->moneyFmt($i->{'amt'}), 'plu' => $i->{'plu'}, 'qty' => $i->{'qty'})));
                               }
                           }
                           #print the tenders too
                           my $tmp;
                           foreach my $t (@{$me->{'sale'}->{'tenders'}})
                           {
                               $tmp = $me->lc->moneyFmt($t->{'amt'});
                               next if !$me->{'tend'}->open($t->{'tender'}) or $me->{'tend'}->isVoid;
                               $me->triggerEvent('Lane/Register/UserInterface/Print Receipt', ' ' x 20 . $me->reduceNl($me->lc->get('Lane/Printer/Format/Tender', 'amt' => $tmp, 'descr' => $me->{'tend'}->{'descr'})));
                           }
                           
                           $me->{'sale'}->{'suspended'} = 0;
                           return 1;
                       }
        );
    $me->registerEvent('Lane/Register/Sale/Suspend',
                       sub
                       {
                           #suspend the current sale
                           
                           #we only use $me
                           my ($qty, $amt, $id) = @_;
                           
                           $me->{'sale'}->{'suspended'} = 1;
                           $me->{'sale'}->save;
                           #print the receipt w/suspend
                           $me->printSummary;
                           $me->{'dev'}->{'printer'}->printFormatted("<b>" . $me->lc->get("SUSPENDED") . "</b>\n") if !$me->{'signals'}{'dieWhenConvient'};
                           $me->triggerEvent('Lane/Register/UserInterface/Print Receipt', " * " . $me->lc->get("SUSPENDED") . " * \n") if !$me->{'signals'}{'dieWhenConvient'};
                           $me->triggerEvent('Lane/Register/UserInterface/Print Receipt', sprintf("\n%-40.40s", $me->lc->get("Ticket") . " " . $me->{'sale'}{'id'})) if !$me->{'signals'}{'dieWhenConvient'};
                           $me->printFooter('') if !$me->{'signals'}{'dieWhenConvient'};
                           $me->newTranz() if !$me->{'signals'}{'dieWhenConvient'};
                           return 1;
                       }
        );
    $me->registerEvent('Lane/Register/Tender',
                       sub
                       {
                           my ($tnd, $amt) = @_; # we don't want the plu-price style amt
                           
                           my $saleDue = 0;
                           
                           my %ext;
                           
                           if(!$me->{'tend'}->open($tnd) or $me->{'tend'}->isVoid)
                           {
                               $me->triggerEvent('Lane/Register/UserInterface/Beep');
                               die 'couldn\'t open or use the specified tender';
                           }
                           
                           #determine how much is due (the sale amt, or the early pay amt)
                           #have we ever used a non-paying tender? if so, we can't use the due w/disc
                           my $neverCharged = 1;
                           for(my $i = 0; $i <= $#{$me->{'sale'}->{'tenders'}}; $i++)
                           {
                               $neverCharged = 0 if !$me->{'sale'}{'tenders'}[$i]{'pays'};
                           }
                           
                           if($me->{'term'}->{'discDays'} > 0 and $me->{'tend'}->pays and $neverCharged and !$me->{'ratranz'})
                           {
                               $saleDue = $me->{'sale'}->{'due'} - $me->{'term'}->applyDisc($me->{'sale'}->{'total'});
                           }
                           else
                           {
                               #the discount doesn't/can't apply
                               $saleDue = $me->{'sale'}->{'due'};
                           }
                           
                           if($me->{'tend'}->mandatoryAmt and $amt eq '')
                           {				# requires amt (mand), but they didn't put one in
                               $me->triggerEvent('Lane/Register/UserInterface/Print Info', $me->lc->get("Amount required for %0 sales.", $me->{'tend'}->{'descr'}));
                               die 'amount required';
                           }
                           
                           if($amt eq '')
                           {
                               $amt = $saleDue; # the clerk doesn't need to enter an amount, if it isn't mandatory
                           }
                           
                           #make sure everything is going ok
                           if(!$me->{'tend'}->pays and $me->{'cust'}->{'id'} eq "")
                           {
                               $me->triggerEvent('Lane/Register/UserInterface/Print Info', $me->lc->get("A customer must be open for %0 sales.", $me->{'tend'}->{'descr'}));
                               die 'customer required';
                           }
                           
                           if(!$me->{'tend'}->pays and $me->{'term'}->{'dueDays'} == 0)
                           {
                               $me->triggerEvent('Lane/Register/UserInterface/Print Info', $me->lc->get("%0 customers must pay at the time of service.", $me->{'term'}->{'descr'}));
                               die 'this customer must pay at the time of service';
                           }
                           
                           if($me->{'ratranz'} and !$me->{'tend'}->pays)
                           {
                               $me->triggerEvent('Lane/Register/UserInterface/Print Info', $me->lc->get('Lane/Register/Tender/RA Requires Pays', $me->{'tend'}->{'descr'}));
                               $me->triggerEvent('Lane/Register/UserInterface/Beep');
                               die 'R/A cannot be tendered with another charging tender';
                           }
                           
                           #the tender amount sign options
                           if($amt == 0 and !$me->{'tend'}->allowZero)
                           {
                               $me->triggerEvent('Lane/Register/UserInterface/Print Info', $me->lc->get('Lane/Register/Tender/No Zero Amount', $me->{'tend'}->{'descr'}));
                               
                               $me->triggerEvent('Lane/Register/UserInterface/Beep');
                               die 'this tender does not allow zero amounts';
                           }
                           if($amt < 0 and !$me->{'tend'}->allowNeg)
                           {
                               $me->triggerEvent('Lane/Register/UserInterface/Print Info', $me->lc->get('Lane/Register/Tender/No Negative Amount', $me->{'tend'}->{'descr'}));
                               $me->triggerEvent('Lane/Register/UserInterface/Beep');
                               die 'this tender does not allow negative amounts';
                           }
                           if($amt > 0 and !$me->{'tend'}->allowPos)
                           {
                               $me->triggerEvent('Lane/Register/UserInterface/Print Info', $me->lc->get('Lane/Register/Tender/No Positive Amount', $me->{'tend'}->{'descr'}));
                               $me->triggerEvent('Lane/Register/UserInterface/Beep');
                               die 'this tender does not allow positive amounts';
                           }
                           #the salesItems checking option
                           if($me->{'tend'}{'requireItems'} eq 'r' and !$me->{'sale'}->lastUnstruckItem)
                           {
                               $me->triggerEvent('Lane/Register/UserInterface/Print Info', $me->lc->get('Lane/Register/Tender/Requires Items', $me->{'tend'}->{'descr'}));
                               #we require items, and they have none
                               $me->triggerEvent('Lane/Register/UserInterface/Beep');
                               die 'this tender requires items in the sale';
                           }
                           elsif($me->{'tend'}{'requireItems'} eq 'd' and $me->{'sale'}->lastUnstruckItem)
                           {
                               $me->triggerEvent('Lane/Register/UserInterface/Print Info', $me->lc->get('Lane/Register/Tender/Does Not Allow Items', $me->{'tend'}->{'descr'}));
                               #we don't allow items, and they have some
                               $me->triggerEvent('Lane/Register/UserInterface/Beep');
                               die 'this tender does not allow items in the sale';
                           }
                           #the else (eq 'a') is a pass through
                           
                           #check allowChange
                           if(! $me->{'tend'}->allowChange and $amt > $saleDue)
                           {
                               $me->triggerEvent('Lane/Register/UserInterface/Beep');
                               $me->triggerEvent('Lane/Register/UserInterface/Print Info', $me->lc->get('Lane/Register/Tender/No Allow Change', $me->{'tend'}->{'descr'}));
                               die 'this tender does not allow change';
                           }
                           
                           #process the eauth stuff, the code should return 1 (authorized) or 0 (not authorized)
                           #before returning 0, explain [$me->triggerEvent('Lane/Register/UserInterface/Print Info', )] to the clerk why the authorization failed,
                           #and what corrective steps can be taken.
                           #if this is going to take awhile, call &main::idleUpdate() periodically
                           if($me->{'tend'}->eauth)
                           {
                               #return 0 if !$me->tenderCode('pre', $me->{'tend'}, $amt);
                               #the tender code must run in this local context
                               die "eauth failed: $@\n" if !eval $me->tenderCode('pre', $me->{'tend'}, $amt);
                           }
                           
                           #we need this again because eauth can change the value of the saledue
                           if($me->{'term'}->{'discDays'} > 0 and $me->{'tend'}->pays and $neverCharged and !$me->{'ratranz'})
                           {
                               $saleDue = $me->{'sale'}->{'due'} - $me->{'term'}->applyDisc($me->{'sale'}->{'total'});
                           }
                           else
                           {
                               #the discount doesn't/can't apply
                               $saleDue = $me->{'sale'}->{'due'};
                           }
                           
                           if($amt < $saleDue)		# they're only paying part of it
                           {
                               $me->{'sale'}->{'due'} -= $amt;
                               
                               #print the info in the on-screen tape
                               my $tmp = $me->lc->moneyFmt($amt);
                               $me->triggerEvent('Lane/Register/UserInterface/Print Receipt', ' ' x 20 . $me->lc->get('Lane/Printer/Format/Tender', 'descr' => $me->{'tend'}->{'descr'}, 'amt' => $tmp));
                               $me->{'dev'}->{'pole'}->printPole(sprintf("%-20.20s%20.20s", $me->{'tend'}->{'descr'}, $tmp));
                               
                               push @{$me->{'sale'}->{'tenders'}}, {'tender' => $me->{'tend'}->{'id'}, 'amt' => $amt, 'pays' => $me->{'tend'}->pays, 'ext' => \%ext};
                               $me->{'cust'}->chargeToAcct($me->lc->extFmt($amt)) unless $me->{'tend'}->pays;
                               $me->applyToOldest(-$amt) if $amt < 0;
                               $me->triggerEvent('Lane/Register/UserInterface/Update Summary Area');
                               $me->{'dev'}->{'drawer'}->openDrawer($me->{'clerk'}{'drawer'}) if $me->{'tend'}->openDrawer;
                               return 1;
                           }
                           elsif($amt == $saleDue)
                           {
                               #this may be the discDue amt
                               $me->autoDiscount('show', $me->{'sale'}, $me->{'sale'}->{'due'} - $saleDue) if $saleDue < $me->{'sale'}->{'due'} and !$me->{'ratranz'};
                               
                               $me->printSummary;
                               
                               #print the info in the on-screen tape
                               my $tmp = $me->lc->moneyFmt($amt);
                               $me->triggerEvent('Lane/Register/UserInterface/Print Receipt', ' ' x 20 . $me->lc->get('Lane/Printer/Format/Tender', 'descr' => $me->{'tend'}->{'descr'}, 'amt' => $tmp));
                               $me->{'dev'}->{'pole'}->printPole(sprintf("%-20.20s%20.20s", $me->{'tend'}->{'descr'}, $tmp));
                               
                               push @{$me->{'sale'}->{'tenders'}}, {'tender' => $me->{'tend'}->{'id'}, 'amt' => $amt, 'pays' => $me->{'tend'}->pays, 'ext' => \%ext};
                               
                               $me->{'cust'}->chargeToAcct($me->lc->extFmt($amt)) unless $me->{'tend'}->pays;
                               $me->applyToOldest(-$amt) if $amt < 0;
                               $me->{'dev'}->{'drawer'}->openDrawer($me->{'clerk'}{'drawer'}) if $me->{'tend'}->openDrawer;
                               
                               #turn suspended off
                               $me->{'sale'}->{'suspended'} = 0;
                               $me->{'sale'}->save;
                               if($me->{'ratranz'})
                               {
                                   $me->{'cust'}->applyToAcct($me->lc->extFmt($me->{'sale'}->{'total'}));
                                   $me->applyToOldest($me->{'sale'}->{'total'});
                               }
                               #print the tenders together now
                               my $tmpTend = Tender->new($me->{'dal'});
                               my $second = -1;
                               foreach my $i (@{$me->{'sale'}->{'tenders'}})
                               {
                                   next if !$tmpTend->open($i->{'tender'}) or $tmpTend->isVoid;
                                   $me->{'dev'}->{'printer'}->printTender($tmpTend->{'descr'}, $i->{'amt'});
                                   #print the card info
                                   if(exists $i->{'ext'} and exists $i->{'ext'}{'printedAcct'} and $i->{'ext'}{'printedAcct'})
                                   {
                                       $me->{'dev'}->{'printer'}->printFormatted(sprintf("%-40.40s\n%-40.40s\n", 'Card Number: ' . $i->{'ext'}{'printedAcct'}, 'Type: ' . $i->{'ext'}{'cardType'}));
                                   }
                                   
                                   if($me->{'sysStr'}->open('register-printSecond-' . $tmpTend->{'id'}) and !$me->{'sysStr'}->isVoid)
                                   {
                                       $second = $tmpTend->{'id'} if $me->{'sysStr'}{'data'};
                                   }
                               }
                               $me->printFooter(''); #this must come after $me->{'sale'}->save to get the sale id
                               foreach my $i (@{$me->{'sale'}->{'tenders'}})
                               {
                                   next if !$tmpTend->open($i->{'tender'}) or $me->{'sysStr'}->isVoid;
                                   my %ext = %{$i->{'ext'}}; #so it's like tenderProcess()
                                   eval $me->tenderCode('post', $tmpTend, $i->{'amt'}) if $tmpTend->eprocess;
                                   $i->{'ext'} = \%ext;
                               }
                               $me->reprintProcess($second) if $second > -1;
                               #$me->endorseprocess($me->{'tend'}) if $me->{'tend'}->endorses;
                               #$me->tenderCode('post', $me->{'tend'}, $amt) if $me->{'tend'}->eprocess;
                               $me->triggerEvent('Lane/Register/UserInterface/Print Receipt', sprintf("\n%-40.40s", $me->lc->get('Ticket') . " " . $me->{'sale'}{'id'}));
                               $me->newTranz();
                           }
                           else
                           {
                               #this may be the discDue amt
                               $me->autoDiscount('show', $me->{'sale'}, $me->{'sale'}->{'due'} - $saleDue) if $saleDue < $me->{'sale'}->{'due'} and !$me->{'ratranz'};
                               
                               my $change = $amt - $saleDue;
                               #print the info in the on-screen tape
                               my $tmp = $me->lc->moneyFmt($amt);
                               $me->triggerEvent('Lane/Register/UserInterface/Print Receipt', ' ' x 20 . $me->lc->get('Lane/Printer/Format/Tender', 'descr' => $me->{'tend'}->{'descr'}, 'amt' => $tmp));
                               $me->{'dev'}->{'pole'}->printPole(sprintf("%-20.20s%20.20s", $me->{'tend'}->{'descr'}, $tmp));
                               
                               push @{$me->{'sale'}->{'tenders'}}, {'tender' => $me->{'tend'}->{'id'}, 'amt' => $amt, 'pays' => $me->{'tend'}->pays, 'ext' => \%ext};
                               $me->{'cust'}->chargeToAcct($me->lc->extFmt($amt)) unless $me->{'tend'}->pays;
                               $me->applyToOldest(-$amt) if $amt < 0;
                               $me->{'dev'}->{'drawer'}->openDrawer($me->{'clerk'}{'drawer'}) if $me->{'tend'}->openDrawer;
                               if($me->{'ratranz'})
                               {
                                   $me->{'cust'}->applyToAcct($me->lc->extFmt($me->{'sale'}->{'total'}));
                                   $me->applyToOldest($me->{'sale'}->{'total'});
                               }
                               
                               #turn suspended off
                               $me->{'sale'}->{'suspended'} = 0;
                               $me->{'sale'}->save;
                               $me->{'dev'}->{'pole'}->printPole(sprintf("%-20.20s%20.20s", $me->lc->get("Change"), $me->lc->moneyFmt($change)));
                               
                               $me->printSummary;
                               #print the tenders together now
                               my $i;
                               my $tmpTend = Tender->new($me->{'dal'});
                               my $second = -1;
                               foreach $i (@{$me->{'sale'}->{'tenders'}})
                               {
                                   next if !$tmpTend->open($i->{'tender'}) or $tmpTend->isVoid;
                                   $me->{'dev'}->{'printer'}->printTender($tmpTend->{'descr'}, $i->{'amt'});
                                   #print the card info
                                   if(exists $i->{'ext'} and exists $i->{'ext'}{'printedAcct'} and $i->{'ext'}{'printedAcct'})
                                   {
                                       $me->{'dev'}->{'printer'}->printFormatted(sprintf("%-40.40s\n%-40.40s\n", 'Card Number: ' . $i->{'ext'}{'printedAcct'}, 'Type: ' . $i->{'ext'}{'cardType'}));
                                   }
                                   if($me->{'sysStr'}->open('register-printSecond-' . $tmpTend->{'id'}) and !$me->{'sysStr'}->isVoid)
                                   {
                                       $second = 1 if $me->{'sysStr'}{'data'};
                                   }
                               }
                               $me->{'dev'}->{'printer'}->printTender("Change", $change);
                               #save the info about the sale in the database
                               $me->printFooter('');
                               foreach my $i (@{$me->{'sale'}->{'tenders'}})
                               {
                                   next if !$tmpTend->open($i->{'tender'}) or $tmpTend->isVoid;
                                   my %ext = %{$i->{'ext'}}; #so it's like tenderProcess()
                                   eval $me->tenderCode('post', $tmpTend, $i->{'amt'}) if $tmpTend->eprocess;
                                   $i->{'ext'} = \%ext;
                               }
                               $me->reprintProcess($second) if $second > -1;
                               #show the clerk the change amount
                               $tmp = $me->lc->moneyFmt($change);
                               $me->triggerEvent('Lane/Register/UserInterface/Print Receipt', ' ' x 20 . $me->lc->get('Lane/Printer/Format/Tender', 'descr' => $me->lc->get('Change'), 'amt' => $tmp));
                               #$me->tenderCode('post', $me->{'tend'}, $amt) if $me->{'tend'}->eprocess;
                               $me->triggerEvent('Lane/Register/UserInterface/Print Receipt', sprintf("\n%-40.40s", $me->lc->get("Ticket") . " " . $me->{'sale'}{'id'}));
                               #this isn't the best solution, but it will work for now
                               #save the change as a negative tender id 0 amount
                               push @{$me->{'sale'}->{'tenders'}}, {'tender' => 0, 'amt' => -$change, 'pays' => 1};
                               #re-save everything to the db again
                               $me->{'sale'}->save();
                               $me->newTranz();
                           }
                       }
        );
    $me->registerEvent('Lane/Register/Tax/Enable',
                       sub
                       {
                           $me->{'sale'}->{'taxMask'} = $me->{'tax'}->{'allTaxMask'};
                           $me->{'sale'}->updateTotals;
                           $me->triggerEvent('Lane/Register/UserInterface/Update Summary Area');
                       }
        );
    $me->registerEvent('Lane/Register/Tax/Exempt',
                       sub
                       {
                           $me->{'sale'}->{'taxMask'} = 0;
                           $me->{'sale'}->updateTotals;
                           $me->triggerEvent('Lane/Register/UserInterface/Update Summary Area');
                           $me->{'dev'}->{'pole'}->printPole($me->lc->get("Tax exempt"));
                       }
        );
    $me->registerEvent('Lane/Register/Customer/Receive on Account',
                       sub
                       {
                           #receive and apply to an acct
                           my ($qty, $amt, $id) = @_;
                           #make sure we aren't already in a sale
                           if($me->{'sale'}->lastUnstruckItem)
                           {
                               #we are in a sale
                               unless($me->{'ratranz'}) #this makes multiple ras possible
                               {
                                   $me->triggerEvent('Lane/Register/UserInterface/Print Info', $me->lc->get("R/A can not be processed inside a standard transaction."));
                                   die 'R/A can not be processed inside a standard transaction.';
                               }
                           }
                           unless($me->{'cust'}->{'id'})
                           {
                               $me->triggerEvent('Lane/Register/UserInterface/Print Info', $me->lc->get("A customer must be open for a R/A transaction."));
                               die 'A customer must be open for a R/A transaction.';
                           }
                           #print the header, if this is the first "item"
                           $me->printHeader('') if $#{$me->{'sale'}->{'items'}} == -1;
                           
                           #put us in a "special" mode
                           push @{$me->{'sale'}->{'items'}}, {
                               'plu' => 'RA-TRANZ',
                               'qty' => 1, 
                               'amt' => $amt,
                               'struck' => 0,
                           };
                           
                           $me->{'dev'}->{'printer'}->printFormatted('<b>' . $me->lc->get('Lane/Printer/Format/Total', 'descr' => $me->lc->get('R/A'), 'amt' => $me->lc->moneyFmt($amt)) . '</b>');
                           $me->triggerEvent('Lane/Register/UserInterface/Print Receipt', ' ' x 20 . $me->reduceNl($me->lc->get('Lane/Printer/Format/Total', 'descr' => $me->lc->get('R/A'), 'amt' => $me->lc->moneyFmt($amt))));
                           $me->{'dev'}->{'pole'}->printPole(sprintf("%-20.20s%20.20s", $me->lc->get("R/A"), $me->lc->moneyFmt($amt)));
                           $me->{'sale'}->{'subt'} += $amt;
                           $me->{'sale'}->updateTotals;
                           $me->triggerEvent('Lane/Register/UserInterface/Update Summary Area');
                           $me->{'ratranz'} = 1;
                           
                           #update the display
                           $me->triggerEvent('Lane/Register/UserInterface/Update Summary Area');
                       }
        );
    $me->registerEvent('Lane/Register/Sale/Subtotal',
                       sub
                       {
                           my ($due, $addTxt);
                           
                           $addTxt = '' if !defined $addTxt;
                           
                           if($me->{'term'}->{'discDays'} > 0)
                           {
                               $due = $me->{'sale'}->{'due'} - $me->{'term'}->applyDisc($me->{'sale'}->{'total'});
                               $addTxt = " " . $me->lc->get('(w/disc)');
                           }
                           else
                           {
                               $due = $me->{'sale'}->{'due'};
                           }
                           $due = $me->lc->moneyFmt($due);
                           $me->triggerEvent('Lane/Register/UserInterface/Print Info', $me->lc->get("Amount Due") . "$addTxt: $due\n\n" . $me->lc->get("Enter the amount and tender type, or continue to enter products"));
                           $me->{'dev'}->{'pole'}->printPole(sprintf("%-20.20s%20.20s", $me->lc->get("Amount Due") . $addTxt, $due));
                           
                       }
        );
    $me->registerEvent('Lane/Register/Customer',
                       sub
                       {
                           my ($id) = @_;
                           if(!$me->{'cust'}->open($id) or $me->{'cust'}->isVoid)
                           {
                               $me->triggerEvent('Lane/Register/UserInterface/Print Info', $me->lc->get('Lane/Register/Customer/Not Found', $id));
                               $me->triggerEvent('Lane/Register/UserInterface/Beep');
                               $me->{'cust'}->open(''); #make it a cash sale
                           }
                           #terms info
                           $me->{'term'}->open('cod') if !$me->{'term'}->open($me->{'cust'}->{'terms'});
                           ($me->{'term'}->{'discFromNow'}, $me->{'term'}->{'dueFromNow'}) = $me->{'term'}->datesFrom('now');
                           #tax info
                           $me->{'sale'}->{'taxMask'} = $me->{'cust'}->{'taxes'};
                           $me->{'sale'}->{'customer'} = $me->{'cust'}->{'id'};
                           $me->{'sale'}->updateTotals;
                           $me->triggerEvent('Lane/Register/UserInterface/Update Summary Area');
                           #$me->{'dev'}->{'pole'}->printPole($me->lc->get("Customer") . ":           " . $me->{'cust'}->getName());
                           return 1;
                           
                       }
        );
    $me->registerEvent('Lane/Register/Printer/Reprint',
                       sub
                       {
                           #reprint the sale
                           my ($var, $xtra) = @_;
                           my ($i, $obj);
                           
                           #switch the printer device
                           #if anyone adds to this event, they'll need to do this local bit again, since we loose it at the end of our sub
                           local ($me->{'dev'}->{'printer'});
                           $me->{'dev'}->{'printer'} = $me->{'dev'}->{'printer2'};
                           #this is a new ticket, so we haven't printed the header
                           $me->{'headerPrinted'} = 0;
                           
                           $me->printHeader($var);
                           #print the items
                           foreach $i (@{$me->{'sale'}->{'items'}})
                           {
                               next if $i->{'struck'};
                               #determine item type, and print it
                               if($i->{'plu'} eq 'RA-TRANZ') # ra
                               {
                                   $me->{'dev'}->{'printer'}->printFormatted('<b>' . $me->lc->get('Lane/Printer/Format/Total', 'descr' => $me->lc->get('R/A'), 'amt' => $me->lc->moneyFmt($i->{'amt'})) . '</b>');
                               }
                               elsif($i->{'plu'} =~ /^:/) # discount
                               {
                                   $obj = Discount->new($me->{'dal'});
                                   next if !$obj->open(substr($i->{'plu'}, 1)) or $obj->isVoid;
                                   my $amtStr = $me->lc->moneyFmt(-$i->{'amt'});
                                   $me->{'dev'}->{'printer'}->printDiscount($obj->{'descr'}, $amtStr);
                               }
                               else			# item
                               {
                                   $obj = Product->new($me->{'dal'});
                                   next if !$obj->open($i->{'plu'}) or $obj->isVoid;
                                   $me->{'dev'}->{'printer'}->printItem($i->{'plu'}, $obj->{'descr'}, $i->{'qty'}, $i->{'amt'});
                               }
                           }
                           #print any extra stuff
                           $me->{'dev'}->{'printer'}->printFormatted($xtra);
                           #print the summary and tenders
                           $me->printSummary();
                           $obj = Tender->new($me->{'dal'});
                           foreach $i (@{$me->{'sale'}->{'tenders'}})
                           {
                               next if !$obj->open($i->{'tender'}) or $obj->isVoid;
                               $me->{'dev'}->{'printer'}->printTender($obj->{'descr'}, $i->{'amt'});
                               if($xtra !~ /Card Number/)
                               {
                                   #print the card info
                                   if(exists $i->{'ext'} and exists $i->{'ext'}{'printedAcct'} and $i->{'ext'}{'printedAcct'})
                                   {
                                       $me->{'dev'}->{'printer'}->printFormatted(sprintf("%-40.40s\n%-40.40s\n", 'Card Number: ' . $i->{'ext'}{'printedAcct'}, 'Type: ' . $i->{'ext'}{'cardType'}));
                                   }
                               }
                           }
                           $me->printFooter($var);
                       }
        );
    $me->registerEvent('Lane/Register/Product',
                       sub
                       {
                           my ($qty, $amt, $id) = @_;
                           my %item;
                           
                           my $extPrice;
                           
                           warn "Register::itemProcess($me, $qty, $amt, $id) \n" if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Register/;
                           
                           return 0 if $me->{'ratranz'}; # can't process items in a ra transaction
                           
                           if(!$me->{'prod'}->open($id) or $me->{'prod'}->isVoid)
                           {
                               $me->triggerEvent('Lane/Register/UserInterface/Beep');
                               $me->triggerEvent('Lane/Register/UserInterface/Print Info', $me->lc->get('Unknown Product', $id));
                               die 'could not open or use product';
                           }
                           
                           #verify this item makes sense (ie clerk gave an open item an amount)
                           ####
                           #determine if the item is open, preset, etc.
                           if($me->{'prod'}->{'type'} eq 'p')
                           {
                               $amt = $me->{'prod'}->{'price'};
                               $amt =~ s/\.//g; #i'm paranoid about decimal arithmetic
                           }
                           elsif($me->{'prod'}->{'type'} =~ /^[on]$/)
                           {
                               if($amt eq '')
                               {
                                   #they must specify a price if open
                                   $me->triggerEvent('Lane/Register/UserInterface/Print Info', $me->lc->get('Lane/Register/Product/Open Without Amount'));
                                   $me->triggerEvent('Lane/Register/UserInterface/Beep');
                                   die 'open items require an amount';
                               }
                               $amt .= '0';
                               $amt = -$amt if $me->{'prod'}->{'type'} eq 'n';
                           }
                           else			# data error
                           {
                               $me->triggerEvent('Lane/Register/UserInterface/Beep');
                               die 'unknow product type';
                           }
                           
                           $qty = 1 if $qty == 0;	# sanity check
                           
                           #call the extended code here
                           if($main::useExtProductCode)
                           {
                               if(!eval $main::extProductCode)
                               {
                                   #warn "\$main::extProductCode eval'ed to: ($@)\n";
                                   warn "Register::itemProcess($qty, $amt, $id): the extended code returned false!\n";
                                   die 'the extended prod code returned false';
                               }
                           }
                           
                           #print the header, if this is the first "item"
                           $me->printHeader('') if $#{$me->{'sale'}->{'items'}} == -1;
                           
                           $me->{'prod'}->consumeUnits($qty);	# consumeUnits ignores unless trackQty
                           $item{'plu'} = $id;
                           $item{'qty'} = $qty;
                           $extPrice = $me->lc->roundingDiv($me->lc->roundingMulti($amt, $qty, 1), 10, 0);
                           $item{'amt'} = $extPrice;
                           $item{'struck'} = 0;
                           
                           #display and print the item
                           my $tmp = $me->lc->moneyFmt($extPrice);
                           $me->triggerEvent('Lane/Register/UserInterface/Print Receipt', $me->reduceNl($me->lc->get('Lane/Printer/Format/Item', 'descr' => $me->{'prod'}->{'descr'}, 'amt' => $tmp, 'plu' => $id, 'qty' => "$qty")));
                           $me->{'dev'}->{'pole'}->printPole($me->lc->get('Lane/Pole/Format/Item', 'descr' => $me->{'prod'}->{'descr'}, 'qty' => "$qty", 'amt' => $me->lc->moneyFmt($extPrice), 'plu' => $id));
                           $me->{'dev'}->{'printer'}->printItem($item{'plu'}, $me->{'prod'}->{'descr'}, "$qty", $extPrice);
                           #update $me->{'sale'}
                           ###
                           push @{$me->{'sale'}->{'items'}}, \%item;
                           #taxes
                           my $t = 1;
                           my $tx = Tax->new($me->{'dal'});
                           for(my $i = 0; 2 ** $i <= $me->{'prod'}->{'taxes'}; $i++, $t <<= 1)
                           {
                               $tx->open($i + 1);
                               next if !($t & $me->{'prod'}->{'taxes'}) or $tx->isVoid;
                               #add to the tax here
                               eval $main::taxCode if $main::useTaxCode;
                               $me->{'sale'}->{'taxes'}[$i]{'taxable'} += $extPrice;
                               $me->{'sale'}->{'taxes'}[$i]{'tax'} = $tx->applyTaxManually($me->{'sale'}->{'taxes'}[$i]{'taxable'}, $me->{'sale'}->{'taxes'}[$i]{'rate'});
                           }
                           $me->{'sale'}->{'subt'} += $extPrice;
                           $me->{'sale'}->updateTotals;
                           $me->triggerEvent('Lane/Register/UserInterface/Update Summary Area');
                       }
        );
    $me->registerEvent('Lane/CORE/Initialize/Machine',
                       sub
                       {
			   # initializes the devices (hardware) [but not the display sys]
			   if($me->{'sysStr'}->open('register-initMachine-default') and !$me->{'sysStr'}->isVoid)
			   {
			       warn "register loaded the register-initMachine-default code from the database\n" if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Register/;
			   }
			   else
			   {
			       #this is a major error: don't hide it behind debug statements
			       warn "ERROR! register couldn't load the register-initMachine code from the database\n";
			   }
			   #this is a terrible hack
			   $main::reg = $me;
			   eval $me->{'sysStr'}->{'data'};	# that should setup the machine
			   warn "register-initMachine-default eval'ed to: $@\n" if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Register/;
			   
			   if($me->{'string'}->open('custdisp-idle') and !$me->{'string'}->isVoid)
			   {
			       $me->{'dev'}->{'pole'}->printPole($me->{'string'}->{'data'});
			   }
			   return 1;  
                       }
        );
    $me->registerEvent('Lane/CORE/Initialize/User Interface',
                       sub
                       {
			   #load the default keymap
			   my %keyMap;
			   if($me->{'sysStr'}->open('register-keymap') and !$me->{'sysStr'}->isVoid)
			   {
			       warn "register loaded the register-keymap from the database\n" if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Register/;
			       foreach(split /\n/, $me->{'sysStr'}{'data'})
			       {
				   my ($k, $f) = split /\s*=\s*/;
				   $keyMap{$k} = $f;
				   #can we push into a hash?
			       }
			   }
			   else
			   {
			       warn "register didn't load the register-keymap from the database--falling back to compatibility mode\n"  if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Register/;
			       $keyMap{'F5'} = 'clear';
			   }
			   eval #for compat, catch undefined main::mapkey
			   {
			       $me->triggerEvent('Lane/Register/UserInterface/Map Key', $_, $keyMap{$_}) foreach(keys %keyMap);
			   };
                       }
        );
    $me->registerEvent('Lane/Register/Printer/Print/Header',
                       sub
                       {
			   #prints the header for the recpt
			   my ($var) = @_;
			   
			   #check to see if we've printed it already
			   return if $me->{'headerPrinted'};
			   $me->{'headerPrinted'} = 1;
			   
			   #per the documentation/specifications of Register, clear the receipt here
			   if($me->{'clearReceipt'} == -1)
			   {
			       $me->triggerEvent('Lane/Register/UserInterface/Clear Receipt');
			   }
			   
			   $me->{'string'} = String->new($me->dal);
			   if($me->{'string'}->open("receipt$var-header") and !$me->{'string'}->isVoid)
			   {
			       my $header = $me->string->data;
			       $me->{'dev'}->{'printer'}->beginReceipt();
			       #allow the header to include various variables
			       my $biz = Customer->new($me->dal);
			       $biz->_resetFlds; #in case they haven't set this up
			       $me->string->open('company-customer-id') and $me->string->data and $biz->open($me->string->data);
			       my %vars = (
				   'bizName' => $biz->getName,
				   'bizAddr1' => $biz->billAddr1,
				   'bizAddr2' => $biz->billAddr2,
				   'bizCity' => $biz->billCity,
				   'bizSt' => $biz->billSt,
				   'bizZip' => $biz->billZip,
				   'bizCountry' => $biz->billCountry,
				   'bizPhone' => $biz->billPhone,
				   'bizFax' => $biz->billFax,
				   'bizShipAddr1' => $biz->shipAddr1,
				   'bizShipAddr2' => $biz->shipAddr2,
				   'bizShipCity' => $biz->shipCity,
				   'bizShipSt' => $biz->shipSt,
				   'bizShipZip' => $biz->shipZip,
				   'bizShipCountry' => $biz->shipCountry,
				   'bizShipPhone' => $biz->shipPhone,
				   'bizShipFax' => $biz->shipFax,
				   'bizEmail' => $biz->email,
				   #maybe add xaction start times, these aren't the same as Sale.tranzDate
				   );
			       $me->{'dev'}->{'printer'}->printHeader($me->lc->replaceVar($header, %vars));
			   }
			   return 1;    
			   
                       }
        );
    $me->registerEvent('Lane/Register/Printer/Print/Summary',
                       sub
                       {
			   #prints the summary (tax, etc) info
			   my @taxDescr = $me->{'tax'}->getAllDescr;
			   
			   #pass the tax info into GenericPrinter->printSummary in a way it expects
			   my @taxes;
			   push @taxes, $me->{'sales'}->{'taxes'}[$_]{'tax'} foreach (0..$#{$me->{'sales'}->{'taxes'}});
			   
			   my $custInfo = sprintf("%-40.40s\n%-40.40s\n%-40.40s\n%-40.40s\n%-40.40s\n\n", $me->{'cust'}->{'id'}, $me->{'cust'}->getName(), $me->{'cust'}->{'billAddr1'}, $me->{'cust'}->{'billAddr2'}, $me->{'cust'}->{'billCity'} . ", " . $me->{'cust'}->{'billSt'} . " " . $me->{'cust'}->{'billZip'}, $me->{'cust'}->{'billPhone'}) if $me->{'cust'}->{'id'};
			   
			   $me->{'dev'}->{'printer'}->printSummary($me->{'sale'}->{'subt'}, $me->{'sale'}->{'total'}, \@taxes, \@taxDescr, $custInfo, $me->{'term'}->{'descr'}, $me->{'term'}->{'discFromNow'}, $me->{'term'}->{'dueFromNow'});
			   return 1; 
                       }
        );
    $me->registerEvent('Lane/Register/Printer/Print/Footer',
                       sub
                       {
			   #prints the footer for the recpt
			   #doesn't check if it has already printed
			   my ($var) = @_; #which variant to print

			   $me->{'string'} = String->new($me->dal);
			   $now = $me->lc->nowFmt('shortTimestamp');

			   my %vars = (
			       'clerkTitle' => $me->lc->get('Clerk'),
			       'clerk' => $me->clerk->name,
			       'ticketTitle' => $me->lc->get('Ticket'),
			       'ticket' => $me->sale->id,
			       'now' => $now,
			       );

			   if($me->string->open("receipt$var-footer") and !$me->string->isVoid)
			   {
			       $vars{'stringFooter'} = $me->string->data;
			   }
			   $me->{'dev'}->{'printer'}->printFooter($me->lc->get('Lane/Printer/Format/Footer', %vars));
			   $me->{'dev'}->{'printer'}->finishReceipt();
			   return 1;  
                       }
        );
    $me->registerEvent('Lane/Register/UserInterface/Update Status Bar',
                       sub
                       {
                           ;
                       }
        );
    $me->registerEvent('Lane/Register/UserInterface/Update Summary Area',
                       sub
                       {
                           ;
                       }
        );
    $me->registerEvent('Lane/Register/UserInterface/Clear Summary Area',
                       sub
                       {
                           ;
                       }
        );
    $me->registerEvent('Lane/Register/UserInterface/Beep',
                       sub
                       {
                           ;
                       }
        );
    $me->registerEvent('Lane/Register/UserInterface/Clear Entry',
                       sub
                       {
                           ;
                       }
        );
    $me->registerEvent('Lane/Register/UserInterface/Print Info',
                       sub
                       {
                           ;
                       }
        );
    $me->registerEvent('Lane/Register/UserInterface/Get Responses',
                       sub
                       {
                           ;
                       }
        );
    $me->registerEvent('Lane/Register/UserInterface/Print Receipt',
                       sub
                       {
                           ;
                       }
        );
    $me->registerEvent('Lane/Register/UserInterface/Clear Receipt',
                       sub
                       {
                           ;
                       }
        );
    $me->registerEvent('Lane/Register/UserInterface/Map Key',
                       sub
                       {
                           ;
                       }
        );
    $me->registerEvent('Lane/Register/UserInterface/Exit',
                       sub
                       {
                           ;
                       }
        );
#    $me->registerEvent('',
#                       sub
#                       {
#                           
#                       }
#        );
    return $r;
}

sub tenderCode
{
    my ($me, $time, $tend, $amt) = @_;
    #the code can access the following things:
    #these local vars: $tend (Tender) $amt (the amount tendered)
    #these global functions: &main:: infoPrint(), getResponses()
    #these obj vars: $me->{'cust'} (Customer), $me->{'sale'} (Sale) [to get tax, other info]

    #$time should be 'pre' or 'post'
    if($time =~ /pre/)
    {
	$time = 'eauth';
    }
    elsif($time =~ /post/)
    {
	$time = 'eprocess';
    }
    elsif($time =~ /cancel/)
    {
	$time = 'ecancel';
    }
    else
    {
	warn "Register::tenderCode($time, ", $tend->{'id'}, ", $amt) couldn't determine the \$time of the transaction (must be pre or post)\n";
    }

    if($me->{'sysStr'}->open("register-$time-" . $tend->{'id'}) and !$me->{'sysStr'}->isVoid)
    {
	warn "Register::tenderCode($time, ", $tend->{'id'}, ", $amt) loaded the register-$time-" . $tend->{'id'} . " code from the database\n"  if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /Register/;
    }
    else
    {
	warn "ERROR! Register::tenderCode($time, ", $tend->{'id'}, ", $amt) couldn't load the register-$time-" . $tend->{'id'} . " code from the database\n";
	return 0;
    }

    return '$amt = ' . $amt . '; ' . $me->{'sysStr'}->{'data'};
#    my $r = eval $me->{'sysStr'}->{'data'};    # notice that this runs in Register:: not main::
#    print STDERR "Register::tenderCode($time, ", $tend->{'id'}, ", $amt) eval'ed to $@\n";
#    return $r;
}

sub newTranz
{
    my ($me, @x) = @_;
    return $me->triggerEvent('Lane/Register/Sale/New', @x);
}

sub clerkSignin
{
    my ($me, @x) = @_;
    return $me->triggerEvent('Lane/Register/Clerk/Signin', @x);
}

sub printHeader
{
    my ($me, @x) = @_;
    return $me->triggerEvent('Lane/Register/Printer/Print/Header', @x);
}

sub printFooter
{
    my ($me, @x) = @_;
    return $me->triggerEvent('Lane/Register/Printer/Print/Footer', @x);
}

sub printSummary
{
    my ($me, @x) = @_;
    return $me->triggerEvent('Lane/Register/Printer/Print/Summary', @x);
}

sub autoDiscount
{
    #CAREFUL, THIS CALLS $sale->updateTotals, SO YOU CAN'T DEPEND ON THEM FOR PRE-DISC INFO AFTER CALLING THIS SUB!!!!
    #it doesn't do that anymore
    my ($me, $show, $sale, $amt) = @_;

    return 0 if $sale->{'ratranz'}; # can't process discounts in a ra transaction

    my @r = (1, undef); #return the autoDisc'ed sale id or 1, if it isn't a separate sale.

    my $negSale = Sale->new($me->{'dal'});

    $show = 0 if $show =~ /hide/;

    if(!$me->{'sysStr'}->open('earlypay-disc-id') or $me->{'sysStr'}->isVoid)
    {
	warn "Register::autoDiscount($me, $sale, $amt) couldn't open the 'earlypay-disc-id' from the database\n";
	return 0;
    }

    my %disc;
    my $amtStr;

    if(!$me->{'disc'}->open($me->{'sysStr'}->{'data'}) or $me->{'disc'}->isVoid)
    {
	warn "Register::autoDiscount($me, $sale, $amt) couldn't open the discount.\n";
	$me->triggerEvent('Lane/Register/UserInterface/Beep') if $show;
	return 0;
    }
    #verify that this is the correct kind of discount
    if(!$me->{'disc'}->isSaleDisc or $me->{'disc'}->isPresetDisc or $me->{'disc'}->isPercentDisc)
    {
	warn "Register::autoDiscount($me, $sale, $amt) ERROR: the 'earlypay-disc-id' isn't an open, \$, sale discount.\n";
	$me->triggerEvent('Lane/Register/UserInterface/Beep') if $show;
	return 0;
    }

    $disc{'plu'} = ":" . $me->{'sysStr'}->{'data'};	# NOTE: THE COLON REPRESENTS A DISCOUNT!!!!
    $disc{'qty'} = 1;		# only one disc at a time
    $disc{'amt'} = $amt;
    $disc{'struck'} = 0;
    $amtStr = "-" . $me->lc->moneyFmt($amt);
    # apply the disc to the sale
    #how should all of this interact with taxes?
    if($show)
    {
	$sale->{'subt'} -= $amt;
	push @{$me->{'sale'}->{'items'}}, \%disc;
	$sale->updateTotals;
    }
    else
    {
	if(!$me->{'sysStr'}->open('earlypay-disc-tender') or $me->{'sysStr'}->isVoid)
	{
	    warn "Register::autoDiscount($me, $sale, $amt) couldn't open the 'earlypay-disc-tender' from the database\n";
	    return 0;
	}
	chomp $me->{'sysStr'}->{'data'};

	$negSale->{'customer'} = $sale->{'customer'};
	$negSale->{'exempt'} = 1;
	$negSale->{'suspended'} = 0;
	$negSale->{'clerk'} = $me->{'sale'}->{'clerk'};
	$negSale->{'terminal'} = $ENV{'LaneTerminal'} ? $me->{'hostname'} . "/$ENV{'LaneTerminal'}" : $me->{'hostname'};
	push @{$negSale->{'items'}}, \%disc;
	$negSale->{'subt'} = -$amt;
	$negSale->updateTotals;
	push @{$negSale->{'tenders'}}, {'tender' => $me->{'sysStr'}->{'data'}, 'amt' => $negSale->{'total'}};
	$negSale->save;
	#apply the discount to the customer's acct too
	$me->{'cust'}->applyToAcct($me->lc->extFmt($amt));
	@r = ($negSale->{'id'}, $negSale->{'tranzDate'});
    }

    #now, print the stuff on the terminal and the printer
    $me->triggerEvent('Lane/Register/UserInterface/Print Receipt', $me->reduceNl($me->lc->get('Lane/Printer/Format/Discount', 'amt' => $amtStr, 'descr' => $me->{'disc'}->{'descr'}, 'id' => $me->{'disc'}->{'id'}))) if $show;
    $me->{'dev'}->{'pole'}->printPole(sprintf("%-20.20s%20.20s", $me->{'disc'}->{'descr'}, $amtStr)) if $show;
    $me->{'dev'}->{'printer'}->printDiscount($me->{'disc'}->{'descr'}, $amtStr) if $show;

    return @r;
}

sub applyToOldest
{
    #auto apply to the oldest tickets

    #make sure we don't double-apply the early-pay sale discount
    #that can't happen--ticket must be paid for tenderProcess to apply it,
    #and it must be unpaid for this sub to get it.
    my ($me, $amt) = @_;
    my @ticks = $me->{'sale'}->getNotPaidByCust($me->{'cust'}->{'id'});
    my $tick = Sale->new($me->{'dal'});
    my $left = $amt;
    my $bal = 0;
    my $disc = 0;

    #we need a Sale.id for Sale->applyToBalance
    $me->{'sale'}->save if !$me->{'sale'}->{'id'};

    foreach my $i (@ticks)
    {
	$tick->open($i);
	next if $tick->isVoid;
	#determine if this ticket can have the sale discount, and apply it
	if($me->{'term'}->isDiscAble($tick->{'tranzDate'}, 'today'))
	{
	    $disc = $me->{'term'}->applyDisc($tick->{'balance'});
	    if($tick->{'balance'} - $disc <= $left)
	    {
		my ($negId, $negTranzDate) = $me->autoDiscount('hide', $tick, $disc);
		$tick->applyToBalance($disc, $negId, $negTranzDate);
	    }
	}
	$bal = $tick->{'balance'};
	#this is where you'd put the late pay fincharge stuff
	if($bal <= $left) #apply to the entire amount
	{
	    $left -= $bal;
	    $tick->applyToBalance($bal, $me->{'sale'}->{'id'}, $me->{'sale'}->{'tranzDate'});
	}
	else #apply to part of the balance
	{
	    $tick->applyToBalance($left, $me->{'sale'}->{'id'}, $me->{'sale'}->{'tranzDate'});
	    $left = 0;
	}
	last if $left == 0;
    }
    return 1;
}

#these subs are called by mainInputLoop
sub tenderProcess
{
    my ($me, @x) = @_;
    return $me->triggerEvent('Lane/Register/Tender', @x);
}

sub discProcess
{
    my ($me, @x) = @_;
    return $me->triggerEvent('Lane/Register/Discount', @x);
}

sub priceCheckProcess
{
    my ($me) = @_;
    return $me->triggerEvent('Lane/Register/Product/Check Price', @x);
}

sub itemProcess
{
    my ($me, @x) = @_;
    return $me->triggerEvent('Lane/Register/Product', @x);

}

sub subtProcess
{
    my ($me, @x) = @_;
    return $me->triggerEvent('Lane/Register/Sale/Subtotal', @x);
}

sub custProcess
{
    my ($me, @x) = @_;
    return $me->triggerEvent('Lane/Register/Customer', @x[1..$#x]);
}

sub cancelProcess
{
    my ($me) = @_;
    return $me->triggerEvent('Lane/Register/Sale/Cancel', @x);
}

sub errCorrectProcess 
{
    my ($me, $num, $amt, @x) = @_;
    return $me->triggerEvent('Lane/Register/Sale/Error Correct', $amt, @x);
}

sub exemptReverse
{
    my ($me) = @_;
    return $me->triggerEvent('Lane/Register/Tax/Enable', @x);
}

sub exemptProcess
{
    my ($me) = @_;
    return $me->triggerEvent('Lane/Register/Tax/Exempt', @x);
}

sub suspendProcess
{
    my ($me, @x) = @_;
    return $me->triggerEvent('Lane/Register/Sale/Suspend', @x);
}

sub resumeProcess
{
    my ($me, @x) = @_;
    return $me->triggerEvent('Lane/Register/Sale/Resume', @x);
}

sub raProcess
{
    my ($me, @x) = @_;
    return $me->triggerEvent('Lane/Register/Customer/Receive on Account', @x);
}

sub reprintProcess
{
    my ($me, @x) = @_;
    return $me->triggerEvent('Lane/Register/Printer/Reprint', @x);
}

sub allowSignals
{
    #call $reg->blockSignals(true) to block the sig handlers, false to allow them
    #the register should normally run under BLOCKED (true) mode
    #to avoid reentrant problems
    my ($me) = @_;

    return 1 if !$me->{'signals'}{'dieWhenConvient'};

    warn "Register: Starting the signal handler...\n" if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /signals/;
    if($me->{'sale'}{'clerk'})
    {
	$me->cancelProcess() or $me->suspendProcess();
    }
    warn "Register:(sig handler) before the exit()...\n" if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /signals/;
    #die "Register: all cleaned up";
    $me->triggerEvent('Lane/Register/UserInterface/Exit');
    POSIX::_exit(0); #just in case UI/Exit doesn't work (for example, in Tk)
    warn "Register:(sig handler) WE SHOULDN'T BE HERE!\n" if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /signals/;
}

sub reduceNl
{
    my ($me, $t) = @_;

    #unlike the printers, the register typically autowraps. so, reduce the \n's by one
    $t =~ s/\n(\n*)/$1/g;
    return $t;
}

1;
