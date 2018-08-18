#Perl Module

#DatacapXml.pm
#This module is part of L'anePOS. Copyright 2006-2010 Jason B. Burrell. See COPYING.
#$Id: DatacapXml.pm 1132 2010-09-19 21:36:50Z jason $

package LanePOS::DatacapXml;

$::VERSION = (q$Revision: 1132 $ =~ /(\d+)/)[0];

=pod

=head1 NAME

LanePOS::DatacapXml - an interface between DatacapE<8217>s SOAP credit card processing services (especially Mercury Payment SystemsE<8217>) and LE<8217>E<acirc>neE<8217>s Register class

=head1 SYNOPSIS

LanePOS::DatacapXml

=head1 DESCRIPTION

=head1 USAGE

=head1 SUBROUTINES

=over

=item new([class])

Creates and returns a new DatacapXml object.

=item authorize(amt, sale, extended)

Attempts an authorization of C<amt> on L<Sale> C<sale> to the card described by the L</Extended Options Hash>. Returns true (and a hash that is needed for other operations) on success or false on failure. On failure, check (and possibly inform the user of) the reponse with L</errorResponse> and/or L</textResponse>. If C<amt> is less than zero, L</authorize(amt, sale, extended)> will perform a return authorization.

=head2 Extended Options Hash

All authorizations must include either L</track2> or L</acct> with L</expDate>.

=over

=item acct

The manually entered account number

=item address

The address info (usually the street number or box number) for this card. I<Only used if L</track2> is not present.>

=item allowZero

Normally, L</authorize> will fail if an attempt to authorize a zero amount is performed. Setting this option to a true value ignores that check.

=item cvv

The card verification value (CVV) for this card or the values C<None> for cards without a CVV number or C<Illegible> for cards with an illegible CVV number. I<Only used if L</track2> is not present.>

=item expDate

The expiration date of the card in YYYY-MM format (ISO-8601 year and month format)

=item invNo

The internal invoice number assigned to the sale. It includes C<Sale.id> and the current tender number. I<Used Internally.>

=item track2

The magnetic track 2 data from the card. This data should be provided as supplied (with any start/stop characters removed).

=item voiceAuth

The code provided by the operator during a voice authorization.

=item zip

The ZIP/Postal code of the address for this card. I<Only used if L</track2> is not present.>

=back

=item process(amt, sale, extended)

This module does not use the process interface.

=item cancel(amt, sale, response, extended)

Attempts to cancel the authorization of C<amt> on L<Sale> C<sale> to the card described by the L</Extended Options Hash>. Returns true (and a hash that is needed for other operations) on success or false on failure. On failure, check (and possibly inform the user of) the reponse with L</errorResponse> and/or L</textResponse>. If C<amt> is less than zero, L</cancel(amt, sale, response, extended)> will cancel a return authorization.

=item sendMessage(type, msg)

B<Internal Use Only>. Sends the message give by C<msg> whose type is C<type> via SOAP to the payment gateway.

=head2 types

=over

=item CreditTransaction

Credit Card Transaction

=item GiftTransaction

B<Not Implimented>. Gift Card Transaction

=item LoyaltyTransaction

B<Not Implimented>. Loyalty Transaction

=item AssociateAccount

B<Not Implimented>. Associate an Identifier to an Account

=item RemoveAccountAssociation

B<Not Implimented>. Remove an Identifier Previously Associated to an Account

=item Cbatch

B<Not Implimented>. Batch Report

=back

=item message(sale, [options...])

B<Internal Use Only>. Creates an XML message for transmitting to the processor based on L<Sale> C<sale> and the L</Options Hash> C<options>. Returns true on success or false on failure. On failure, check (and possibly inform the user of) the reponse with L</errorResponse> and/or L<textResponse>.

=head2 Options Hash

Also see L</Extended Options Hash>

=over

=item amt

The amount to authorize/purchase in LE<8217>E<acirc>neE<8217>s internal format

=item address

The cardE<8217>s billing address.

=item cvv

The cardE<8217>s three or four CVV/CVC digits, C<None>, or C<Illegible>.

=item duplicateOverride

Set to override a C<duplicate error> response from the processor.

=item tranCode

The code of the transaction: C<Sale>, C<VoidSale>, C<Return>, and C<VoidReturn>.

=item tranType

The type of transaction: C<Credit> (Also see: L</tranCode>.)

=item zip

The cardE<8217>s billing zip (US only).

=back

=back

=head1 PROPERTIES

=over

=item errorResponse

The symbolic error response.

=item textResponse

The text response.

=item Values

The possible values of L</errorResponse> and their related L</textResponse> are below.

=over

=item Lane/CancelNonExistent

ERROR: This sale was not authorized so it can not be canceled.

=item Lane/Declined

ERROR: DECLINED: The processor declined this transaction.

=item Lane/DisallowZeroSales

ERROR: CHECK: You may not authorize zero amounts without specifically requesting it via 'allowZero'.

=item Lane/InsufficientFunds

ERROR: INSUFFICIENT FUNDS: The account specified does not have sufficient funds.

=item Lane/InvalidInfo

ERROR: USAGE: Some information supplied was invalid (recheck all info).

=item Lane/Misc

ERROR: MISC.: An unknown error occured: Call technical support.

=item Lane/MissingSaleId

ERROR: USAGE: The supplied sale must have a non-zero ID.

=item Lane/Timeout

ERROR: TIMEOUT: The processor did not respond to this request.

=item Lane/UsageError

ERROR: USAGE: You must supply one of 'track2' or 'acct' with 'expDate'.

=item Lane/UsageError/TooManyTenders

=item Lane/UsageError/TransCode

ERROR: USAGE: The supplied transaction code is not recognized.

=item Lane/UsageError/TranType

ERROR: USAGE: The supplied transaction type is not recognized.

=item Lane/UsageError/ServiceType

ERROR: USAGE: The supplied web services type is not recognized.

=back

=back

=head2 SysStrings

=over

=item com/BurrellBizSys/Lane/Register/Tender/DatacapXml/N/Voice

This tender with and ID of C<N> requires a manual voice authorization number.

=item com/BurrellBizSys/Lane/Register/Tender/DatacapXml/Merchant ID

The merchant ID which identifies the business to the authorization network

=item com/BurrellBizSys/Lane/Register/Tender/DatacapXml/Operator ID Prefix

A prefix attached to the operator ID field (primarily used for testing).

=item com/BurrellBizSys/Lane/Register/Tender/DatacapXml/Password

The password which authorizes the business to the authorization network

=item com/BurrellBizSys/Lane/Register/Tender/DatacapXml/Terminal ID

The terminal ID assigned by the processor, if provided

=back

=head1 AUTHOR

Jason Burrell

=head1 BUGS

=over

=item *

Unfinished

=back

=head1 SEE ALSO

The LE<8217>E<acirc>ne Website L<http://l-ane.net/>

The task in Bugzilla L<http://tasks.l-ane.net/show_bug.cgi?id=256> (bug 256).

Mercury Payment SystemsE<8217> Website L<http://www.mercurypay.com/>

=cut

sub new
{
    my ($class, $dal) = @_;

    require XML::Simple;

    use SOAP::Lite;# +trace => [qw(method fault transport result debug)];

    use LanePOS::SysString;
    use LanePOS::Locale;
    
    my $me = {
	#these are accessible -- see the pod above
	'errorResponse' => undef,
	'textResponse' => undef,
	#these are internal things (i'm not too keen on the _name business)
	'validType' => {'Credit' => 1, },
	'validCode' => {
	    'Sale' => 1,
	    'Return' => 1,
	    #'AuthOnly' => 1,
	    'VoidSale' => 1,
	    'VoidReturn' => 1,
	    'VoiceAuth' => 1,
	},
	'error' => {
	    '' => '', #to clear the error messages
	    'Lane/DisallowZeroSales' => 'ERROR: CHECK: You may not authorize zero amounts without specifically requesting it via \'allowZero\'.',
	    'Lane/UsageError' => 'ERROR: USAGE: You must supply one of \'track2\' or \'acct\' with \'expDate\'',
	    'Lane/UsageError/TransCode' => 'ERROR: USAGE: The supplied transaction code is not recognized.',
	    'Lane/UsageError/TranType' => 'ERROR: USAGE: The supplied transaction type is not recognized.',
	    'Lane/UsageError/ServiceType' => 'ERROR: USAGE: The supplied web services type is not recognized.',
	    'Lane/MissingSaleId' => 'ERROR: USAGE: The supplied sale must have a non-zero ID.',
	    'Lane/Misc' => 'ERROR: MISC.: An unknown error occured: Call technical support.', #this is a misc error, but a failure
	    'Lane/InvalidInfo' => 'ERROR: USAGE: Some information supplied was invalid (recheck all info).',
	    'Lane/InsufficientFunds' => 'ERROR: INSUFFICIENT FUNDS: The account specified does not have sufficient funds.',
	    'Lane/Declined' => 'ERROR: DECLINED: The processor declined this transaction.',
	    'Lane/CancelNonExistent' => 'ERROR: This sale was not authorized so it can not be canceled.',
	    'Lane/UseageError/TooManyTenders' => 'ERROR: This module only supports 100 split-tenders per transaction.',
	    'Lane/Timeout' => 'ERROR: TIMEOUT: The processor did not respond to this request.',
	},
	'dsiToLane' => {
	    '000000' => '', #blanks are ok
	    '001004' => 'Lane/InsufficientFunds',
	    '001007' => 'Lane/Timeout',
	    '003010' => 'Lane/Timeout',
	    '004017' => 'Lane/InvalidInfo',
	    '100201' => 'Lane/InvalidInfo',
	    '100202' => 'Lane/InvalidInfo',
	    '100203' => 'Lane/InvalidInfo',
	    '100204' => 'Lane/InvalidInfo',
	    '100205' => 'Lane/InvalidInfo',
	    '100206' => 'Lane/InvalidInfo',
	    '100207' => 'Lane/InvalidInfo',
	    '100208' => 'Lane/InvalidInfo',
	    '100209' => 'Lane/InvalidInfo',
	    '100210' => 'Lane/InvalidInfo',
	    '100211' => 'Lane/InvalidInfo',
	    '100212' => 'Lane/InvalidInfo',
	    '100213' => 'Lane/InvalidInfo',
	    '100214' => 'Lane/InvalidInfo',
	    '100215' => 'Lane/InvalidInfo',
	    '100216' => 'Lane/InvalidInfo',
	    '100217' => 'Lane/InvalidInfo',
	    '100218' => 'Lane/InvalidInfo',
	    '100219' => 'Lane/InvalidInfo',
	    '100220' => 'Lane/InvalidInfo',
	    '100221' => 'Lane/InvalidInfo',
	    '100222' => 'Lane/InvalidInfo',
	    '100223' => 'Lane/InvalidInfo',
	    '100224' => 'Lane/InvalidInfo',
	    '100225' => 'Lane/InvalidInfo',
	    '100226' => 'Lane/InvalidInfo',
	    '100227' => 'Lane/InvalidInfo',
	    '100228' => 'Lane/InvalidInfo',
	},
	'sysStr' => SysString->new($dal),
	'lc' => Locale->new($dal),
	'xs' => XML::Simple->new(),
	'soap' => undef, #SOAP::Lite->service($ws),
	'uri' => [ #these should be numbered to match the serviceProxy
		  'http://www.mercurypay.com',
		  'http://www.mercurypay.com',
		  ],
	'serviceProxy' => [
			   'https://w1.mercurypay.com/ws/ws.asmx',
			   'https://w2.backuppay.com/ws/ws.asmx',
			   ],
	'versionForProcessor' => 'BurrellBizSys.com DatacapXml v' . $::VERSION,
	};
    my %d = $me->{'sysStr'}->getTree('com/BurrellBizSys/Lane/Register/Tender/DatacapXml/');
    $me->{$_} = $d{$_} foreach (keys(%d));
    #set some reasonable defaults
$me->{'com/BurrellBizSys/Lane/Register/Tender/DatacapXml/Operator ID Prefix'} = '' if !(exists $me->{'com/BurrellBizSys/Lane/Register/Tender/DatacapXml/Operator ID Prefix'} and defined $me->{'com/BurrellBizSys/Lane/Register/Tender/DatacapXml/Operator ID Prefix'});
	$me->{'com/BurrellBizSys/Lane/Register/Tender/DatacapXml/Merchant ID'} = '494901' if !(exists $me->{'com/BurrellBizSys/Lane/Register/Tender/DatacapXml/Merchant ID'} and defined $me->{'com/BurrellBizSys/Lane/Register/Tender/DatacapXml/Merchant ID'});
    $me->{'com/BurrellBizSys/Lane/Register/Tender/DatacapXml/Password'} = 'xyz' if !(exists $me->{'com/BurrellBizSys/Lane/Register/Tender/DatacapXml/Password'} and defined $me->{'com/BurrellBizSys/Lane/Register/Tender/DatacapXml/Password'});

    bless $me, $class;
    return $me;
}

sub authorize
{
    my ($me, $amt, $sale) = splice @_, 0, 3;

    my %eo = @_;

    $me->error(''); #clears the errors

    my $tranCode = 'Sale';

    #make sure they're trying to authorize a non-zero value
    if($amt == 0 and !(exists $eo{'allowZero'} and defined $eo{'allowZero'} and $eo{'allowZero'}))
    {
	return $me->error('Lane/DisallowZeroSales');
    }
    if($amt < 0)
    {
	$tranCode = 'Return';
	$amt *= -1;
    }
    if(exists $eo{'voiceAuth'} and defined $eo{'voiceAuth'} and $eo{'voiceAuth'})
    {
	$eo{'AuthCode'} = $eo{'voiceAuth'};
	$tranCode = 'VoiceAuth';
    }
    my $msg = $me->message($sale, %eo, 'amt' => $amt, 'tranCode' => $tranCode, 'serviceType' => 'CreditTransaction');
    my $r;
    if($msg)
    {
	$r = $me->sendMessage('CreditTransaction', $msg);
    }
    else
    {	    
	return undef; #internal error
    }
    if(exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /DatacapXml/)
    {
	use Data::Dumper;
	print STDERR Dumper($r);
    }
    if(!defined $r)
    {
	return $me->error('Lane/Misc');
    }
    if(exists $r->{'CmdResponse'} and exists $r->{'CmdResponse'}{'DSIXReturnCode'} and exists $me->{'dsiToLane'}{$r->{'CmdResponse'}{'DSIXReturnCode'}} and $me->{'dsiToLane'}{$r->{'CmdResponse'}{'DSIXReturnCode'}} eq '' and exists $r->{'CmdResponse'}{'CmdStatus'} and $r->{'CmdResponse'}{'CmdStatus'} eq 'Approved')
    {
	$me->{'textResponse'} = $r->{'CmdResponse'}{'TextResponse'};
	#it's authorized
	return $r;
    }
    else
    {
	#it wasn't authorized/approved
	if($r->{'CmdResponse'}{'CmdStatus'} eq 'Error')
	{
	    if(exists $r->{'CmdResponse'}{'DSIXReturnCode'} and exists $me->{'dsiToLane'}{$r->{'CmdResponse'}{'DSIXReturnCode'}})
	    {
		$me->error($me->{'dsiToLane'}{$r->{'CmdResponse'}{'DSIXReturnCode'}});
	    }
	    else
	    {
		$me->error('Lane/Misc');
	    }
	    $me->{'textResponse'} .= "\nCard Services said: " . $r->{'CmdResponse'}{'TextResponse'};
	    return undef;
	    #die 'authorize(): failed to authorize';
	}
	elsif($r->{'CmdResponse'}{'CmdStatus'} eq 'Declined')
	{
	    $me->error('Lane/Declined');
	    $me->{'textResponse'} .= "\nCard Services said: " . $r->{'CmdResponse'}{'TextResponse'};
	    return undef;
	}
	else
	{
	    #not sure what happened
	    return $me->error('Lane/Misc');
	}
    }
}

sub process
{
    my ($me, $amt, $sale) = splice @_, 0, 3;
    return 1;
}

sub cancel
{
    my ($me, $amt, $sale, $response) = splice @_, 0, 4;

    my %eo = @_;

    $me->error('');
    
    #$response needs to contain at least the previous AuthCode
    if(!(exists $response->{'TranResponse'} and exists $response->{'TranResponse'}{'AuthCode'} and defined $response->{'TranResponse'}{'AuthCode'} and exists $response->{'TranResponse'}{'RefNo'} and defined $response->{'TranResponse'}{'RefNo'}))
    {
	return $me->error('Lane/CancelNonExistent');
    }

    $eo{'invNo'} = $response->{'TranResponse'}{'InvoiceNo'} if exists $response->{'TranResponse'} and exists $response->{'TranResponse'}{'InvoiceNo'};

    my $tranCode = 'VoidSale';
    if($amt < 0)
    {
	$tranCode = 'VoidReturn';
	$amt *= -1;
    }

    my $msg = $me->message(
			   $sale, %eo,
			   'amt' => $amt,
			   'tranCode' => $tranCode,
			   'AuthCode' => $response->{'TranResponse'}{'AuthCode'},
			   'RefNo' => $response->{'TranResponse'}{'RefNo'},
			   'serviceType' => 'CreditTransaction'
			   );
    my $r;
    if($msg)
    {

	$r = $me->sendMessage('CreditTransaction', $msg);
    }
    else
    {
	return undef; #internal error, the previous code likely set the error fields
    }
    if(exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /DatacapXml/)
    {
	use Data::Dumper;
	print STDERR Dumper($r);
    }
    if(!defined $r)
    {
	return $me->error('Lane/Misc');
    }
    if(exists $r->{'CmdResponse'} and exists $r->{'CmdResponse'}{'DSIXReturnCode'} and exists $me->{'dsiToLane'}{$r->{'CmdResponse'}{'DSIXReturnCode'}} and $me->{'dsiToLane'}{$r->{'CmdResponse'}{'DSIXReturnCode'}} eq '' and exists $r->{'CmdResponse'}{'CmdStatus'} and ($r->{'CmdResponse'}{'CmdStatus'} eq 'Approved' or $r->{'CmdResponse'}{'CmdStatus'} eq 'Success'))
    {
	$me->{'textResponse'} = $r->{'CmdResponse'}{'TextResponse'};
	#it authorized/succeeded
	return $r;
    }
    else
    {
	#it wasn't authorized/approved
	if($r->{'CmdResponse'}{'CmdStatus'} eq 'Error')
	{
	    if(exists $r->{'CmdResponse'}{'DSIXReturnCode'} and exists $me->{'dsiToLane'}{$r->{'CmdResponse'}{'DSIXReturnCode'}})
	    {
		$me->error($me->{'dsiToLane'}{$r->{'CmdResponse'}{'DSIXReturnCode'}});
	    }
	    else
	    {
		$me->error('Lane/Misc');
	    }
	    $me->{'textResponse'} .= "\nCard Services said: " . $r->{'CmdResponse'}{'TextResponse'};
	    return undef;
	    #die 'authorize(): failed to authorize';
	}
	elsif($r->{'CmdResponse'}{'CmdStatus'} eq 'Declined')
	{
	    $me->error('Lane/Declined');
	    $me->{'textResponse'} .= "\nCard Services said: " . $r->{'CmdResponse'}{'TextResponse'};
	    return undef;
	}
	else
	{
	    #not sure what happened
	    return $me->error('Lane/Misc');
	}
    }
    return 1;
}

sub message
{
    my ($me, $sale) = splice @_, 0, 2;

    my %o = @_;

    #check sale info
    if(!exists $sale->{'id'} or !defined $sale->{'id'} or $sale->{'id'} eq '' or $sale->{'id'} == 0)
    {
	#we need a valid Sale.id
	return $me->error('Lane/MissingSaleId');
    }

    #we can only handle 100 tenders/ticket
    if($#{$sale->{'tenders'}} > 98)
    {
	return $me->error('Lane/UsageError/TooManyTenders');
    }

    #check tranType
    if(exists $o{'tranType'} and !exist $me->{'validType'}{$o{'tranType'}})
    {
	#that isn't a valid type
	return $me->error('Lane/UsageError/TransType');
    }
    #check AuthOnly
    if(exists $o{'tranCode'})
    {
	if(!exists $me->{'validCode'}{$o{'tranCode'}})
	{
	    #that isn't a valid type
	    return $me->error('Lane/UsageError/TransCode');
	}

	if($o{'tranCode'} eq 'Sale' or $o{'tranCode'} eq 'VoidSale' or $o{'tranCode'} eq 'Return' or $o{'tranCode'} eq 'VoidReturn' or $o{'tranCode'} eq 'VoiceAuth')
	{
	    if($o{'serviceType'} eq 'CreditTransaction')
	    {
		$o{'tranType'} = 'Credit';
	    }
	    else
	    {
		return $me->error('Lane/UsageError/ServiceType');
	    }
	}
    }
    #check account info
    #make sure we were supplied either a track2 or an acct with expDate
    $o{'useVerification'} = 0;
    if(exists $o{'track2'} and defined $o{'track2'} and length($o{'track2'}))
    {
	$o{'cardData'} = '<Account><Track2>' . substr($o{'track2'}, 0, 37) . '</Track2></Account>';	
    }    
    elsif((exists $o{'acct'} and defined $o{'acct'} and length($o{'acct'})) and (exists $o{'expDate'} and defined $o{'expDate'} and length($o{'expDate'})))	
    {
	return $me->error('Lane/UsageError') if !($o{'expDate'} =~ /^\d{2}(\d{2})-(\d{2})$/);
	
	$o{'cardData'} = '<Account><AcctNo>' . substr($o{'acct'}, 0, 19) . '</AcctNo><ExpDate>' . "$2$1" . '</ExpDate></Account>';	
	$o{'useVerification'} = 1;
    }
    else
    {
	return $me->error('Lane/UsageError');	
    }
    if($o{'useVerification'})
    {
	$o{'verification'} = '<AVS>';
	if(exists $o{'address'})
	{
	    if($o{'address'} =~ m/^\D*(\d+)/)
	    {
		$o{'verification'} .= '<Address>' . substr($1, 0, 8) . '</Address>';
	    }
	}
	if(exists $o{'zip'})
	{
	    $o{'zip'} = substr("$1$3", 0, 9) if($o{'zip'} =~ m/^(\d{5})(-(\d{4}))?$/);
	}
	$o{'verification'} .= '</AVS>';
	delete $o{'verification'} if $o{'verification'} eq '<AVS></AVS>';
	if(exists $o{'cvv'})
	{
	    if($o{'cvv'} =~ m/^(\d{3,4})$/)
	    {
		$o{'verification'} .= '<CVVData>' . substr($1, 0, 4) . '</CVVData>';
	    }
	    elsif($o{'cvv'} =~ /^(None|Illegible)$/)
	    {
		$o{'verification'} .= '<CVVData>' . $1 . '</CVVData>';
	    }
	}
    }
    my $invNo = $sale->{'id'} . sprintf('%.2d', $#{$sale->{'tenders'}} + 1);
    $invNo = $o{'invNo'} if exists $o{'invNo'} and defined $o{'invNo'} and $o{'invNo'} > 0;
    my $extAmt = substr((exists $o{'amt'} ? $me->{'lc'}->extFmt($o{'amt'}) : 0), 0, 8);
    my $extTax = substr((exists $sale->{'allTaxes'} ? $me->{'lc'}->extFmt($sale->{'allTaxes'}) : 0.00), 0, 8);
    return '<?xml version=\'1.0\' encoding=\'US-ASCII\'?>
<TStream>
<Transaction>
<MerchantID>' . substr($me->{'com/BurrellBizSys/Lane/Register/Tender/DatacapXml/Merchant ID'}, 0, 24) . '</MerchantID>' .
(exists $me->{'com/BurrellBizSys/Lane/Register/Tender/DatacapXml/Terminal ID'} ? '<TerminalID>' . substr($me->{'com/BurrellBizSys/Lane/Register/Tender/DatacapXml/Terminal ID'}, 0, 24) . '</TerminalID>': '' ) .
'<OperatorID>' . substr($me->{'com/BurrellBizSys/Lane/Register/Tender/DatacapXml/Operator ID Prefix'} . $sale->{'clerk'}, 0, 20) . '</OperatorID>' .
(exists $o{'tranType'} ? '<TranType>' . $o{'tranType'} . '</TranType>' : '' ) .
'<TranCode>' . $o{'tranCode'} . '</TranCode>' .
(exists $o{'duplicateOverride'} ? '<Duplicate>Override</Duplicate>' : '') . '
<InvoiceNo>' . substr($invNo, 0, 16) . '</InvoiceNo>
<RefNo>' . substr(exists $o{'RefNo'} ? $o{'RefNo'} : $invNo, 0, 16) . '</RefNo>
<Memo>' . $me->{'versionForProcessor'} . '</Memo>
' . $o{'cardData'} .
(exists $o{'amt'} ? '
<Amount><Purchase>' . $extAmt . '</Purchase><Tax>' . $extTax . '</Tax></Amount>' : '') .
(exists $o{'verification'} ? $o{'verification'} : '') . '
<TerminalName>' . substr($sale->{'terminal'}, 0, 20) . '</TerminalName>
' . '<TranInfo>' . (exists $o{'AuthCode'} ? '<AuthCode>' . substr($o{'AuthCode'}, 0, 16) . '</AuthCode>': '') . '<CustomerCode>' . $sale->{'id'} . '</CustomerCode></TranInfo>' . '
</Transaction>
</TStream>
';
}

sub error
{
    my ($me, $error) = @_;

    if(exists $me->{'error'}{$error})
    {
	$me->{'errorResponse'} = $error;
	$me->{'textResponse'} = $me->{'error'}{$error};
    }
    return undef;
}

sub sendMessage
{
    my ($me, $type, $msg) = @_;
#    die "sendMessage($type, $msg): died";

    warn "DatacapXml::sendMessage($type, $msg)\n" if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /DatacapXml/;
    #we only support CreditTransaction
    if($type ne 'CreditTransaction')
    {
	return $me->error('Lane/UsageError/ServiceType');
    }

    my $s;
    my $success;

    #->on_action(sub {join('',@_);})
    my $r;
    for(my $currentProxy = 0; $currentProxy <= $#{$me->{'serviceProxy'}} and !defined $success; $currentProxy++)
    {
	#->on_fault(sub{die 'soap fault';})
	$success = eval { #catch soap faults
	    $s = SOAP::Lite->service($me->{'serviceProxy'}[$currentProxy] . '?WSDL');
	    $r = $s
		->on_action(sub {join('/',@_);})
		->uri($me->{'uri'}[$currentProxy])
		->proxy($me->{'serviceProxy'}[$currentProxy])
		->call(
		       SOAP::Data->name($type)->attr({xmlns => $me->{'uri'}[$currentProxy]}),
		       SOAP::Data->name('tran' => $msg),
		       SOAP::Data->name('pw' => $me->{'com/BurrellBizSys/Lane/Register/Tender/DatacapXml/Password'}),
		       );
	};
    }
    if($@)
    {
	warn "DatacapXml::sendMessage(): failed. eval said ($success) [$@]\n" if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /DatacapXml/;
	return $me->error('Lane/MiscError');
    }
    #what do i do with the result?
    my $rtn;
    my $raw = $r->result;
    $rtn = $me->{'xs'}->XMLin($raw);
    $rtn->{'_raw'} = $raw;
    return $rtn;
}

1;
