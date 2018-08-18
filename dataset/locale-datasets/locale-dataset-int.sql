--locale-dataset-int.sql
--copyright 2003-2010 Jason Burrell
--This file is part of L'anePOS. See COPYING.

--These are the various international formats (at the moment, they are only
--euro currency formats).
--To select one, specify the 'int-EURO...' BEFORE your locale in LaneLang.
--For example: LaneLang='int-EURO.REVISO,fr-FR,fr'

--The Euro-zone locales should use the 'int-EURO' format as their default.

--'int-EURO' is the "standard" euro symbol via ISO8859-15 or Unicode: ¤1 234.56
--'int-EURO.ISO' is an ASCII-only version of the ISO currency code: 1 234.56 EUR
--'int-EURO.REVISO' is an ASCII-only version of the ISO currency code, reversed from the standard: EUR 1 234.56

--LATIN9 = ISO-8559-15
\encoding LATIN9

BEGIN;

delete from locale where lower(lang)=lower('int-EURO') or lower(lang)=lower('int-EURO.ISO') or lower(lang)=lower('int-EURO.REVISO');

COPY "locale" FROM stdin;
int-EURO	locale-data-version	$Id: locale-dataset-int.sql 1193 2010-10-22 21:10:11Z jason $
int-EURO	locale-data-name	Standard Euro-Overlay Locale
int-EURO	Lane/Locale/Money/CurrencyCode	EUR
int-EURO	Lane/Locale/Money/GroupingDigits	3
int-EURO	Lane/Locale/Money/GroupingSeparator	 
int-EURO	Lane/Locale/Money/DecimalSeparator	.
int-EURO	Lane/Locale/Money/DecimalDigits	2
int-EURO	Lane/Locale/Money/Prefix	¤ 
int-EURO	Lane/Locale/Money/Suffix	
int-EURO	Lane/Locale/Money/Negative/GroupingDigits	3
int-EURO	Lane/Locale/Money/Negative/GroupingSeparator	 
int-EURO	Lane/Locale/Money/Negative/DecimalSeparator	.
int-EURO	Lane/Locale/Money/Negative/Prefix	-¤ 
int-EURO	Lane/Locale/Money/Negative/Suffix	
int-EURO.ISO	locale-data-version	$Id: locale-dataset-int.sql 1193 2010-10-22 21:10:11Z jason $
int-EURO.ISO	locale-data-name	ISO Euro-Overlay Locale
int-EURO.ISO	Lane/Locale/Money/CurrencyCode	EUR
int-EURO.ISO	Lane/Locale/Money/GroupingDigits	3
int-EURO.ISO	Lane/Locale/Money/GroupingSeparator	 
int-EURO.ISO	Lane/Locale/Money/DecimalSeparator	.
int-EURO.ISO	Lane/Locale/Money/DecimalDigits	2
int-EURO.ISO	Lane/Locale/Money/Prefix	
int-EURO.ISO	Lane/Locale/Money/Suffix	 EUR
int-EURO.ISO	Lane/Locale/Money/Negative/GroupingDigits	3
int-EURO.ISO	Lane/Locale/Money/Negative/GroupingSeparator	 
int-EURO.ISO	Lane/Locale/Money/Negative/DecimalSeparator	.
int-EURO.ISO	Lane/Locale/Money/Negative/Prefix	-
int-EURO.ISO	Lane/Locale/Money/Negative/Suffix	 EUR
int-EURO.REVISO	locale-data-version	$Id: locale-dataset-int.sql 1193 2010-10-22 21:10:11Z jason $
int-EURO.REVISO	locale-data-name	Reversed ISO Euro-Overlay Locale
int-EURO.REVISO	Lane/Locale/Money/CurrencyCode	EUR
int-EURO.REVISO	Lane/Locale/Money/GroupingDigits	3
int-EURO.REVISO	Lane/Locale/Money/GroupingSeparator	 
int-EURO.REVISO	Lane/Locale/Money/DecimalSeparator	.
int-EURO.REVISO	Lane/Locale/Money/DecimalDigits	2
int-EURO.REVISO	Lane/Locale/Money/Prefix	EUR 
int-EURO.REVISO	Lane/Locale/Money/Suffix	
int-EURO.REVISO	Lane/Locale/Money/Negative/GroupingDigits	3
int-EURO.REVISO	Lane/Locale/Money/Negative/GroupingSeparator	 
int-EURO.REVISO	Lane/Locale/Money/Negative/DecimalSeparator	.
int-EURO.REVISO	Lane/Locale/Money/Negative/Prefix	-EUR 
int-EURO.REVISO	Lane/Locale/Money/Negative/Suffix	
\.

COMMIT;
