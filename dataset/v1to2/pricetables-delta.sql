--pricetables-delta.sql

--bug 1329
alter table pricetables add constraint pricetable_pkey PRIMARY KEY (id);

begin;

alter table pricetables add column voidAt timestamp with time zone;
alter table pricetables add column voidBy text;

alter table pricetables add column created timestamp with time zone;
alter table pricetables add column createdBy text;
alter table pricetables add column modified timestamp with time zone;
alter table pricetables add column modifiedBy text;

update pricetables set created=current_timestamp where created is null;
update pricetables set createdBy='installer@localhost' where createdBy is null; --so it's obvious
update pricetables set modified=current_timestamp where modified is null;
update pricetables set modifiedBy='installer@localhost' where modifiedBy is null; --so it's obvious

alter table pricetables alter column created set not null;
alter table pricetables alter column createdBy set not null;
alter table pricetables alter column modified set not null;
alter table pricetables alter column modifiedBy set not null;

create trigger setUserInfoPricetables before insert or update on pricetables for each row execute procedure setuserinfo();

create table pricetables_rev (
       id smallint NOT NULL,
       pricelist text,

       voidAt timestamp with time zone,
       voidBy text,
       created timestamp with time zone,
       createdBy text,
       modified timestamp with time zone,
       modifiedBy text,

       r bigserial,

       primary key (id, r),
       foreign key (id) references pricetables
);

insert into pricetables_rev select * from pricetables;
create trigger disallowChangesPricetables_rev before update or delete on pricetables_rev for each statement execute procedure disallowChanges();
select installPopulateRevTable('pricetables');

commit;

