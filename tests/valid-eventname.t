#!/usr/bin/perl -wn

#valid-eventname.t
#Copyright 2004 Jason Burrell.
#This file is part of L'anePOS. See the top-level COPYING for licensing info.

#$Id: valid-eventname.t 1040 2009-03-08 21:16:17Z jason $

if(/^(([a-z]|[0-9]|[-\.,])+\/)+([a-z]|[0-9]|[-\.,])+(#(([a-z]|[0-9]|[-\.,])+(=([a-z]|[0-9]|[-\.,])+)?)(&([a-z]|[0-9]|[-\.,])+(=([a-z]|[0-9]|[-\.,])+)?)*)?$/i)
{
    print "valid eventname";
    if(/^[^\/]*l.?ane[^\/]*\//i)
    {
	print " (but RESERVED see http://tasks.l-ane.net/show_bug.cgi?id=6 )";
    }
    print "\n";
}
else
{
    print "INVALID eventname (see http://tasks.l-ane.net/show_bug.cgi?id=6 )\n";
}
