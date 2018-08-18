#!/usr/bin/perl -w

#LaneRoot/config/init.pl
#Copyright 2004-2010 Jason Burrell
#This file is part of the L'anePOS. See COPYING.

#this file isn't executed directly (hence no +x mode)
#$Id: init.pl 1166 2010-09-30 16:53:09Z jason $

######################################################
# MAKE SITE-SPECIFIC CHANGES IN site.pl, NOT HERE!!! #
######################################################

#programs should include the following:
###

#BEGIN {
#    use FindBin;
#    use File::Spec;
#    $ENV{'LaneRoot'} = File::Spec->catdir($FindBin::Bin, $File::Spec->updir, $File::Spec->updir); #use the correct number of updirs
#    require File::Spec->catfile($ENV{'LaneRoot'}, 'config', 'init.pl');
#}

###end of include

require 5.008;

#LaneRoot should be set before requiring this file, but just in case...
BEGIN {
    if(!exists $ENV{'LaneRoot'} or !$ENV{'LaneRoot'}) #demorgan is fun
    {
#    use FindBin;
#    use File::Spec;
#    $ENV{'LaneRoot'} = File::Spec->catdir($FindBin::Bin, File::Spec->updir);
#    require File::Spec->catfile($ENV{'LaneRoot'}, 'config', 'init.pl');
	
#I don't think that would have worked (how do we determine the number of updirs
#since it's running in the program's perl-space?) so...
	die "You need to set \$ENV{'LaneRoot'} before requiring \"config/init.pl\" (see the top of that file for a sample)";
    }
}

use File::Spec;
#LaneRoot cleanup/check
{
    my $oldRoot = $ENV{'LaneRoot'};
    $ENV{'LaneRoot'} = cleanupPath($ENV{'LaneRoot'});
    #see if the new LaneRoot exists and is a directory
    $ENV{'LaneRoot'} = $oldRoot if !(-r $ENV{'LaneRoot'} and -d $ENV{'LaneRoot'});
    #while we're at it, check the given LaneRoot
    die 'your $ENV{\'LaneRoot\'} ' . $ENV{'LaneRoot'} . ' does not exist or you lack read permission on it' if !(-r $ENV{'LaneRoot'} and -d $ENV{'LaneRoot'});
};

require lib;

import lib $ENV{'LaneRoot'};
import lib File::Spec->catdir($ENV{'LaneRoot'}, 'site-perl', 'lib'); #this is where our non-lane stuff lives
#this block was a simple 'use lib ...'
{
    use Config;
    foreach (reverse(split(/\s+/, $Config{'inc_version_list'})), $Config{'version'})
    {
	my $d = File::Spec->catdir($ENV{'LaneRoot'}, 'site-perl', 'lib', 'perl5', $_);
	-r $d ? import lib $d : exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /init\.pl/ and print STDERR "init.pl: no such readable directory $d\n";
	$d = File::Spec->catdir($ENV{'LaneRoot'}, 'site-perl', 'lib', 'perl5', 'site_perl', $_);
	-r $d ? import lib $d : exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /init\.pl/ and print STDERR "init.pl: no such readable directory $d\n";
	$d = File::Spec->catdir($ENV{'LaneRoot'}, 'site-perl', 'lib', 'site_perl', $_);
	-r $d ? import lib $d : exists $ENV{'LaneDebug'} and $ENV{'LaneDebug'} =~ /init\.pl/ and print STDERR "init.pl: no such readable directory $d\n";
	#import lib $d if -r $d; # : print STDERR "init.pl: no such readable directory $d\n";
    }
};

my $site;
if(exists $ENV{'LaneSiteConf'} and $ENV{'LaneSiteConf'} and -r $ENV{'LaneSiteConf'} and -s $ENV{'LaneSiteConf'})
{
    $site = $ENV{'LaneSiteConf'};
}
else
{
    $site = File::Spec->catfile($ENV{'LaneRoot'}, 'config', 'site.pl');
}

if(-r $site and -s $site)
{
    #we removed the old paranoia, as you may want to set regular env vars in the lane config
    #ie LANG, LANGUAGE
    #the site file exists, use it
    require $site;
}

#allow the homedir site.pl to override the main site.pl
my $homeSite = "$ENV{HOME}/.l-ane-site-conf.pl";
if(-r $homeSite and -s $homeSite)
{
    require $homeSite;
}

#force everyone into utf8
#delete $ENV{'PGCLIENTENCODING'};
$ENV{'PGCLIENTENCODING'} = 'UTF8';

sub cleanupPath
{
    #this probably won't work on vms or other very non-unix-like systems
    #interestingly, DOS based systems (like Windows) should work, as they
    #use a unix-like "updir"
    my @p = File::Spec->splitdir($_[0]);
    my $up = File::Spec->updir;
    my $ups = 0;
    foreach (reverse(@p))
    {
	if($_ eq $up)
	{
	    $ups++;
	    pop @p;
	}
	else
	{
	    last;
	}
    }
    pop @p foreach (1..$ups);
    return File::Spec->catdir(@p);
}

#platform specific code (in cvs) goes here
#this section isn't for site-platform-specific data, use site.pl

#if($^O eq '')
#{
#}
#elsif($^O eq '')
#{
#}
#no else, as good platforms don't need any special help

1;
