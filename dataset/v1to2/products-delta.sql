--product-delta.sql
--Copyright 2009-2010 Jason Burrell
--This file is part of L'ane. See COPYING for licensing information.
--$Id: products-delta.sql 1139 2010-09-21 22:22:04Z jason $

begin;

alter table products alter column caseId drop not null;

commit;

--bug 1358 modify Product->extended to use the GenericObject style ext format
begin;
--if they have \t, they've already been updated
update products set extended=regexp_replace(extended,',',E'\n', 'g') where extended !~ E'\t' and extended is not null and extended <> '';
update products set extended=regexp_replace(extended,E'([[:alpha:][:punct:]]+)(\\d*)',E'\\1\t\\2', 'g') where extended !~ E'\t' and extended is not null and extended <> '';
commit;

--bug 1329, bug 47
begin;
alter table products alter column vendor drop not null;
alter table products alter column caseid drop not null;
alter table products alter column caseqty drop not null;

update products set vendor=null where vendor='';
update products set caseid=null where caseid='';

ALTER TABLE products
    ADD CONSTRAINT products_vendor_fkey FOREIGN KEY (vendor) REFERENCES vendors(id);
ALTER TABLE products
    ADD CONSTRAINT products_caseid_fkey FOREIGN KEY (caseid) REFERENCES products(id);

alter table products add column voidAt timestamp with time zone;
alter table products add column voidBy text;

alter table products add column created timestamp with time zone;
alter table products add column createdBy text;
alter table products add column modified timestamp with time zone;
alter table products add column modifiedBy text;

update products set created=current_timestamp where created is null;
update products set createdBy='installer@localhost' where createdBy is null; --so it's obvious
update products set modified=current_timestamp where modified is null;
update products set modifiedBy='installer@localhost' where modifiedBy is null; --so it's obvious

alter table products alter column created set not null;
alter table products alter column createdBy set not null;
alter table products alter column modified set not null;
alter table products alter column modifiedBy set not null;

create trigger setUserInfoProducts before insert or update on products for each row execute procedure setuserinfo();

create table products_rev (
       id character varying(20) NOT NULL,
       descr character varying(40) NOT NULL,
       price numeric(8,3) NOT NULL,
       category character varying(5) NOT NULL,
       taxes smallint NOT NULL,
       "type" character(1) NOT NULL,
       trackqty boolean NOT NULL,
       onhand numeric(15,3) NOT NULL,
       minimum numeric(15,3) NOT NULL,
       reorder numeric(15,3) NOT NULL,
       vendor character varying(20),
       caseqty numeric(15,3),
       caseid character varying(20),
       extended text,
       cost numeric(8,3),
       reorderid character varying(20),

       voidAt timestamp with time zone,
       voidBy text,
       created timestamp with time zone,
       createdBy text,
       modified timestamp with time zone,
       modifiedBy text,

       r bigserial,

       primary key (id, r),
       foreign key (id) references products,
       foreign key (vendor) references vendors,
       foreign key (caseid) references products
);

insert into products_rev select * from products;
create trigger disallowChangesProducts_rev before update or delete on products_rev for each statement execute procedure disallowChanges();
select installPopulateRevTable('products');

commit;
