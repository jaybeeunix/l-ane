--tenders-delta.sql
--Copyright 2008-2010 Jason Burrell

--upgrades a release dataset to the version need by HEAD

alter table tenders add column allowZero boolean default 't'::boolean not null;
alter table tenders add column allowNeg boolean default 't'::boolean not null;
alter table tenders add column allowPos boolean default 't'::boolean not null;
alter table tenders add column requireItems character(1) default 'a'::bpchar not null;

--bug 1329: revisioning

begin;

alter table tenders add column voidAt timestamp with time zone;
alter table tenders add column voidBy text;

alter table tenders add column created timestamp with time zone;
alter table tenders add column createdBy text;
alter table tenders add column modified timestamp with time zone;
alter table tenders add column modifiedBy text;

update tenders set created=current_timestamp where created is null;
update tenders set createdBy='installer@localhost' where createdBy is null; --so it's obvious
update tenders set modified=current_timestamp where modified is null;
update tenders set modifiedBy='installer@localhost' where modifiedBy is null; --so it's obvious

alter table tenders alter column created set not null;
alter table tenders alter column createdBy set not null;
alter table tenders alter column modified set not null;
alter table tenders alter column modifiedBy set not null;

create trigger setUserInfoTenders before insert or update on tenders for each row execute procedure setuserinfo();

CREATE TABLE tenders_rev (
       id smallint NOT NULL,
       descr character varying(10) NOT NULL,
       allowchange boolean NOT NULL,
       mandatoryamt boolean NOT NULL,
       opendrawer boolean NOT NULL,
       pays boolean NOT NULL,
       eprocess boolean NOT NULL,
       eauth boolean NOT NULL,
       allowzero boolean DEFAULT true NOT NULL,
       allowneg boolean DEFAULT true NOT NULL,
       allowpos boolean DEFAULT true NOT NULL,
       requireitems character(1) DEFAULT 'a'::bpchar NOT NULL,

       voidAt timestamp with time zone,
       voidBy text,
       created timestamp with time zone,
       createdBy text,
       modified timestamp with time zone,
       modifiedBy text,

       r bigserial,
    
       primary key (id, r),
       foreign key (id) references tenders
);

insert into tenders_rev select * from tenders;
create trigger disallowChangesTenders_rev before update or delete on tenders_rev for each statement execute procedure disallowChanges();
select installPopulateRevTable('tenders');

commit;
