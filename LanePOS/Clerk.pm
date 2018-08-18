#Clerk.pm
#This file is part of LanePOS.
#Copyright 2003-2010 Jason Burrell, portions Copyright 2000-2002 Burrell Business Systems
#See ../COPYING for licensing information

#$Id: Clerk.pm 1132 2010-09-19 21:36:50Z jason $

package LanePOS::Clerk;

require 5.008;
use base 'LanePOS::GenericObject';

sub new
{
    my ($class, $dal) = @_;
    $class = ref($class) || $class || 'LanePOS::Clerk';
    my $me = $class->SUPER::new($dal);
    
    $me->{'table'} = 'clerks';
    $me->{'columns'} = [
        'id',
        'name',
        'passcode',
        'drawer',
        'voidAt',
        'voidBy',
        'created',
        'createdBy',
        'modified',
        'modifiedBy',
        ];
    $me->{'keys'} = ['id'];
    $me->{'revisioned'} = 1;

    return $me;
}

sub _resetFlds
{
    my ($me) = @_;
    $me->SUPER::_resetFlds();
    #we don't need this anymore
    #$me->{'passcode'} = '-Don\'t Authorize-';
    $me->{'drawer'} = 0; #the default undef would probably work too, but this might rid us of some warnings
}

sub open
{
    my $me = shift;

    #we need to catch potential dies from our ancestors' code so legacy code won't bork
    my $r;
    eval {
        $r = $me->SUPER::open(@_);
    };
    if($@)
    {
        return undef;
    }
    return $r;
}

sub authenticate
{
    my ($me, $pass) = @_;

    return 1 if defined($me->{'passcode'}) and $me->{'passcode'} == $pass;
    return 0;
}

1;
