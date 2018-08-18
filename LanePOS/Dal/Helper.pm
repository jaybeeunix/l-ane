#Helper.pm
#This file is part of L'ane. Copyright 2009 Jason Burrell.
#See COPYING for licensing information.

#a base class for all Dal Helpers
package LanePOS::Dal::Helper;

require 5.008;
use LanePOS::Dal;

sub new
{
    my ($class, $dal, %opts) = @_;

    $class = ref($class) || $class || 'LanePOS::Dal::Helper';

    #don't autovivify it, just die
    die $class . "::new: \$dal must be a Dal object!\n" if !UNIVERSAL::isa($dal, 'LanePOS::Dal');

    my $me = {'dal' => $dal};

    foreach my $k (keys %opts)
    {
        $me->{$k} = $opts{$k};
    }

    bless $me, $class;
    return $me;
}

1;
