--locale-dataset-sample.sql
--Copyright 2005-2010 Jason Burrell
--This file is part of L'anePOS. See COPYING.

--LaneLocale: sample (Sample Locale)

--This file contains the authoritative list of the strings used by the
--various L'ane programs.

--It should be used by people who want to create a new translation for
--L'ane by copying it to a new file in the form "locale-dataset-XX.sql",
--where XX is the official language code from RFC 3066 (this choice is
--for parity with XML). The filename should only contain lowercase
--characters even though Locale does not distinguish between language
--tag name cases.

--$Id: locale-dataset-sample.sql 1197 2010-10-24 18:23:51Z jason $

\encoding LATIN9

BEGIN;

delete from locale where lower(lang)=lower('sample');

COPY "locale" FROM stdin;
sample	locale-data-version	$Id: locale-dataset-sample.sql 1197 2010-10-24 18:23:51Z jason $
sample	locale-data-name	Sample Locale
sample	Lane/Locale/Money/CurrencyCode	???
sample	Lane/Locale/Money/Prefix	$
sample	Lane/Locale/Money/Suffix	
sample	Lane/Locale/Money/GroupingDigits	3
sample	Lane/Locale/Money/GroupingSeparator	 
sample	Lane/Locale/Money/DecimalSeparator	.
sample	Lane/Locale/Money/DecimalDigits	2
sample	Lane/Locale/Money/Negative/Prefix	-$
sample	Lane/Locale/Money/Negative/Suffix	
sample	Lane/Locale/Money/Negative/GroupingDigits	3
sample	Lane/Locale/Money/Negative/GroupingSeparator	 
sample	Lane/Locale/Money/Negative/DecimalSeparator	.
sample	Lane/Locale/Temporal/LongTimestamp	%d %B %Y %H:%M
sample	Lane/Locale/Temporal/ShortTimestamp	%Y-%m-%d %H:%M
sample	Lane/Locale/Temporal/LongTime	%H:%M
sample	Lane/Locale/Temporal/ShortTime	%H:%M
sample	Lane/Locale/Temporal/LongDate	%d %B %Y
sample	Lane/Locale/Temporal/ShortDate	%Y-%m-%d
sample	Lane/GenericObject/ID	ID
sample	Lane/BackOffice/Save Prompt	This record is not saved. Do you want a chance to save your changes?\n(Selecting 'Yes' only cancels the previous operation.)
sample	Lane/BackOffice/Remove Prompt	Are you sure you want to permanently\nremove this record from the database?
sample	Lane/BackOffice/Confirmation	Confirmation
sample	Lane/BackOffice/Buttons/Yes	Yes
sample	Lane/BackOffice/Buttons/Yes, Remove	Yes, Remove
sample	Lane/BackOffice/Buttons/No	No
sample	Lane/BackOffice/Buttons/No, Cancel	No, Cancel
sample	Lane/BackOffice/Buttons/No, Discard	No, Discard
sample	Lane/BackOffice/Buttons/Discard	Discard
sample	Lane/BackOffice/Buttons/Cancel	Cancel
sample	Lane/BackOffice/Buttons/New	New
sample	Lane/BackOffice/Buttons/Process	Process
sample	Lane/BackOffice/Buttons/Quit	Quit
sample	Lane/BackOffice/Buttons/Remove	Remove
sample	Lane/BackOffice/Buttons/Search	Search
sample	Lane/BackOffice/Buttons/OK	OK
sample	Lane/BackOffice/Buttons/Add	Add
sample	Lane/BackOffice/Buttons/View	View
sample	Lane/BackOffice/Buttons/Print	Print
sample	Lane/BackOffice/Search Results	Search Results
sample	Lane/BackOffice/Search Results Text	The database found the following records:
sample	Lane/BackOffice/Notes	Notes
sample	Lane/BackOffice/Select	Select One
sample	Lane/BackOffice/Clerks	Clerks
sample	Lane/BackOffice/Customers	Customers
sample	Lane/BackOffice/Discounts	Discounts
sample	Lane/BackOffice/Machines	Machines
sample	Lane/BackOffice/Products	Products
sample	Lane/BackOffice/QWO	QWO
sample	Lane/BackOffice/Strings	Strings
sample	Lane/BackOffice/System Strings	System Strings
sample	Lane/BackOffice/Taxes	Taxes
sample	Lane/BackOffice/Tenders	Tenders
sample	Lane/BackOffice/Terms	Terms
sample	Lane/BackOffice/Vendors	Vendors
sample	Lane/Clerk/Clerk	Clerk
sample	Lane/Clerk/Name	Name
sample	Lane/Clerk/Passcode	Passcode
sample	Lane/Clerk/Drawer	Drawer
sample	Lane/String/Data	Data
sample	Lane/Tax/Description	Description
sample	Lane/Tax/Amount	Amount
sample	Lane/Term/Description	Description
sample	Lane/Term/Days Until Due	Days Until Due
sample	Lane/Term/Finance Rate	Finance Rate
sample	Lane/Term/Days For Discount	Days For Discount
sample	Lane/Term/Discount Rate	Discount Rate
sample	Lane/Tender/Description	Description
sample	Lane/Tender/Allow Change	Allow Change
sample	Lane/Tender/Mandatory Amount	Mandatory Amount
sample	Lane/Tender/Open Drawer	Open Drawer
sample	Lane/Tender/Pays	Pays
sample	Lane/Tender/eProcess	eProcess
sample	Lane/Tender/eAuthorize	eAuthorize
sample	Lane/Tender/Allow Zero Amounts	Allow Zero Amounts
sample	Lane/Tender/Allow Negative Amounts	Allow Negative Amounts
sample	Lane/Tender/Allow Positive Amounts	Allow Positive Amounts
sample	Lane/Tender/Require Items/Require Items	Require Items
sample	Lane/Tender/Require Items/Do Not Allow Items	Do Not Allow Items
sample	Lane/Tender/Require Items/Either	Either
sample	Lane/Customer/Company Name	Company Name
sample	Lane/Customer/Contact Given Name	Contact Given Name
sample	Lane/Customer/Contact Family Name	Contact Surname
sample	Lane/Customer/Billing	Billing
sample	Lane/Customer/Billing Address 1	Address 1
sample	Lane/Customer/Billing Address 2	Address 2
sample	Lane/Customer/Billing City	City
sample	Lane/Customer/Billing State	State
sample	Lane/Customer/Billing Zip	Zip
sample	Lane/Customer/Billing Country	Country
sample	Lane/Customer/Billing Phone	Phone
sample	Lane/Customer/Billing Fax	Fax
sample	Lane/Customer/Shipping	Shipping
sample	Lane/Customer/Same As Billing	Same as Billing
sample	Lane/Customer/Shipping Address 1	Address 1
sample	Lane/Customer/Shipping Address 2	Address 2
sample	Lane/Customer/Shipping City	City
sample	Lane/Customer/Shipping State	State
sample	Lane/Customer/Shipping Zip	Zip
sample	Lane/Customer/Shipping Country	Country
sample	Lane/Customer/Shipping Phone	Phone
sample	Lane/Customer/Shipping Fax	Fax
sample	Lane/Customer/Email	Email
sample	Lane/Customer/Accounting	Accounting
sample	Lane/Customer/Account Terms	Terms
sample	Lane/Customer/Customer Type	Customer Type
sample	Lane/Customer/Customer Type/0	Company
sample	Lane/Customer/Customer Type/1	Individual
sample	Lane/Customer/Customer Type/2	Web Only
sample	Lane/Customer/Customer Type/3	Dealer
sample	Lane/Customer/Credit Limit	Credit Limit
sample	Lane/Customer/Balance	Balance
sample	Lane/Customer/Taxes	Taxes
sample	Lane/Customer/Credit Remaining	Credit Remaining
sample	Lane/Customer/Last Sale	Last Sale
sample	Lane/Customer/Last Payment	Last Payment
sample	Lane/Customer/Search Prompt	Enter part of the company's name or part of the contact's last name to search.
sample	Lane/Vendor/Vendor	Vendor
sample	Lane/Discount/Description	Description
sample	Lane/Discount/Preset	Preset
sample	Lane/Discount/Open	Open
sample	Lane/Discount/Fixed	Fixed Amount
sample	Lane/Discount/Percent	Percent Amount
sample	Lane/Discount/Amount	Amount
sample	Lane/Discount/Sale	Discount applies to Sale
sample	Lane/Discount/Item	Discount applies to Previous Item
sample	Lane/Product/Description	Description
sample	Lane/Product/Price	Price
sample	Lane/Product/Category	Category
sample	Lane/Product/Taxes	Taxes
sample	Lane/Product/Type	Type
sample	Lane/Product/Type/Preset	Preset
sample	Lane/Product/Type/Open	Open
sample	Lane/Product/Type/Open Negative	Open, Negative
sample	Lane/Product/Track Quantity	Track Quantity
sample	Lane/Product/On Hand	On Hand
sample	Lane/Product/Minimum	Minimum
sample	Lane/Product/Reorder	Reorder
sample	Lane/Product/Items Per Case	Items per Case
sample	Lane/Product/Case ID	Case ID
sample	Lane/Product/Vendor	Vendor
sample	Lane/Product/Extended	Extended
sample	Lane/Product/Cost	Cost
sample	Lane/Product/Reorder ID	Reorder ID
sample	Lane/Product/Search Prompt	Enter part of the product's description to search.
sample	Lane/Machine/Search Prompt	Enter part of any or all of the following fields to search for machines.
sample	Lane/Machine/Make	Make
sample	Lane/Machine/Model	Model
sample	Lane/Machine/Serial Number	Serial Number
sample	Lane/Machine/Counter	Counter
sample	Lane/Machine/Accessories	Accessories
sample	Lane/Machine/Owner	Owner
sample	Lane/Machine/Purchase Date	Purchase Date
sample	Lane/Machine/Last Service Date	Last Service Date
sample	Lane/Machine/Contract	Contract
sample	Lane/Machine/Contract/On Contract	On Contract
sample	Lane/Machine/Contract/Begins	Begins
sample	Lane/Machine/Contract/Ends	Ends
sample	Lane/QWO/Machines Owned By	Machines Owned By
sample	Lane/QWO/Machine Search Prompt	Enter part of any or all of the following fields to search for machines.
sample	Lane/QWO/Status	Status
sample	Lane/QWO/Status/Staff	Staff
sample	Lane/QWO/Status/Contact	Contact
sample	Lane/QWO/Status/0	Awaiting Estimate
sample	Lane/QWO/Status/1	Estimate Given
sample	Lane/QWO/Status/2	Estimate Denied
sample	Lane/QWO/Status/3	Approved
sample	Lane/QWO/Status/4	Serviced
sample	Lane/QWO/Status/5	Picked Up
sample	Lane/QWO/Status/6	Taken Back
sample	Lane/QWO/Status/7	Traded In
sample	Lane/QWO/Status/8	Canceled
sample	Lane/QWO/Number	WO ID
sample	Lane/QWO/Date Issued	Date Issued
sample	Lane/QWO/Type	Type
sample	Lane/QWO/Type/0	Std in Shop
sample	Lane/QWO/Type/1	Rush in Shop
sample	Lane/QWO/Type/2	Std Service Call
sample	Lane/QWO/Type/3	Emergency Service Call
sample	Lane/QWO/Type/4	Maintenance Agreement
sample	Lane/QWO/Type/5	Shop-Other
sample	Lane/QWO/Type/6	Call-Other
sample	Lane/QWO/Type/7	Other
sample	Lane/QWO/Buttons/Process And Print	Process and Print
sample	Lane/QWO/Machine	Machine
sample	Lane/QWO/Loaner	Loaner
sample	Lane/QWO/Problem and Solution	Problem and Solution
sample	Lane/QWO/Technician	Technician
sample	Lane/QWO/Customer	Customer
sample	Lane/QWO/Search By Owner	Search by Owner
sample	Lane/QWO/Search By Machine	Search by Machine
sample	Lane/QWO/Problem	Problem
sample	Lane/QWO/Solution	Solution
sample	Enter a product ID, or press a function key	Enter a product ID, or press a function key
sample	Clerk	Clerk
sample	Subtotal	Subtotal
sample	Total	Total
sample	Taxes	Taxes
sample	Amount Due	Amount Due
sample	Due w/Disc	Due w/Disc
sample	Disc Date	Disc Date
sample	Due Date	Due Date
sample	Enter your clerk ID	Enter your clerk ID
sample	Enter your clerk Passcode	Enter your clerk Passcode
sample	Ticket	Ticket
sample	Amount required for %0 sales.	Amount required for %0 sales.
sample	A customer must be open for %0 sales.	A customer must be open for %0 sales.
sample	%0 customers must pay at the time of service.	%0 customers must pay at the time of service.
sample	Change	Change
sample	Enter or scan the item to check	Enter or scan the item to check
sample	Price Check	Price Check
sample	Unknown Product	Unknown Product: %0
sample	Enter your passcode to shutdown the register	Enter your passcode to shutdown the register
sample	Shutdown in progress...	Shutdown in progress...
sample	(w/disc)	(w/disc)
sample	Enter the amount and tender type, or continue to enter products	Enter the amount and tender type, or continue to enter products
sample	Customer	Customer
sample	This sale has been (partially?) committed, so it can not be canceled.	This sale has been (partially?) committed, so it can not be canceled.
sample	CANCELED	CANCELED
sample	none	none
sample	Cancel R/A	Cancel R/A
sample	Tax exempt	Tax exempt
sample	SUSPENDED	SUSPENDED
sample	A suspended sale can not be resumed inside another transaction.	A suspended sale can not be resumed inside another transaction.
sample	There are no suspended tickets.	There are no suspended tickets.
sample	There is no ticket %0.	There is no ticket %0.
sample	The ticket %0 was not suspended (it is finalized).	The ticket %0 was not suspended (it is finalized).
sample	RESUMED	RESUMED
sample	R/A can not be processed inside a standard transaction.	R/A can not be processed inside a standard transaction.
sample	A customer must be open for a R/A transaction.	A customer must be open for a R/A transaction.
sample	clear	clear
sample	Lane/Register/Tender/RA Requires Pays	You can not tender R/A transactions with %0.
sample	Lane/Register/Tender/No Zero Amount	%0 does not allow zero amounts.
sample	Lane/Register/Tender/No Negative Amount	%0 does not allow negative amounts.
sample	Lane/Register/Tender/No Positive Amount	%0 does not allow positive amounts.
sample	Lane/Register/Tender/Requires Items	%0 requires items in the sale.
sample	Lane/Register/Tender/Does Not Allow Items	%0 does not allow items in the sale.
sample	Lane/Register/Tender/No Allow Change	%0 sales do not allow change.
sample	Lane/Register/Discount/RA Transaction	Discounts can not be used in an R/A transaction.
sample	Lane/Register/Product/Open Without Amount	Open items require an amount.
sample	Lane/Register/RA	R/A
sample	Lane/Register/Customer/Not Found	The customer, %0, was not found.
sample	Lane/Register/Sale/Void by ID/Confirmation	Are you sure you want to permanently void ticket %0 (%1 %2) ?\n
sample	Lane/Register/Sale/Void by ID/Success	%0 voided.
sample	Lane/Printer/Format/Item	%{qty(4)}x%{plu(-20)} %{amt(14)}\n%{descr(-40)}\n\n
sample	Lane/Pole/Format/Item	%{descr(-20)}%{qty(-3)} %{amt(16)}
sample	Lane/Printer/Format/Discount	%{descr(-20)} %{amt(19)}\n\n
sample	Lane/Printer/Format/Tender	%{descr(-10)}%{amt(10)}\n
sample	Lane/Printer/Format/Subtotal	%{descr(-19)} %{amt(20)}\n
sample	Lane/Printer/Format/Tax	%{descr(-20)} %{amt(19)}\n
sample	Lane/Printer/Format/Total	%{descr(-6)}%{amt(14)}\n
sample	Lane/Printer/Format/Terms	\n%{termsTitle}: %{terms}\n%{discDateTitle}: %{discDate}\n%{dueDateTitle}: %{dueDate}\n
sample	Lane/Printer/Format/Footer	<center>%{clerkTitle}: %{clerk}\n%{now}\n%{ticketTitle} %{ticket}\n\n%{stringFooter}
sample	Lane/Timeclock/Successful Clock In	%0 clocked in.
sample	Lane/Timeclock/Successful Clock Out	%0 clocked out with %1 hours today.
sample	Lane/Timeclock/Failed Clock	Failed to clock-in/out.
sample	Lane/BackOffice/Timekeeping	Timekeeping
sample	Lane/BackOffice/Timekeeping/Invalid Time/Title	Error
sample	Lane/BackOffice/Timekeeping/Invalid Time	The value entered is not a valid time.
\.

/*
sample		
sample		
sample		
sample		
sample		
sample		
sample		
*/

COMMIT;
