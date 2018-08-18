--vendors-delta.sql
--This file is part of L'ane. See COPYING for licensing information
--Copyright 2010 Jason Burrell.
--$Id: vendors-delta.sql 1139 2010-09-21 22:22:04Z jason $

\echo vendors-delta.sql

\echo bug 47
begin;

ALTER TABLE vendors
    ADD CONSTRAINT vendors_terms_fkey FOREIGN KEY (terms) REFERENCES terms;

--taxes can never be modified or deleted, post rev table, so fkeys on them aren't absolutely needed.

commit;
\echo /bug 47

\echo bug 1329
begin;

--so, L'ane BMS did some things a little different, so we'll try to L'ane-ify them here
alter table vendors rename column creationDate to created;
alter table vendors rename column creator to createdBy;
alter table vendors alter column createdBy type text;

alter table vendors add column voidAt timestamp with time zone;
alter table vendors add column voidBy text;

--alter table vendors add column created timestamp with time zone;
--alter table vendors add column createdBy text;
alter table vendors add column modified timestamp with time zone;
alter table vendors add column modifiedBy text;

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

update vendors set createdBy='installer+'||username||'@localhost' from sysPasswd where vendors.createdBy=(sysPasswd.uid)::text;
update vendors set createdBy='installer@localhost' where createdBy not like '%@%';

drop table syspasswd;

update vendors set modified=current_timestamp where modified is null;
update vendors set modifiedBy='installer@localhost' where modifiedBy is null; --so it's obvious

alter table vendors alter column created set not null;
alter table vendors alter column createdBy set not null;
alter table vendors alter column modified set not null;
alter table vendors alter column modifiedBy set not null;

create trigger setUserInfoVendors before insert or update on vendors for each row execute procedure setuserinfo();

create table vendors_rev (
       id character varying(15) NOT NULL,
       coname character varying(40) NOT NULL,
       cntfirst character varying(35) NOT NULL,
       cntlast character varying(35) NOT NULL,
       billaddr1 character varying(40) NOT NULL,
       billaddr2 character varying(40) NOT NULL,
       billcity character varying(35) NOT NULL,
       billst character varying(2) NOT NULL,
       billzip character varying(10) NOT NULL,
       billcountry character varying(2) DEFAULT 'us'::character varying NOT NULL,
       billphone character varying(15) NOT NULL,
       billfax character varying(15) NOT NULL,
       shipaddr1 character varying(40) NOT NULL,
       shipaddr2 character varying(40) NOT NULL,
       shipcity character varying(35) NOT NULL,
       shipst character varying(2) NOT NULL,
       shipzip character varying(10) NOT NULL,
       shipcountry character varying(2) DEFAULT 'us'::character varying NOT NULL,
       shipphone character varying(15) NOT NULL,
       shipfax character varying(15) NOT NULL,
       email character varying(40) NOT NULL,
       creditlmt numeric(15,2) NOT NULL,
       balance numeric(15,2) NOT NULL,
       creditrmn numeric(15,2) NOT NULL,
       lastsale date,
       lastpay date,
       terms character varying(5) NOT NULL,
       notes text,
       createdBy text NOT NULL,
       created timestamp with time zone NOT NULL,
       taxes smallint DEFAULT 32767 NOT NULL,
       voidAt timestamp with time zone,
       voidBy text,
       modified timestamp with time zone NOT NULL,
       modifiedBy text NOT NULL,

       r bigserial,

       primary key (id, r),
       foreign key (id) references vendors,
       foreign key (terms) references terms
);

insert into vendors_rev select * from vendors;
create trigger disallowChangesVendors_rev before update or delete on vendors_rev for each statement execute procedure disallowChanges();
select installPopulateRevTable('vendors');

commit;
\echo /bug 1329

\echo /vendors-delta.sql
