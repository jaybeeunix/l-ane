--locale-dataset-nl.sql
--Copyright 2003-2010 Jason Burrell
--This file is part of L'anePOS. See COPYING.

--LaneLocale: nl (Dutch), nl-NL (Dutch in the Netherlands), nl-BE (Dutch in Belgium)

--this was provided 2002-12-06 by Edwin van Drunen
--  with slight modifications 2003-11-06 by Jason Burrell
--it was updated 2005-09-26 by Edwin van Drunen and Rik Jongerius
--  with slight modifications 2005-09-26 by Jason Burrell (primarily comment and cvs updates)

--This file contains a Dutch translation.

--$Id: locale-dataset-nl.sql 1193 2010-10-22 21:10:11Z jason $

\encoding LATIN9

BEGIN;

DELETE from locale where lower(lang)=lower('nl') or lower(lang)=lower('nl-NL') or lower(lang)=lower('nl-BE');

COPY "locale" FROM stdin;
nl-NL	locale-data-version	$Id: locale-dataset-nl.sql 1193 2010-10-22 21:10:11Z jason $
nl-NL	locale-data-name	Dutch in the Netherlands Locale
nl-NL	Lane/Locale/Money/CurrencyCode	EUR
nl-NL	Lane/Locale/Money/Prefix	 ¤
nl-NL	Lane/Locale/Money/Suffix	
nl-NL	Lane/Locale/Money/GroupingDigits	3
nl-NL	Lane/Locale/Money/GroupingSeparator	.
nl-NL	Lane/Locale/Money/DecimalSeparator	3
nl-NL	Lane/Locale/Money/DecimalDigits	2
nl-NL	Lane/Locale/Money/Negative/Prefix	 -¤
nl-NL	Lane/Locale/Money/Negative/Suffix	
nl-NL	Lane/Locale/Money/Negative/GroupingDigits	3
nl-NL	Lane/Locale/Money/Negative/GroupingSeparator	.
nl-NL	Lane/Locale/Money/Negative/DecimalSeparator	3
nl-BE	locale-data-version	$Id: locale-dataset-nl.sql 1193 2010-10-22 21:10:11Z jason $
nl-BE	locale-data-name	Dutch in Belgium Locale
nl-BE	Lane/Locale/Money/CurrencyCode	EUR
nl-BE	Lane/Locale/Money/Prefix	¤
nl-BE	Lane/Locale/Money/Suffix	
nl-BE	Lane/Locale/Money/GroupingDigits	3
nl-BE	Lane/Locale/Money/GroupingSeparator	.
nl-BE	Lane/Locale/Money/DecimalSeparator	,
nl-BE	Lane/Locale/Money/DecimalDigits	2
nl-BE	Lane/Locale/Money/Negative/Prefix	-¤
nl-BE	Lane/Locale/Money/Negative/Suffix	
nl-BE	Lane/Locale/Money/Negative/GroupingDigits	3
nl-BE	Lane/Locale/Money/Negative/GroupingSeparator	.
nl-BE	Lane/Locale/Money/Negative/DecimalSeparator	,
nl	locale-data-version	$Id: locale-dataset-nl.sql 1193 2010-10-22 21:10:11Z jason $
nl	locale-data-name	Generic Dutch Locale
nl	Lane/Locale/Money/CurrencyCode	EUR
nl	Lane/Locale/Money/Prefix	 ¤
nl	Lane/Locale/Money/Suffix	
nl	Lane/Locale/Money/GroupingDigits	3
nl	Lane/Locale/Money/GroupingSeparator	.
nl	Lane/Locale/Money/DecimalSeparator	,
nl	Lane/Locale/Money/DecimalDigits	2
nl	Lane/Locale/Money/Negative/Prefix	 ¤
nl	Lane/Locale/Money/Negative/Suffix	
nl	Lane/Locale/Money/Negative/GroupingDigits	3
nl	Lane/Locale/Money/Negative/GroupingSeparator	.
nl	Lane/Locale/Money/Negative/DecimalSeparator	,
nl	Lane/GenericObject/ID	ID
nl	Lane/BackOffice/Save Prompt	Deze vermelding is niet opgeslagen. Wilt u een kans de veranderingen op te slaan?\n ('Ja' kiezen annuleert alleen de vorige operatie).
nl	Lane/BackOffice/Remove Prompt	Weet u zeker dat u deze vermelding permanent\n uit de database wilt verwijderen?
nl	Lane/BackOffice/Confirmation	Bevestiging
nl	Lane/BackOffice/Buttons/Yes	Ja
nl	Lane/BackOffice/Buttons/Yes, Remove	Ja, Verwijder
nl	Lane/BackOffice/Buttons/No	Nee
nl	Lane/BackOffice/Buttons/No, Cancel	Nee, Annuleer
nl	Lane/BackOffice/Buttons/No, Discard	Nee, Verwerp
nl	Lane/BackOffice/Buttons/Discard	Verwerp
nl	Lane/BackOffice/Buttons/Cancel	Annuleer
nl	Lane/BackOffice/Buttons/New	Nieuw
nl	Lane/BackOffice/Buttons/Process	Verwerk
nl	Lane/BackOffice/Buttons/Quit	Stop
nl	Lane/BackOffice/Buttons/Remove	Verwijder
nl	Lane/BackOffice/Buttons/Search	Zoek
nl	Lane/BackOffice/Buttons/OK	OK
nl	Lane/BackOffice/Buttons/Add	Voeg toe
nl	Lane/BackOffice/Buttons/View	Bekijk
nl	Lane/BackOffice/Buttons/Print	Print
nl	Lane/BackOffice/Search Results	Zoek resultaten
nl	Lane/BackOffice/Search Results Text	De database heeft de volgende vermeldingen gevonden:
nl	Lane/BackOffice/Notes	Notities
nl	Lane/BackOffice/Select	Selecteer
nl	Lane/BackOffice/Clerks	Verkopers
nl	Lane/BackOffice/Customers	Klanten
nl	Lane/BackOffice/Discounts	Kortingen
nl	Lane/BackOffice/Machines	Machines
nl	Lane/BackOffice/Products	Produkten
nl	Lane/BackOffice/QWO	Werk order
nl	Lane/BackOffice/Strings	Instellingen
nl	Lane/BackOffice/System Strings	Systeem instellingen
nl	Lane/BackOffice/Taxes	Belastingen
nl	Lane/BackOffice/Tenders	Betaalmiddelen
nl	Lane/BackOffice/Terms	Voorwaarden
nl	Lane/BackOffice/Vendors	Leveranciers
nl	Lane/Clerk/Clerk	Verkoper
nl	Lane/Clerk/Name	Naam
nl	Lane/Clerk/Passcode	PIN
nl	Lane/Clerk/Drawer	Lade
nl	Lane/String/Data	Data
nl	Lane/Tax/Description	Omschrijving
nl	Lane/Tax/Amount	Hoeveelheid
nl	Lane/Term/Description	Omschrijving
nl	Lane/Term/Days Until Due	Looptijd in dagen
nl	Lane/Term/Finance Rate	Financiërings tarief
nl	Lane/Term/Days For Discount	Dagen voor korting
nl	Lane/Term/Discount Rate	Kortings tarief
nl	Lane/Tender/Description	Omschrijving
nl	Lane/Tender/Allow Change	Wisselgeld toestaan
nl	Lane/Tender/Mandatory Amount	Verplichte hoeveelheid
nl	Lane/Tender/Open Drawer	Open lade
nl	Lane/Tender/Pays	Betaald
nl	Lane/Tender/eProcess	eProcess
nl	Lane/Tender/eAuthorize	eAuthorize
nl	Lane/Customer/Company Name	Bedrijf
nl	Lane/Customer/Contact Given Name	Contactpersoon voornaam
nl	Lane/Customer/Contact Family Name	Achternaam
nl	Lane/Customer/Billing	Facturering
nl	Lane/Customer/Billing Address 1	Adres
nl	Lane/Customer/Billing Address 2	Adres 2
nl	Lane/Customer/Billing City	Stad
nl	Lane/Customer/Billing State	Staat/Provincie
nl	Lane/Customer/Billing Zip	Postcode
nl	Lane/Customer/Billing Country	Land
nl	Lane/Customer/Billing Phone	Tel.
nl	Lane/Customer/Billing Fax	Fax
nl	Lane/Customer/Shipping	Verzending
nl	Lane/Customer/Same As Billing	Zelfde als facturering
nl	Lane/Customer/Shipping Address 1	Adres
nl	Lane/Customer/Shipping Address 2	Adres 2
nl	Lane/Customer/Shipping City	Stad
nl	Lane/Customer/Shipping State	Staat/Provincie
nl	Lane/Customer/Shipping Zip	Postcode
nl	Lane/Customer/Shipping Country	Land
nl	Lane/Customer/Shipping Phone	Tel.
nl	Lane/Customer/Shipping Fax	Fax
nl	Lane/Customer/Email	e-Mail
nl	Lane/Customer/Accounting	Financiën
nl	Lane/Customer/Account Terms	Voorwaarden
nl	Lane/Customer/Customer Type	Klant type
nl	Lane/Customer/Customer Type/0	Klant type/0
nl	Lane/Customer/Customer Type/1	Klant type/1
nl	Lane/Customer/Customer Type/2	Klant type/2
nl	Lane/Customer/Customer Type/3	Klant type/3
nl	Lane/Customer/Credit Limit	Crediet limiet
nl	Lane/Customer/Balance	Balans
nl	Lane/Customer/Credit Remaining	Bestedingsruimte
nl	Lane/Customer/Last Sale	Laatste verkoop
nl	Lane/Customer/Last Payment	Laatste betaling
nl	Lane/Customer/Search Prompt	Type een deel van de bedrijfsnaam of achternaam van contactpersoon om te zoeken.
nl	Lane/Vendor/Vendor	Leverancier
nl	Lane/Discount/Description	Omschrijving
nl	Lane/Discount/Preset	Bepaald
nl	Lane/Discount/Open	Onbepaald
nl	Lane/Discount/Fixed	Vast bedrag
nl	Lane/Discount/Percent	Percentage
nl	Lane/Discount/Amount	Hoeveelheid
nl	Lane/Discount/Sale	Korting van toepassing op hele verkoop
nl	Lane/Discount/Item	Korting van toepassing op vorige produkt
nl	Lane/Product/Description	Omschrijving
nl	Lane/Product/Price	Prijs
nl	Lane/Product/Category	Categorie
nl	Lane/Product/Taxes	Belastingen
nl	Lane/Product/Type	Type
nl	Lane/Product/Type/Preset	Bepaald
nl	Lane/Product/Type/Open	Onbepaald
nl	Lane/Product/Type/Open Negative	Onbepaald negatief
nl	Lane/Product/Track Quantity	Voorraad beheer
nl	Lane/Product/On Hand	Op voorraad
nl	Lane/Product/Minimum	Minimum
nl	Lane/Product/Reorder	Bijbestellen
nl	Lane/Product/Items Per Case	Aantal per doos
nl	Lane/Product/Case ID	Doos ID
nl	Lane/Product/Vendor	Leverancier
nl	Lane/Product/Extended	Extensie
nl	Lane/Product/Cost	Kosten
nl	Lane/Product/Reorder ID	Bijbestel ID
nl	Lane/Product/Search Prompt	Type een deel van de produktomschrijving om te zoeken
nl	Lane/Machine/Search Prompt	Type een deel van een van de velden om te zoeken naar machines
nl	Lane/Machine/Make	Type
nl	Lane/Machine/Model	Model
nl	Lane/Machine/Serial Number	Serienummer
nl	Lane/Machine/Counter	Tellerstand
nl	Lane/Machine/Accessories	Accessoires
nl	Lane/Machine/Owner	Eigenaar
nl	Lane/Machine/Purchase Date	Aankoop datum
nl	Lane/Machine/Last Service Date	Laatste onderhoud datum
nl	Lane/Machine/Contract	Contract
nl	Lane/Machine/Contract/On Contract	Op contract
nl	Lane/Machine/Contract/Begins	Begint
nl	Lane/Machine/Contract/Ends	Eindigt
nl	Lane/QWO/Machines Owned By	Machines eigendom van
nl	Lane/QWO/Machine Search Prompt	Type een deel van een van de velden om te zoeken naar machines
nl	Lane/QWO/Status	Status
nl	Lane/QWO/Status/Staff	Personeel
nl	Lane/QWO/Status/Contact	Contact
nl	Lane/QWO/Status/0	0
nl	Lane/QWO/Status/1	1
nl	Lane/QWO/Status/2	2
nl	Lane/QWO/Status/3	3
nl	Lane/QWO/Status/4	4
nl	Lane/QWO/Status/5	5
nl	Lane/QWO/Status/6	6
nl	Lane/QWO/Status/7	7
nl	Lane/QWO/Status/8	8
nl	Lane/QWO/Number	Nummer
nl	Lane/QWO/Date Issued	Datum van uitgifte
nl	Lane/QWO/Type	Type
nl	Lane/QWO/Type/0	0
nl	Lane/QWO/Type/1	1
nl	Lane/QWO/Type/2	2
nl	Lane/QWO/Type/3	3
nl	Lane/QWO/Type/4	4
nl	Lane/QWO/Type/5	5
nl	Lane/QWO/Type/6	6
nl	Lane/QWO/Type/7	7
nl	Lane/QWO/Buttons/Process And Print	Verwerk en print
nl	Lane/QWO/Machine	Machine
nl	Lane/QWO/Loaner	In bruikleen
nl	Lane/QWO/Problem and Solution	Probleem en oplossing
nl	Lane/QWO/Technician	Monteur
nl	Lane/QWO/Customer	Klant
nl	Lane/QWO/Search By Owner	Zoek op klant
nl	Lane/QWO/Search By Machine	Zoek op machine
nl	Lane/QWO/Problem	Probleem
nl	Lane/QWO/Solution	Oplossing
nl	Enter a product ID, or press a function key	Voer een produkt ID in, of druk een functie toets
nl	Clerk	Verkoper
nl	Subtotal	Subtotaal
nl	Total	Totaal
nl	Taxes	BTW
nl	Amount Due	Te betalen
nl	Due w/Disc	Te betalen met korting
nl	Disc Date	Kortings datum
nl	Due Date	Betaal datum
nl	Enter your clerk ID	Type uw verkopers ID
nl	Enter your clerk Passcode	Type uw PIN
nl	Lane/Locale/Temporal/ShortTimestamp	%m-%d-%Y %H:%M
nl	Lane/Locale/Temporal/LongTimestamp	%A, %d %B, %Y %H:%M
nl	Ticket	Bon
nl	Amount required for %0 sales.	Hoeveelheid nodig voor %0 verkoop.
nl	A customer must be open for %0 sales.	Een klant moet zijn geopend voor %0 verkoop.
nl	%0 customers must pay at the time of service.	%0 klanten moeten direct betalen.
nl	Change	Wisselgeld
nl	Enter or scan the item to check	Type of scan het te controleren produkt
nl	Price Check	Prijs controle
nl	Unknown Product	Onbekend produkt
nl	Enter your passcode to shutdown the register	Type uw PIN om het systeem af te sluiten
nl	Shutdown in progress...	Bezig met afsluiten...
nl	(w/disc)	(incl. korting)
nl	Enter the amount and tender type, or continue to enter products	Type het bedrag en betaalmethode, of ga verder met invoeren produkten 
nl	Customer	Klant
nl	This sale has been (partially?) committed, so it can not be canceled.	Deze verkoop is al (gedeeltelijk?) voldaan, deze kan niet geannuleerd worden.
nl	CANCELED	GEANNULEERD
nl	none	geen
nl	Cancel R/A	Annuleer R/A
nl	Tax exempt	BTW vrijstelling
nl	SUSPENDED	GEPAUZEERD
nl	A suspended sale can not be resumed inside another transaction.	Een gepauzeerde verkoop kan niet worden hervat binnen een andere transactie.
nl	There are no suspended tickets.	Er zijn geen gepauzeerde bonnen.
nl	There is no ticket %0.	Er is geen bon %0.
nl	The ticket %0 was not suspended (it is finalized).	Bon %0 is niet gepauzeerd (al afgerond).
nl	RESUMED	HERVAT
nl	R/A can not be processed inside a standard transaction.	R/A kan niet worden verwerkt binnen een standaard transactie.
nl	A customer must be open for a R/A transaction.	Een klant moet zijn geopend voor een R/A transactie.
nl	clear	leeg
\.

COMMIT;
