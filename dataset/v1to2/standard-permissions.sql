--standard-permissions.sql

--Copyright 2010 Jason Burrell

--This file grants the two standard roles typical permissions.

--The business manager role is different from the previous DB admin "posmgr" role.

\echo /standard-permissions.sql

begin;

--remember, every table someone has insert/update on, they need insert on the _rev table!

grant select on table clerks, discounts, locale, machines, pricetables, qwo, qwostatuses, strings, sysstrings, taxes, tenders, terms to registersys;
grant select, update, insert on table sales, salesitems, salestaxes, salestenders, timeclock to registersys;
grant delete on table salesitems, salestaxes, salestenders to registersys;
grant select, update on table customers, products to registersys;

grant insert on table customers_rev, products_rev, sales_rev, salesitems_rev, salestaxes_rev, salestenders_rev, timeclock_rev to registersys;

grant select, update on sales_id_seq, sales_rev_r_seq, timeclock_rev_r_seq, products_rev_r_seq, customers_rev_r_seq to registersys;

--this should be moved to a "set role..." priv
--this doesn't appear to be used -- we can setNonPersonUsername() w/o it
--grant temporary on database :DBNAME to registersys;

/*
The sequences:
purchaseorders_id_seq
qwo_id_seq
sales_id_seq


*/

grant select, insert, update on table purchaseorders, purchaseordersordereditems, purchaseordersreceiveditems, vendors to bizmgr;

grant insert, update on table clerks, discounts, machines, pricetables, qwo, qwostatuses, strings, taxes, tenders, terms to bizmgr;
grant insert on table customers, products to bizmgr;

grant select, insert on table clerks_rev, discounts_rev, machines_rev, pricetables_rev, qwo_rev, qwostatuses_rev, strings_rev, taxes_rev, tenders_rev, terms_rev, purchaseorders_rev, purchaseordersordereditems_rev, purchaseordersreceiveditems_rev, vendors_rev to bizmgr;

grant select on table customers_rev, products_rev, sales_rev, salesitems_rev, salestaxes_rev, salestenders_rev, timeclock_rev to bizmgr;

grant insert on table customers, products to bizmgr;

grant select, update on purchaseorders_id_seq, purchaseorders_rev_r_seq, vendors_rev_r_seq, clerks_rev_r_seq, discounts_rev_r_seq, machines_rev_r_seq, pricetables_rev_r_seq, qwo_id_seq, qwo_rev_r_seq, strings_rev_r_seq, taxes_rev_r_seq, tenders_rev_r_seq, terms_rev_r_seq to bizmgr;

commit;

\echo /standard-permissions.sql
