--discounts-delta.sql

--bug 1329
begin;

alter table discounts add column voidAt timestamp with time zone;
alter table discounts add column voidBy text;

alter table discounts add column created timestamp with time zone;
alter table discounts add column createdBy text;
alter table discounts add column modified timestamp with time zone;
alter table discounts add column modifiedBy text;

update discounts set created=current_timestamp where created is null;
update discounts set createdBy='installer@localhost' where createdBy is null; --so it's obvious
update discounts set modified=current_timestamp where modified is null;
update discounts set modifiedBy='installer@localhost' where modifiedBy is null; --so it's obvious

alter table discounts alter column created set not null;
alter table discounts alter column createdBy set not null;
alter table discounts alter column modified set not null;
alter table discounts alter column modifiedBy set not null;

create trigger setUserInfoDiscounts before insert or update on discounts for each row execute procedure setuserinfo();

create table discounts_rev (
       id smallint NOT NULL,
       descr character varying(20) NOT NULL,
       preset boolean NOT NULL,
       per boolean NOT NULL,
       amt numeric(10,2) NOT NULL,
       sale boolean NOT NULL,

       voidAt timestamp with time zone,
       voidBy text,
       created timestamp with time zone,
       createdBy text,
       modified timestamp with time zone,
       modifiedBy text,

       r bigserial,

       primary key (id, r),
       foreign key (id) references discounts
);

insert into discounts_rev select * from discounts;
create trigger disallowChangesDiscounts_rev before update or delete on discounts_rev for each statement execute procedure disallowChanges();
select installPopulateRevTable('discounts');

commit;

