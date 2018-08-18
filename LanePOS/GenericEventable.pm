#L'anePOS Perl Module
#GenericEventable.pm
#Copyright 2008-2010 Jason Burrell.
#See ../COPYING for licensing information

=pod

=head1 NAME

LanePOS/GenericEventable.pm  LE<8217>E<acirc>neE<8217>s Event Manager class


=head1 SYNOPSIS

LanePOS::GenericEventable

=head1 DESCRIPTION

B<GenericEventable> provides basic support for events in LE<8217>E<acirc>ne applications

=head1 USAGE

B<GenericEventable> is used by any application which needs an event manager

=head1 SUBROUTINES

=over

=item initEvents

Initializes the event system.

=item registerEvent(name, coderef)

Register (add) and event to the end of the handler queue

=item preregisterEvent(name, coderef)

Register (add) and event to the beginning of the handler queue

=item triggerEvent(name)

Trigger the event C<name>

=back

=head1 EVENTS

=over

=item Lane/CORE/Reload Config

Reload the configuration information. By default, this event is triggered by SIGHUP.

=back

=head1 AUTHOR

Jason Burrell

=head1 BUGS

=over

=item *

There are no known bugs in this class.

=item * 

See L<http://tasks.l-ane.net/show_bug.cgi?id=1321>.

=back

=head1 SEE ALSO

The LE<8217>E<acirc>ne Website L<http://l-ane.net/>

L<http://wiki.l-ane.net/wiki/Events>

=cut

package LanePOS::GenericEventable;

require 5.008;
use strict;

$::VERSION = (q$Revision: 1207 $ =~ /(\d+)/)[0];

sub initEvents
{
    #this sub initialized the event system
    #see http://wiki.l-ane.net/wiki/Events for the names of standardized events
    #other events should be in Javaesque namespace, for example
    #if i (jb) were creating an event "myEvent" the event would be: com/Ryotous/Lane/myEvent
    #standard events are in one of these event namespaces:
    #Lane/CORE/
    #Lane/MODULE/ (where MODULE is the class name, ie: Register, Customer)
    #net/L-ane/
    #net/SourceForge/L-ane/

    my ($me) = @_;

    my $r = 1;
    #initEvents destroys the events handlers, so you should NEVER call this sub
    #(let Register::new() handle it)
    $me->{'events'} = {};

    #load the default events
    $r &&= $me->registerEvent('Lane/CORE/Reload Config', sub {
        warn "Lane/CORE/Reload Config: reload event\n" if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /GenericEventable/;
        use File::Spec;
        #NOTICE: This only reloads *site.pl* not the entire *init.pl*, so changing things like LaneRoot won't work.
        my $file = File::Spec->catfile($ENV{'LaneRoot'}, 'config', 'site.pl');
        do $file;
        warn "Lane/CORE/Reload Config: LaneDSN is now $ENV{'LaneDSN'}\n" if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /GenericEventable/;
                       });
    $r &&= eval {
	my $code = sub { $me->triggerEvent('Lane/CORE/Reload Config'); };
	my $existing = $SIG{'HUP'};

	if($existing)
	{
	    $SIG{'HUP'} = sub { &$existing; &$code; }
	}
	else
	{
	    $SIG{'HUP'} = $code;
	}
    };

    #insert support for plugins here@@@@
    return $r;
}

sub registerEvent
{
    #this sub adds a sub ref to the event handler queue
    #these events are ALWAYS called (this method isn't for single-run events)
    my ($me, $event, $code) = @_;
    return undef if ref($code) ne 'CODE'; #don't put things in there that will fail
    return push(@{$me->{'events'}{$event}}, $code);
}

sub preregisterEvent
{
    my ($me, $event, $code) = @_;
    return unshift(@{$me->{'events'}{$event}}, $code);
}

sub triggerEvent
{
    my ($me, $event) = splice @_, 0, 2;
    my @r = eval
    {
	#NOTE!NOTE!NOTE!NOTE!NOTE!NOTE!NOTE!NOTE!NOTE!NOTE!
	#if a lower-numbered event dies, none of the higher-numbered events will run!
	#NOTE!NOTE!NOTE!NOTE!NOTE!NOTE!NOTE!NOTE!NOTE!NOTE!
	my @innerR;
	if(!exists $me->{'events'}{$event} or !UNIVERSAL::isa($me->{'events'}{$event}, 'ARRAY'))
	{
	    warn "WARNING: GenericEventable::triggerEvent($event): no such event exists!\n";
	    die "$event: no such event\n";
	}
	foreach my $s (@{$me->{'events'}{$event}})
	{
	    @innerR = &$s;
	}
	return @innerR;
    };
    warn ref($me) . '::triggerEvent(', join(', ', $event, @_), ") eval'ed to: $@ [@r]\n" if exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /GenericEventable/;
    return ($@) ? !$@ : @r;
}

1;
