--strings-delta.sql
--Copyright 2008-2010 Jason Burrell

--see bug 100

alter table strings alter column id type text;
alter table sysstrings alter column id type text;

--bug 1329
begin;

alter table strings add column voidAt timestamp with time zone;
alter table strings add column voidBy text;

alter table strings add column created timestamp with time zone;
alter table strings add column createdBy text;
alter table strings add column modified timestamp with time zone;
alter table strings add column modifiedBy text;

update strings set created=current_timestamp where created is null;
update strings set createdBy='installer@localhost' where createdBy is null; --so it's obvious
update strings set modified=current_timestamp where modified is null;
update strings set modifiedBy='installer@localhost' where modifiedBy is null; --so it's obvious

alter table strings alter column created set not null;
alter table strings alter column createdBy set not null;
alter table strings alter column modified set not null;
alter table strings alter column modifiedBy set not null;

create trigger setUserInfoStrings before insert or update on strings for each row execute procedure setuserinfo();

create table strings_rev (
       id text,
       data text,
       voidAt timestamp with time zone,
       voidBy text,
       created timestamp with time zone not null,
       createdBy text not null,
       modified timestamp with time zone not null,
       modifiedBy text not null,

       r bigserial,

       primary key (id, r),
       foreign key (id) references strings
);

insert into strings_rev select * from strings;
create trigger disallowChangesStrings_rev before update or delete on strings_rev for each statement execute procedure disallowChanges();
select installPopulateRevTable('strings');

commit;

begin;

alter table sysstrings add column voidAt timestamp with time zone;
alter table sysstrings add column voidBy text;

alter table sysstrings add column created timestamp with time zone;
alter table sysstrings add column createdBy text;
alter table sysstrings add column modified timestamp with time zone;
alter table sysstrings add column modifiedBy text;

update sysstrings set created=current_timestamp where created is null;
update sysstrings set createdBy='installer@localhost' where createdBy is null; --so it's obvious
update sysstrings set modified=current_timestamp where modified is null;
update sysstrings set modifiedBy='installer@localhost' where modifiedBy is null; --so it's obvious

alter table sysstrings alter column created set not null;
alter table sysstrings alter column createdBy set not null;
alter table sysstrings alter column modified set not null;
alter table sysstrings alter column modifiedBy set not null;

create trigger setUserInfoSysStrings before insert or update on sysstrings for each row execute procedure setuserinfo();

create table sysstrings_rev (
       id text,
       data text,
       voidAt timestamp with time zone,
       voidBy text,
       created timestamp with time zone not null,
       createdBy text not null,
       modified timestamp with time zone not null,
       modifiedBy text not null,

       r bigserial,

       primary key (id, r),
       foreign key (id) references sysstrings
);

insert into sysstrings_rev select * from sysstrings;
create trigger disallowChangesSysStrings_rev before update or delete on sysstrings_rev for each statement execute procedure disallowChanges();
select installPopulateRevTable('sysstrings');

commit;
