--sales-delta.sql
--Copyright 2010 Jason Burrell

\echo sales-delta.sql
begin;
\echo bug 1309 - out of order errCorrect

alter table salesitems disable trigger all;
alter table salesitems_rev disable trigger all;

alter table salesitems add column struck boolean not null default false;

alter table salesitems_rev rename column r to r_old;
alter table salesitems_rev add column struck boolean not null default false;
alter table salesitems_rev add column r bigint;
update salesitems_rev set r=r_old;
alter table salesitems_rev drop column r_old cascade;
alter table salesitems_rev add primary key (id, lineno, r);
alter table salesitems_rev add foreign key (id, r) references sales_rev;

alter table salesitems enable trigger all;
alter table salesitems_rev enable trigger all;

commit;
\echo /bug 1309 - out of order errCorrect

\echo bug 1330 - salesPayments
begin;

create table salesPayments (
       id integer not null,
       lineNo smallint not null,
       tranzDate timestamp with time zone not null,
       raId integer not null,
       amt bigint not null,
       struck boolean not null default false,
       notes text,
       ext text,

       primary key (id, lineNo),
       foreign key (raId) references sales
);

create table salesPayments_rev (
       id integer not null,
       lineNo smallint not null,
       tranzDate timestamp with time zone not null,
       raId integer not null,
       amt bigint not null,
       struck boolean not null default false,
       notes text,
       ext text,

       r bigint not null,

       primary key (id, lineNo, r),
       foreign key (raId) references sales
);

select installPopulateKidzRevTable('salesPayments', 'sales_rev_r_seq');

\echo WARNING: This tool does not populate historic salesPayments since we do not have the information to reconstruct that data.

commit;
\echo /bug 1330 - salesPayments

\echo /sales-delta.sql
