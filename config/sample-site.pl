#/usr/bin/perl -w

#cp this file to "LanePOS/config" as "site.pl"
#and edit it to fit your site's needs

#based on cvs $Id: sample-site.pl 1040 2009-03-08 21:16:17Z jason $

#######################################################
#options                                              #
#######################################################
#LaneDSN is the datasource name: the database and database server info
$ENV{'LaneDSN'} = 'dbname=lanedemo'; #for POS/BMS

#LaneLang is the list of locales, from most desirable to least
$ENV{'LaneLang'} = 'int-EURO.REVISO,en-IE,en-UK,en-US,en,c'; #Ireland (English) with a reversed ISO euro

#LaneDebug enables debugging output
#$ENV{'LaneDebug'} = 'moneyFmt()';

#######################################################
#other examples                                       #
#######################################################
#$ENV{'LaneDSN'} = 'pg:///lanedemo'; # for NextGen
#$ENV{'LaneDSN'} = 'dbname=lanedemo host=dbserver.you.tld port=5432 options="otherstuff"'; #for POS/BMS
#$ENV{'LaneDSN'} = 'pg://otheruser@dbserver.you.tld:5432/lanedemo?otherstuff'; # for NextGen

