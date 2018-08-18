--locale-dataset-fr.sql
--Copyright 2003-2010 Jason Burrell
--This file is part of L'ânePOS. See COPYING.

--LaneLocale: c (implied POSIX English), en (Generic English), en-US (English in the United States), en-CA (English in Canada), en-IE (English in Ireland), en-AU (English in Australia), en-NZ (English in New Zealand), en-UK (English in the United Kingdom), en-ZA (English in South Africa), en-IN (English in India)

--English Locale Dataset
--These are the various English locales.
--At the moment, these locales only specify currency information.
--$Id: locale-dataset-en.sql 1197 2010-10-24 18:23:51Z jason $

--This file was created based on information available via the Internet.
--Thus, some information contained here has not been verified by native
--speakers. Caveat emptor.

--The included locales:
--en-US: United States: $1,234.56
--en-CA: Canada (English): $1,234.56
--en-IE: Ireland (English): ¤1 234.56
--en-AU: Australia: $1 234.56
--en-NZ: New Zealand: $1,234.56
--en-UK: United Kingdom: £1,234.56
--en-ZA: South Africa (English): R 1 234.56
--en-IN: India (English): Rs.1234.56

--Rumor has it that other people speak English too. ;)

--LATIN9 = ISO-8559-15
\encoding LATIN9

BEGIN;

delete from locale where lower(lang)=lower('en-US') or lower(lang)=lower('en-CA') or lower(lang)=lower('en-IE') or lower(lang)=lower('en-AU') or lower(lang)=lower('en-NZ') or lower(lang)=lower('en-UK') or lower(lang)=lower('en-ZA') or lower(lang)=lower('en-IN');

COPY "locale" FROM stdin;
en-US	locale-data-version	$Id: locale-dataset-en.sql 1197 2010-10-24 18:23:51Z jason $
en-US	locale-data-name	English in the United States Locale
en-US	Lane/Locale/Money/CurrencyCode	USD
en-US	Lane/Locale/Money/GroupingDigits	3
en-US	Lane/Locale/Money/GroupingSeparator	,
en-US	Lane/Locale/Money/DecimalSeparator	.
en-US	Lane/Locale/Money/DecimalDigits	2
en-US	Lane/Locale/Money/Prefix	$
en-US	Lane/Locale/Money/Suffix	
en-US	Lane/Locale/Money/Negative/GroupingDigits	3
en-US	Lane/Locale/Money/Negative/GroupingSeparator	,
en-US	Lane/Locale/Money/Negative/DecimalSeparator	.
en-US	Lane/Locale/Money/Negative/Prefix	-$
en-US	Lane/Locale/Money/Negative/Suffix	
en-US	Lane/Locale/Temporal/ShortTimestamp	%m-%d-%Y %l:%M%p
en-US	Lane/Locale/Temporal/LongTimestamp	%A, %B %e, %Y %l:%M%p
en-US	Lane/Locale/Temporal/ShortTime	%l:%M%p
en-US	Lane/Locale/Temporal/LongTime	%l:%M%p
en-US	Lane/Locale/Temporal/ShortDate	%m-%d-%Y
en-US	Lane/Locale/Temporal/LongDate	%A, %B %e, %Y
en-CA	locale-data-version	$Id: locale-dataset-en.sql 1197 2010-10-24 18:23:51Z jason $
en-CA	locale-data-name	English in Canada Locale
en-CA	Lane/Locale/Money/CurrencyCode	CAD
en-CA	Lane/Locale/Money/GroupingDigits	3
en-CA	Lane/Locale/Money/GroupingSeparator	,
en-CA	Lane/Locale/Money/DecimalSeparator	.
en-CA	Lane/Locale/Money/DecimalDigits	2
en-CA	Lane/Locale/Money/Prefix	$
en-CA	Lane/Locale/Money/Suffix	
en-CA	Lane/Locale/Money/Negative/GroupingDigits	3
en-CA	Lane/Locale/Money/Negative/GroupingSeparator	,
en-CA	Lane/Locale/Money/Negative/DecimalSeparator	.
en-CA	Lane/Locale/Money/Negative/Prefix	-$
en-CA	Lane/Locale/Money/Negative/Suffix	
en-CA	Lane/Locale/Temporal/ShortTimestamp	%m-%d-%Y %l:%M%p
en-CA	Lane/Locale/Temporal/LongTimestamp	%A, %B %e, %Y %l:%M%p
en-CA	Lane/Locale/Temporal/ShortTime	%l:%M%p
en-CA	Lane/Locale/Temporal/LongTime	%l:%M%p
en-CA	Lane/Locale/Temporal/ShortDate	%m-%d-%Y
en-CA	Lane/Locale/Temporal/LongDate	%A, %B %e, %Y
en-AU	locale-data-version	$Id: locale-dataset-en.sql 1197 2010-10-24 18:23:51Z jason $
en-AU	locale-data-name	English in Australia Locale
en-AU	Lane/Locale/Money/CurrencyCode	AUD
en-AU	Lane/Locale/Money/GroupingDigits	3
en-AU	Lane/Locale/Money/GroupingSeparator	 
en-AU	Lane/Locale/Money/DecimalSeparator	.
en-AU	Lane/Locale/Money/DecimalDigits	2
en-AU	Lane/Locale/Money/Prefix	$
en-AU	Lane/Locale/Money/Suffix	
en-AU	Lane/Locale/Money/Negative/GroupingDigits	3
en-AU	Lane/Locale/Money/Negative/GroupingSeparator	 
en-AU	Lane/Locale/Money/Negative/DecimalSeparator	.
en-AU	Lane/Locale/Money/Negative/Prefix	-$
en-AU	Lane/Locale/Money/Negative/Suffix	
en-IE	locale-data-version	$Id: locale-dataset-en.sql 1197 2010-10-24 18:23:51Z jason $
en-IE	locale-data-name	English in Ireland Locale
en-IE	Lane/Locale/Money/CurrencyCode	EUR
en-IE	Lane/Locale/Money/GroupingDigits	3
en-IE	Lane/Locale/Money/GroupingSeparator	 
en-IE	Lane/Locale/Money/DecimalSeparator	.
en-IE	Lane/Locale/Money/DecimalDigits	2
en-IE	Lane/Locale/Money/Prefix	¤
en-IE	Lane/Locale/Money/Suffix	
en-IE	Lane/Locale/Money/Negative/GroupingDigits	3
en-IE	Lane/Locale/Money/Negative/GroupingSeparator	 
en-IE	Lane/Locale/Money/Negative/DecimalSeparator	.
en-IE	Lane/Locale/Money/Negative/Prefix	-¤
en-IE	Lane/Locale/Money/Negative/Suffix	
en-NZ	locale-data-version	$Id: locale-dataset-en.sql 1197 2010-10-24 18:23:51Z jason $
en-NZ	locale-data-name	English in New Zealand Locale
en-NZ	Lane/Locale/Money/CurrencyCode	NZD
en-NZ	Lane/Locale/Money/GroupingDigits	3
en-NZ	Lane/Locale/Money/GroupingSeparator	,
en-NZ	Lane/Locale/Money/DecimalSeparator	.
en-NZ	Lane/Locale/Money/DecimalDigits	2
en-NZ	Lane/Locale/Money/Prefix	$
en-NZ	Lane/Locale/Money/Suffix	
en-NZ	Lane/Locale/Money/Negative/GroupingDigits	3
en-NZ	Lane/Locale/Money/Negative/GroupingSeparator	,
en-NZ	Lane/Locale/Money/Negative/DecimalSeparator	.
en-NZ	Lane/Locale/Money/Negative/Prefix	-$
en-NZ	Lane/Locale/Money/Negative/Suffix	
en-UK	locale-data-version	$Id: locale-dataset-en.sql 1197 2010-10-24 18:23:51Z jason $
en-UK	locale-data-name	English in the United Kingdom Locale
en-UK	Lane/Locale/Money/CurrencyCode	GBP
en-UK	Lane/Locale/Money/GroupingDigits	3
en-UK	Lane/Locale/Money/GroupingSeparator	,
en-UK	Lane/Locale/Money/DecimalSeparator	.
en-UK	Lane/Locale/Money/DecimalDigits	2
en-UK	Lane/Locale/Money/Prefix	£
en-UK	Lane/Locale/Money/Suffix	
en-UK	Lane/Locale/Money/Negative/GroupingDigits	3
en-UK	Lane/Locale/Money/Negative/GroupingSeparator	,
en-UK	Lane/Locale/Money/Negative/DecimalSeparator	.
en-UK	Lane/Locale/Money/Negative/Prefix	-£
en-UK	Lane/Locale/Money/Negative/Suffix	
en-ZA	locale-data-version	$Id: locale-dataset-en.sql 1197 2010-10-24 18:23:51Z jason $
en-ZA	locale-data-name	English in South Africa Locale
en-ZA	Lane/Locale/Money/CurrencyCode	ZAR
en-ZA	Lane/Locale/Money/GroupingDigits	3
en-ZA	Lane/Locale/Money/GroupingSeparator	 
en-ZA	Lane/Locale/Money/DecimalSeparator	.
en-ZA	Lane/Locale/Money/DecimalDigits	2
en-ZA	Lane/Locale/Money/Prefix	R
en-ZA	Lane/Locale/Money/Suffix	
en-ZA	Lane/Locale/Money/Negative/GroupingDigits	3
en-ZA	Lane/Locale/Money/Negative/GroupingSeparator	 
en-ZA	Lane/Locale/Money/Negative/DecimalSeparator	.
en-ZA	Lane/Locale/Money/Negative/Prefix	-R
en-ZA	Lane/Locale/Money/Negative/Suffix	
en-IN	locale-data-version	$Id: locale-dataset-en.sql 1197 2010-10-24 18:23:51Z jason $
en-IN	locale-data-name	English in India Locale
en-IN	Lane/Locale/Money/CurrencyCode	INR
en-IN	Lane/Locale/Money/GroupingDigits	3
en-IN	Lane/Locale/Money/GroupingSeparator	
en-IN	Lane/Locale/Money/DecimalSeparator	.
en-IN	Lane/Locale/Money/DecimalDigits	2
en-IN	Lane/Locale/Money/Prefix	Rs.
en-IN	Lane/Locale/Money/Suffix	
en-IN	Lane/Locale/Money/Negative/GroupingDigits	3
en-IN	Lane/Locale/Money/Negative/GroupingSeparator	
en-IN	Lane/Locale/Money/Negative/DecimalSeparator	.
en-IN	Lane/Locale/Money/Negative/Prefix	-Rs.
en-IN	Lane/Locale/Money/Negative/Suffix	
\.

COMMIT;
