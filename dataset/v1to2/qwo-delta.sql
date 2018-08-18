--qwo-delta.sql
--This file is part of L'ane. See COPYING for licensing information
--Copyright 2009-2010 Jason Burrell.
--$Id: qwo-delta.sql 1139 2010-09-21 22:22:04Z jason $

\echo qwo-delta.sql

--see bug 1322
\echo bug 1322
begin;

--qwo
alter table qwo rename column num to id;
alter table qwo alter column id drop default;

alter sequence qwo_num_seq rename to qwo_id_seq;

--qwoStatus
alter table qwoStatus rename to qwoStatuses;
alter table qwoStatuses rename column wonum to id;

commit;

\echo The following drop will fail if you never had this trigger.
drop trigger setAdditionalQwoInfo on qwo;
create or replace function setAdditionalQwoInfo() returns "trigger" as $_$
begin
        --fix a small issue with GenericObject/Dal being overly aggressive in making nulls
        if new.customer is null then
           new.customer := '';
        end if;
        if new.loanerMake is null then
           new.loanerMake := '';
        end if;
        if new.loanerModel is null then
           new.loanerModel := '';
        end if;
        if new.loanerSn is null then
           new.loanerSn := '';
        end if;
        if new.loanerAccessories is null then
           new.loanerAccessories := '';
        end if;
        /*
        if new. is null then
           new. := '';
        end if;
        */
	return new;       
end;
$_$ language plpgsql stable;

create trigger setAdditionalQwoInfo before insert or update on qwo for each row execute procedure setAdditionalQwoInfo();

create or replace function setAdditionalMachinesInfo() returns "trigger" as $_$
begin
        --fix a small issue with GenericObject/Dal being overly aggressive in making nulls
        if new.owner is null then
           new.owner := '';
        end if;

	return new;       
end;
$_$ language plpgsql stable;

drop trigger setAdditionalMachinesInfo on machines;

create trigger setAdditionalMachinesInfo before insert or update on machines for each row execute procedure setAdditionalMachinesInfo();

begin;
/*these will complicate things -- disable them for now

alter table qwo alter column make drop not null;
alter table qwo alter column model drop not null;
alter table qwo alter column sn drop not null;
alter table qwo alter column loanerMake drop not null;
alter table qwo alter column loanerModel drop not null;
alter table qwo alter column loanerSn drop not null;


*/

--foreign key constraints
alter table qwo add constraint qwo_customer_fkey foreign key (customer) references customers;
alter table qwoStatuses add constraint qwostatuses_id_fkey foreign key (id) references qwo;

/*
 * disable these foreign keys, as this isn't how BBS currently uses QWO
 * 

begin;

ALTER TABLE qwo
    ADD CONSTRAINT qwo_make_model_sn_fkey FOREIGN KEY (make, model, sn) REFERENCES machines;

ALTER TABLE qwo
    ADD CONSTRAINT qwo_loanermake_loanermodel_loanersn_fkey FOREIGN KEY (loanermake, loanermodel, loanersn) REFERENCES machines;

commit;
*/

--machines
commit;

\echo further bug 1322
begin;

--so, L'ane BMS did some things a little different, so we'll try to L'ane-ify them here
alter table qwo rename column creationDate to created;
alter table qwo rename column creator to createdBy;
alter table qwo alter column createdBy type text;
alter table qwostatuses rename column creationDate to created;
alter table qwostatuses rename column creator to createdBy;
alter table qwostatuses alter column createdBy type text;

alter table qwo add column voidAt timestamp with time zone;
alter table qwo add column voidBy text;
alter table qwostatuses add column voidAt timestamp with time zone;
alter table qwostatuses add column voidBy text;

--alter table qwo add column created timestamp with time zone;
--alter table qwo add column createdBy text;
alter table qwo add column modified timestamp with time zone;
alter table qwo add column modifiedBy text;
alter table qwostatuses add column modified timestamp with time zone;
alter table qwostatuses add column modifiedBy text;

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

update qwo set createdBy='installer+'||username||'@localhost' from sysPasswd where qwo.createdBy=(sysPasswd.uid)::text;
update qwo set createdBy='installer@localhost' where createdBy not like '%@%';

update qwo set modified=current_timestamp where modified is null;
update qwo set modifiedBy='installer@localhost' where modifiedBy is null; --so it's obvious

update qwostatuses set createdBy='installer+'||username||'@localhost' from sysPasswd where qwostatuses.createdBy=(sysPasswd.uid)::text;
update qwostatuses set createdBy='installer@localhost' where createdBy not like '%@%';

update qwostatuses set modified=current_timestamp where modified is null;
update qwostatuses set modifiedBy='installer@localhost' where modifiedBy is null; --so it's obvious
drop table syspasswd;

alter table qwo alter column created set not null;
alter table qwo alter column createdBy set not null;
alter table qwo alter column modified set not null;
alter table qwo alter column modifiedBy set not null;

alter table qwostatuses alter column created set not null;
alter table qwostatuses alter column createdBy set not null;
alter table qwostatuses alter column modified set not null;
alter table qwostatuses alter column modifiedBy set not null;

create trigger setUserInfoQwo before insert or update on qwo for each row execute procedure setuserinfo();
create trigger setUserInfoQwoStatuses before insert or update on qwostatuses for each row execute procedure setuserinfo();

--we may want to enable this feature in the future, but it makes voids permanent
--create trigger disallowChangesIfVoidedQwo before insert or update on qwo for each row execute procedure disallowChangesIfParentIsVoid('qwo');

--to enable this feature, we'd need to override QWO->void like how Sale->void does (aka, moving the void into the db)
--create trigger disallowChangesIfParentIsVoidQwoStatuses before insert or update on qwostatuses for each row execute procedure disallowChangesIfParentIsVoid('qwo');


commit;
\echo /further bug 1322

\echo bug 1329
begin;

create table qwo_rev (
       id integer NOT NULL,
       dateissued date NOT NULL,
       type smallint DEFAULT 0 NOT NULL,
       customer character varying(15) NOT NULL,
       notes character varying(50) NOT NULL,
       make character varying(35) NOT NULL,
       model character varying(35) NOT NULL,
       sn character varying(35) NOT NULL,
       counter numeric(7,0) NOT NULL,
       accessories character varying(35) NOT NULL,
       loanermake character varying(35) NOT NULL,
       loanermodel character varying(35) NOT NULL,
       loanersn character varying(35) NOT NULL,
       loanercounter numeric(7,0) NOT NULL,
       loaneraccessories character varying(35) NOT NULL,
       custprob text,
       tech character varying(10) NOT NULL,
       technotes text,
       solution text,
       status smallint DEFAULT 0 NOT NULL,
       createdby text NOT NULL,
       created timestamp with time zone NOT NULL,
       voidat timestamp with time zone,
       voidby text,
       modified timestamp with time zone NOT NULL,
       modifiedby text NOT NULL,

       r bigserial,

       primary key (id, r),
       foreign key (id) references qwo,
       foreign key (customer) references customers
);

create table qwoStatuses_rev (
       id integer NOT NULL,
       status smallint DEFAULT 0 NOT NULL,
       staff character varying(10) NOT NULL,
       contact character varying(35) NOT NULL,
       notes text,
       createdby text NOT NULL,
       created timestamp with time zone NOT NULL,
       voidat timestamp with time zone,
       voidby text,
       modified timestamp with time zone NOT NULL,
       modifiedby text NOT NULL,

       r bigint, --this uses qwo_rev_r_seq

       primary key (id, status, r),
       foreign key (id, r) references qwo_rev(id, r)
);

insert into qwo_rev select * from qwo;
create trigger disallowChangesQwo_rev before update or delete on qwo_rev for each statement execute procedure disallowChanges();
select installPopulateRevTable('qwo');

insert into qwostatuses_rev select qwostatuses.*, r from qwostatuses, qwo_rev where qwo_rev.id=qwostatuses.id;
create trigger disallowChangesQwoStatuses_rev before update or delete on qwostatuses_rev for each statement execute procedure disallowChanges();
select installPopulateKidzRevTable('qwostatuses', 'qwo_rev_r_seq');

commit;

\echo /qwo-delta.sql
