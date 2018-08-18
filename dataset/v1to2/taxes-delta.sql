--taxes-delta.sql

--bug 1329
begin;

alter table taxes add column voidAt timestamp with time zone;
alter table taxes add column voidBy text;

alter table taxes add column created timestamp with time zone;
alter table taxes add column createdBy text;
alter table taxes add column modified timestamp with time zone;
alter table taxes add column modifiedBy text;

update taxes set created=current_timestamp where created is null;
update taxes set createdBy='installer@localhost' where createdBy is null; --so it's obvious
update taxes set modified=current_timestamp where modified is null;
update taxes set modifiedBy='installer@localhost' where modifiedBy is null; --so it's obvious

alter table taxes alter column created set not null;
alter table taxes alter column createdBy set not null;
alter table taxes alter column modified set not null;
alter table taxes alter column modifiedBy set not null;

create trigger setUserInfoTaxes before insert or update on taxes for each row execute procedure setuserinfo();

create table taxes_rev (
       id smallint NOT NULL,
       descr character varying(20) NOT NULL,
       amount numeric(8,4),

       voidAt timestamp with time zone,
       voidBy text,
       created timestamp with time zone,
       createdBy text,
       modified timestamp with time zone,
       modifiedBy text,

       r bigserial,

       primary key (id, r),
       foreign key (id) references taxes
);

insert into taxes_rev select * from taxes;
create trigger disallowChangesTaxes_rev before update or delete on taxes_rev for each statement execute procedure disallowChanges();
select installPopulateRevTable('taxes');

commit;

