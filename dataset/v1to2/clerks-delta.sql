--clerks-delta.sql

--bug 1329
begin;

alter table clerks add column voidAt timestamp with time zone;
alter table clerks add column voidBy text;

alter table clerks add column created timestamp with time zone;
alter table clerks add column createdBy text;
alter table clerks add column modified timestamp with time zone;
alter table clerks add column modifiedBy text;

update clerks set created=current_timestamp where created is null;
update clerks set createdBy='installer@localhost' where createdBy is null; --so it's obvious
update clerks set modified=current_timestamp where modified is null;
update clerks set modifiedBy='installer@localhost' where modifiedBy is null; --so it's obvious

alter table clerks alter column created set not null;
alter table clerks alter column createdBy set not null;
alter table clerks alter column modified set not null;
alter table clerks alter column modifiedBy set not null;

create trigger setUserInfoClerks before insert or update on clerks for each row execute procedure setuserinfo();

create table clerks_rev (
       id smallint not null,
       name character varying(20) not null,
       passcode smallint not null,
       drawer character(1),
       voidAt timestamp with time zone,
       voidBy text,
       created timestamp with time zone not null,
       createdBy text not null,
       modified timestamp with time zone not null,
       modifiedBy text not null,

       r bigserial,

       primary key (id, r),
       foreign key (id) references clerks
);

insert into clerks_rev select * from clerks;
create trigger disallowChangesClerks_rev before update or delete on clerks_rev for each statement execute procedure disallowChanges();
select installPopulateRevTable('clerks');

commit;
