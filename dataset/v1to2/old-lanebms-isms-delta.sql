--old-lanebms-isms-delta.sql

--bug 1329
begin;

------------------------------------------------------------
------------------------------------------------------------
-- 
-- TERMS
--
------------------------------------------------------------
------------------------------------------------------------

--so, L'ane BMS did some things a little different, so we'll try to L'ane-ify them here
alter table terms rename column creationDate to created;
alter table terms rename column creator to createdBy;
alter table terms alter column createdBy type text;

alter table terms add column voidAt timestamp with time zone;
alter table terms add column voidBy text;

--alter table terms add column created timestamp with time zone;
--alter table terms add column createdBy text;
alter table terms add column modified timestamp with time zone;
alter table terms add column modifiedBy text;

--now, try to update the createdBy info
--THIS DOESN'T WORK IF YOUR SYSTEM USES NIS, LDAP, OR HESIOD!
create temporary table sysPasswd (
       username text not null,
       passwd text,
       uid bigint,
       gid bigint,
       gcos text,
       home text,
       shell text
);

copy sysPasswd from '/etc/passwd' with delimiter ':';
update terms set createdBy='installer+'||username||'@localhost' from sysPasswd where terms.createdBy=(sysPasswd.uid)::text;
update terms set createdBy='installer@localhost' where createdBy not like '%@%';

update terms set modified=current_timestamp where modified is null;
update terms set modifiedBy='installer@localhost' where modifiedBy is null; --so it's obvious

drop table syspasswd;

alter table terms alter column created set not null;
alter table terms alter column createdBy set not null;
alter table terms alter column modified set not null;
alter table terms alter column modifiedBy set not null;

create trigger setUserInfoTerms before insert or update on terms for each row execute procedure setuserinfo();

create table terms_rev (
       id character varying(5) NOT NULL,
       descr character varying(20) NOT NULL,
       duedays smallint NOT NULL,
       finrate numeric(9,4) NOT NULL,
       discdays smallint NOT NULL,
       discrate numeric(9,4) NOT NULL,

       --this is out of order because the trigger expects this table exactly matches the layout of the revisioned table
       createdBy text not null,
       created timestamp with time zone not null,

       voidAt timestamp with time zone,
       voidBy text,
       modified timestamp with time zone,
       modifiedBy text,

       r bigserial,

       primary key (id, r),
       foreign key (id) references terms
);

insert into terms_rev select * from terms;
create trigger disallowChangesTerms_rev before update or delete on terms_rev for each statement execute procedure disallowChanges();
select installPopulateRevTable('terms');

commit;

