--sales-delta.sql
--This file is part of L'ane. See COPYING for licensing information
--Copyright 2007-2010 Jason Burrell.
--$Id: sales-delta.sql 1139 2010-09-21 22:22:04Z jason $

--see bug 56
\echo bug 56
begin;

alter table sales add column notes text;
create index sales_tranzDate_index on sales (tranzDate);

alter table salesTenders add column ext text;

commit;

--bug 1302
\echo bug 1302
begin;

alter table sales add column voidAt timestamp with time zone;
alter table sales add column voidBy text;

--allow the use of the existing triggers
alter table sales add column created timestamp with time zone;
alter table sales add column createdBy text;
alter table sales add column modified timestamp with time zone;
alter table sales add column modifiedBy text;

update sales set created=tranzdate where created is null;
update sales set createdBy='installer@localhost' where createdBy is null; --so it's obvious
update sales set modified=tranzdate where modified is null;
update sales set modifiedBy='installer@localhost' where modifiedBy is null; --so it's obvious

alter table sales alter column created set not null;
alter table sales alter column createdBy set not null;
alter table sales alter column modified set not null;
alter table sales alter column modifiedBy set not null;

create trigger setUserInfoSales before insert or update on sales for each row execute procedure setuserinfo();

commit;

begin;
create trigger disallowChangesIfParentIsVoidSalesItems before insert or update on salesitems for each row execute procedure disallowChangesIfParentIsVoid('sales');
create trigger disallowChangesIfParentIsVoidSalesTenders before insert or update on salestenders for each row execute procedure disallowChangesIfParentIsVoid('sales');
create trigger disallowChangesIfParentIsVoidSalesTaxes before insert or update on salestaxes for each row execute procedure disallowChangesIfParentIsVoid('sales');

insert into SysStrings (id, data) values ('Lane/Sale/Void/Voidable Time Window', '2 weeks');
insert into SysStrings (id, data) values ('Lane/Sale/Void/Earliest Voidable Timestamp', '1776-07-04 00:00');
commit;

create or replace function voidSale(sales.id%TYPE) returns boolean as $_$
declare
        isVoidable boolean := false;
        tranz timestamp with time zone;
        earliest timestamp with time zone;
        earliestInterval interval;
        totalCharged int8 := 0;
begin
        --absolute check
        select into isVoidable, tranz, earliest sales.tranzdate >= cast(sysstrings.data as timestamp with time zone), sales.tranzDate, cast(sysstrings.data as timestamp with time zone) from sales, sysstrings where sysstrings.id='Lane/Sale/Void/Earliest Voidable Timestamp' and sales.id=$1;
        if isVoidable = false then
           raise exception 'You cannot void sale % from % as it is earlier than %.', $1, tranz, earliest;
        end if;
        --relative check
        select into isVoidable, tranz, earliestInterval sales.tranzdate >= current_timestamp - cast(sysstrings.data as interval), sales.tranzdate, cast(sysstrings.data as interval) from sales, sysstrings where sysstrings.id='Lane/Sale/Void/Voidable Time Window' and sales.id=$1;
        if isVoidable = false then
           raise exception 'You cannot void sale % from % as it is earlier than % ago.', $1, tranz, earliestInterval;
        end if;
        --ra-tranz check
        perform 1 from sales, salesItems where salesItems.plu='RA-TRANZ' and sales.id=$1 and sales.id=salesItems.id;
        if found then
           raise exception 'You cannot void a R/A transaction.';
        end if;
        --ok, void it
        update sales set voidAt=current_timestamp where id=$1;
        --manually update the audit table subtables, since the triggers won't work here
        insert into salesitems_rev select salesitems.*, currval('sales_rev_r_seq') from salesitems where salesitems.id=$1;
        insert into salestaxes_rev select salestaxes.*, currval('sales_rev_r_seq') from salestaxes where salestaxes.id=$1;
        insert into salestenders_rev select salestenders.*, currval('sales_rev_r_seq') from salestenders where salestenders.id=$1;
        --remove any tenders.pays=false amounts from the customer record
        select into totalCharged sum(amt) from salesTenders, tenders where salesTenders.id=$1 and salesTenders.tender=tenders.id and tenders.pays=false;
        if totalCharged <> 0 then
           update
                customers
                set
                        balance = customers.balance - totalCharged,
                        creditRmn = customers.creditRmn + totalCharged
                from sales
                where sales.customer=customers.id and sales.id=$1;
        end if;
        --update Customers.last{Pay,Sale} too
        update customers set lastPay=null, lastSale=null where id in (select customer from sales where id=$1);
        update customers set lastPay = getBusinessDayFor(big.tranzDate) from (select max(sales.tranzDate) as tranzDate, sales.customer as customer from sales, salesItems where sales.suspended=false and sales.id=salesItems.id and salesItems.lineNo=0 and salesItems.plu='RA-TRANZ' and sales.voidAt is null and sales.customer<>'' group by sales.customer) as big, sales where big.customer=customers.id and customers.id=sales.customer and sales.id=$1;
        update customers set lastSale = getBusinessDayFor(big.tranzDate) from (select max(sales.tranzDate) as tranzDate, sales.customer as customer from sales, salesItems where sales.suspended=false and sales.id=salesItems.id and salesItems.lineNo=0 and salesItems.plu<>'RA-TRANZ' and sales.voidAt is null and sales.customer<>'' group by sales.customer) as big, sales where big.customer=customers.id and customers.id=sales.customer and sales.id=$1;

        return true;
end;
$_$ language plpgsql volatile;

begin;
--bug 47
\echo bug 47
--foreign key constraints

--we can't use the following style, as they will create another foreign key contraint each time we run them
--
--alter table sales add foreign key (customer) references customers (id);
--alter table sales add foreign key (clerk) references clerks (id);
--alter table salesItems add foreign key (id) references sales (id);
--alter table salesTenders add foreign key (id) references sales (id);
--alter table salesTaxes add foreign key (id) references sales (id);
--alter table salesTenders add foreign key (tender) references tenders (id);
--alter table salesTaxes add foreign key (taxid) references taxes (id);

--used directly named constraints so they'll fail if they exist
ALTER TABLE sales
    ADD CONSTRAINT sales_clerk_fkey FOREIGN KEY (clerk) REFERENCES clerks(id);

ALTER TABLE sales
    ADD CONSTRAINT sales_customer_fkey FOREIGN KEY (customer) REFERENCES customers(id);

ALTER TABLE salesitems
    ADD CONSTRAINT salesitems_id_fkey FOREIGN KEY (id) REFERENCES sales(id);

ALTER TABLE salestaxes
    ADD CONSTRAINT salestaxes_id_fkey FOREIGN KEY (id) REFERENCES sales(id);

ALTER TABLE salestaxes
    ADD CONSTRAINT salestaxes_taxid_fkey FOREIGN KEY (taxid) REFERENCES taxes(id);

ALTER TABLE salestenders
    ADD CONSTRAINT salestenders_id_fkey FOREIGN KEY (id) REFERENCES sales(id);

ALTER TABLE salestenders
    ADD CONSTRAINT salestenders_tender_fkey FOREIGN KEY (tender) REFERENCES tenders(id);

--change for GenericObject
alter table salesseq rename to sales_id_seq;

create or replace function checkAndUpdateSalesMoney() returns boolean as $_$
declare
        moneyType text;
begin
        raise warning 'Checking the datatypes of your sales tables...';
        --check the type of sales.total
        
        select into moneyType pg_type.typname from pg_class, pg_attribute, pg_type where pg_class.relname='sales' and pg_class.oid=pg_attribute.attrelid and attname='total' and pg_attribute.atttypid=pg_type.oid;
        raise info 'The type of the sales table is %', moneyType;
        --
        if moneyType = 'int8' then
           raise info 'Your sales tables have already been updated.';
           return true;
        elsif moneyType = 'numeric' then
             --sales
             raise info 'Updating sales...';
             alter table sales alter column total type int8 using total * 10 ^ 2;
             alter table sales alter column balance type int8 using balance * 10 ^ 2;
             --salesItems
             raise info 'Updating salesItems...';
             alter table salesItems alter column amt type int8 using amt * 10 ^ 2;
             --salesTenders
             raise info 'Updating salesTenders...';
             alter table salesTenders alter column amt type int8 using amt * 10 ^ 2;
             --salesTaxes
             raise info 'Updating salesTaxes...';
             alter table salesTaxes alter column amt type int8 using amt * 10 ^ 2;
             return true;
        end if;
        return false;
end;
$_$ language plpgsql volatile;

select checkAndUpdateSalesMoney();
drop function checkAndUpdateSalesMoney();

--additions to salesTaxes
alter table salesTaxes rename column amt to taxable;

alter table salesTaxes add column rate numeric(8,4);
update salesTaxes set rate=taxes.amount from taxes where taxes.id=salesTaxes.taxid;
alter table salesTaxes alter column rate set not null;

alter table salesTaxes add column tax int8;
update salesTaxes set tax=(taxes.amount / 100) * salesTaxes.taxable from taxes where taxes.id=salesTaxes.taxid;
alter table salesTaxes alter column tax set not null;

--changes to sales
alter table sales alter column exempt type smallint using case when exempt then 0 else 32767 end;
alter table sales rename column exempt to taxMask;
update sales set taxMask=customers.taxes from customers where sales.customer=customers.id and taxMask<>0;
alter table sales alter column taxMask set not null;

create or replace function setAdditionalSalesInfo() returns "trigger" as $_$
begin
        --fix a small issue with GenericObject/Dal being overly aggressive in making nulls
        if new.customer is null then
           new.customer := '';
        end if;

	return new;       
end;
$_$ language plpgsql stable;

create or replace function setAdditionalSalesInfoPostCommit() returns "trigger" as $_$
declare
        updateLastSale boolean := false;
        updateLastPay boolean := false;
        custId text;
begin
        --set the customers info related to a sale
        select into custId customer from sales where id=new.id;
        if custId <> '' then --don't try to modify the cash customer -- it may throw an exception
           perform id from sales where suspended=false and voidAt is null and id=new.id;
           if found then --don't update if the sale is either suspended or void
              perform salesItems.id from salesItems, sales where lineNo=0 and salesItems.id=new.id and plu='RA-TRANZ';
              if found then
                 --this is an r/a: update lastPay
                 update customers set lastPay=getBusinessDayFor(sales.tranzDate) from sales where customers.id=sales.customer and sales.id=new.id and coalesce(lastPay, '1776-07-04') < getBusinessDayFor(sales.tranzDate);
              else
                --this is a sale: update lastSale
                update customers set lastSale=getBusinessDayFor(sales.tranzDate) from sales where customers.id=sales.customer and sales.id=new.id and coalesce(lastSale, '1776-07-04') < getBusinessDayFor(sales.tranzDate);
              end if;
          end if;
        end if;

	return new;       
end;
$_$ language plpgsql volatile;

create trigger setAdditionalSalesInfo before insert or update on sales for each row execute procedure setAdditionalSalesInfo();
create trigger setAdditionalSalesInfoPostCommit after insert or update on salesTenders for each row execute procedure setAdditionalSalesInfoPostCommit();

--emulate foreign keys on salesitems.plu
create or replace function salesitemsreferences() returns "trigger"
  as $$
declare
	tmp text;
begin
	if new.plu like ':%' then
		tmp := substring(new.plu from 2);
		perform id from discounts where id=cast(tmp as integer);
		if not found then
			raise exception 'The discount, %, does not exist.', tmp;
		end if;
	elsif new.plu like '#%' then --comments
		null;
	elsif new.plu like 'RA-TRANZ' then --r/a tranzactions
		null;
	else
		perform id from products where id=new.plu;
		if not found then
			raise exception 'The product, %, does not exist.', new.plu;
		end if;
	end if;
	return new;
end;
$$
  language plpgsql;

--products
create or replace function productsreferenced() returns "trigger"
  as $$
declare
	okrow record;
	itemstable text;
begin
	itemstable := TG_ARGV[0];
	if tg_op = 'UPDATE' then
		okrow := new;
		if new.id <> old.id then
			execute 'select plu from ' || quote_ident(itemstable) || ' where plu=old.id limit 1;';
			--perform plu from salesitems where plu=old.id limit 1;
			if found then
				raise exception 'As the product "%" is referenced in %, its ID can not be changed.', old.id, itemstable;
			end if;
		end if;
	elsif tg_op = 'DELETE' then
		okrow := old;
		execute 'select plu from ' || quote_ident(salesitems) || ' where plu=old.id limit 1;';
		--perform plu from salesitems where plu=old.id limit 1;
		if found then
			raise exception 'As the product "%" is referenced in %, it can not be deleted.', old.id, itemstable;
		end if;
	end if;
	return okrow;
end;
$$
  language plpgsql;

--discounts
create or replace function discountsreferenced() returns "trigger"
  as $$
declare
	okrow record;
	itemstable text;
begin
	itemstable := TG_ARGV[0];
	if tg_op = 'UPDATE' then
		okrow := new;
		if new.id <> old.id then
			execute 'select plu from ' || quote_ident(itemstable) || ' where plu=' || quote_literal(':') || '||' || quote_literal(old.id) ||' limit 1;';
			--perform plu from salesitems where plu=':'||old.id limit 1;
			if found then
				raise exception 'As the discount "%" is referenced in %, its ID can not be changed.', old.descr, itemstable;
			end if;
		end if;
	elsif tg_op = 'DELETE' then
		okrow := old;
		execute 'select plu from ' || quote_ident(itemstable) || ' where plu=' || quote_literal(':') || '||' || quote_literal(old.id) ||' limit 1;';
		--perform plu from salesitems where plu=':'||old.id limit 1;
		if found then
			raise exception 'As the discount "%" is referenced in %, it can not be deleted.', old.descr, itemstable;
		end if;
	end if;
	return okrow;
end;
$$
  language plpgsql;

--these are new, so we need to drop any old ones
drop trigger if exists discountsreferencedinsalecheck on discounts;
drop trigger if exists productsreferencedinsalecheck on products;

create trigger salesitemsreferencesinsalecheck before insert or update on salesitems for each row execute procedure salesitemsreferences();
create trigger productsreferencedinsalecheck before update or delete on products for each row execute procedure productsreferenced('salesitems');
create trigger discountsreferencedinsalecheck before update or delete on discounts for each row execute procedure discountsreferenced('salesitems');
--/emulated

--update lastSale, lastPay

update customers set lastPay = getBusinessDayFor(big.tranzDate) from (select max(sales.tranzDate) as tranzDate, sales.customer as customer from sales, salesItems where sales.suspended=false and sales.id=salesItems.id and salesItems.lineNo=0 and salesItems.plu='RA-TRANZ' and sales.voidAt is null and sales.customer<>'' group by sales.customer) as big where big.customer=customers.id;

update customers set lastSale = getBusinessDayFor(big.tranzDate) from (select max(sales.tranzDate) as tranzDate, sales.customer as customer from sales, salesItems where sales.suspended=false and sales.id=salesItems.id and salesItems.lineNo=0 and salesItems.plu<>'RA-TRANZ' and sales.voidAt is null and sales.customer<>'' group by sales.customer) as big where big.customer=customers.id;

--bug 1344 - separate cashier and server clerks
\echo bug 1344
begin;

alter table sales add column server smallint;
update sales set server=clerk where server is null;
alter table sales alter column server set not null;

alter table sales add foreign key (server) references clerks (id);

create index sales_server_ndx on sales (server);

commit;
\echo /bug 1344

--bug 1329
\echo bug 1329
begin;

CREATE TABLE sales_rev (
    id integer NOT NULL,
    customer character varying(20) NOT NULL,
    tranzdate timestamp with time zone NOT NULL,
    suspended boolean NOT NULL,
    clerk smallint NOT NULL,
    taxmask smallint NOT NULL,
    total bigint,
    balance bigint,
    terminal text,
    notes text,
    voidat timestamp with time zone,
    voidby text,
    created timestamp with time zone NOT NULL,
    createdby text NOT NULL,
    modified timestamp with time zone NOT NULL,
    modifiedby text NOT NULL,
    server smallint NOT NULL,

    r bigserial,

    primary key (id, r),
    foreign key (customer) references customers(id),
    foreign key (clerk) references clerks(id),
    foreign key (server) references clerks(id),

    foreign key (id) references sales(id)
);

create table salesItems_rev (
    id integer NOT NULL,
    lineno smallint NOT NULL,
    plu character varying(20),
    qty numeric(8,3) NOT NULL,
    amt bigint,

    r bigint,

    primary key (id, lineno, r),
    foreign key (id, r) references sales_rev(id, r)
);

CREATE TABLE salestaxes_rev (
    id integer NOT NULL,
    taxid smallint NOT NULL,
    taxable bigint,
    rate numeric(8,4) NOT NULL,
    tax bigint NOT NULL,

    r bigint,

    primary key (id, taxid, r),
    foreign key (id, r) references sales_rev(id, r),
    foreign key (taxid) references taxes(id)
);

CREATE TABLE salestenders_rev (
    id integer NOT NULL,
    lineno smallint NOT NULL,
    tender smallint NOT NULL,
    amt bigint,
    ext text,

    r bigint,

    primary key (id, lineno, r),
    foreign key (id, r) references sales_rev(id, r),
    foreign key (tender) references tenders(id)
);


insert into sales_rev select * from sales;
create trigger disallowChangesSales_rev before update or delete on sales_rev for each statement execute procedure disallowChanges();
select installPopulateRevTable('sales');

insert into salesitems_rev select salesitems.*, r from salesitems, sales_rev where sales_rev.id=salesitems.id;
create trigger disallowChangesSalesitems_rev before update or delete on salesitems_rev for each statement execute procedure disallowChanges();
select installPopulateKidzRevTable('salesitems', 'sales_rev_r_seq');

insert into salestaxes_rev select salestaxes.*, r from salestaxes, sales_rev where sales_rev.id=salestaxes.id;
create trigger disallowChangesSalestaxes_rev before update or delete on salestaxes_rev for each statement execute procedure disallowChanges();
select installPopulateKidzRevTable('salestaxes', 'sales_rev_r_seq');

insert into salestenders_rev select salestenders.*, r from salestenders, sales_rev where sales_rev.id=salestenders.id;
create trigger disallowChangesSalestenders_rev before update or delete on salestenders_rev for each statement execute procedure disallowChanges();
select installPopulateKidzRevTable('salestenders', 'sales_rev_r_seq');

create trigger salesitems_revreferencesinsale_revcheck before insert or update on salesitems_rev for each row execute procedure salesitemsreferences();
create trigger productsreferencedinsale_revcheck before update or delete on products for each row execute procedure productsreferenced('salesitems_rev');
create trigger discountsreferencedinsale_revcheck before update or delete on discounts for each row execute procedure discountsreferenced('salesitems_rev');

commit;
\echo /bug 1329

\echo /sales-delta.sql