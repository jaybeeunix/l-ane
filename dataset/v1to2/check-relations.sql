--check-relations.sql

--Copyright 2010 Jason Burrell

\echo
\echo
\echo
\echo This file checks for the relational data that will need to exist before
\echo upgrading the dataset to version 2. It may refer to some tables or
\echo columns which do not exist: Those errors can be ignored.
\echo
\echo You must fix these errors before running "upgrade-dataset.sql".
\echo

\echo Checking customers referenced in sales...
select id from sales where customer not in (select id from customers);
\echo Checking clerks referenced in sales...
select id from sales where clerk not in (select id from clerks);



\echo Checking terms referenced in customers...
select id from customers where terms not in (select id from terms);


\echo Checking owners referenced in machines...
select make, model, sn from machines where owner not in (select id from customers);


\echo Checking vendors referenced in products...
select id from products where vendor <> '' and vendor not in (select id from vendors);
\echo Checking products(caseId) referenced in products...
select id from products where caseID <> '' and caseId not in (select id from products);


\echo Checking vendors referenced in purchaseorders...
select id from purchaseorders where vendor not in (select id from vendors);
\echo Checking products referenced in purchaseordersordereditems...
select id from purchaseordersordereditems where plu not in (select id from products);
\echo Checking products referenced in purchaseordersreceiveditems...
select id from purchaseordersreceiveditems where plu not in (select id from products);
\echo Checking purchaseorders referenced in purchaseordersordereditems...
select id from purchaseordersordereditems where plu not in (select id from purchaseorders);
\echo Checking purchaseorders referenced in purchaseordersreceiveditems...
select id from purchaseordersreceiveditems where plu not in (select id from purchaseorders);


\echo Checking customers referenced in qwo...
select id from qwo where customer not in (select id from customers);
\echo Checking qwo referenced in qwostatuses...
select id from qwostatus where id not in (select id from qwo);
\echo Checking customers referenced in qwo (old name)...
select num from qwo where customer not in (select id from customers);
\echo Checking qwo referenced in qwostatuses...
select wonum from qwostatus where wonum not in (select num from qwo);


\echo Checking clerks referenced in timeclocks...
select clerk, punch from timeclocks where clerk not in (select id from clerks);

\echo Checking terms referenced in vendors...
select id from vendors where terms not in (select id from terms);


\echo Checking taxes referenced in salestaxes...
select id, taxid from salestaxes where taxid not in (select id from taxes);
\echo Checking tenders referenced in salestenders...
select id, tender from salestenders where tender not in (select id from tenders);
\echo Checking products referenced in salesitems...
select id, plu from salesitems where plu not like ':%' and plu not like '#%' and plu <>'RA-TRANZ' and plu not in (select id from products);
\echo Checking discounts referenced in salesitems...
select id, plu from salesitems where plu like ':%' and plu not in (select ':' || id from discounts);

\echo Checking sales referenced in salestaxes...
create temporary table checkn (id integer);
insert into checkn (select distinct id from salestaxes);
delete from checkn where id in (select id from sales);
select * from checkn;
truncate table checkn;
--select id from salestaxes where id not in (select id from sales);
\echo Checking sales referenced in salestenders...
insert into checkn (select distinct id from salestenders);
delete from checkn where id in (select id from sales);
select * from checkn;
truncate table checkn;
--select id from salestenders where id not in (select id from sales);
\echo Checking sales referenced in salesitems...
insert into checkn (select distinct id from salesitems);
delete from checkn where id in (select id from sales);
select * from checkn;
truncate table checkn;
--select id from salesitems where id not in (select id from sales);

/*
\echo Checking  referenced in ...
select id from  where  not in (select id from );
*/


\echo 
\echo
\echo Done checking relations. Any IDs matched above need to be fixed
\echo BEFORE running "update-dataset.sql".
\echo
