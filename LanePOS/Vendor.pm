#Vendor.pm
#Copyright 2004-2010 Jason Burrell.
#Perl Module for vendors info access
#part of L'ane BMS

#$Id: Vendor.pm 1132 2010-09-19 21:36:50Z jason $

package LanePOS::Vendor;

require 5.008;

use base 'LanePOS::Customer';

sub new
{
    my ($class, $dal) = @_;
    $class = ref($class) || $class || 'LanePOS::Vendor';
    my $me = $class->SUPER::new($dal);
    
    $me->{'table'} = 'vendors';

    return $me;
}

1;
