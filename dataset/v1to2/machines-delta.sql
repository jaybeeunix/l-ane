--machines-delta.sql
--Copyright 2010 Jason Burrell

--bug 1329
begin;

--bug 47: foreign keys
ALTER TABLE machines
    ADD CONSTRAINT machines_owner_fkey FOREIGN KEY (owner) REFERENCES customers(id);

--change the onContract field to a boolean
alter table machines alter column onContract drop default;
alter table machines alter column oncontract type boolean using oncontract::boolean;
alter table machines alter column onContract set default false;

--L'ane BMS did some things a little different, so we'll try to L'ane-ify them here
alter table machines rename column creationDate to created;
alter table machines rename column creator to createdBy;
alter table machines alter column createdBy type text;

alter table machines add column voidAt timestamp with time zone;
alter table machines add column voidBy text;

alter table machines add column modified timestamp with time zone;
alter table machines add column modifiedBy text;

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
update machines set createdBy='installer+'||username||'@localhost' from sysPasswd where machines.createdBy=(sysPasswd.uid)::text;
update machines set createdBy='installer@localhost' where createdBy not like '%@%';

update machines set modified=current_timestamp where modified is null;
update machines set modifiedBy='installer@localhost' where modifiedBy is null; --so it's obvious
drop table syspasswd;

alter table machines alter column created set not null;
alter table machines alter column createdBy set not null;
alter table machines alter column modified set not null;
alter table machines alter column modifiedBy set not null;

create trigger setUserInfoMachines before insert or update on machines for each row execute procedure setuserinfo();

create table machines_rev (
       make character varying(35) NOT NULL,
       model character varying(35) NOT NULL,
       sn character varying(35) NOT NULL,
       counter numeric(7,0) NOT NULL,
       accessories character varying(35) NOT NULL,
       owner character varying(15) NOT NULL,
       location character varying(35) NOT NULL,
       purchased date,
       lastservice date,
       notes text,
       oncontract boolean DEFAULT false NOT NULL,
       contractbegins date,
       contractends date,
       createdby text NOT NULL,
       created timestamp with time zone NOT NULL,
       voidat timestamp with time zone,
       voidby text,
       modified timestamp with time zone NOT NULL,
       modifiedby text NOT NULL,

       r bigserial,

       primary key (make, model, sn, r),
       foreign key (make, model, sn) references machines,
       foreign key (owner) references customers
);

insert into machines_rev select * from machines;
create trigger disallowChangesMachines_rev before update or delete on machines_rev for each statement execute procedure disallowChanges();
select installPopulateRevTable('machines');

commit;

