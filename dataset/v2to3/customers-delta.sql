--customers-delta.sql
--Copyright 2010 Jason Burrell

\echo customers-delta.sql

begin;

alter table customers alter column coName drop not null;
alter table customers alter column cntFirst drop not null;
alter table customers alter column cntLast drop not null;
alter table customers alter column billAddr1 drop not null;
alter table customers alter column billAddr2 drop not null;
alter table customers alter column billCity drop not null;
alter table customers alter column billSt drop not null;
alter table customers alter column billZip drop not null;
alter table customers alter column billCountry drop not null;
alter table customers alter column billPhone drop not null;
alter table customers alter column billFax drop not null;
alter table customers alter column shipAddr1 drop not null;
alter table customers alter column shipAddr2 drop not null;
alter table customers alter column shipCity drop not null;
alter table customers alter column shipSt drop not null;
alter table customers alter column shipZip drop not null;
alter table customers alter column shipCountry drop not null;
alter table customers alter column shipPhone drop not null;
alter table customers alter column shipFax drop not null;
alter table customers alter column email drop not null;

alter table customers_rev alter column coName drop not null;
alter table customers_rev alter column cntFirst drop not null;
alter table customers_rev alter column cntLast drop not null;
alter table customers_rev alter column billAddr1 drop not null;
alter table customers_rev alter column billAddr2 drop not null;
alter table customers_rev alter column billCity drop not null;
alter table customers_rev alter column billSt drop not null;
alter table customers_rev alter column billZip drop not null;
alter table customers_rev alter column billCountry drop not null;
alter table customers_rev alter column billPhone drop not null;
alter table customers_rev alter column billFax drop not null;
alter table customers_rev alter column shipAddr1 drop not null;
alter table customers_rev alter column shipAddr2 drop not null;
alter table customers_rev alter column shipCity drop not null;
alter table customers_rev alter column shipSt drop not null;
alter table customers_rev alter column shipZip drop not null;
alter table customers_rev alter column shipCountry drop not null;
alter table customers_rev alter column shipPhone drop not null;
alter table customers_rev alter column shipFax drop not null;
alter table customers_rev alter column email drop not null;

alter table vendors alter column coName drop not null;
alter table vendors alter column cntFirst drop not null;
alter table vendors alter column cntLast drop not null;
alter table vendors alter column billAddr1 drop not null;
alter table vendors alter column billAddr2 drop not null;
alter table vendors alter column billCity drop not null;
alter table vendors alter column billSt drop not null;
alter table vendors alter column billZip drop not null;
alter table vendors alter column billCountry drop not null;
alter table vendors alter column billPhone drop not null;
alter table vendors alter column billFax drop not null;
alter table vendors alter column shipAddr1 drop not null;
alter table vendors alter column shipAddr2 drop not null;
alter table vendors alter column shipCity drop not null;
alter table vendors alter column shipSt drop not null;
alter table vendors alter column shipZip drop not null;
alter table vendors alter column shipCountry drop not null;
alter table vendors alter column shipPhone drop not null;
alter table vendors alter column shipFax drop not null;
alter table vendors alter column email drop not null;

alter table vendors_rev alter column coName drop not null;
alter table vendors_rev alter column cntFirst drop not null;
alter table vendors_rev alter column cntLast drop not null;
alter table vendors_rev alter column billAddr1 drop not null;
alter table vendors_rev alter column billAddr2 drop not null;
alter table vendors_rev alter column billCity drop not null;
alter table vendors_rev alter column billSt drop not null;
alter table vendors_rev alter column billZip drop not null;
alter table vendors_rev alter column billCountry drop not null;
alter table vendors_rev alter column billPhone drop not null;
alter table vendors_rev alter column billFax drop not null;
alter table vendors_rev alter column shipAddr1 drop not null;
alter table vendors_rev alter column shipAddr2 drop not null;
alter table vendors_rev alter column shipCity drop not null;
alter table vendors_rev alter column shipSt drop not null;
alter table vendors_rev alter column shipZip drop not null;
alter table vendors_rev alter column shipCountry drop not null;
alter table vendors_rev alter column shipPhone drop not null;
alter table vendors_rev alter column shipFax drop not null;
alter table vendors_rev alter column email drop not null;

commit;

\echo /customers-delta.sql
