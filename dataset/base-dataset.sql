--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

--
-- Name: plpgsql; Type: PROCEDURAL LANGUAGE; Schema: -; Owner: lanedbadmin
--

CREATE PROCEDURAL LANGUAGE plpgsql;


ALTER PROCEDURAL LANGUAGE plpgsql OWNER TO lanedbadmin;

SET search_path = public, pg_catalog;

--
-- Name: clearnonpersonusername(); Type: FUNCTION; Schema: public; Owner: lanedbadmin
--

CREATE FUNCTION clearnonpersonusername() RETURNS boolean
    LANGUAGE plpgsql
    AS $$
begin
        perform relname from pg_class where relname='lanenonpersonusername' and relnamespace=pg_my_temp_schema();
        if not found then
           return true;
        end if;
	drop table lanenonpersonusername;
       	return true;
end;
$$;


ALTER FUNCTION public.clearnonpersonusername() OWNER TO lanedbadmin;

--
-- Name: disallowchanges(); Type: FUNCTION; Schema: public; Owner: lanedbadmin
--

CREATE FUNCTION disallowchanges() RETURNS trigger
    LANGUAGE plpgsql IMMUTABLE
    AS $$
begin
        raise exception 'The table "%" does not allow % operations. Consider using "void" or balancing transactions.', tg_table_name, tg_op;
end;
$$;


ALTER FUNCTION public.disallowchanges() OWNER TO lanedbadmin;

--
-- Name: disallowchangesifparentisvoid(); Type: FUNCTION; Schema: public; Owner: lanedbadmin
--

CREATE FUNCTION disallowchangesifparentisvoid() RETURNS trigger
    LANGUAGE plpgsql STABLE
    AS $$
declare
        void timestamp with time zone;
        parent text;
begin
        parent := TG_ARGV[0];
        --raise info 'Trying: ' || 'select voidAt from ' || parent || ' where id=' || quote_literal(new.id);
        execute 'select voidAt from ' || parent || ' where id=' || quote_literal(new.id) into void;
        --select into void voidAt from parent where id=new.id;
        if void is not null then
           raise exception 'You cannot modify voided % or their subparts.', parent;
        end if;
        return new;
end;
$$;


ALTER FUNCTION public.disallowchangesifparentisvoid() OWNER TO lanedbadmin;

--
-- Name: disallowdelete(); Type: FUNCTION; Schema: public; Owner: lanedbadmin
--

CREATE FUNCTION disallowdelete() RETURNS trigger
    LANGUAGE plpgsql IMMUTABLE
    AS $$
begin
        if TG_OP = 'DELETE' then
                raise exception 'You may not delete % rows.', TG_RELNAME;
                --insert some sort of security accounting here
        end if;
        return new;
end;
$$;


ALTER FUNCTION public.disallowdelete() OWNER TO lanedbadmin;

--
-- Name: discountsreferenced(); Type: FUNCTION; Schema: public; Owner: lanedbadmin
--

CREATE FUNCTION discountsreferenced() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.discountsreferenced() OWNER TO lanedbadmin;

--
-- Name: getbusinessdayfor(timestamp with time zone); Type: FUNCTION; Schema: public; Owner: lanedbadmin
--

CREATE FUNCTION getbusinessdayfor(timestamp with time zone) RETURNS date
    LANGUAGE sql IMMUTABLE
    AS $_$select case when $1::time < data::time then ($1::date - '1 day'::interval)::date else $1::date end from sysStrings where id='Lane/CORE/Business Day Start Time'$_$;


ALTER FUNCTION public.getbusinessdayfor(timestamp with time zone) OWNER TO lanedbadmin;

--
-- Name: getcustname(character varying); Type: FUNCTION; Schema: public; Owner: lanedbadmin
--

CREATE FUNCTION getcustname(character varying) RETURNS character varying
    LANGUAGE sql
    AS $_$select case when char_length(coName) = 0 then cntFirst || ' ' || cntLast else coName end from customers where id = $1$_$;


ALTER FUNCTION public.getcustname(character varying) OWNER TO lanedbadmin;

--
-- Name: installpopulatekidzrevtable(name, name); Type: FUNCTION; Schema: public; Owner: lanedbadmin
--

CREATE FUNCTION installpopulatekidzrevtable(name, name) RETURNS void
    LANGUAGE plpgsql
    AS $_$
declare
        fbody text;
        fcmd text;
        tablename name;
begin
        tablename := $1 || '_rev';
        fbody := 'create or replace function populateKidzRev' || $1 || '() returns "trigger" as ' || quote_literal('
begin
        insert into ' || tablename || ' select new.*, currval(' || quote_literal($2) || ');
        return new;
end;') ||
' language plpgsql volatile;';

        fcmd := 'create trigger populateKidzRev' || $1 || ' after insert or update on ' || $1 || ' for each row execute procedure populateKidzRev' || $1 || '();';
        execute fbody;
        execute fcmd;
end;
$_$;


ALTER FUNCTION public.installpopulatekidzrevtable(name, name) OWNER TO lanedbadmin;

--
-- Name: installpopulaterevtable(name); Type: FUNCTION; Schema: public; Owner: lanedbadmin
--

CREATE FUNCTION installpopulaterevtable(name) RETURNS void
    LANGUAGE plpgsql
    AS $_$
declare
        fbody text;
        fcmd text;
        tablename name;
begin
        tablename := $1 || '_rev';
        fbody := 'create or replace function populateRev' || $1 || '() returns "trigger" as ' || quote_literal('
begin
        insert into ' || tablename || ' select new.*;
        return new;
end;') ||
' language plpgsql volatile;';

        fcmd := 'create trigger populateRev' || $1 || ' after insert or update on ' || $1 || ' for each row execute procedure populateRev' || $1 || '();';
        execute fbody;
        execute fcmd;
end;
$_$;


ALTER FUNCTION public.installpopulaterevtable(name) OWNER TO lanedbadmin;

--
-- Name: laneusername(); Type: FUNCTION; Schema: public; Owner: lanedbadmin
--

CREATE FUNCTION laneusername() RETURNS text
    LANGUAGE plpgsql STABLE
    AS $$
declare
        hostname text;
        username text := '';
begin
        /*
        Ideas for the nonperson+ID@terminal form:
         - in a single transaction
         - create a temporary table: create temporary table lanenonpersonauth (id text);
         - insert the "operation performed as" id into it: insert into lanenonpersonauth ('Clerks.id');
         - make the code below check for and use the info
         - drop the temporary table
         - commit the transaction
        */

	if inet_client_addr() is null then
		hostname := 'localhost';
	else
		hostname := inet_client_addr();
	end if;

        perform tablename from pg_tables where tablename='lanenonpersonusername';
        if found then
           select into username '+' || id from lanenonpersonusername limit 1;
        end if;

        username := session_user || username;

        return username || '@' || hostname;
end;
$$;


ALTER FUNCTION public.laneusername() OWNER TO lanedbadmin;

--
-- Name: populatekidzrevpurchaseordersordereditems(); Type: FUNCTION; Schema: public; Owner: lanedbadmin
--

CREATE FUNCTION populatekidzrevpurchaseordersordereditems() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
        insert into purchaseordersordereditems_rev select new.*, currval('purchaseorders_rev_r_seq');
        return new;
end;$$;


ALTER FUNCTION public.populatekidzrevpurchaseordersordereditems() OWNER TO lanedbadmin;

--
-- Name: populatekidzrevpurchaseordersreceiveditems(); Type: FUNCTION; Schema: public; Owner: lanedbadmin
--

CREATE FUNCTION populatekidzrevpurchaseordersreceiveditems() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
        insert into purchaseordersreceiveditems_rev select new.*, currval('purchaseorders_rev_r_seq');
        return new;
end;$$;


ALTER FUNCTION public.populatekidzrevpurchaseordersreceiveditems() OWNER TO lanedbadmin;

--
-- Name: populatekidzrevqwostatuses(); Type: FUNCTION; Schema: public; Owner: lanedbadmin
--

CREATE FUNCTION populatekidzrevqwostatuses() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
        insert into qwostatuses_rev select new.*, currval('qwo_rev_r_seq');
        return new;
end;$$;


ALTER FUNCTION public.populatekidzrevqwostatuses() OWNER TO lanedbadmin;

--
-- Name: populatekidzrevsalesitems(); Type: FUNCTION; Schema: public; Owner: lanedbadmin
--

CREATE FUNCTION populatekidzrevsalesitems() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
        insert into salesitems_rev select new.*, currval('sales_rev_r_seq');
        return new;
end;$$;


ALTER FUNCTION public.populatekidzrevsalesitems() OWNER TO lanedbadmin;

--
-- Name: populatekidzrevsalespayments(); Type: FUNCTION; Schema: public; Owner: lanedbadmin
--

CREATE FUNCTION populatekidzrevsalespayments() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
        insert into salesPayments_rev select new.*, currval('sales_rev_r_seq');
        return new;
end;$$;


ALTER FUNCTION public.populatekidzrevsalespayments() OWNER TO lanedbadmin;

--
-- Name: populatekidzrevsalestaxes(); Type: FUNCTION; Schema: public; Owner: lanedbadmin
--

CREATE FUNCTION populatekidzrevsalestaxes() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
        insert into salestaxes_rev select new.*, currval('sales_rev_r_seq');
        return new;
end;$$;


ALTER FUNCTION public.populatekidzrevsalestaxes() OWNER TO lanedbadmin;

--
-- Name: populatekidzrevsalestenders(); Type: FUNCTION; Schema: public; Owner: lanedbadmin
--

CREATE FUNCTION populatekidzrevsalestenders() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
        insert into salestenders_rev select new.*, currval('sales_rev_r_seq');
        return new;
end;$$;


ALTER FUNCTION public.populatekidzrevsalestenders() OWNER TO lanedbadmin;

--
-- Name: populaterevclerks(); Type: FUNCTION; Schema: public; Owner: lanedbadmin
--

CREATE FUNCTION populaterevclerks() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
        insert into clerks_rev select new.*;
        return new;
end;$$;


ALTER FUNCTION public.populaterevclerks() OWNER TO lanedbadmin;

--
-- Name: populaterevcustomers(); Type: FUNCTION; Schema: public; Owner: lanedbadmin
--

CREATE FUNCTION populaterevcustomers() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
        insert into customers_rev select new.*;
        return new;
end;$$;


ALTER FUNCTION public.populaterevcustomers() OWNER TO lanedbadmin;

--
-- Name: populaterevdiscounts(); Type: FUNCTION; Schema: public; Owner: lanedbadmin
--

CREATE FUNCTION populaterevdiscounts() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
        insert into discounts_rev select new.*;
        return new;
end;$$;


ALTER FUNCTION public.populaterevdiscounts() OWNER TO lanedbadmin;

--
-- Name: populaterevmachines(); Type: FUNCTION; Schema: public; Owner: lanedbadmin
--

CREATE FUNCTION populaterevmachines() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
        insert into machines_rev select new.*;
        return new;
end;$$;


ALTER FUNCTION public.populaterevmachines() OWNER TO lanedbadmin;

--
-- Name: populaterevpricetables(); Type: FUNCTION; Schema: public; Owner: lanedbadmin
--

CREATE FUNCTION populaterevpricetables() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
        insert into pricetables_rev select new.*;
        return new;
end;$$;


ALTER FUNCTION public.populaterevpricetables() OWNER TO lanedbadmin;

--
-- Name: populaterevproducts(); Type: FUNCTION; Schema: public; Owner: lanedbadmin
--

CREATE FUNCTION populaterevproducts() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
        insert into products_rev select new.*;
        return new;
end;$$;


ALTER FUNCTION public.populaterevproducts() OWNER TO lanedbadmin;

--
-- Name: populaterevpurchaseorders(); Type: FUNCTION; Schema: public; Owner: lanedbadmin
--

CREATE FUNCTION populaterevpurchaseorders() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
        insert into purchaseorders_rev select new.*;
        return new;
end;$$;


ALTER FUNCTION public.populaterevpurchaseorders() OWNER TO lanedbadmin;

--
-- Name: populaterevqwo(); Type: FUNCTION; Schema: public; Owner: lanedbadmin
--

CREATE FUNCTION populaterevqwo() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
        insert into qwo_rev select new.*;
        return new;
end;$$;


ALTER FUNCTION public.populaterevqwo() OWNER TO lanedbadmin;

--
-- Name: populaterevsales(); Type: FUNCTION; Schema: public; Owner: lanedbadmin
--

CREATE FUNCTION populaterevsales() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
        insert into sales_rev select new.*;
        return new;
end;$$;


ALTER FUNCTION public.populaterevsales() OWNER TO lanedbadmin;

--
-- Name: populaterevstrings(); Type: FUNCTION; Schema: public; Owner: lanedbadmin
--

CREATE FUNCTION populaterevstrings() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
        insert into strings_rev select new.*;
        return new;
end;$$;


ALTER FUNCTION public.populaterevstrings() OWNER TO lanedbadmin;

--
-- Name: populaterevsysstrings(); Type: FUNCTION; Schema: public; Owner: lanedbadmin
--

CREATE FUNCTION populaterevsysstrings() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
        insert into sysstrings_rev select new.*;
        return new;
end;$$;


ALTER FUNCTION public.populaterevsysstrings() OWNER TO lanedbadmin;

--
-- Name: populaterevtaxes(); Type: FUNCTION; Schema: public; Owner: lanedbadmin
--

CREATE FUNCTION populaterevtaxes() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
        insert into taxes_rev select new.*;
        return new;
end;$$;


ALTER FUNCTION public.populaterevtaxes() OWNER TO lanedbadmin;

--
-- Name: populaterevtenders(); Type: FUNCTION; Schema: public; Owner: lanedbadmin
--

CREATE FUNCTION populaterevtenders() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
        insert into tenders_rev select new.*;
        return new;
end;$$;


ALTER FUNCTION public.populaterevtenders() OWNER TO lanedbadmin;

--
-- Name: populaterevterms(); Type: FUNCTION; Schema: public; Owner: lanedbadmin
--

CREATE FUNCTION populaterevterms() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
        insert into terms_rev select new.*;
        return new;
end;$$;


ALTER FUNCTION public.populaterevterms() OWNER TO lanedbadmin;

--
-- Name: populaterevtimeclock(); Type: FUNCTION; Schema: public; Owner: lanedbadmin
--

CREATE FUNCTION populaterevtimeclock() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
        insert into timeclock_rev select new.*;
        return new;
end;$$;


ALTER FUNCTION public.populaterevtimeclock() OWNER TO lanedbadmin;

--
-- Name: populaterevvendors(); Type: FUNCTION; Schema: public; Owner: lanedbadmin
--

CREATE FUNCTION populaterevvendors() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
        insert into vendors_rev select new.*;
        return new;
end;$$;


ALTER FUNCTION public.populaterevvendors() OWNER TO lanedbadmin;

--
-- Name: productsreferenced(); Type: FUNCTION; Schema: public; Owner: lanedbadmin
--

CREATE FUNCTION productsreferenced() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.productsreferenced() OWNER TO lanedbadmin;

--
-- Name: purchaseorderssetuserinfo(); Type: FUNCTION; Schema: public; Owner: lanedbadmin
--

CREATE FUNCTION purchaseorderssetuserinfo() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
	username text;
begin
        select into username laneusername();

	if TG_OP = 'UPDATE' then
                if old.voidAt is not null then
                        raise exception 'Voided purchase orders may not be modified.';
                end if;
		--you can't change the creation info
		new.created := old.created;
		new.createdBy := old.createdBy;
		if new.voidAt is not null and old.voidAt is null then
			new.voidAt := current_timestamp;
			new.voidBy := username;
		end if;
	elsif TG_OP = 'INSERT' then
		new.created := current_timestamp;
		new.createdBy := username;
		if new.voidAt is not null then
			new.voidAt := current_timestamp;
			new.voidBy := username;
		end if;
	else
		raise exception 'This trigger can only be used for INSERT and UPDATE queries.';
	end if;

	if new.orderedVia is not null then
		new.orderedAt := current_timestamp;
		new.orderedBy := username;
	end if;

	new.modified := current_timestamp;
	new.modifiedBy := username;

	return new;
end;
$$;


ALTER FUNCTION public.purchaseorderssetuserinfo() OWNER TO lanedbadmin;

--
-- Name: purchaseorderssubparts(); Type: FUNCTION; Schema: public; Owner: lanedbadmin
--

CREATE FUNCTION purchaseorderssubparts() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
	username text;
        parentVoid boolean := false;
begin
        select into username laneusername();
        perform id from purchaseorders where id=new.id and voidAt is not null;
        if found then
                parentVoid := true;
        end if;

        if TG_OP = 'UPDATE' then
                if old.voidAt is not null then
                        raise exception 'Voided purchase orders may not be modified.';
                end if;
		/*--you can't change the creation info
		new.created := old.created;
		new.createdBy := old.createdBy;*/
		if new.voidAt is not null and (old.voidAt is null or parentVoid) then
			new.voidAt := current_timestamp;
			new.voidBy := username;
		end if;
                if TG_RELNAME = 'purchaseordersreceiveditems' then
                	new.received := old.received;
        		new.receivedBy := old.receivedBy;
                end if;
	elsif TG_OP = 'INSERT' then
                if TG_RELNAME = 'purchaseordersreceiveditems' then
                	new.received := current_timestamp;
        		new.receivedBy := username;
                end if;
		if new.voidAt is not null or parentVoid then
			new.voidAt := current_timestamp;
			new.voidBy := username;
		end if;
	else
		raise exception 'This trigger can only be used for INSERT and UPDATE queries.';
	end if;

	return new;       
end;
$$;


ALTER FUNCTION public.purchaseorderssubparts() OWNER TO lanedbadmin;

--
-- Name: salesitemsreferences(); Type: FUNCTION; Schema: public; Owner: lanedbadmin
--

CREATE FUNCTION salesitemsreferences() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.salesitemsreferences() OWNER TO lanedbadmin;

--
-- Name: secondsworkedcompleted(timestamp with time zone[]); Type: FUNCTION; Schema: public; Owner: lanedbadmin
--

CREATE FUNCTION secondsworkedcompleted(timestamp with time zone[]) RETURNS numeric
    LANGUAGE plpgsql IMMUTABLE
    AS $_$
declare
/*	times timestamp with time zone[] := ARRAY[];*/
	times timestamp with time zone[];
	count integer := 1;
	span numeric := 0;
	mag integer := 0;
begin
	times := $1;

	mag := array_upper(times,1);

	if mag % 2 = 1 then
           --remove the last time from the calculation -- only show completed ones
	   mag := mag - 1;
	end if;

	while count <= mag loop
		span := span + extract(epoch from times[count + 1] - times[count]);
		count := count + 2;
	end loop;
	return span;
end;
$_$;


ALTER FUNCTION public.secondsworkedcompleted(timestamp with time zone[]) OWNER TO lanedbadmin;

--
-- Name: secondsworkedestimated(timestamp with time zone[]); Type: FUNCTION; Schema: public; Owner: lanedbadmin
--

CREATE FUNCTION secondsworkedestimated(timestamp with time zone[]) RETURNS numeric
    LANGUAGE plpgsql STABLE
    AS $_$
declare
/*	times timestamp with time zone[] := ARRAY[];*/
	times timestamp with time zone[];
begin
	times := $1;
	if array_upper(times, 1) % 2 = 1 then
		times := times || current_timestamp;
	end if;
	return secondsWorkedCompleted(times);
end;
$_$;


ALTER FUNCTION public.secondsworkedestimated(timestamp with time zone[]) OWNER TO lanedbadmin;

--
-- Name: setadditionalsalesinfo(); Type: FUNCTION; Schema: public; Owner: lanedbadmin
--

CREATE FUNCTION setadditionalsalesinfo() RETURNS trigger
    LANGUAGE plpgsql STABLE
    AS $$
begin
        --fix a small issue with GenericObject/Dal being overly aggressive in making nulls
        if new.customer is null then
           new.customer := '';
        end if;

	return new;       
end;
$$;


ALTER FUNCTION public.setadditionalsalesinfo() OWNER TO lanedbadmin;

--
-- Name: setadditionalsalesinfopostcommit(); Type: FUNCTION; Schema: public; Owner: lanedbadmin
--

CREATE FUNCTION setadditionalsalesinfopostcommit() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.setadditionalsalesinfopostcommit() OWNER TO lanedbadmin;

--
-- Name: setadditionaltimeclockinfo(); Type: FUNCTION; Schema: public; Owner: lanedbadmin
--

CREATE FUNCTION setadditionaltimeclockinfo() RETURNS trigger
    LANGUAGE plpgsql STABLE
    AS $$
begin
	if TG_OP = 'UPDATE' then
           new.forced := old.forced;
           --don't allow any time to be adjusted: void and make new ones
           --if old.forced = false then
              if new.punch <> old.punch then
                 raise exception 'You can not adjust the time on punches. Void this record and create a new manual punch record.';
              end if;
              if new.clerk <> old.clerk then
                 raise exception 'You can not adjust the time on punches (clerk injection). Void this record and create a new manual punch record.';
              end if;
           --end if;
	elsif TG_OP = 'INSERT' then
              if new.forced = false then
                 new.punch := current_timestamp; --this may cause problems in the future
              end if;
	else
		raise exception 'This trigger can only be used for INSERT and UPDATE queries.';
	end if;

	return new;
end;
$$;


ALTER FUNCTION public.setadditionaltimeclockinfo() OWNER TO lanedbadmin;

--
-- Name: setnonpersonusername(text); Type: FUNCTION; Schema: public; Owner: lanedbadmin
--

CREATE FUNCTION setnonpersonusername(text) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
declare
        myschema text;
begin
        /*this needs to make use of various integrity checks*/
        perform relname from pg_class where relname='lanenonpersonusername' and relnamespace=pg_my_temp_schema();
        if not found then
           create temporary table lanenonpersonusername (id text);
        end if;
        delete from lanenonpersonusername;
        insert into lanenonpersonusername (id) values ($1);
        return true;
end;
$_$;


ALTER FUNCTION public.setnonpersonusername(text) OWNER TO lanedbadmin;

--
-- Name: setuserinfo(); Type: FUNCTION; Schema: public; Owner: lanedbadmin
--

CREATE FUNCTION setuserinfo() RETURNS trigger
    LANGUAGE plpgsql STABLE
    AS $$
declare
	username text;
begin
        select into username laneusername();

	if TG_OP = 'UPDATE' then
                if old.voidAt is not null then
                        raise exception 'Voided records may not be modified.';
                end if;
		--you can't change the creation info
		new.created := old.created;
		new.createdBy := old.createdBy;
		if new.voidAt is not null and old.voidAt is null then
                   new.voidAt := current_timestamp;
		   new.voidBy := username;
		end if;
	elsif TG_OP = 'INSERT' then
		new.created := current_timestamp;
		new.createdBy := username;
		if new.voidAt is not null then
			new.voidAt := current_timestamp;
			new.voidBy := username;
		end if;
	else
		raise exception 'This trigger can only be used for INSERT and UPDATE queries.';
	end if;

        new.modified := current_timestamp;
        new.modifiedBy := username;

	return new;
end;
$$;


ALTER FUNCTION public.setuserinfo() OWNER TO lanedbadmin;

--
-- Name: setuserinfotimeclockonly(); Type: FUNCTION; Schema: public; Owner: lanedbadmin
--

CREATE FUNCTION setuserinfotimeclockonly() RETURNS trigger
    LANGUAGE plpgsql STABLE
    AS $$
declare
	username text;
begin
        select into username laneusername();

	if TG_OP = 'UPDATE' then
                if old.voidAt is not null then
                        --the onlything you can change is the voidAt
                        if new.voidAt is not null then
                           raise exception 'Voided records may not be modified.';
                        else
                           new.voidAt := null;
                           new.voidBy := null;
                        end if;
                end if;
		--you can't change the creation info
		new.created := old.created;
		new.createdBy := old.createdBy;
		if new.voidAt is not null and old.voidAt is null then
                   new.voidAt := current_timestamp;
		   new.voidBy := username;
		end if;
	elsif TG_OP = 'INSERT' then
		new.created := current_timestamp;
		new.createdBy := username;
		if new.voidAt is not null then
			new.voidAt := current_timestamp;
			new.voidBy := username;
		end if;
	else
		raise exception 'This trigger can only be used for INSERT and UPDATE queries.';
	end if;

        new.modified := current_timestamp;
        new.modifiedBy := username;

	return new;
end;
$$;


ALTER FUNCTION public.setuserinfotimeclockonly() OWNER TO lanedbadmin;

--
-- Name: voidsale(integer); Type: FUNCTION; Schema: public; Owner: lanedbadmin
--

CREATE FUNCTION voidsale(integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
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
$_$;


ALTER FUNCTION public.voidsale(integer) OWNER TO lanedbadmin;

--
-- Name: secondsworkedcompleted(timestamp with time zone); Type: AGGREGATE; Schema: public; Owner: lanedbadmin
--

CREATE AGGREGATE secondsworkedcompleted(timestamp with time zone) (
    SFUNC = array_append,
    STYPE = timestamp with time zone[],
    INITCOND = '{}',
    FINALFUNC = public.secondsworkedcompleted
);


ALTER AGGREGATE public.secondsworkedcompleted(timestamp with time zone) OWNER TO lanedbadmin;

--
-- Name: secondsworkedestimated(timestamp with time zone); Type: AGGREGATE; Schema: public; Owner: lanedbadmin
--

CREATE AGGREGATE secondsworkedestimated(timestamp with time zone) (
    SFUNC = array_append,
    STYPE = timestamp with time zone[],
    INITCOND = '{}',
    FINALFUNC = public.secondsworkedestimated
);


ALTER AGGREGATE public.secondsworkedestimated(timestamp with time zone) OWNER TO lanedbadmin;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: clerks; Type: TABLE; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE TABLE clerks (
    id smallint NOT NULL,
    name character varying(20) NOT NULL,
    passcode smallint NOT NULL,
    drawer character(1),
    voidat timestamp with time zone,
    voidby text,
    created timestamp with time zone NOT NULL,
    createdby text NOT NULL,
    modified timestamp with time zone NOT NULL,
    modifiedby text NOT NULL
);


ALTER TABLE public.clerks OWNER TO lanedbadmin;

--
-- Name: clerks_rev; Type: TABLE; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE TABLE clerks_rev (
    id smallint NOT NULL,
    name character varying(20) NOT NULL,
    passcode smallint NOT NULL,
    drawer character(1),
    voidat timestamp with time zone,
    voidby text,
    created timestamp with time zone NOT NULL,
    createdby text NOT NULL,
    modified timestamp with time zone NOT NULL,
    modifiedby text NOT NULL,
    r bigint NOT NULL
);


ALTER TABLE public.clerks_rev OWNER TO lanedbadmin;

--
-- Name: clerks_rev_r_seq; Type: SEQUENCE; Schema: public; Owner: lanedbadmin
--

CREATE SEQUENCE clerks_rev_r_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.clerks_rev_r_seq OWNER TO lanedbadmin;

--
-- Name: clerks_rev_r_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: lanedbadmin
--

ALTER SEQUENCE clerks_rev_r_seq OWNED BY clerks_rev.r;


--
-- Name: clerks_rev_r_seq; Type: SEQUENCE SET; Schema: public; Owner: lanedbadmin
--

SELECT pg_catalog.setval('clerks_rev_r_seq', 1, true);


--
-- Name: customers; Type: TABLE; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE TABLE customers (
    id character varying(15) NOT NULL,
    coname character varying(40),
    cntfirst character varying(35),
    cntlast character varying(35),
    billaddr1 character varying(40),
    billaddr2 character varying(40),
    billcity character varying(35),
    billst character varying(2),
    billzip character varying(10),
    billcountry character varying(2) DEFAULT 'us'::character varying,
    billphone character varying(15),
    billfax character varying(15),
    shipaddr1 character varying(40),
    shipaddr2 character varying(40),
    shipcity character varying(35),
    shipst character varying(2),
    shipzip character varying(10),
    shipcountry character varying(2) DEFAULT 'us'::character varying,
    shipphone character varying(15),
    shipfax character varying(15),
    email character varying(40),
    custtype smallint DEFAULT 0 NOT NULL,
    creditlmt numeric(15,2) NOT NULL,
    balance numeric(15,2) NOT NULL,
    creditrmn numeric(15,2) NOT NULL,
    lastsale date,
    lastpay date,
    terms character varying(5) NOT NULL,
    notes text,
    createdby text NOT NULL,
    created timestamp with time zone NOT NULL,
    taxes smallint DEFAULT 32767 NOT NULL,
    voidat timestamp with time zone,
    voidby text,
    modified timestamp with time zone NOT NULL,
    modifiedby text NOT NULL
);


ALTER TABLE public.customers OWNER TO lanedbadmin;

--
-- Name: customers_rev; Type: TABLE; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE TABLE customers_rev (
    id character varying(15) NOT NULL,
    coname character varying(40),
    cntfirst character varying(35),
    cntlast character varying(35),
    billaddr1 character varying(40),
    billaddr2 character varying(40),
    billcity character varying(35),
    billst character varying(2),
    billzip character varying(10),
    billcountry character varying(2) DEFAULT 'us'::character varying,
    billphone character varying(15),
    billfax character varying(15),
    shipaddr1 character varying(40),
    shipaddr2 character varying(40),
    shipcity character varying(35),
    shipst character varying(2),
    shipzip character varying(10),
    shipcountry character varying(2) DEFAULT 'us'::character varying,
    shipphone character varying(15),
    shipfax character varying(15),
    email character varying(40),
    custtype smallint DEFAULT 0 NOT NULL,
    creditlmt numeric(15,2) NOT NULL,
    balance numeric(15,2) NOT NULL,
    creditrmn numeric(15,2) NOT NULL,
    lastsale date,
    lastpay date,
    terms character varying(5) NOT NULL,
    notes text,
    createdby text NOT NULL,
    created timestamp with time zone NOT NULL,
    taxes smallint DEFAULT 32767 NOT NULL,
    voidat timestamp with time zone,
    voidby text,
    modified timestamp with time zone NOT NULL,
    modifiedby text NOT NULL,
    r bigint NOT NULL
);


ALTER TABLE public.customers_rev OWNER TO lanedbadmin;

--
-- Name: customers_rev_r_seq; Type: SEQUENCE; Schema: public; Owner: lanedbadmin
--

CREATE SEQUENCE customers_rev_r_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.customers_rev_r_seq OWNER TO lanedbadmin;

--
-- Name: customers_rev_r_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: lanedbadmin
--

ALTER SEQUENCE customers_rev_r_seq OWNED BY customers_rev.r;


--
-- Name: customers_rev_r_seq; Type: SEQUENCE SET; Schema: public; Owner: lanedbadmin
--

SELECT pg_catalog.setval('customers_rev_r_seq', 1, true);


--
-- Name: discounts; Type: TABLE; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE TABLE discounts (
    id smallint NOT NULL,
    descr character varying(20) NOT NULL,
    preset boolean NOT NULL,
    per boolean NOT NULL,
    amt numeric(10,2) NOT NULL,
    sale boolean NOT NULL,
    voidat timestamp with time zone,
    voidby text,
    created timestamp with time zone NOT NULL,
    createdby text NOT NULL,
    modified timestamp with time zone NOT NULL,
    modifiedby text NOT NULL
);


ALTER TABLE public.discounts OWNER TO lanedbadmin;

--
-- Name: discounts_rev; Type: TABLE; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE TABLE discounts_rev (
    id smallint NOT NULL,
    descr character varying(20) NOT NULL,
    preset boolean NOT NULL,
    per boolean NOT NULL,
    amt numeric(10,2) NOT NULL,
    sale boolean NOT NULL,
    voidat timestamp with time zone,
    voidby text,
    created timestamp with time zone,
    createdby text,
    modified timestamp with time zone,
    modifiedby text,
    r bigint NOT NULL
);


ALTER TABLE public.discounts_rev OWNER TO lanedbadmin;

--
-- Name: discounts_rev_r_seq; Type: SEQUENCE; Schema: public; Owner: lanedbadmin
--

CREATE SEQUENCE discounts_rev_r_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.discounts_rev_r_seq OWNER TO lanedbadmin;

--
-- Name: discounts_rev_r_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: lanedbadmin
--

ALTER SEQUENCE discounts_rev_r_seq OWNED BY discounts_rev.r;


--
-- Name: discounts_rev_r_seq; Type: SEQUENCE SET; Schema: public; Owner: lanedbadmin
--

SELECT pg_catalog.setval('discounts_rev_r_seq', 5, true);


--
-- Name: locale; Type: TABLE; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE TABLE locale (
    lang text NOT NULL,
    id text NOT NULL,
    data text
);


ALTER TABLE public.locale OWNER TO lanedbadmin;

--
-- Name: machines; Type: TABLE; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE TABLE machines (
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
    modifiedby text NOT NULL
);


ALTER TABLE public.machines OWNER TO lanedbadmin;

--
-- Name: machines_rev; Type: TABLE; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE TABLE machines_rev (
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
    r bigint NOT NULL
);


ALTER TABLE public.machines_rev OWNER TO lanedbadmin;

--
-- Name: machines_rev_r_seq; Type: SEQUENCE; Schema: public; Owner: lanedbadmin
--

CREATE SEQUENCE machines_rev_r_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.machines_rev_r_seq OWNER TO lanedbadmin;

--
-- Name: machines_rev_r_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: lanedbadmin
--

ALTER SEQUENCE machines_rev_r_seq OWNED BY machines_rev.r;


--
-- Name: machines_rev_r_seq; Type: SEQUENCE SET; Schema: public; Owner: lanedbadmin
--

SELECT pg_catalog.setval('machines_rev_r_seq', 1, false);


--
-- Name: po; Type: TABLE; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE TABLE po (
    id integer NOT NULL,
    vendor character varying(20) NOT NULL,
    created timestamp with time zone NOT NULL,
    modified timestamp with time zone NOT NULL,
    creator integer NOT NULL,
    notes text
);


ALTER TABLE public.po OWNER TO lanedbadmin;

--
-- Name: po2vendor; Type: TABLE; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE TABLE po2vendor (
    vendor character varying(20) NOT NULL,
    action text NOT NULL
);


ALTER TABLE public.po2vendor OWNER TO lanedbadmin;

--
-- Name: poitems; Type: TABLE; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE TABLE poitems (
    id integer NOT NULL,
    lineno smallint NOT NULL,
    product character varying(20) NOT NULL,
    orderedqty numeric(8,3) NOT NULL,
    rcvdqty numeric(8,3) NOT NULL
);


ALTER TABLE public.poitems OWNER TO lanedbadmin;

--
-- Name: poseq; Type: SEQUENCE; Schema: public; Owner: lanedbadmin
--

CREATE SEQUENCE poseq
    START WITH 1
    INCREMENT BY 1
    MAXVALUE 2147483647
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.poseq OWNER TO lanedbadmin;

--
-- Name: poseq; Type: SEQUENCE SET; Schema: public; Owner: lanedbadmin
--

SELECT pg_catalog.setval('poseq', 1, false);


--
-- Name: pricetables; Type: TABLE; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE TABLE pricetables (
    id smallint NOT NULL,
    pricelist text,
    voidat timestamp with time zone,
    voidby text,
    created timestamp with time zone NOT NULL,
    createdby text NOT NULL,
    modified timestamp with time zone NOT NULL,
    modifiedby text NOT NULL
);


ALTER TABLE public.pricetables OWNER TO lanedbadmin;

--
-- Name: pricetables_rev; Type: TABLE; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE TABLE pricetables_rev (
    id smallint NOT NULL,
    pricelist text,
    voidat timestamp with time zone,
    voidby text,
    created timestamp with time zone,
    createdby text,
    modified timestamp with time zone,
    modifiedby text,
    r bigint NOT NULL
);


ALTER TABLE public.pricetables_rev OWNER TO lanedbadmin;

--
-- Name: pricetables_rev_r_seq; Type: SEQUENCE; Schema: public; Owner: lanedbadmin
--

CREATE SEQUENCE pricetables_rev_r_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.pricetables_rev_r_seq OWNER TO lanedbadmin;

--
-- Name: pricetables_rev_r_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: lanedbadmin
--

ALTER SEQUENCE pricetables_rev_r_seq OWNED BY pricetables_rev.r;


--
-- Name: pricetables_rev_r_seq; Type: SEQUENCE SET; Schema: public; Owner: lanedbadmin
--

SELECT pg_catalog.setval('pricetables_rev_r_seq', 1, true);


--
-- Name: products; Type: TABLE; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE TABLE products (
    id character varying(20) NOT NULL,
    descr character varying(40) NOT NULL,
    price numeric(8,3) NOT NULL,
    category character varying(5) NOT NULL,
    taxes smallint NOT NULL,
    type character(1) NOT NULL,
    trackqty boolean NOT NULL,
    onhand numeric(15,3) NOT NULL,
    minimum numeric(15,3) NOT NULL,
    reorder numeric(15,3) NOT NULL,
    vendor character varying(20),
    caseqty numeric(15,3),
    caseid character varying(20),
    extended text,
    cost numeric(8,3),
    reorderid character varying(20),
    voidat timestamp with time zone,
    voidby text,
    created timestamp with time zone NOT NULL,
    createdby text NOT NULL,
    modified timestamp with time zone NOT NULL,
    modifiedby text NOT NULL
);


ALTER TABLE public.products OWNER TO lanedbadmin;

--
-- Name: products_rev; Type: TABLE; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE TABLE products_rev (
    id character varying(20) NOT NULL,
    descr character varying(40) NOT NULL,
    price numeric(8,3) NOT NULL,
    category character varying(5) NOT NULL,
    taxes smallint NOT NULL,
    type character(1) NOT NULL,
    trackqty boolean NOT NULL,
    onhand numeric(15,3) NOT NULL,
    minimum numeric(15,3) NOT NULL,
    reorder numeric(15,3) NOT NULL,
    vendor character varying(20),
    caseqty numeric(15,3),
    caseid character varying(20),
    extended text,
    cost numeric(8,3),
    reorderid character varying(20),
    voidat timestamp with time zone,
    voidby text,
    created timestamp with time zone,
    createdby text,
    modified timestamp with time zone,
    modifiedby text,
    r bigint NOT NULL
);


ALTER TABLE public.products_rev OWNER TO lanedbadmin;

--
-- Name: products_rev_r_seq; Type: SEQUENCE; Schema: public; Owner: lanedbadmin
--

CREATE SEQUENCE products_rev_r_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.products_rev_r_seq OWNER TO lanedbadmin;

--
-- Name: products_rev_r_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: lanedbadmin
--

ALTER SEQUENCE products_rev_r_seq OWNED BY products_rev.r;


--
-- Name: products_rev_r_seq; Type: SEQUENCE SET; Schema: public; Owner: lanedbadmin
--

SELECT pg_catalog.setval('products_rev_r_seq', 1, false);


--
-- Name: purchaseorders; Type: TABLE; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE TABLE purchaseorders (
    id integer NOT NULL,
    vendor character varying(15),
    created timestamp with time zone,
    createdby text,
    modified timestamp with time zone,
    modifiedby text,
    notes text,
    extended text,
    total integer NOT NULL,
    voidat timestamp with time zone,
    voidby text,
    orderedat timestamp with time zone,
    orderedby text,
    orderedvia text,
    completelyreceived boolean DEFAULT false NOT NULL
);


ALTER TABLE public.purchaseorders OWNER TO lanedbadmin;

--
-- Name: purchaseorders_id_seq; Type: SEQUENCE; Schema: public; Owner: lanedbadmin
--

CREATE SEQUENCE purchaseorders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.purchaseorders_id_seq OWNER TO lanedbadmin;

--
-- Name: purchaseorders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: lanedbadmin
--

ALTER SEQUENCE purchaseorders_id_seq OWNED BY purchaseorders.id;


--
-- Name: purchaseorders_id_seq; Type: SEQUENCE SET; Schema: public; Owner: lanedbadmin
--

SELECT pg_catalog.setval('purchaseorders_id_seq', 1, false);


--
-- Name: purchaseorders_rev; Type: TABLE; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE TABLE purchaseorders_rev (
    id integer NOT NULL,
    vendor character varying(15),
    created timestamp with time zone,
    createdby text,
    modified timestamp with time zone,
    modifiedby text,
    notes text,
    extended text,
    total integer NOT NULL,
    voidat timestamp with time zone,
    voidby text,
    orderedat timestamp with time zone,
    orderedby text,
    orderedvia text,
    completelyreceived boolean DEFAULT false NOT NULL,
    r bigint NOT NULL
);


ALTER TABLE public.purchaseorders_rev OWNER TO lanedbadmin;

--
-- Name: purchaseorders_rev_r_seq; Type: SEQUENCE; Schema: public; Owner: lanedbadmin
--

CREATE SEQUENCE purchaseorders_rev_r_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.purchaseorders_rev_r_seq OWNER TO lanedbadmin;

--
-- Name: purchaseorders_rev_r_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: lanedbadmin
--

ALTER SEQUENCE purchaseorders_rev_r_seq OWNED BY purchaseorders_rev.r;


--
-- Name: purchaseorders_rev_r_seq; Type: SEQUENCE SET; Schema: public; Owner: lanedbadmin
--

SELECT pg_catalog.setval('purchaseorders_rev_r_seq', 1, false);


--
-- Name: purchaseordersordereditems; Type: TABLE; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE TABLE purchaseordersordereditems (
    id integer NOT NULL,
    lineno smallint NOT NULL,
    plu character varying(20) NOT NULL,
    qty numeric(20,6) NOT NULL,
    amt integer NOT NULL,
    voidat timestamp with time zone,
    voidby text,
    extended text
);


ALTER TABLE public.purchaseordersordereditems OWNER TO lanedbadmin;

--
-- Name: purchaseordersordereditems_rev; Type: TABLE; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE TABLE purchaseordersordereditems_rev (
    id integer NOT NULL,
    lineno smallint NOT NULL,
    plu character varying(20) NOT NULL,
    qty numeric(20,6) NOT NULL,
    amt integer NOT NULL,
    voidat timestamp with time zone,
    voidby text,
    extended text,
    r bigint NOT NULL
);


ALTER TABLE public.purchaseordersordereditems_rev OWNER TO lanedbadmin;

--
-- Name: purchaseordersreceiveditems; Type: TABLE; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE TABLE purchaseordersreceiveditems (
    id integer NOT NULL,
    lineno smallint NOT NULL,
    plu character varying(20) NOT NULL,
    qty numeric(20,6) NOT NULL,
    received timestamp with time zone,
    receivedby text,
    voidat timestamp with time zone,
    voidby text,
    extended text
);


ALTER TABLE public.purchaseordersreceiveditems OWNER TO lanedbadmin;

--
-- Name: purchaseordersreceiveditems_rev; Type: TABLE; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE TABLE purchaseordersreceiveditems_rev (
    id integer NOT NULL,
    lineno smallint NOT NULL,
    plu character varying(20) NOT NULL,
    qty numeric(20,6) NOT NULL,
    received timestamp with time zone,
    receivedby text,
    voidat timestamp with time zone,
    voidby text,
    extended text,
    r bigint NOT NULL
);


ALTER TABLE public.purchaseordersreceiveditems_rev OWNER TO lanedbadmin;

--
-- Name: qwo; Type: TABLE; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE TABLE qwo (
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
    modifiedby text NOT NULL
);


ALTER TABLE public.qwo OWNER TO lanedbadmin;

--
-- Name: qwo_id_seq; Type: SEQUENCE; Schema: public; Owner: lanedbadmin
--

CREATE SEQUENCE qwo_id_seq
    START WITH 1
    INCREMENT BY 1
    MAXVALUE 10000000
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.qwo_id_seq OWNER TO lanedbadmin;

--
-- Name: qwo_id_seq; Type: SEQUENCE SET; Schema: public; Owner: lanedbadmin
--

SELECT pg_catalog.setval('qwo_id_seq', 1, true);


--
-- Name: qwo_rev; Type: TABLE; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE TABLE qwo_rev (
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
    r bigint NOT NULL
);


ALTER TABLE public.qwo_rev OWNER TO lanedbadmin;

--
-- Name: qwo_rev_r_seq; Type: SEQUENCE; Schema: public; Owner: lanedbadmin
--

CREATE SEQUENCE qwo_rev_r_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.qwo_rev_r_seq OWNER TO lanedbadmin;

--
-- Name: qwo_rev_r_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: lanedbadmin
--

ALTER SEQUENCE qwo_rev_r_seq OWNED BY qwo_rev.r;


--
-- Name: qwo_rev_r_seq; Type: SEQUENCE SET; Schema: public; Owner: lanedbadmin
--

SELECT pg_catalog.setval('qwo_rev_r_seq', 1, false);


--
-- Name: qwostatuses; Type: TABLE; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE TABLE qwostatuses (
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
    modifiedby text NOT NULL
);


ALTER TABLE public.qwostatuses OWNER TO lanedbadmin;

--
-- Name: qwostatuses_rev; Type: TABLE; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE TABLE qwostatuses_rev (
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
    r bigint NOT NULL
);


ALTER TABLE public.qwostatuses_rev OWNER TO lanedbadmin;

--
-- Name: sales; Type: TABLE; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE TABLE sales (
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
    server smallint NOT NULL
);


ALTER TABLE public.sales OWNER TO lanedbadmin;

--
-- Name: sales_id_seq; Type: SEQUENCE; Schema: public; Owner: lanedbadmin
--

CREATE SEQUENCE sales_id_seq
    START WITH 1
    INCREMENT BY 1
    MAXVALUE 2147483647
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.sales_id_seq OWNER TO lanedbadmin;

--
-- Name: sales_id_seq; Type: SEQUENCE SET; Schema: public; Owner: lanedbadmin
--

SELECT pg_catalog.setval('sales_id_seq', 1, true);


--
-- Name: sales_rev; Type: TABLE; Schema: public; Owner: lanedbadmin; Tablespace: 
--

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
    r bigint NOT NULL
);


ALTER TABLE public.sales_rev OWNER TO lanedbadmin;

--
-- Name: sales_rev_r_seq; Type: SEQUENCE; Schema: public; Owner: lanedbadmin
--

CREATE SEQUENCE sales_rev_r_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.sales_rev_r_seq OWNER TO lanedbadmin;

--
-- Name: sales_rev_r_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: lanedbadmin
--

ALTER SEQUENCE sales_rev_r_seq OWNED BY sales_rev.r;


--
-- Name: sales_rev_r_seq; Type: SEQUENCE SET; Schema: public; Owner: lanedbadmin
--

SELECT pg_catalog.setval('sales_rev_r_seq', 1, false);


--
-- Name: salesitems; Type: TABLE; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE TABLE salesitems (
    id integer NOT NULL,
    lineno smallint NOT NULL,
    plu character varying(20),
    qty numeric(8,3) NOT NULL,
    amt bigint,
    struck boolean DEFAULT false NOT NULL
);


ALTER TABLE public.salesitems OWNER TO lanedbadmin;

--
-- Name: salesitems_rev; Type: TABLE; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE TABLE salesitems_rev (
    id integer NOT NULL,
    lineno smallint NOT NULL,
    plu character varying(20),
    qty numeric(8,3) NOT NULL,
    amt bigint,
    struck boolean DEFAULT false NOT NULL,
    r bigint NOT NULL
);


ALTER TABLE public.salesitems_rev OWNER TO lanedbadmin;

--
-- Name: salespayments; Type: TABLE; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE TABLE salespayments (
    id integer NOT NULL,
    lineno smallint NOT NULL,
    tranzdate timestamp with time zone NOT NULL,
    raid integer NOT NULL,
    amt bigint NOT NULL,
    struck boolean DEFAULT false NOT NULL,
    notes text,
    ext text
);


ALTER TABLE public.salespayments OWNER TO lanedbadmin;

--
-- Name: salespayments_rev; Type: TABLE; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE TABLE salespayments_rev (
    id integer NOT NULL,
    lineno smallint NOT NULL,
    tranzdate timestamp with time zone NOT NULL,
    raid integer NOT NULL,
    amt bigint NOT NULL,
    struck boolean DEFAULT false NOT NULL,
    notes text,
    ext text,
    r bigint NOT NULL
);


ALTER TABLE public.salespayments_rev OWNER TO lanedbadmin;

--
-- Name: salestaxes; Type: TABLE; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE TABLE salestaxes (
    id integer NOT NULL,
    taxid smallint NOT NULL,
    taxable bigint,
    rate numeric(8,4) NOT NULL,
    tax bigint NOT NULL
);


ALTER TABLE public.salestaxes OWNER TO lanedbadmin;

--
-- Name: salestaxes_rev; Type: TABLE; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE TABLE salestaxes_rev (
    id integer NOT NULL,
    taxid smallint NOT NULL,
    taxable bigint,
    rate numeric(8,4) NOT NULL,
    tax bigint NOT NULL,
    r bigint NOT NULL
);


ALTER TABLE public.salestaxes_rev OWNER TO lanedbadmin;

--
-- Name: salestenders; Type: TABLE; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE TABLE salestenders (
    id integer NOT NULL,
    lineno smallint NOT NULL,
    tender smallint NOT NULL,
    amt bigint,
    ext text
);


ALTER TABLE public.salestenders OWNER TO lanedbadmin;

--
-- Name: salestenders_rev; Type: TABLE; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE TABLE salestenders_rev (
    id integer NOT NULL,
    lineno smallint NOT NULL,
    tender smallint NOT NULL,
    amt bigint,
    ext text,
    r bigint NOT NULL
);


ALTER TABLE public.salestenders_rev OWNER TO lanedbadmin;

--
-- Name: strings; Type: TABLE; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE TABLE strings (
    id text NOT NULL,
    data text NOT NULL,
    voidat timestamp with time zone,
    voidby text,
    created timestamp with time zone NOT NULL,
    createdby text NOT NULL,
    modified timestamp with time zone NOT NULL,
    modifiedby text NOT NULL
);


ALTER TABLE public.strings OWNER TO lanedbadmin;

--
-- Name: strings_rev; Type: TABLE; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE TABLE strings_rev (
    id text NOT NULL,
    data text,
    voidat timestamp with time zone,
    voidby text,
    created timestamp with time zone NOT NULL,
    createdby text NOT NULL,
    modified timestamp with time zone NOT NULL,
    modifiedby text NOT NULL,
    r bigint NOT NULL
);


ALTER TABLE public.strings_rev OWNER TO lanedbadmin;

--
-- Name: strings_rev_r_seq; Type: SEQUENCE; Schema: public; Owner: lanedbadmin
--

CREATE SEQUENCE strings_rev_r_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.strings_rev_r_seq OWNER TO lanedbadmin;

--
-- Name: strings_rev_r_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: lanedbadmin
--

ALTER SEQUENCE strings_rev_r_seq OWNED BY strings_rev.r;


--
-- Name: strings_rev_r_seq; Type: SEQUENCE SET; Schema: public; Owner: lanedbadmin
--

SELECT pg_catalog.setval('strings_rev_r_seq', 10, true);


--
-- Name: sysstrings; Type: TABLE; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE TABLE sysstrings (
    id text NOT NULL,
    data text NOT NULL,
    voidat timestamp with time zone,
    voidby text,
    created timestamp with time zone NOT NULL,
    createdby text NOT NULL,
    modified timestamp with time zone NOT NULL,
    modifiedby text NOT NULL
);


ALTER TABLE public.sysstrings OWNER TO lanedbadmin;

--
-- Name: sysstrings_rev; Type: TABLE; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE TABLE sysstrings_rev (
    id text NOT NULL,
    data text,
    voidat timestamp with time zone,
    voidby text,
    created timestamp with time zone NOT NULL,
    createdby text NOT NULL,
    modified timestamp with time zone NOT NULL,
    modifiedby text NOT NULL,
    r bigint NOT NULL
);


ALTER TABLE public.sysstrings_rev OWNER TO lanedbadmin;

--
-- Name: sysstrings_rev_r_seq; Type: SEQUENCE; Schema: public; Owner: lanedbadmin
--

CREATE SEQUENCE sysstrings_rev_r_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.sysstrings_rev_r_seq OWNER TO lanedbadmin;

--
-- Name: sysstrings_rev_r_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: lanedbadmin
--

ALTER SEQUENCE sysstrings_rev_r_seq OWNED BY sysstrings_rev.r;


--
-- Name: sysstrings_rev_r_seq; Type: SEQUENCE SET; Schema: public; Owner: lanedbadmin
--

SELECT pg_catalog.setval('sysstrings_rev_r_seq', 19, true);


--
-- Name: taxes; Type: TABLE; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE TABLE taxes (
    id smallint NOT NULL,
    descr character varying(20) NOT NULL,
    amount numeric(8,4),
    voidat timestamp with time zone,
    voidby text,
    created timestamp with time zone NOT NULL,
    createdby text NOT NULL,
    modified timestamp with time zone NOT NULL,
    modifiedby text NOT NULL
);


ALTER TABLE public.taxes OWNER TO lanedbadmin;

--
-- Name: taxes_rev; Type: TABLE; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE TABLE taxes_rev (
    id smallint NOT NULL,
    descr character varying(20) NOT NULL,
    amount numeric(8,4),
    voidat timestamp with time zone,
    voidby text,
    created timestamp with time zone,
    createdby text,
    modified timestamp with time zone,
    modifiedby text,
    r bigint NOT NULL
);


ALTER TABLE public.taxes_rev OWNER TO lanedbadmin;

--
-- Name: taxes_rev_r_seq; Type: SEQUENCE; Schema: public; Owner: lanedbadmin
--

CREATE SEQUENCE taxes_rev_r_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.taxes_rev_r_seq OWNER TO lanedbadmin;

--
-- Name: taxes_rev_r_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: lanedbadmin
--

ALTER SEQUENCE taxes_rev_r_seq OWNED BY taxes_rev.r;


--
-- Name: taxes_rev_r_seq; Type: SEQUENCE SET; Schema: public; Owner: lanedbadmin
--

SELECT pg_catalog.setval('taxes_rev_r_seq', 2, true);


--
-- Name: tenders; Type: TABLE; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE TABLE tenders (
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
    voidat timestamp with time zone,
    voidby text,
    created timestamp with time zone NOT NULL,
    createdby text NOT NULL,
    modified timestamp with time zone NOT NULL,
    modifiedby text NOT NULL
);


ALTER TABLE public.tenders OWNER TO lanedbadmin;

--
-- Name: tenders_rev; Type: TABLE; Schema: public; Owner: lanedbadmin; Tablespace: 
--

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
    voidat timestamp with time zone,
    voidby text,
    created timestamp with time zone,
    createdby text,
    modified timestamp with time zone,
    modifiedby text,
    r bigint NOT NULL
);


ALTER TABLE public.tenders_rev OWNER TO lanedbadmin;

--
-- Name: tenders_rev_r_seq; Type: SEQUENCE; Schema: public; Owner: lanedbadmin
--

CREATE SEQUENCE tenders_rev_r_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.tenders_rev_r_seq OWNER TO lanedbadmin;

--
-- Name: tenders_rev_r_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: lanedbadmin
--

ALTER SEQUENCE tenders_rev_r_seq OWNED BY tenders_rev.r;


--
-- Name: tenders_rev_r_seq; Type: SEQUENCE SET; Schema: public; Owner: lanedbadmin
--

SELECT pg_catalog.setval('tenders_rev_r_seq', 9, true);


--
-- Name: terms; Type: TABLE; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE TABLE terms (
    id character varying(5) NOT NULL,
    descr character varying(20) NOT NULL,
    duedays smallint NOT NULL,
    finrate numeric(9,4) NOT NULL,
    discdays smallint NOT NULL,
    discrate numeric(9,4) NOT NULL,
    createdby text NOT NULL,
    created timestamp with time zone NOT NULL,
    voidat timestamp with time zone,
    voidby text,
    modified timestamp with time zone NOT NULL,
    modifiedby text NOT NULL
);


ALTER TABLE public.terms OWNER TO lanedbadmin;

--
-- Name: terms_rev; Type: TABLE; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE TABLE terms_rev (
    id character varying(5) NOT NULL,
    descr character varying(20) NOT NULL,
    duedays smallint NOT NULL,
    finrate numeric(9,4) NOT NULL,
    discdays smallint NOT NULL,
    discrate numeric(9,4) NOT NULL,
    createdby text NOT NULL,
    created timestamp with time zone NOT NULL,
    voidat timestamp with time zone,
    voidby text,
    modified timestamp with time zone,
    modifiedby text,
    r bigint NOT NULL
);


ALTER TABLE public.terms_rev OWNER TO lanedbadmin;

--
-- Name: terms_rev_r_seq; Type: SEQUENCE; Schema: public; Owner: lanedbadmin
--

CREATE SEQUENCE terms_rev_r_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.terms_rev_r_seq OWNER TO lanedbadmin;

--
-- Name: terms_rev_r_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: lanedbadmin
--

ALTER SEQUENCE terms_rev_r_seq OWNED BY terms_rev.r;


--
-- Name: terms_rev_r_seq; Type: SEQUENCE SET; Schema: public; Owner: lanedbadmin
--

SELECT pg_catalog.setval('terms_rev_r_seq', 6, true);


--
-- Name: testgl; Type: TABLE; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE TABLE testgl (
    id integer NOT NULL,
    parent integer
);


ALTER TABLE public.testgl OWNER TO lanedbadmin;

--
-- Name: timeclock; Type: TABLE; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE TABLE timeclock (
    clerk smallint NOT NULL,
    punch timestamp with time zone DEFAULT now() NOT NULL,
    forced boolean DEFAULT false NOT NULL,
    created timestamp with time zone DEFAULT now() NOT NULL,
    createdby text DEFAULT ''::text NOT NULL,
    modified timestamp with time zone DEFAULT now() NOT NULL,
    modifiedby text DEFAULT ''::text NOT NULL,
    voidat timestamp with time zone,
    voidby text
);


ALTER TABLE public.timeclock OWNER TO lanedbadmin;

--
-- Name: timeclock_rev; Type: TABLE; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE TABLE timeclock_rev (
    clerk smallint NOT NULL,
    punch timestamp with time zone DEFAULT now() NOT NULL,
    forced boolean DEFAULT false NOT NULL,
    created timestamp with time zone DEFAULT now() NOT NULL,
    createdby text DEFAULT ''::text NOT NULL,
    modified timestamp with time zone DEFAULT now() NOT NULL,
    modifiedby text DEFAULT ''::text NOT NULL,
    voidat timestamp with time zone,
    voidby text,
    r bigint NOT NULL
);


ALTER TABLE public.timeclock_rev OWNER TO lanedbadmin;

--
-- Name: timeclock_rev_r_seq; Type: SEQUENCE; Schema: public; Owner: lanedbadmin
--

CREATE SEQUENCE timeclock_rev_r_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.timeclock_rev_r_seq OWNER TO lanedbadmin;

--
-- Name: timeclock_rev_r_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: lanedbadmin
--

ALTER SEQUENCE timeclock_rev_r_seq OWNED BY timeclock_rev.r;


--
-- Name: timeclock_rev_r_seq; Type: SEQUENCE SET; Schema: public; Owner: lanedbadmin
--

SELECT pg_catalog.setval('timeclock_rev_r_seq', 1, false);


--
-- Name: vendors; Type: TABLE; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE TABLE vendors (
    id character varying(15) NOT NULL,
    coname character varying(40),
    cntfirst character varying(35),
    cntlast character varying(35),
    billaddr1 character varying(40),
    billaddr2 character varying(40),
    billcity character varying(35),
    billst character varying(2),
    billzip character varying(10),
    billcountry character varying(2) DEFAULT 'us'::character varying,
    billphone character varying(15),
    billfax character varying(15),
    shipaddr1 character varying(40),
    shipaddr2 character varying(40),
    shipcity character varying(35),
    shipst character varying(2),
    shipzip character varying(10),
    shipcountry character varying(2) DEFAULT 'us'::character varying,
    shipphone character varying(15),
    shipfax character varying(15),
    email character varying(40),
    creditlmt numeric(15,2) NOT NULL,
    balance numeric(15,2) NOT NULL,
    creditrmn numeric(15,2) NOT NULL,
    lastsale date,
    lastpay date,
    terms character varying(5) NOT NULL,
    notes text,
    createdby text NOT NULL,
    created timestamp with time zone NOT NULL,
    taxes smallint DEFAULT 32767 NOT NULL,
    voidat timestamp with time zone,
    voidby text,
    modified timestamp with time zone NOT NULL,
    modifiedby text NOT NULL
);


ALTER TABLE public.vendors OWNER TO lanedbadmin;

--
-- Name: vendors_rev; Type: TABLE; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE TABLE vendors_rev (
    id character varying(15) NOT NULL,
    coname character varying(40),
    cntfirst character varying(35),
    cntlast character varying(35),
    billaddr1 character varying(40),
    billaddr2 character varying(40),
    billcity character varying(35),
    billst character varying(2),
    billzip character varying(10),
    billcountry character varying(2) DEFAULT 'us'::character varying,
    billphone character varying(15),
    billfax character varying(15),
    shipaddr1 character varying(40),
    shipaddr2 character varying(40),
    shipcity character varying(35),
    shipst character varying(2),
    shipzip character varying(10),
    shipcountry character varying(2) DEFAULT 'us'::character varying,
    shipphone character varying(15),
    shipfax character varying(15),
    email character varying(40),
    creditlmt numeric(15,2) NOT NULL,
    balance numeric(15,2) NOT NULL,
    creditrmn numeric(15,2) NOT NULL,
    lastsale date,
    lastpay date,
    terms character varying(5) NOT NULL,
    notes text,
    createdby text NOT NULL,
    created timestamp with time zone NOT NULL,
    taxes smallint DEFAULT 32767 NOT NULL,
    voidat timestamp with time zone,
    voidby text,
    modified timestamp with time zone NOT NULL,
    modifiedby text NOT NULL,
    r bigint NOT NULL
);


ALTER TABLE public.vendors_rev OWNER TO lanedbadmin;

--
-- Name: vendors_rev_r_seq; Type: SEQUENCE; Schema: public; Owner: lanedbadmin
--

CREATE SEQUENCE vendors_rev_r_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.vendors_rev_r_seq OWNER TO lanedbadmin;

--
-- Name: vendors_rev_r_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: lanedbadmin
--

ALTER SEQUENCE vendors_rev_r_seq OWNED BY vendors_rev.r;


--
-- Name: vendors_rev_r_seq; Type: SEQUENCE SET; Schema: public; Owner: lanedbadmin
--

SELECT pg_catalog.setval('vendors_rev_r_seq', 1, false);


--
-- Name: r; Type: DEFAULT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE clerks_rev ALTER COLUMN r SET DEFAULT nextval('clerks_rev_r_seq'::regclass);


--
-- Name: r; Type: DEFAULT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE customers_rev ALTER COLUMN r SET DEFAULT nextval('customers_rev_r_seq'::regclass);


--
-- Name: r; Type: DEFAULT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE discounts_rev ALTER COLUMN r SET DEFAULT nextval('discounts_rev_r_seq'::regclass);


--
-- Name: r; Type: DEFAULT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE machines_rev ALTER COLUMN r SET DEFAULT nextval('machines_rev_r_seq'::regclass);


--
-- Name: r; Type: DEFAULT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE pricetables_rev ALTER COLUMN r SET DEFAULT nextval('pricetables_rev_r_seq'::regclass);


--
-- Name: r; Type: DEFAULT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE products_rev ALTER COLUMN r SET DEFAULT nextval('products_rev_r_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE purchaseorders ALTER COLUMN id SET DEFAULT nextval('purchaseorders_id_seq'::regclass);


--
-- Name: r; Type: DEFAULT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE purchaseorders_rev ALTER COLUMN r SET DEFAULT nextval('purchaseorders_rev_r_seq'::regclass);


--
-- Name: r; Type: DEFAULT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE qwo_rev ALTER COLUMN r SET DEFAULT nextval('qwo_rev_r_seq'::regclass);


--
-- Name: r; Type: DEFAULT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE sales_rev ALTER COLUMN r SET DEFAULT nextval('sales_rev_r_seq'::regclass);


--
-- Name: r; Type: DEFAULT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE strings_rev ALTER COLUMN r SET DEFAULT nextval('strings_rev_r_seq'::regclass);


--
-- Name: r; Type: DEFAULT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE sysstrings_rev ALTER COLUMN r SET DEFAULT nextval('sysstrings_rev_r_seq'::regclass);


--
-- Name: r; Type: DEFAULT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE taxes_rev ALTER COLUMN r SET DEFAULT nextval('taxes_rev_r_seq'::regclass);


--
-- Name: r; Type: DEFAULT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE tenders_rev ALTER COLUMN r SET DEFAULT nextval('tenders_rev_r_seq'::regclass);


--
-- Name: r; Type: DEFAULT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE terms_rev ALTER COLUMN r SET DEFAULT nextval('terms_rev_r_seq'::regclass);


--
-- Name: r; Type: DEFAULT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE timeclock_rev ALTER COLUMN r SET DEFAULT nextval('timeclock_rev_r_seq'::regclass);


--
-- Name: r; Type: DEFAULT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE vendors_rev ALTER COLUMN r SET DEFAULT nextval('vendors_rev_r_seq'::regclass);


--
-- Data for Name: clerks; Type: TABLE DATA; Schema: public; Owner: lanedbadmin
--

COPY clerks (id, name, passcode, drawer, voidat, voidby, created, createdby, modified, modifiedby) FROM stdin;
100	Stress Test Clerk	100	1	\N	\N	2010-09-19 17:08:56.439554-05	installer@localhost	2010-09-19 17:08:56.439554-05	installer@localhost
\.


--
-- Data for Name: clerks_rev; Type: TABLE DATA; Schema: public; Owner: lanedbadmin
--

COPY clerks_rev (id, name, passcode, drawer, voidat, voidby, created, createdby, modified, modifiedby, r) FROM stdin;
100	Stress Test Clerk	100	1	\N	\N	2010-09-19 17:08:56.439554-05	installer@localhost	2010-09-19 17:08:56.439554-05	installer@localhost	1
\.


--
-- Data for Name: customers; Type: TABLE DATA; Schema: public; Owner: lanedbadmin
--

COPY customers (id, coname, cntfirst, cntlast, billaddr1, billaddr2, billcity, billst, billzip, billcountry, billphone, billfax, shipaddr1, shipaddr2, shipcity, shipst, shipzip, shipcountry, shipphone, shipfax, email, custtype, creditlmt, balance, creditrmn, lastsale, lastpay, terms, notes, createdby, created, taxes, voidat, voidby, modified, modifiedby) FROM stdin;
	Cash								us								us				0	0.00	0.00	0.00	\N	\N	cod		installer@localhost	2001-01-15 00:00:00-06	32767	\N	\N	2010-09-19 17:09:00.724676-05	installer@localhost
\.


--
-- Data for Name: customers_rev; Type: TABLE DATA; Schema: public; Owner: lanedbadmin
--

COPY customers_rev (id, coname, cntfirst, cntlast, billaddr1, billaddr2, billcity, billst, billzip, billcountry, billphone, billfax, shipaddr1, shipaddr2, shipcity, shipst, shipzip, shipcountry, shipphone, shipfax, email, custtype, creditlmt, balance, creditrmn, lastsale, lastpay, terms, notes, createdby, created, taxes, voidat, voidby, modified, modifiedby, r) FROM stdin;
	Cash								us								us				0	0.00	0.00	0.00	\N	\N	cod		installer@localhost	2001-01-15 00:00:00-06	32767	\N	\N	2010-09-19 17:09:00.724676-05	installer@localhost	1
\.


--
-- Data for Name: discounts; Type: TABLE DATA; Schema: public; Owner: lanedbadmin
--

COPY discounts (id, descr, preset, per, amt, sale, voidat, voidby, created, createdby, modified, modifiedby) FROM stdin;
5	Open $ Disc	f	f	0.00	f	\N	\N	2010-09-19 17:09:03.536561-05	installer@localhost	2010-09-19 17:09:03.536561-05	installer@localhost
3	2% Early Pay	t	t	2.00	t	\N	\N	2010-09-19 17:09:03.536561-05	installer@localhost	2010-09-19 17:09:03.536561-05	installer@localhost
10	2% Post-Sale Disc	f	f	0.00	t	\N	\N	2010-09-19 17:09:03.536561-05	installer@localhost	2010-09-19 17:09:03.536561-05	installer@localhost
1	Open % Disc	f	t	0.00	f	\N	\N	2010-09-19 17:09:03.536561-05	installer@localhost	2010-09-19 17:09:03.536561-05	installer@localhost
2	10% Qty Disc	t	t	10.00	f	\N	\N	2010-09-19 17:09:03.536561-05	installer@localhost	2010-09-19 17:09:03.536561-05	installer@localhost
\.


--
-- Data for Name: discounts_rev; Type: TABLE DATA; Schema: public; Owner: lanedbadmin
--

COPY discounts_rev (id, descr, preset, per, amt, sale, voidat, voidby, created, createdby, modified, modifiedby, r) FROM stdin;
5	Open $ Disc	f	f	0.00	f	\N	\N	2010-09-19 17:09:03.536561-05	installer@localhost	2010-09-19 17:09:03.536561-05	installer@localhost	1
3	2% Early Pay	t	t	2.00	t	\N	\N	2010-09-19 17:09:03.536561-05	installer@localhost	2010-09-19 17:09:03.536561-05	installer@localhost	2
10	2% Post-Sale Disc	f	f	0.00	t	\N	\N	2010-09-19 17:09:03.536561-05	installer@localhost	2010-09-19 17:09:03.536561-05	installer@localhost	3
1	Open % Disc	f	t	0.00	f	\N	\N	2010-09-19 17:09:03.536561-05	installer@localhost	2010-09-19 17:09:03.536561-05	installer@localhost	4
2	10% Qty Disc	t	t	10.00	f	\N	\N	2010-09-19 17:09:03.536561-05	installer@localhost	2010-09-19 17:09:03.536561-05	installer@localhost	5
\.


--
-- Data for Name: locale; Type: TABLE DATA; Schema: public; Owner: lanedbadmin
--

COPY locale (lang, id, data) FROM stdin;
franglais	moneyFmt()-thou	 
franglais	moneyFmt()-dec	.
franglais	Enter a product ID, or press a function key	Entrez une identite du produit, ou pressez une cle de la functionne
franglais	Clerk	Clerke
franglais	Subtotal	Pretotale
franglais	Total	Totale
franglais	Taxes	Taques
franglais	Amount Due	Billet Demande
franglais	Due w/Disc	Demande avec Disc
franglais	Disc Date	Dahte Disc
franglais	Due Date	Dahte Demande
franglais	Enter your clerk ID	Entrez votre identite
franglais	Enter your clerk Passcode	Entrez votre cle de l'access
franglais	extFmt()-decimal	2
franglais	nowFmt()-shortTimestamp	%m-%d-%Y %I:%M%p
franglais	nowFmt()-longTimestamp	%A, %B %d, %Y %l:%M %p
franglais	Ticket	Billet
franglais	Amount required for %0 sales.	Declarationne demande pour les salhes de %0.
franglais	A customer must be open for %0 sales.	Il faut que une client ouvert pour les sales %0.
franglais	%0 customers must pay at the time of service.	Les %0 clientes payent a la temp de la service.
franglais	Change	Les Changes
franglais	Enter or scan the item to check	Entrez ou escannez l'item chequer
franglais	Price Check	Cheques de Price
franglais	Unknown Product	Je ne trouve pas la produit.
franglais	Enter your passcode to shutdown the register	Entrez votre cle shutdowner la registoure
franglais	Shutdown in progress...	Shutdownne en progresse
franglais	(w/disc)	(avec disc)
franglais	Enter the amount and tender type, or continue to enter products	Entrez l'amounte et type de le tender, ou continuez entre 
franglais	Customer	Cliente
franglais	This sale has been (partially?) committed, so it can not be canceled.	Ce sale committe, s'il ne cancelent pas.
franglais	CANCELED	CANCELE'
franglais	none	pas
franglais	Cancel R/A	Cancellez R/A
franglais	Tax exempt	Taxe' Exempte
franglais	SUSPENDED	SUSPENDE'
franglais	A suspended sale can not be resumed inside another transaction.	Une sale suspende ne resume pas en une autre transactionne.
franglais	There are no suspended tickets.	Il n'est pas du billet suspende'.
franglais	There is no ticket %0.	Il n'est pas un billet %0.
franglais	The ticket %0 was not suspended (it is finalized).	Le billet %0 n'a pas suspende (il est finale).
franglais	RESUMED	RE'SUME'
franglais	R/A can not be processed inside a standard transaction.	ne process une RA en une autre transactionne
franglais	A customer must be open for a R/A transaction.	Il faut qwu une cliente overte pour une transactionne RA
franglais	moneyFmt()-pre	¤
franglais	moneyFmt()-suf	
franglais	clear	cleare'
en-IE	Lane/Locale/Money/DecimalDigits	2
en-US	locale-data-version	$Id: base-dataset.sql 1197 2010-10-24 18:23:51Z jason $
en-US	locale-data-name	English in the United States Locale
en-US	Lane/Locale/Money/CurrencyCode	USD
en-US	Lane/Locale/Money/GroupingDigits	3
en-US	Lane/Locale/Money/GroupingSeparator	,
en-US	Lane/Locale/Money/DecimalSeparator	.
en-US	Lane/Locale/Money/DecimalDigits	2
en-US	Lane/Locale/Money/Prefix	$
en-US	Lane/Locale/Money/Suffix	
en-US	Lane/Locale/Money/Negative/GroupingDigits	3
en-US	Lane/Locale/Money/Negative/GroupingSeparator	,
en-US	Lane/Locale/Money/Negative/DecimalSeparator	.
en-US	Lane/Locale/Money/Negative/Prefix	-$
en-US	Lane/Locale/Money/Negative/Suffix	
en-US	Lane/Locale/Temporal/ShortTimestamp	%m-%d-%Y %l:%M%p
en-US	Lane/Locale/Temporal/LongTimestamp	%A, %B %e, %Y %l:%M%p
en-US	Lane/Locale/Temporal/ShortTime	%l:%M%p
en-US	Lane/Locale/Temporal/LongTime	%l:%M%p
en-US	Lane/Locale/Temporal/ShortDate	%m-%d-%Y
en-US	Lane/Locale/Temporal/LongDate	%A, %B %e, %Y
en-CA	locale-data-version	$Id: base-dataset.sql 1197 2010-10-24 18:23:51Z jason $
en-CA	locale-data-name	English in Canada Locale
en-CA	Lane/Locale/Money/CurrencyCode	CAD
en-CA	Lane/Locale/Money/GroupingDigits	3
en-CA	Lane/Locale/Money/GroupingSeparator	,
en-CA	Lane/Locale/Money/DecimalSeparator	.
en-CA	Lane/Locale/Money/DecimalDigits	2
en-CA	Lane/Locale/Money/Prefix	$
en-CA	Lane/Locale/Money/Suffix	
en-CA	Lane/Locale/Money/Negative/GroupingDigits	3
en-CA	Lane/Locale/Money/Negative/GroupingSeparator	,
en-CA	Lane/Locale/Money/Negative/DecimalSeparator	.
en-CA	Lane/Locale/Money/Negative/Prefix	-$
en-CA	Lane/Locale/Money/Negative/Suffix	
en-CA	Lane/Locale/Temporal/ShortTimestamp	%m-%d-%Y %l:%M%p
en-CA	Lane/Locale/Temporal/LongTimestamp	%A, %B %e, %Y %l:%M%p
en-CA	Lane/Locale/Temporal/ShortTime	%l:%M%p
en-CA	Lane/Locale/Temporal/LongTime	%l:%M%p
en-CA	Lane/Locale/Temporal/ShortDate	%m-%d-%Y
en-CA	Lane/Locale/Temporal/LongDate	%A, %B %e, %Y
en-AU	locale-data-version	$Id: base-dataset.sql 1197 2010-10-24 18:23:51Z jason $
en-AU	locale-data-name	English in Australia Locale
en-AU	Lane/Locale/Money/CurrencyCode	AUD
en-AU	Lane/Locale/Money/GroupingDigits	3
en-AU	Lane/Locale/Money/GroupingSeparator	 
en-AU	Lane/Locale/Money/DecimalSeparator	.
en-AU	Lane/Locale/Money/DecimalDigits	2
en-AU	Lane/Locale/Money/Prefix	$
en-AU	Lane/Locale/Money/Suffix	
en-AU	Lane/Locale/Money/Negative/GroupingDigits	3
en-AU	Lane/Locale/Money/Negative/GroupingSeparator	 
en-AU	Lane/Locale/Money/Negative/DecimalSeparator	.
en-AU	Lane/Locale/Money/Negative/Prefix	-$
en-AU	Lane/Locale/Money/Negative/Suffix	
en-IE	locale-data-version	$Id: base-dataset.sql 1197 2010-10-24 18:23:51Z jason $
en-IE	locale-data-name	English in Ireland Locale
en-IE	Lane/Locale/Money/CurrencyCode	EUR
en-IE	Lane/Locale/Money/GroupingDigits	3
en-IE	Lane/Locale/Money/GroupingSeparator	 
en-IE	Lane/Locale/Money/DecimalSeparator	.
en-IE	Lane/Locale/Money/Prefix	€
en-IE	Lane/Locale/Money/Suffix	
en-IE	Lane/Locale/Money/Negative/GroupingDigits	3
en-IE	Lane/Locale/Money/Negative/GroupingSeparator	 
en-IE	Lane/Locale/Money/Negative/DecimalSeparator	.
en-IE	Lane/Locale/Money/Negative/Prefix	-€
en-IE	Lane/Locale/Money/Negative/Suffix	
en-NZ	locale-data-version	$Id: base-dataset.sql 1197 2010-10-24 18:23:51Z jason $
en-NZ	locale-data-name	English in New Zealand Locale
en-NZ	Lane/Locale/Money/CurrencyCode	NZD
en-NZ	Lane/Locale/Money/GroupingDigits	3
en-NZ	Lane/Locale/Money/GroupingSeparator	,
en-NZ	Lane/Locale/Money/DecimalSeparator	.
en-NZ	Lane/Locale/Money/DecimalDigits	2
en-NZ	Lane/Locale/Money/Prefix	$
en-NZ	Lane/Locale/Money/Suffix	
en-NZ	Lane/Locale/Money/Negative/GroupingDigits	3
en-NZ	Lane/Locale/Money/Negative/GroupingSeparator	,
en-NZ	Lane/Locale/Money/Negative/DecimalSeparator	.
en-NZ	Lane/Locale/Money/Negative/Prefix	-$
en-NZ	Lane/Locale/Money/Negative/Suffix	
en-UK	locale-data-version	$Id: base-dataset.sql 1197 2010-10-24 18:23:51Z jason $
en-UK	locale-data-name	English in the United Kingdom Locale
en-UK	Lane/Locale/Money/CurrencyCode	GBP
en-UK	Lane/Locale/Money/GroupingDigits	3
en-UK	Lane/Locale/Money/GroupingSeparator	,
en-UK	Lane/Locale/Money/DecimalSeparator	.
en-UK	Lane/Locale/Money/DecimalDigits	2
en-UK	Lane/Locale/Money/Prefix	£
en-UK	Lane/Locale/Money/Suffix	
en-UK	Lane/Locale/Money/Negative/GroupingDigits	3
en-UK	Lane/Locale/Money/Negative/GroupingSeparator	,
en-UK	Lane/Locale/Money/Negative/DecimalSeparator	.
en-UK	Lane/Locale/Money/Negative/Prefix	-£
en-UK	Lane/Locale/Money/Negative/Suffix	
en-ZA	locale-data-version	$Id: base-dataset.sql 1197 2010-10-24 18:23:51Z jason $
en-ZA	locale-data-name	English in South Africa Locale
en-ZA	Lane/Locale/Money/CurrencyCode	ZAR
en-ZA	Lane/Locale/Money/GroupingDigits	3
en-ZA	Lane/Locale/Money/GroupingSeparator	 
en-ZA	Lane/Locale/Money/DecimalSeparator	.
en-ZA	Lane/Locale/Money/DecimalDigits	2
en-ZA	Lane/Locale/Money/Prefix	R
en-ZA	Lane/Locale/Money/Suffix	
en-ZA	Lane/Locale/Money/Negative/GroupingDigits	3
en-ZA	Lane/Locale/Money/Negative/GroupingSeparator	 
en-ZA	Lane/Locale/Money/Negative/DecimalSeparator	.
en-ZA	Lane/Locale/Money/Negative/Prefix	-R
en-ZA	Lane/Locale/Money/Negative/Suffix	
en-IN	locale-data-version	$Id: base-dataset.sql 1197 2010-10-24 18:23:51Z jason $
en-IN	locale-data-name	English in India Locale
en-IN	Lane/Locale/Money/CurrencyCode	INR
en-IN	Lane/Locale/Money/GroupingDigits	3
en-IN	Lane/Locale/Money/GroupingSeparator	
en-IN	Lane/Locale/Money/DecimalSeparator	.
en-IN	Lane/Locale/Money/DecimalDigits	2
en-IN	Lane/Locale/Money/Prefix	Rs.
en-IN	Lane/Locale/Money/Suffix	
en-IN	Lane/Locale/Money/Negative/GroupingDigits	3
en-IN	Lane/Locale/Money/Negative/GroupingSeparator	
en-IN	Lane/Locale/Money/Negative/DecimalSeparator	.
en-IN	Lane/Locale/Money/Negative/Prefix	-Rs.
en-IN	Lane/Locale/Money/Negative/Suffix	
int-EURO	locale-data-version	$Id: base-dataset.sql 1197 2010-10-24 18:23:51Z jason $
int-EURO	locale-data-name	Standard Euro-Overlay Locale
int-EURO	Lane/Locale/Money/CurrencyCode	EUR
int-EURO	Lane/Locale/Money/GroupingDigits	3
int-EURO	Lane/Locale/Money/GroupingSeparator	 
int-EURO	Lane/Locale/Money/DecimalSeparator	.
int-EURO	Lane/Locale/Money/DecimalDigits	2
int-EURO	Lane/Locale/Money/Prefix	€ 
int-EURO	Lane/Locale/Money/Suffix	
int-EURO	Lane/Locale/Money/Negative/GroupingDigits	3
int-EURO	Lane/Locale/Money/Negative/GroupingSeparator	 
int-EURO	Lane/Locale/Money/Negative/DecimalSeparator	.
int-EURO	Lane/Locale/Money/Negative/Prefix	-€ 
int-EURO	Lane/Locale/Money/Negative/Suffix	
int-EURO.ISO	locale-data-version	$Id: base-dataset.sql 1197 2010-10-24 18:23:51Z jason $
int-EURO.ISO	locale-data-name	ISO Euro-Overlay Locale
int-EURO.ISO	Lane/Locale/Money/CurrencyCode	EUR
int-EURO.ISO	Lane/Locale/Money/GroupingDigits	3
int-EURO.ISO	Lane/Locale/Money/GroupingSeparator	 
int-EURO.ISO	Lane/Locale/Money/DecimalSeparator	.
int-EURO.ISO	Lane/Locale/Money/DecimalDigits	2
int-EURO.ISO	Lane/Locale/Money/Prefix	
int-EURO.ISO	Lane/Locale/Money/Suffix	 EUR
int-EURO.ISO	Lane/Locale/Money/Negative/GroupingDigits	3
int-EURO.ISO	Lane/Locale/Money/Negative/GroupingSeparator	 
int-EURO.ISO	Lane/Locale/Money/Negative/DecimalSeparator	.
int-EURO.ISO	Lane/Locale/Money/Negative/Prefix	-
int-EURO.ISO	Lane/Locale/Money/Negative/Suffix	 EUR
int-EURO.REVISO	locale-data-version	$Id: base-dataset.sql 1197 2010-10-24 18:23:51Z jason $
int-EURO.REVISO	locale-data-name	Reversed ISO Euro-Overlay Locale
int-EURO.REVISO	Lane/Locale/Money/CurrencyCode	EUR
int-EURO.REVISO	Lane/Locale/Money/GroupingDigits	3
int-EURO.REVISO	Lane/Locale/Money/GroupingSeparator	 
int-EURO.REVISO	Lane/Locale/Money/DecimalSeparator	.
int-EURO.REVISO	Lane/Locale/Money/DecimalDigits	2
int-EURO.REVISO	Lane/Locale/Money/Prefix	EUR 
int-EURO.REVISO	Lane/Locale/Money/Suffix	
sample	Lane/QWO/Type/1	Rush in Shop
int-EURO.REVISO	Lane/Locale/Money/Negative/GroupingDigits	3
int-EURO.REVISO	Lane/Locale/Money/Negative/GroupingSeparator	 
int-EURO.REVISO	Lane/Locale/Money/Negative/DecimalSeparator	.
int-EURO.REVISO	Lane/Locale/Money/Negative/Prefix	-EUR 
int-EURO.REVISO	Lane/Locale/Money/Negative/Suffix	
nl-NL	locale-data-version	$Id: base-dataset.sql 1197 2010-10-24 18:23:51Z jason $
nl-NL	locale-data-name	Dutch in the Netherlands Locale
nl-NL	Lane/Locale/Money/CurrencyCode	EUR
nl-NL	Lane/Locale/Money/Prefix	 €
nl-NL	Lane/Locale/Money/Suffix	
nl-NL	Lane/Locale/Money/GroupingDigits	3
nl-NL	Lane/Locale/Money/GroupingSeparator	.
nl-NL	Lane/Locale/Money/DecimalSeparator	3
nl-NL	Lane/Locale/Money/DecimalDigits	2
nl-NL	Lane/Locale/Money/Negative/Prefix	 -€
nl-NL	Lane/Locale/Money/Negative/Suffix	
nl-NL	Lane/Locale/Money/Negative/GroupingDigits	3
nl-NL	Lane/Locale/Money/Negative/GroupingSeparator	.
nl-NL	Lane/Locale/Money/Negative/DecimalSeparator	3
nl-BE	locale-data-version	$Id: base-dataset.sql 1197 2010-10-24 18:23:51Z jason $
nl-BE	locale-data-name	Dutch in Belgium Locale
nl-BE	Lane/Locale/Money/CurrencyCode	EUR
nl-BE	Lane/Locale/Money/Prefix	€
nl-BE	Lane/Locale/Money/Suffix	
nl-BE	Lane/Locale/Money/GroupingDigits	3
nl-BE	Lane/Locale/Money/GroupingSeparator	.
nl-BE	Lane/Locale/Money/DecimalSeparator	,
nl-BE	Lane/Locale/Money/DecimalDigits	2
nl-BE	Lane/Locale/Money/Negative/Prefix	-€
nl-BE	Lane/Locale/Money/Negative/Suffix	
nl-BE	Lane/Locale/Money/Negative/GroupingDigits	3
nl-BE	Lane/Locale/Money/Negative/GroupingSeparator	.
nl-BE	Lane/Locale/Money/Negative/DecimalSeparator	,
nl	locale-data-version	$Id: base-dataset.sql 1197 2010-10-24 18:23:51Z jason $
nl	locale-data-name	Generic Dutch Locale
nl	Lane/Locale/Money/CurrencyCode	EUR
nl	Lane/Locale/Money/Prefix	 €
nl	Lane/Locale/Money/Suffix	
nl	Lane/Locale/Money/GroupingDigits	3
nl	Lane/Locale/Money/GroupingSeparator	.
nl	Lane/Locale/Money/DecimalSeparator	,
nl	Lane/Locale/Money/DecimalDigits	2
nl	Lane/Locale/Money/Negative/Prefix	 €
nl	Lane/Locale/Money/Negative/Suffix	
nl	Lane/Locale/Money/Negative/GroupingDigits	3
nl	Lane/Locale/Money/Negative/GroupingSeparator	.
nl	Lane/Locale/Money/Negative/DecimalSeparator	,
nl	Lane/GenericObject/ID	ID
nl	Lane/BackOffice/Save Prompt	Deze vermelding is niet opgeslagen. Wilt u een kans de veranderingen op te slaan?\n ('Ja' kiezen annuleert alleen de vorige operatie).
nl	Lane/BackOffice/Remove Prompt	Weet u zeker dat u deze vermelding permanent\n uit de database wilt verwijderen?
nl	Lane/BackOffice/Confirmation	Bevestiging
nl	Lane/BackOffice/Buttons/Yes	Ja
nl	Lane/BackOffice/Buttons/Yes, Remove	Ja, Verwijder
nl	Lane/BackOffice/Buttons/No	Nee
nl	Lane/BackOffice/Buttons/No, Cancel	Nee, Annuleer
nl	Lane/BackOffice/Buttons/No, Discard	Nee, Verwerp
nl	Lane/BackOffice/Buttons/Discard	Verwerp
nl	Lane/BackOffice/Buttons/Cancel	Annuleer
nl	Lane/BackOffice/Buttons/New	Nieuw
nl	Lane/BackOffice/Buttons/Process	Verwerk
nl	Lane/BackOffice/Buttons/Quit	Stop
nl	Lane/BackOffice/Buttons/Remove	Verwijder
nl	Lane/BackOffice/Buttons/Search	Zoek
nl	Lane/BackOffice/Buttons/OK	OK
nl	Lane/BackOffice/Buttons/Add	Voeg toe
nl	Lane/BackOffice/Buttons/View	Bekijk
nl	Lane/BackOffice/Buttons/Print	Print
nl	Lane/BackOffice/Search Results	Zoek resultaten
nl	Lane/BackOffice/Search Results Text	De database heeft de volgende vermeldingen gevonden:
nl	Lane/BackOffice/Notes	Notities
nl	Lane/BackOffice/Select	Selecteer
nl	Lane/BackOffice/Clerks	Verkopers
nl	Lane/BackOffice/Customers	Klanten
nl	Lane/BackOffice/Discounts	Kortingen
nl	Lane/BackOffice/Machines	Machines
nl	Lane/BackOffice/Products	Produkten
nl	Lane/BackOffice/QWO	Werk order
nl	Lane/BackOffice/Strings	Instellingen
nl	Lane/BackOffice/System Strings	Systeem instellingen
nl	Lane/BackOffice/Taxes	Belastingen
nl	Lane/BackOffice/Tenders	Betaalmiddelen
nl	Lane/BackOffice/Terms	Voorwaarden
nl	Lane/BackOffice/Vendors	Leveranciers
nl	Lane/Clerk/Clerk	Verkoper
nl	Lane/Clerk/Name	Naam
nl	Lane/Clerk/Passcode	PIN
nl	Lane/Clerk/Drawer	Lade
nl	Lane/String/Data	Data
nl	Lane/Tax/Description	Omschrijving
nl	Lane/Tax/Amount	Hoeveelheid
nl	Lane/Term/Description	Omschrijving
nl	Lane/Term/Days Until Due	Looptijd in dagen
nl	Lane/Term/Finance Rate	Financiërings tarief
nl	Lane/Term/Days For Discount	Dagen voor korting
nl	Lane/Term/Discount Rate	Kortings tarief
nl	Lane/Tender/Description	Omschrijving
nl	Lane/Tender/Allow Change	Wisselgeld toestaan
nl	Lane/Tender/Mandatory Amount	Verplichte hoeveelheid
nl	Lane/Tender/Open Drawer	Open lade
nl	Lane/Tender/Pays	Betaald
nl	Lane/Tender/eProcess	eProcess
nl	Lane/Tender/eAuthorize	eAuthorize
nl	Lane/Customer/Company Name	Bedrijf
nl	Lane/Customer/Contact Given Name	Contactpersoon voornaam
nl	Lane/Customer/Contact Family Name	Achternaam
nl	Lane/Customer/Billing	Facturering
nl	Lane/Customer/Billing Address 1	Adres
nl	Lane/Customer/Billing Address 2	Adres 2
nl	Lane/Customer/Billing City	Stad
nl	Lane/Customer/Billing State	Staat/Provincie
nl	Lane/Customer/Billing Zip	Postcode
nl	Lane/Customer/Billing Country	Land
nl	Lane/Customer/Billing Phone	Tel.
nl	Lane/Customer/Billing Fax	Fax
nl	Lane/Customer/Shipping	Verzending
nl	Lane/Customer/Same As Billing	Zelfde als facturering
nl	Lane/Customer/Shipping Address 1	Adres
nl	Lane/Customer/Shipping Address 2	Adres 2
nl	Lane/Customer/Shipping City	Stad
nl	Lane/Customer/Shipping State	Staat/Provincie
nl	Lane/Customer/Shipping Zip	Postcode
nl	Lane/Customer/Shipping Country	Land
nl	Lane/Customer/Shipping Phone	Tel.
nl	Lane/Customer/Shipping Fax	Fax
nl	Lane/Customer/Email	e-Mail
nl	Lane/Customer/Accounting	Financiën
nl	Lane/Customer/Account Terms	Voorwaarden
nl	Lane/Customer/Customer Type	Klant type
nl	Lane/Customer/Customer Type/0	Klant type/0
nl	Lane/Customer/Customer Type/1	Klant type/1
nl	Lane/Customer/Customer Type/2	Klant type/2
nl	Lane/Customer/Customer Type/3	Klant type/3
nl	Lane/Customer/Credit Limit	Crediet limiet
nl	Lane/Customer/Balance	Balans
nl	Lane/Customer/Credit Remaining	Bestedingsruimte
nl	Lane/Customer/Last Sale	Laatste verkoop
nl	Lane/Customer/Last Payment	Laatste betaling
nl	Lane/Customer/Search Prompt	Type een deel van de bedrijfsnaam of achternaam van contactpersoon om te zoeken.
nl	Lane/Vendor/Vendor	Leverancier
nl	Lane/Discount/Description	Omschrijving
nl	Lane/Discount/Preset	Bepaald
nl	Lane/Discount/Open	Onbepaald
nl	Lane/Discount/Fixed	Vast bedrag
nl	Lane/Discount/Percent	Percentage
nl	Lane/Discount/Amount	Hoeveelheid
nl	Lane/Discount/Sale	Korting van toepassing op hele verkoop
nl	Lane/Discount/Item	Korting van toepassing op vorige produkt
nl	Lane/Product/Description	Omschrijving
nl	Lane/Product/Price	Prijs
nl	Lane/Product/Category	Categorie
nl	Lane/Product/Taxes	Belastingen
nl	Lane/Product/Type	Type
nl	Lane/Product/Type/Preset	Bepaald
nl	Lane/Product/Type/Open	Onbepaald
nl	Lane/Product/Type/Open Negative	Onbepaald negatief
nl	Lane/Product/Track Quantity	Voorraad beheer
nl	Lane/Product/On Hand	Op voorraad
nl	Lane/Product/Minimum	Minimum
nl	Lane/Product/Reorder	Bijbestellen
nl	Lane/Product/Items Per Case	Aantal per doos
nl	Lane/Product/Case ID	Doos ID
nl	Lane/Product/Vendor	Leverancier
nl	Lane/Product/Extended	Extensie
nl	Lane/Product/Cost	Kosten
nl	Lane/Product/Reorder ID	Bijbestel ID
nl	Lane/Product/Search Prompt	Type een deel van de produktomschrijving om te zoeken
nl	Lane/Machine/Search Prompt	Type een deel van een van de velden om te zoeken naar machines
nl	Lane/Machine/Make	Type
nl	Lane/Machine/Model	Model
nl	Lane/Machine/Serial Number	Serienummer
nl	Lane/Machine/Counter	Tellerstand
nl	Lane/Machine/Accessories	Accessoires
nl	Lane/Machine/Owner	Eigenaar
nl	Lane/Machine/Purchase Date	Aankoop datum
nl	Lane/Machine/Last Service Date	Laatste onderhoud datum
nl	Lane/Machine/Contract	Contract
nl	Lane/Machine/Contract/On Contract	Op contract
nl	Lane/Machine/Contract/Begins	Begint
nl	Lane/Machine/Contract/Ends	Eindigt
nl	Lane/QWO/Machines Owned By	Machines eigendom van
nl	Lane/QWO/Machine Search Prompt	Type een deel van een van de velden om te zoeken naar machines
nl	Lane/QWO/Status	Status
nl	Lane/QWO/Status/Staff	Personeel
nl	Lane/QWO/Status/Contact	Contact
nl	Lane/QWO/Status/0	0
nl	Lane/QWO/Status/1	1
nl	Lane/QWO/Status/2	2
nl	Lane/QWO/Status/3	3
nl	Lane/QWO/Status/4	4
nl	Lane/QWO/Status/5	5
nl	Lane/QWO/Status/6	6
nl	Lane/QWO/Status/7	7
nl	Lane/QWO/Status/8	8
nl	Lane/QWO/Number	Nummer
nl	Lane/QWO/Date Issued	Datum van uitgifte
nl	Lane/QWO/Type	Type
nl	Lane/QWO/Type/0	0
nl	Lane/QWO/Type/1	1
nl	Lane/QWO/Type/2	2
nl	Lane/QWO/Type/3	3
nl	Lane/QWO/Type/4	4
nl	Lane/QWO/Type/5	5
nl	Lane/QWO/Type/6	6
nl	Lane/QWO/Type/7	7
nl	Lane/QWO/Buttons/Process And Print	Verwerk en print
nl	Lane/QWO/Machine	Machine
nl	Lane/QWO/Loaner	In bruikleen
nl	Lane/QWO/Problem and Solution	Probleem en oplossing
nl	Lane/QWO/Technician	Monteur
nl	Lane/QWO/Customer	Klant
nl	Lane/QWO/Search By Owner	Zoek op klant
nl	Lane/QWO/Search By Machine	Zoek op machine
nl	Lane/QWO/Problem	Probleem
nl	Lane/QWO/Solution	Oplossing
nl	Enter a product ID, or press a function key	Voer een produkt ID in, of druk een functie toets
nl	Clerk	Verkoper
nl	Subtotal	Subtotaal
nl	Total	Totaal
nl	Taxes	BTW
nl	Amount Due	Te betalen
nl	Due w/Disc	Te betalen met korting
nl	Disc Date	Kortings datum
nl	Due Date	Betaal datum
nl	Enter your clerk ID	Type uw verkopers ID
nl	Enter your clerk Passcode	Type uw PIN
nl	Lane/Locale/Temporal/ShortTimestamp	%m-%d-%Y %H:%M
nl	Lane/Locale/Temporal/LongTimestamp	%A, %d %B, %Y %H:%M
nl	Ticket	Bon
nl	Amount required for %0 sales.	Hoeveelheid nodig voor %0 verkoop.
nl	A customer must be open for %0 sales.	Een klant moet zijn geopend voor %0 verkoop.
nl	%0 customers must pay at the time of service.	%0 klanten moeten direct betalen.
nl	Change	Wisselgeld
nl	Enter or scan the item to check	Type of scan het te controleren produkt
nl	Price Check	Prijs controle
nl	Unknown Product	Onbekend produkt
nl	Enter your passcode to shutdown the register	Type uw PIN om het systeem af te sluiten
nl	Shutdown in progress...	Bezig met afsluiten...
nl	(w/disc)	(incl. korting)
nl	Enter the amount and tender type, or continue to enter products	Type het bedrag en betaalmethode, of ga verder met invoeren produkten 
nl	Customer	Klant
nl	This sale has been (partially?) committed, so it can not be canceled.	Deze verkoop is al (gedeeltelijk?) voldaan, deze kan niet geannuleerd worden.
nl	CANCELED	GEANNULEERD
nl	none	geen
nl	Cancel R/A	Annuleer R/A
nl	Tax exempt	BTW vrijstelling
nl	SUSPENDED	GEPAUZEERD
nl	A suspended sale can not be resumed inside another transaction.	Een gepauzeerde verkoop kan niet worden hervat binnen een andere transactie.
nl	There are no suspended tickets.	Er zijn geen gepauzeerde bonnen.
nl	There is no ticket %0.	Er is geen bon %0.
nl	The ticket %0 was not suspended (it is finalized).	Bon %0 is niet gepauzeerd (al afgerond).
nl	RESUMED	HERVAT
nl	R/A can not be processed inside a standard transaction.	R/A kan niet worden verwerkt binnen een standaard transactie.
nl	A customer must be open for a R/A transaction.	Een klant moet zijn geopend voor een R/A transactie.
nl	clear	leeg
sample	locale-data-version	$Id: base-dataset.sql 1197 2010-10-24 18:23:51Z jason $
sample	locale-data-name	Sample Locale
sample	Lane/Locale/Money/CurrencyCode	???
sample	Lane/Locale/Money/Prefix	$
sample	Lane/Locale/Money/Suffix	
sample	Lane/Locale/Money/GroupingDigits	3
sample	Lane/Locale/Money/GroupingSeparator	 
sample	Lane/Locale/Money/DecimalSeparator	.
sample	Lane/Locale/Money/DecimalDigits	2
sample	Lane/Locale/Money/Negative/Prefix	-$
sample	Lane/Locale/Money/Negative/Suffix	
sample	Lane/Locale/Money/Negative/GroupingDigits	3
sample	Lane/Locale/Money/Negative/GroupingSeparator	 
sample	Lane/Locale/Money/Negative/DecimalSeparator	.
sample	Lane/Locale/Temporal/LongTimestamp	%d %B %Y %H:%M
sample	Lane/Locale/Temporal/ShortTimestamp	%Y-%m-%d %H:%M
sample	Lane/Locale/Temporal/LongTime	%H:%M
sample	Lane/Locale/Temporal/ShortTime	%H:%M
sample	Lane/Locale/Temporal/LongDate	%d %B %Y
sample	Lane/Locale/Temporal/ShortDate	%Y-%m-%d
sample	Lane/GenericObject/ID	ID
sample	Lane/BackOffice/Save Prompt	This record is not saved. Do you want a chance to save your changes?\n(Selecting 'Yes' only cancels the previous operation.)
sample	Lane/BackOffice/Remove Prompt	Are you sure you want to permanently\nremove this record from the database?
sample	Lane/BackOffice/Confirmation	Confirmation
sample	Lane/BackOffice/Buttons/Yes	Yes
sample	Lane/BackOffice/Buttons/Yes, Remove	Yes, Remove
sample	Lane/BackOffice/Buttons/No	No
sample	Lane/BackOffice/Buttons/No, Cancel	No, Cancel
sample	Lane/BackOffice/Buttons/No, Discard	No, Discard
sample	Lane/BackOffice/Buttons/Discard	Discard
sample	Lane/BackOffice/Buttons/Cancel	Cancel
sample	Lane/BackOffice/Buttons/New	New
sample	Lane/BackOffice/Buttons/Process	Process
sample	Lane/BackOffice/Buttons/Quit	Quit
sample	Lane/BackOffice/Buttons/Remove	Remove
sample	Lane/BackOffice/Buttons/Search	Search
sample	Lane/BackOffice/Buttons/OK	OK
sample	Lane/BackOffice/Buttons/Add	Add
sample	Lane/BackOffice/Buttons/View	View
sample	Lane/BackOffice/Buttons/Print	Print
sample	Lane/BackOffice/Search Results	Search Results
sample	Lane/BackOffice/Search Results Text	The database found the following records:
sample	Lane/BackOffice/Notes	Notes
sample	Lane/BackOffice/Select	Select One
sample	Lane/BackOffice/Clerks	Clerks
sample	Lane/BackOffice/Customers	Customers
sample	Lane/BackOffice/Discounts	Discounts
sample	Lane/BackOffice/Machines	Machines
sample	Lane/BackOffice/Products	Products
sample	Lane/BackOffice/QWO	QWO
sample	Lane/BackOffice/Strings	Strings
sample	Lane/BackOffice/System Strings	System Strings
sample	Lane/BackOffice/Taxes	Taxes
sample	Lane/BackOffice/Tenders	Tenders
sample	Lane/BackOffice/Terms	Terms
sample	Lane/BackOffice/Vendors	Vendors
sample	Lane/Clerk/Clerk	Clerk
sample	Lane/Clerk/Name	Name
sample	Lane/Clerk/Passcode	Passcode
sample	Lane/Clerk/Drawer	Drawer
sample	Lane/String/Data	Data
sample	Lane/Tax/Description	Description
sample	Lane/Tax/Amount	Amount
sample	Lane/Term/Description	Description
sample	Lane/Term/Days Until Due	Days Until Due
sample	Lane/Term/Finance Rate	Finance Rate
sample	Lane/Term/Days For Discount	Days For Discount
sample	Lane/Term/Discount Rate	Discount Rate
sample	Lane/Tender/Description	Description
sample	Lane/Tender/Allow Change	Allow Change
sample	Lane/Tender/Mandatory Amount	Mandatory Amount
sample	Lane/Tender/Open Drawer	Open Drawer
sample	Lane/Tender/Pays	Pays
sample	Lane/Tender/eProcess	eProcess
sample	Lane/Tender/eAuthorize	eAuthorize
sample	Lane/Tender/Allow Zero Amounts	Allow Zero Amounts
sample	Lane/Tender/Allow Negative Amounts	Allow Negative Amounts
sample	Lane/Tender/Allow Positive Amounts	Allow Positive Amounts
sample	Lane/Tender/Require Items/Require Items	Require Items
sample	Lane/Tender/Require Items/Do Not Allow Items	Do Not Allow Items
sample	Lane/Tender/Require Items/Either	Either
sample	Lane/Customer/Company Name	Company Name
sample	Lane/Customer/Contact Given Name	Contact Given Name
sample	Lane/Customer/Contact Family Name	Contact Surname
sample	Lane/Customer/Billing	Billing
sample	Lane/Customer/Billing Address 1	Address 1
sample	Lane/Customer/Billing Address 2	Address 2
sample	Lane/Customer/Billing City	City
sample	Lane/Customer/Billing State	State
sample	Lane/Customer/Billing Zip	Zip
sample	Lane/Customer/Billing Country	Country
sample	Lane/Customer/Billing Phone	Phone
sample	Lane/Customer/Billing Fax	Fax
sample	Lane/Customer/Shipping	Shipping
sample	Lane/Customer/Same As Billing	Same as Billing
sample	Lane/Customer/Shipping Address 1	Address 1
sample	Lane/Customer/Shipping Address 2	Address 2
sample	Lane/Customer/Shipping City	City
sample	Lane/Customer/Shipping State	State
sample	Lane/Customer/Shipping Zip	Zip
sample	Lane/Customer/Shipping Country	Country
sample	Lane/Customer/Shipping Phone	Phone
sample	Lane/Customer/Shipping Fax	Fax
sample	Lane/Customer/Email	Email
sample	Lane/Customer/Accounting	Accounting
sample	Lane/Customer/Account Terms	Terms
sample	Lane/Customer/Customer Type	Customer Type
sample	Lane/Customer/Customer Type/0	Company
sample	Lane/Customer/Customer Type/1	Individual
sample	Lane/Customer/Customer Type/2	Web Only
sample	Lane/Customer/Customer Type/3	Dealer
sample	Lane/Customer/Credit Limit	Credit Limit
sample	Lane/Customer/Balance	Balance
sample	Lane/Customer/Taxes	Taxes
sample	Lane/Customer/Credit Remaining	Credit Remaining
sample	Lane/Customer/Last Sale	Last Sale
sample	Lane/Customer/Last Payment	Last Payment
sample	Lane/Customer/Search Prompt	Enter part of the company's name or part of the contact's last name to search.
sample	Lane/Vendor/Vendor	Vendor
sample	Lane/Discount/Description	Description
sample	Lane/Discount/Preset	Preset
sample	Lane/Discount/Open	Open
sample	Lane/Discount/Fixed	Fixed Amount
sample	Lane/Discount/Percent	Percent Amount
sample	Lane/Discount/Amount	Amount
sample	Lane/Discount/Sale	Discount applies to Sale
sample	Lane/Discount/Item	Discount applies to Previous Item
sample	Lane/Product/Description	Description
sample	Lane/Product/Price	Price
sample	Lane/Product/Category	Category
sample	Lane/Product/Taxes	Taxes
sample	Lane/Product/Type	Type
sample	Lane/Product/Type/Preset	Preset
sample	Lane/Product/Type/Open	Open
sample	Lane/Product/Type/Open Negative	Open, Negative
sample	Lane/Product/Track Quantity	Track Quantity
sample	Lane/Product/On Hand	On Hand
sample	Lane/Product/Minimum	Minimum
sample	Lane/Product/Reorder	Reorder
sample	Lane/Product/Items Per Case	Items per Case
sample	Lane/Product/Case ID	Case ID
sample	Lane/Product/Vendor	Vendor
sample	Lane/Product/Extended	Extended
sample	Lane/Product/Cost	Cost
sample	Lane/Product/Reorder ID	Reorder ID
sample	Lane/Product/Search Prompt	Enter part of the product's description to search.
sample	Lane/Machine/Search Prompt	Enter part of any or all of the following fields to search for machines.
sample	Lane/Machine/Make	Make
sample	Lane/Machine/Model	Model
sample	Lane/Machine/Serial Number	Serial Number
sample	Lane/Machine/Counter	Counter
sample	Lane/Machine/Accessories	Accessories
sample	Lane/Machine/Owner	Owner
sample	Lane/Machine/Purchase Date	Purchase Date
sample	Lane/Machine/Last Service Date	Last Service Date
sample	Lane/Machine/Contract	Contract
sample	Lane/Machine/Contract/On Contract	On Contract
sample	Lane/Machine/Contract/Begins	Begins
sample	Lane/Machine/Contract/Ends	Ends
sample	Lane/QWO/Machines Owned By	Machines Owned By
sample	Lane/QWO/Machine Search Prompt	Enter part of any or all of the following fields to search for machines.
sample	Lane/QWO/Status	Status
sample	Lane/QWO/Status/Staff	Staff
sample	Lane/QWO/Status/Contact	Contact
sample	Lane/QWO/Status/0	Awaiting Estimate
sample	Lane/QWO/Status/1	Estimate Given
sample	Lane/QWO/Status/2	Estimate Denied
sample	Lane/QWO/Status/3	Approved
sample	Lane/QWO/Status/4	Serviced
sample	Lane/QWO/Status/5	Picked Up
sample	Lane/QWO/Status/6	Taken Back
sample	Lane/QWO/Status/7	Traded In
sample	Lane/QWO/Status/8	Canceled
sample	Lane/QWO/Number	WO ID
sample	Lane/QWO/Date Issued	Date Issued
sample	Lane/QWO/Type	Type
sample	Lane/QWO/Type/0	Std in Shop
sample	Lane/QWO/Type/2	Std Service Call
sample	Lane/QWO/Type/3	Emergency Service Call
sample	Lane/QWO/Type/4	Maintenance Agreement
sample	Lane/QWO/Type/5	Shop-Other
sample	Lane/QWO/Type/6	Call-Other
sample	Lane/QWO/Type/7	Other
sample	Lane/QWO/Buttons/Process And Print	Process and Print
sample	Lane/QWO/Machine	Machine
sample	Lane/QWO/Loaner	Loaner
sample	Lane/QWO/Problem and Solution	Problem and Solution
sample	Lane/QWO/Technician	Technician
sample	Lane/QWO/Customer	Customer
sample	Lane/QWO/Search By Owner	Search by Owner
sample	Lane/QWO/Search By Machine	Search by Machine
sample	Lane/QWO/Problem	Problem
sample	Lane/QWO/Solution	Solution
sample	Enter a product ID, or press a function key	Enter a product ID, or press a function key
sample	Clerk	Clerk
sample	Subtotal	Subtotal
sample	Total	Total
sample	Taxes	Taxes
sample	Amount Due	Amount Due
sample	Due w/Disc	Due w/Disc
sample	Disc Date	Disc Date
sample	Due Date	Due Date
sample	Enter your clerk ID	Enter your clerk ID
sample	Enter your clerk Passcode	Enter your clerk Passcode
sample	Ticket	Ticket
sample	Amount required for %0 sales.	Amount required for %0 sales.
sample	A customer must be open for %0 sales.	A customer must be open for %0 sales.
sample	%0 customers must pay at the time of service.	%0 customers must pay at the time of service.
sample	Change	Change
sample	Enter or scan the item to check	Enter or scan the item to check
sample	Price Check	Price Check
sample	Unknown Product	Unknown Product: %0
sample	Enter your passcode to shutdown the register	Enter your passcode to shutdown the register
sample	Shutdown in progress...	Shutdown in progress...
sample	(w/disc)	(w/disc)
sample	Enter the amount and tender type, or continue to enter products	Enter the amount and tender type, or continue to enter products
sample	Customer	Customer
sample	This sale has been (partially?) committed, so it can not be canceled.	This sale has been (partially?) committed, so it can not be canceled.
sample	CANCELED	CANCELED
sample	none	none
sample	Cancel R/A	Cancel R/A
sample	Tax exempt	Tax exempt
sample	SUSPENDED	SUSPENDED
sample	A suspended sale can not be resumed inside another transaction.	A suspended sale can not be resumed inside another transaction.
sample	There are no suspended tickets.	There are no suspended tickets.
sample	There is no ticket %0.	There is no ticket %0.
sample	The ticket %0 was not suspended (it is finalized).	The ticket %0 was not suspended (it is finalized).
sample	RESUMED	RESUMED
sample	R/A can not be processed inside a standard transaction.	R/A can not be processed inside a standard transaction.
sample	A customer must be open for a R/A transaction.	A customer must be open for a R/A transaction.
sample	clear	clear
sample	Lane/Register/Tender/RA Requires Pays	You can not tender R/A transactions with %0.
sample	Lane/Register/Tender/No Zero Amount	%0 does not allow zero amounts.
sample	Lane/Register/Tender/No Negative Amount	%0 does not allow negative amounts.
sample	Lane/Register/Tender/No Positive Amount	%0 does not allow positive amounts.
sample	Lane/Register/Tender/Requires Items	%0 requires items in the sale.
sample	Lane/Register/Tender/Does Not Allow Items	%0 does not allow items in the sale.
sample	Lane/Register/Tender/No Allow Change	%0 sales do not allow change.
sample	Lane/Register/Discount/RA Transaction	Discounts can not be used in an R/A transaction.
sample	Lane/Register/Product/Open Without Amount	Open items require an amount.
sample	Lane/Register/RA	R/A
sample	Lane/Register/Customer/Not Found	The customer, %0, was not found.
sample	Lane/Register/Sale/Void by ID/Confirmation	Are you sure you want to permanently void ticket %0 (%1 %2) ?\n
sample	Lane/Register/Sale/Void by ID/Success	%0 voided.
sample	Lane/Printer/Format/Item	%{qty(4)}x%{plu(-20)} %{amt(14)}\n%{descr(-40)}\n\n
sample	Lane/Pole/Format/Item	%{descr(-20)}%{qty(-3)} %{amt(16)}
sample	Lane/Printer/Format/Discount	%{descr(-20)} %{amt(19)}\n\n
sample	Lane/Printer/Format/Tender	%{descr(-10)}%{amt(10)}\n
sample	Lane/Printer/Format/Subtotal	%{descr(-19)} %{amt(20)}\n
sample	Lane/Printer/Format/Tax	%{descr(-20)} %{amt(19)}\n
sample	Lane/Printer/Format/Total	%{descr(-6)}%{amt(14)}\n
sample	Lane/Printer/Format/Terms	\n%{termsTitle}: %{terms}\n%{discDateTitle}: %{discDate}\n%{dueDateTitle}: %{dueDate}\n
sample	Lane/Printer/Format/Footer	<center>%{clerkTitle}: %{clerk}\n%{now}\n%{ticketTitle} %{ticket}\n\n%{stringFooter}
sample	Lane/Timeclock/Successful Clock In	%0 clocked in.
sample	Lane/Timeclock/Successful Clock Out	%0 clocked out with %1 hours today.
sample	Lane/Timeclock/Failed Clock	Failed to clock-in/out.
sample	Lane/BackOffice/Timekeeping	Timekeeping
sample	Lane/BackOffice/Timekeeping/Invalid Time/Title	Error
sample	Lane/BackOffice/Timekeeping/Invalid Time	The value entered is not a valid time.
c	Lane/QWO/Type/1	Rush in Shop
c	locale-data-version	$Id: base-dataset.sql 1197 2010-10-24 18:23:51Z jason $
c	locale-data-name	Sample Locale
c	Lane/Locale/Money/CurrencyCode	???
c	Lane/Locale/Money/Prefix	$
c	Lane/Locale/Money/Suffix	
c	Lane/Locale/Money/GroupingDigits	3
c	Lane/Locale/Money/GroupingSeparator	 
c	Lane/Locale/Money/DecimalSeparator	.
c	Lane/Locale/Money/DecimalDigits	2
c	Lane/Locale/Money/Negative/Prefix	-$
c	Lane/Locale/Money/Negative/Suffix	
c	Lane/Locale/Money/Negative/GroupingDigits	3
c	Lane/Locale/Money/Negative/GroupingSeparator	 
c	Lane/Locale/Money/Negative/DecimalSeparator	.
c	Lane/Locale/Temporal/LongTimestamp	%d %B %Y %H:%M
c	Lane/Locale/Temporal/ShortTimestamp	%Y-%m-%d %H:%M
c	Lane/Locale/Temporal/LongTime	%H:%M
c	Lane/Locale/Temporal/ShortTime	%H:%M
c	Lane/Locale/Temporal/LongDate	%d %B %Y
c	Lane/Locale/Temporal/ShortDate	%Y-%m-%d
c	Lane/GenericObject/ID	ID
c	Lane/BackOffice/Save Prompt	This record is not saved. Do you want a chance to save your changes?\n(Selecting 'Yes' only cancels the previous operation.)
c	Lane/BackOffice/Remove Prompt	Are you sure you want to permanently\nremove this record from the database?
c	Lane/BackOffice/Confirmation	Confirmation
c	Lane/BackOffice/Buttons/Yes	Yes
c	Lane/BackOffice/Buttons/Yes, Remove	Yes, Remove
c	Lane/BackOffice/Buttons/No	No
c	Lane/BackOffice/Buttons/No, Cancel	No, Cancel
c	Lane/BackOffice/Buttons/No, Discard	No, Discard
c	Lane/BackOffice/Buttons/Discard	Discard
c	Lane/BackOffice/Buttons/Cancel	Cancel
c	Lane/BackOffice/Buttons/New	New
c	Lane/BackOffice/Buttons/Process	Process
c	Lane/BackOffice/Buttons/Quit	Quit
c	Lane/BackOffice/Buttons/Remove	Remove
c	Lane/BackOffice/Buttons/Search	Search
c	Lane/BackOffice/Buttons/OK	OK
c	Lane/BackOffice/Buttons/Add	Add
c	Lane/BackOffice/Buttons/View	View
c	Lane/BackOffice/Buttons/Print	Print
c	Lane/BackOffice/Search Results	Search Results
c	Lane/BackOffice/Search Results Text	The database found the following records:
c	Lane/BackOffice/Notes	Notes
c	Lane/BackOffice/Select	Select One
c	Lane/BackOffice/Clerks	Clerks
c	Lane/BackOffice/Customers	Customers
c	Lane/BackOffice/Discounts	Discounts
c	Lane/BackOffice/Machines	Machines
c	Lane/BackOffice/Products	Products
c	Lane/BackOffice/QWO	QWO
c	Lane/BackOffice/Strings	Strings
c	Lane/BackOffice/System Strings	System Strings
c	Lane/BackOffice/Taxes	Taxes
c	Lane/BackOffice/Tenders	Tenders
c	Lane/BackOffice/Terms	Terms
c	Lane/BackOffice/Vendors	Vendors
c	Lane/Clerk/Clerk	Clerk
c	Lane/Clerk/Name	Name
c	Lane/Clerk/Passcode	Passcode
c	Lane/Clerk/Drawer	Drawer
c	Lane/String/Data	Data
c	Lane/Tax/Description	Description
c	Lane/Tax/Amount	Amount
c	Lane/Term/Description	Description
c	Lane/Term/Days Until Due	Days Until Due
c	Lane/Term/Finance Rate	Finance Rate
c	Lane/Term/Days For Discount	Days For Discount
c	Lane/Term/Discount Rate	Discount Rate
c	Lane/Tender/Description	Description
c	Lane/Tender/Allow Change	Allow Change
c	Lane/Tender/Mandatory Amount	Mandatory Amount
c	Lane/Tender/Open Drawer	Open Drawer
c	Lane/Tender/Pays	Pays
c	Lane/Tender/eProcess	eProcess
c	Lane/Tender/eAuthorize	eAuthorize
c	Lane/Tender/Allow Zero Amounts	Allow Zero Amounts
c	Lane/Tender/Allow Negative Amounts	Allow Negative Amounts
c	Lane/Tender/Allow Positive Amounts	Allow Positive Amounts
c	Lane/Tender/Require Items/Require Items	Require Items
c	Lane/Tender/Require Items/Do Not Allow Items	Do Not Allow Items
c	Lane/Tender/Require Items/Either	Either
c	Lane/Customer/Company Name	Company Name
c	Lane/Customer/Contact Given Name	Contact Given Name
c	Lane/Customer/Contact Family Name	Contact Surname
c	Lane/Customer/Billing	Billing
c	Lane/Customer/Billing Address 1	Address 1
c	Lane/Customer/Billing Address 2	Address 2
c	Lane/Customer/Billing City	City
c	Lane/Customer/Billing State	State
c	Lane/Customer/Billing Zip	Zip
c	Lane/Customer/Billing Country	Country
c	Lane/Customer/Billing Phone	Phone
c	Lane/Customer/Billing Fax	Fax
c	Lane/Customer/Shipping	Shipping
c	Lane/Customer/Same As Billing	Same as Billing
c	Lane/Customer/Shipping Address 1	Address 1
c	Lane/Customer/Shipping Address 2	Address 2
c	Lane/Customer/Shipping City	City
c	Lane/Customer/Shipping State	State
c	Lane/Customer/Shipping Zip	Zip
c	Lane/Customer/Shipping Country	Country
c	Lane/Customer/Shipping Phone	Phone
c	Lane/Customer/Shipping Fax	Fax
c	Lane/Customer/Email	Email
c	Lane/Customer/Accounting	Accounting
c	Lane/Customer/Account Terms	Terms
c	Lane/Customer/Customer Type	Customer Type
c	Lane/Customer/Customer Type/0	Company
c	Lane/Customer/Customer Type/1	Individual
c	Lane/Customer/Customer Type/2	Web Only
c	Lane/Customer/Customer Type/3	Dealer
c	Lane/Customer/Credit Limit	Credit Limit
c	Lane/Customer/Balance	Balance
c	Lane/Customer/Taxes	Taxes
c	Lane/Customer/Credit Remaining	Credit Remaining
c	Lane/Customer/Last Sale	Last Sale
c	Lane/Customer/Last Payment	Last Payment
c	Lane/Customer/Search Prompt	Enter part of the company's name or part of the contact's last name to search.
c	Lane/Vendor/Vendor	Vendor
c	Lane/Discount/Description	Description
c	Lane/Discount/Preset	Preset
c	Lane/Discount/Open	Open
c	Lane/Discount/Fixed	Fixed Amount
c	Lane/Discount/Percent	Percent Amount
c	Lane/Discount/Amount	Amount
c	Lane/Discount/Sale	Discount applies to Sale
c	Lane/Discount/Item	Discount applies to Previous Item
c	Lane/Product/Description	Description
c	Lane/Product/Price	Price
c	Lane/Product/Category	Category
c	Lane/Product/Taxes	Taxes
c	Lane/Product/Type	Type
c	Lane/Product/Type/Preset	Preset
c	Lane/Product/Type/Open	Open
c	Lane/Product/Type/Open Negative	Open, Negative
c	Lane/Product/Track Quantity	Track Quantity
c	Lane/Product/On Hand	On Hand
c	Lane/Product/Minimum	Minimum
c	Lane/Product/Reorder	Reorder
c	Lane/Product/Items Per Case	Items per Case
c	Lane/Product/Case ID	Case ID
c	Lane/Product/Vendor	Vendor
c	Lane/Product/Extended	Extended
c	Lane/Product/Cost	Cost
c	Lane/Product/Reorder ID	Reorder ID
c	Lane/Product/Search Prompt	Enter part of the product's description to search.
c	Lane/Machine/Search Prompt	Enter part of any or all of the following fields to search for machines.
c	Lane/Machine/Make	Make
c	Lane/Machine/Model	Model
c	Lane/Machine/Serial Number	Serial Number
c	Lane/Machine/Counter	Counter
c	Lane/Machine/Accessories	Accessories
c	Lane/Machine/Owner	Owner
c	Lane/Machine/Purchase Date	Purchase Date
c	Lane/Machine/Last Service Date	Last Service Date
c	Lane/Machine/Contract	Contract
c	Lane/Machine/Contract/On Contract	On Contract
c	Lane/Machine/Contract/Begins	Begins
c	Lane/Machine/Contract/Ends	Ends
c	Lane/QWO/Machines Owned By	Machines Owned By
c	Lane/QWO/Machine Search Prompt	Enter part of any or all of the following fields to search for machines.
c	Lane/QWO/Status	Status
c	Lane/QWO/Status/Staff	Staff
c	Lane/QWO/Status/Contact	Contact
c	Lane/QWO/Status/0	Awaiting Estimate
c	Lane/QWO/Status/1	Estimate Given
c	Lane/QWO/Status/2	Estimate Denied
c	Lane/QWO/Status/3	Approved
c	Lane/QWO/Status/4	Serviced
c	Lane/QWO/Status/5	Picked Up
c	Lane/QWO/Status/6	Taken Back
c	Lane/QWO/Status/7	Traded In
c	Lane/QWO/Status/8	Canceled
c	Lane/QWO/Number	WO ID
c	Lane/QWO/Date Issued	Date Issued
c	Lane/QWO/Type	Type
c	Lane/QWO/Type/0	Std in Shop
c	Lane/QWO/Type/2	Std Service Call
c	Lane/QWO/Type/3	Emergency Service Call
c	Lane/QWO/Type/4	Maintenance Agreement
c	Lane/QWO/Type/5	Shop-Other
c	Lane/QWO/Type/6	Call-Other
c	Lane/QWO/Type/7	Other
c	Lane/QWO/Buttons/Process And Print	Process and Print
c	Lane/QWO/Machine	Machine
c	Lane/QWO/Loaner	Loaner
c	Lane/QWO/Problem and Solution	Problem and Solution
c	Lane/QWO/Technician	Technician
c	Lane/QWO/Customer	Customer
c	Lane/QWO/Search By Owner	Search by Owner
c	Lane/QWO/Search By Machine	Search by Machine
c	Lane/QWO/Problem	Problem
c	Lane/QWO/Solution	Solution
c	Enter a product ID, or press a function key	Enter a product ID, or press a function key
c	Clerk	Clerk
c	Subtotal	Subtotal
c	Total	Total
c	Taxes	Taxes
c	Amount Due	Amount Due
c	Due w/Disc	Due w/Disc
c	Disc Date	Disc Date
c	Due Date	Due Date
c	Enter your clerk ID	Enter your clerk ID
c	Enter your clerk Passcode	Enter your clerk Passcode
c	Ticket	Ticket
c	Amount required for %0 sales.	Amount required for %0 sales.
c	A customer must be open for %0 sales.	A customer must be open for %0 sales.
c	%0 customers must pay at the time of service.	%0 customers must pay at the time of service.
c	Change	Change
c	Enter or scan the item to check	Enter or scan the item to check
c	Price Check	Price Check
c	Unknown Product	Unknown Product: %0
c	Enter your passcode to shutdown the register	Enter your passcode to shutdown the register
c	Shutdown in progress...	Shutdown in progress...
c	(w/disc)	(w/disc)
c	Enter the amount and tender type, or continue to enter products	Enter the amount and tender type, or continue to enter products
c	Customer	Customer
c	This sale has been (partially?) committed, so it can not be canceled.	This sale has been (partially?) committed, so it can not be canceled.
c	CANCELED	CANCELED
c	none	none
c	Cancel R/A	Cancel R/A
c	Tax exempt	Tax exempt
c	SUSPENDED	SUSPENDED
c	A suspended sale can not be resumed inside another transaction.	A suspended sale can not be resumed inside another transaction.
c	There are no suspended tickets.	There are no suspended tickets.
c	There is no ticket %0.	There is no ticket %0.
c	The ticket %0 was not suspended (it is finalized).	The ticket %0 was not suspended (it is finalized).
c	RESUMED	RESUMED
c	R/A can not be processed inside a standard transaction.	R/A can not be processed inside a standard transaction.
c	A customer must be open for a R/A transaction.	A customer must be open for a R/A transaction.
c	clear	clear
c	Lane/Register/Tender/RA Requires Pays	You can not tender R/A transactions with %0.
c	Lane/Register/Tender/No Zero Amount	%0 does not allow zero amounts.
c	Lane/Register/Tender/No Negative Amount	%0 does not allow negative amounts.
c	Lane/Register/Tender/No Positive Amount	%0 does not allow positive amounts.
c	Lane/Register/Tender/Requires Items	%0 requires items in the sale.
c	Lane/Register/Tender/Does Not Allow Items	%0 does not allow items in the sale.
c	Lane/Register/Tender/No Allow Change	%0 sales do not allow change.
c	Lane/Register/Discount/RA Transaction	Discounts can not be used in an R/A transaction.
c	Lane/Register/Product/Open Without Amount	Open items require an amount.
c	Lane/Register/RA	R/A
c	Lane/Register/Customer/Not Found	The customer, %0, was not found.
c	Lane/Register/Sale/Void by ID/Confirmation	Are you sure you want to permanently void ticket %0 (%1 %2) ?\n
c	Lane/Register/Sale/Void by ID/Success	%0 voided.
c	Lane/Printer/Format/Item	%{qty(4)}x%{plu(-20)} %{amt(14)}\n%{descr(-40)}\n\n
c	Lane/Pole/Format/Item	%{descr(-20)}%{qty(-3)} %{amt(16)}
c	Lane/Printer/Format/Discount	%{descr(-20)} %{amt(19)}\n\n
c	Lane/Printer/Format/Tender	%{descr(-10)}%{amt(10)}\n
c	Lane/Printer/Format/Subtotal	%{descr(-19)} %{amt(20)}\n
c	Lane/Printer/Format/Tax	%{descr(-20)} %{amt(19)}\n
c	Lane/Printer/Format/Total	%{descr(-6)}%{amt(14)}\n
c	Lane/Printer/Format/Terms	\n%{termsTitle}: %{terms}\n%{discDateTitle}: %{discDate}\n%{dueDateTitle}: %{dueDate}\n
c	Lane/Printer/Format/Footer	<center>%{clerkTitle}: %{clerk}\n%{now}\n%{ticketTitle} %{ticket}\n\n%{stringFooter}
c	Lane/Timeclock/Successful Clock In	%0 clocked in.
c	Lane/Timeclock/Successful Clock Out	%0 clocked out with %1 hours today.
c	Lane/Timeclock/Failed Clock	Failed to clock-in/out.
c	Lane/BackOffice/Timekeeping	Timekeeping
c	Lane/BackOffice/Timekeeping/Invalid Time/Title	Error
c	Lane/BackOffice/Timekeeping/Invalid Time	The value entered is not a valid time.
\.


--
-- Data for Name: machines; Type: TABLE DATA; Schema: public; Owner: lanedbadmin
--

COPY machines (make, model, sn, counter, accessories, owner, location, purchased, lastservice, notes, oncontract, contractbegins, contractends, createdby, created, voidat, voidby, modified, modifiedby) FROM stdin;
\.


--
-- Data for Name: machines_rev; Type: TABLE DATA; Schema: public; Owner: lanedbadmin
--

COPY machines_rev (make, model, sn, counter, accessories, owner, location, purchased, lastservice, notes, oncontract, contractbegins, contractends, createdby, created, voidat, voidby, modified, modifiedby, r) FROM stdin;
\.


--
-- Data for Name: po; Type: TABLE DATA; Schema: public; Owner: lanedbadmin
--

COPY po (id, vendor, created, modified, creator, notes) FROM stdin;
\.


--
-- Data for Name: po2vendor; Type: TABLE DATA; Schema: public; Owner: lanedbadmin
--

COPY po2vendor (vendor, action) FROM stdin;
\.


--
-- Data for Name: poitems; Type: TABLE DATA; Schema: public; Owner: lanedbadmin
--

COPY poitems (id, lineno, product, orderedqty, rcvdqty) FROM stdin;
0	0	012502054528	20.000	3.000
\.


--
-- Data for Name: pricetables; Type: TABLE DATA; Schema: public; Owner: lanedbadmin
--

COPY pricetables (id, pricelist, voidat, voidby, created, createdby, modified, modifiedby) FROM stdin;
1	0.34 0.33 0.22	\N	\N	2010-09-19 17:09:57.26482-05	installer@localhost	2010-09-19 17:09:57.26482-05	installer@localhost
\.


--
-- Data for Name: pricetables_rev; Type: TABLE DATA; Schema: public; Owner: lanedbadmin
--

COPY pricetables_rev (id, pricelist, voidat, voidby, created, createdby, modified, modifiedby, r) FROM stdin;
1	0.34 0.33 0.22	\N	\N	2010-09-19 17:09:57.26482-05	installer@localhost	2010-09-19 17:09:57.26482-05	installer@localhost	1
\.


--
-- Data for Name: products; Type: TABLE DATA; Schema: public; Owner: lanedbadmin
--

COPY products (id, descr, price, category, taxes, type, trackqty, onhand, minimum, reorder, vendor, caseqty, caseid, extended, cost, reorderid, voidat, voidby, created, createdby, modified, modifiedby) FROM stdin;
\.


--
-- Data for Name: products_rev; Type: TABLE DATA; Schema: public; Owner: lanedbadmin
--

COPY products_rev (id, descr, price, category, taxes, type, trackqty, onhand, minimum, reorder, vendor, caseqty, caseid, extended, cost, reorderid, voidat, voidby, created, createdby, modified, modifiedby, r) FROM stdin;
\.


--
-- Data for Name: purchaseorders; Type: TABLE DATA; Schema: public; Owner: lanedbadmin
--

COPY purchaseorders (id, vendor, created, createdby, modified, modifiedby, notes, extended, total, voidat, voidby, orderedat, orderedby, orderedvia, completelyreceived) FROM stdin;
\.


--
-- Data for Name: purchaseorders_rev; Type: TABLE DATA; Schema: public; Owner: lanedbadmin
--

COPY purchaseorders_rev (id, vendor, created, createdby, modified, modifiedby, notes, extended, total, voidat, voidby, orderedat, orderedby, orderedvia, completelyreceived, r) FROM stdin;
\.


--
-- Data for Name: purchaseordersordereditems; Type: TABLE DATA; Schema: public; Owner: lanedbadmin
--

COPY purchaseordersordereditems (id, lineno, plu, qty, amt, voidat, voidby, extended) FROM stdin;
\.


--
-- Data for Name: purchaseordersordereditems_rev; Type: TABLE DATA; Schema: public; Owner: lanedbadmin
--

COPY purchaseordersordereditems_rev (id, lineno, plu, qty, amt, voidat, voidby, extended, r) FROM stdin;
\.


--
-- Data for Name: purchaseordersreceiveditems; Type: TABLE DATA; Schema: public; Owner: lanedbadmin
--

COPY purchaseordersreceiveditems (id, lineno, plu, qty, received, receivedby, voidat, voidby, extended) FROM stdin;
\.


--
-- Data for Name: purchaseordersreceiveditems_rev; Type: TABLE DATA; Schema: public; Owner: lanedbadmin
--

COPY purchaseordersreceiveditems_rev (id, lineno, plu, qty, received, receivedby, voidat, voidby, extended, r) FROM stdin;
\.


--
-- Data for Name: qwo; Type: TABLE DATA; Schema: public; Owner: lanedbadmin
--

COPY qwo (id, dateissued, type, customer, notes, make, model, sn, counter, accessories, loanermake, loanermodel, loanersn, loanercounter, loaneraccessories, custprob, tech, technotes, solution, status, createdby, created, voidat, voidby, modified, modifiedby) FROM stdin;
\.


--
-- Data for Name: qwo_rev; Type: TABLE DATA; Schema: public; Owner: lanedbadmin
--

COPY qwo_rev (id, dateissued, type, customer, notes, make, model, sn, counter, accessories, loanermake, loanermodel, loanersn, loanercounter, loaneraccessories, custprob, tech, technotes, solution, status, createdby, created, voidat, voidby, modified, modifiedby, r) FROM stdin;
\.


--
-- Data for Name: qwostatuses; Type: TABLE DATA; Schema: public; Owner: lanedbadmin
--

COPY qwostatuses (id, status, staff, contact, notes, createdby, created, voidat, voidby, modified, modifiedby) FROM stdin;
\.


--
-- Data for Name: qwostatuses_rev; Type: TABLE DATA; Schema: public; Owner: lanedbadmin
--

COPY qwostatuses_rev (id, status, staff, contact, notes, createdby, created, voidat, voidby, modified, modifiedby, r) FROM stdin;
\.


--
-- Data for Name: sales; Type: TABLE DATA; Schema: public; Owner: lanedbadmin
--

COPY sales (id, customer, tranzdate, suspended, clerk, taxmask, total, balance, terminal, notes, voidat, voidby, created, createdby, modified, modifiedby, server) FROM stdin;
\.


--
-- Data for Name: sales_rev; Type: TABLE DATA; Schema: public; Owner: lanedbadmin
--

COPY sales_rev (id, customer, tranzdate, suspended, clerk, taxmask, total, balance, terminal, notes, voidat, voidby, created, createdby, modified, modifiedby, server, r) FROM stdin;
\.


--
-- Data for Name: salesitems; Type: TABLE DATA; Schema: public; Owner: lanedbadmin
--

COPY salesitems (id, lineno, plu, qty, amt, struck) FROM stdin;
\.


--
-- Data for Name: salesitems_rev; Type: TABLE DATA; Schema: public; Owner: lanedbadmin
--

COPY salesitems_rev (id, lineno, plu, qty, amt, struck, r) FROM stdin;
\.


--
-- Data for Name: salespayments; Type: TABLE DATA; Schema: public; Owner: lanedbadmin
--

COPY salespayments (id, lineno, tranzdate, raid, amt, struck, notes, ext) FROM stdin;
\.


--
-- Data for Name: salespayments_rev; Type: TABLE DATA; Schema: public; Owner: lanedbadmin
--

COPY salespayments_rev (id, lineno, tranzdate, raid, amt, struck, notes, ext, r) FROM stdin;
\.


--
-- Data for Name: salestaxes; Type: TABLE DATA; Schema: public; Owner: lanedbadmin
--

COPY salestaxes (id, taxid, taxable, rate, tax) FROM stdin;
\.


--
-- Data for Name: salestaxes_rev; Type: TABLE DATA; Schema: public; Owner: lanedbadmin
--

COPY salestaxes_rev (id, taxid, taxable, rate, tax, r) FROM stdin;
\.


--
-- Data for Name: salestenders; Type: TABLE DATA; Schema: public; Owner: lanedbadmin
--

COPY salestenders (id, lineno, tender, amt, ext) FROM stdin;
\.


--
-- Data for Name: salestenders_rev; Type: TABLE DATA; Schema: public; Owner: lanedbadmin
--

COPY salestenders_rev (id, lineno, tender, amt, ext, r) FROM stdin;
\.


--
-- Data for Name: strings; Type: TABLE DATA; Schema: public; Owner: lanedbadmin
--

COPY strings (id, data, voidat, voidby, created, createdby, modified, modifiedby) FROM stdin;
endorse-1	<center><b>    FOR DEPOSIT ONLY</b</center>	\N	\N	2010-09-19 17:11:27.302878-05	installer@localhost	2010-09-19 17:11:27.302878-05	installer@localhost
receipt2-footer	<center>I agree to pay for the above items.<br><br><br>X___________________________________</center>	\N	\N	2010-09-19 17:11:27.302878-05	installer@localhost	2010-09-19 17:11:27.302878-05	installer@localhost
custdisp-idle	Visit us at http://l-ane.sf.net	\N	\N	2010-09-19 17:11:27.302878-05	installer@localhost	2010-09-19 17:11:27.302878-05	installer@localhost
receipt-footer	<center><b>Thank You!</b></center><br>	\N	\N	2010-09-19 17:11:27.302878-05	installer@localhost	2010-09-19 17:11:27.302878-05	installer@localhost
receipt2-header	<center><b>L'anePOS</b><br>House Acct Charge<br><b>TEST SETUP</b><br>	\N	\N	2010-09-19 17:11:27.302878-05	installer@localhost	2010-09-19 17:11:27.302878-05	installer@localhost
receipt5-header	<center><b>L'anePOS</b><br>Credit Card Charge<br><b>TEST SETUP</b><br>	\N	\N	2010-09-19 17:11:27.302878-05	installer@localhost	2010-09-19 17:11:27.302878-05	installer@localhost
receipt5-footer	<center>I agree to pay for the above items\naccording to my cardholder's agreement.\n<br><br><br>X___________________________________</center>	\N	\N	2010-09-19 17:11:27.302878-05	installer@localhost	2010-09-19 17:11:27.302878-05	installer@localhost
debit-remaining-ticket	<center><b>L'anePOS TEST<br><br>BALANCE REMAINING</b><br><br><customer><br><b><acctId><br>Remaining <balance></b>	\N	\N	2010-09-19 17:11:27.302878-05	installer@localhost	2010-09-19 17:11:27.302878-05	installer@localhost
receipt-header	<center><b>L'ane POS<br>TEST SETUP</b><br>	\N	\N	2010-09-19 17:11:27.302878-05	installer@localhost	2010-09-19 17:11:27.302878-05	installer@localhost
register-touch-menusetup	page = Entrees\nitem = Steak\nforeground = black\nbackground = grey\nplu = 1000\nitem = Shrimp\nforeground = white\nbackground = blue\nplu = 1001\nitem = Catfish\nforeground = black\nbackground = green\nplu = 1003\nitem = Burger\nforeground = white\nbackground = brown\nplu = 1004\nitem = Cheese\\nBurger\nforeground = white\nbackground = brown\nplu = 1005\nitem = Caesar\\nSalad\nforeground = black\nbackground = green\nplu = 1006\nitem = Filet\\nMignon\nforeground = white\nbackground = DarkGoldenrod\nplu=1002\nitem = Rare\nforeground = black\nbackground = magenta\nplu = raredone\nitem = Medium\nforeground = black\nbackground = magenta\nplu = mediumdone\nitem = Well\nforeground = black\nbackground = magenta\nplu = welldone\npage = Sides\nitem = French\\nFries\nforeground = white\nbackground = red\nplu = 20000\nitem = Baked\\nPotato\nforeground = white\nbackground = grey\nplu = 20001\nitem = Mashed\\nPotato\nforeground = black\nbackground = white\nplu = 20002\nitem = Salad\nforeground = black\nbackground = green\nplu = 20003\nitem = Soup\nforeground = black\nbackground = white\nplu = 20004\npage = Desserts\nitem = Cheese\\nCake\nforeground = black\nbackground = wheat\nplu = 30001\npage = Liquor\nitem = Draft\\nBeer\nforeground = black\nbackground = yellow\nplu = 40001\nitem = Wine\nforeground = white\nbackground = BlueViolet\nplu = 40002\npage = Drinks\nitem = Small\nforeground = black\nbackground = magenta\nplu = sm\nitem = Medium\nforeground = black\nbackground = magenta\nplu = med\nitem = Large\nforeground = black\nbackground = magenta\nplu = lrg\nitem = Coke\nforeground = white\nbackground = red\nplu = 2000\nitem = Diet Coke\nforeground = red\nbackground = white\nplu = 2001\nitem = Sprite\nforeground = white\nbackground = green\nplu = 2002\nitem = Water\nforeground = darkgrey\nbackground = wheat\nplu = 2003\nend\n	\N	\N	2010-09-19 17:11:27.302878-05	installer@localhost	2010-09-19 17:11:27.302878-05	installer@localhost
\.


--
-- Data for Name: strings_rev; Type: TABLE DATA; Schema: public; Owner: lanedbadmin
--

COPY strings_rev (id, data, voidat, voidby, created, createdby, modified, modifiedby, r) FROM stdin;
endorse-1	<center><b>    FOR DEPOSIT ONLY</b</center>	\N	\N	2010-09-19 17:11:27.302878-05	installer@localhost	2010-09-19 17:11:27.302878-05	installer@localhost	1
receipt2-footer	<center>I agree to pay for the above items.<br><br><br>X___________________________________</center>	\N	\N	2010-09-19 17:11:27.302878-05	installer@localhost	2010-09-19 17:11:27.302878-05	installer@localhost	2
custdisp-idle	Visit us at http://l-ane.sf.net	\N	\N	2010-09-19 17:11:27.302878-05	installer@localhost	2010-09-19 17:11:27.302878-05	installer@localhost	3
receipt-footer	<center><b>Thank You!</b></center><br>	\N	\N	2010-09-19 17:11:27.302878-05	installer@localhost	2010-09-19 17:11:27.302878-05	installer@localhost	4
receipt2-header	<center><b>L'anePOS</b><br>House Acct Charge<br><b>TEST SETUP</b><br>	\N	\N	2010-09-19 17:11:27.302878-05	installer@localhost	2010-09-19 17:11:27.302878-05	installer@localhost	5
receipt5-header	<center><b>L'anePOS</b><br>Credit Card Charge<br><b>TEST SETUP</b><br>	\N	\N	2010-09-19 17:11:27.302878-05	installer@localhost	2010-09-19 17:11:27.302878-05	installer@localhost	6
receipt5-footer	<center>I agree to pay for the above items\naccording to my cardholder's agreement.\n<br><br><br>X___________________________________</center>	\N	\N	2010-09-19 17:11:27.302878-05	installer@localhost	2010-09-19 17:11:27.302878-05	installer@localhost	7
debit-remaining-ticket	<center><b>L'anePOS TEST<br><br>BALANCE REMAINING</b><br><br><customer><br><b><acctId><br>Remaining <balance></b>	\N	\N	2010-09-19 17:11:27.302878-05	installer@localhost	2010-09-19 17:11:27.302878-05	installer@localhost	8
receipt-header	<center><b>L'ane POS<br>TEST SETUP</b><br>	\N	\N	2010-09-19 17:11:27.302878-05	installer@localhost	2010-09-19 17:11:27.302878-05	installer@localhost	9
register-touch-menusetup	page = Entrees\nitem = Steak\nforeground = black\nbackground = grey\nplu = 1000\nitem = Shrimp\nforeground = white\nbackground = blue\nplu = 1001\nitem = Catfish\nforeground = black\nbackground = green\nplu = 1003\nitem = Burger\nforeground = white\nbackground = brown\nplu = 1004\nitem = Cheese\\nBurger\nforeground = white\nbackground = brown\nplu = 1005\nitem = Caesar\\nSalad\nforeground = black\nbackground = green\nplu = 1006\nitem = Filet\\nMignon\nforeground = white\nbackground = DarkGoldenrod\nplu=1002\nitem = Rare\nforeground = black\nbackground = magenta\nplu = raredone\nitem = Medium\nforeground = black\nbackground = magenta\nplu = mediumdone\nitem = Well\nforeground = black\nbackground = magenta\nplu = welldone\npage = Sides\nitem = French\\nFries\nforeground = white\nbackground = red\nplu = 20000\nitem = Baked\\nPotato\nforeground = white\nbackground = grey\nplu = 20001\nitem = Mashed\\nPotato\nforeground = black\nbackground = white\nplu = 20002\nitem = Salad\nforeground = black\nbackground = green\nplu = 20003\nitem = Soup\nforeground = black\nbackground = white\nplu = 20004\npage = Desserts\nitem = Cheese\\nCake\nforeground = black\nbackground = wheat\nplu = 30001\npage = Liquor\nitem = Draft\\nBeer\nforeground = black\nbackground = yellow\nplu = 40001\nitem = Wine\nforeground = white\nbackground = BlueViolet\nplu = 40002\npage = Drinks\nitem = Small\nforeground = black\nbackground = magenta\nplu = sm\nitem = Medium\nforeground = black\nbackground = magenta\nplu = med\nitem = Large\nforeground = black\nbackground = magenta\nplu = lrg\nitem = Coke\nforeground = white\nbackground = red\nplu = 2000\nitem = Diet Coke\nforeground = red\nbackground = white\nplu = 2001\nitem = Sprite\nforeground = white\nbackground = green\nplu = 2002\nitem = Water\nforeground = darkgrey\nbackground = wheat\nplu = 2003\nend\n	\N	\N	2010-09-19 17:11:27.302878-05	installer@localhost	2010-09-19 17:11:27.302878-05	installer@localhost	10
\.


--
-- Data for Name: sysstrings; Type: TABLE DATA; Schema: public; Owner: lanedbadmin
--

COPY sysstrings (id, data, voidat, voidby, created, createdby, modified, modifiedby) FROM stdin;
Lane/Sale/Void/Earliest Voidable Timestamp	1776-07-04 00:00	\N	\N	2010-09-19 17:12:15.683993-05	lanedbadmin@localhost	2010-09-19 17:12:15.683993-05	lanedbadmin@localhost
company-customer-id	us	\N	\N	2010-09-19 17:11:27.351123-05	installer@localhost	2010-09-19 17:11:27.351123-05	installer@localhost
register-printSecond-2	1	\N	\N	2010-09-19 17:11:27.351123-05	installer@localhost	2010-09-19 17:11:27.351123-05	installer@localhost
earlypay-disc-tender	7	\N	\N	2010-09-19 17:11:27.351123-05	installer@localhost	2010-09-19 17:11:27.351123-05	installer@localhost
earlypay-disc-id	10	\N	\N	2010-09-19 17:11:27.351123-05	installer@localhost	2010-09-19 17:11:27.351123-05	installer@localhost
register-eauth-3	$amt = $main::fsTotal if $amt > $main::fsTotal;\n   #remove the tax from the fstax\n   #!!!!HARD-CODED TAX 2\n   my $tx = Tax->new;\n   my $i = 1;\n   $tx->open($i);\n   $me->{'sale'}->{'due'} -= $me->{'sale'}->{'taxes'};\n   $me->{'sale'}->{'taxable'}[$i - 1] -= $amt;\n   $me->{'Taxes'}[$i - 1] = $tx->applyTax($me->{'sale'}->{'taxable'}[$i - 1]);\n   $me->{'sale'}->{'taxes'} = 0;\n   for(my $j = 0; $j <= $#{$me->{'Taxes'}}; $j++)\n   {\n\t$me->{'sale'}->{'taxes'} += $me->{'Taxes'}[$j];\n   }\n\n   $main::fsTotal -= $amt;\n   $me->{'sale'}->{'due'} += $me->{'sale'}->{'taxes'};\n   #$me->{'sale'}->updateTotals;\n   &main::writeSummaryArea();\n   return 1;\n\n	\N	\N	2010-09-19 17:11:27.351123-05	installer@localhost	2010-09-19 17:11:27.351123-05	installer@localhost
register-eauth-4	$amt = $main::wicTotal;\n$main::wicTotal = 0;\n#remove the tax from the wictax, but remove the amt from fstax so we don't over remove the tax\n   $main::fsTotal -= $amt;\n   my $tx = Tax->new;\n   my $i = 1;\n   $tx->open($i);\n   $me->{'sale'}->{'due'} -= $me->{'sale'}->{'taxes'};\n   $me->{'sale'}->{'taxable'}[$i - 1] -= $amt;\n   $me->{'Taxes'}[$i - 1] = $tx->applyTax($me->{'sale'}->{'taxable'}[$i - 1]);\n   $me->{'sale'}->{'taxes'} = 0;\n   for(my $j = 0; $j <= $#{$me->{'Taxes'}}; $j++)\n   {\n\t$me->{'sale'}->{'taxes'} += $me->{'Taxes'}[$j];\n   }\n   $me->{'sale'}->{'due'} += $me->{'sale'}->{'taxes'};\n   #$me->{'sale'}->updateTotals;\n   &main::writeSummaryArea();\n\nreturn 1;	\N	\N	2010-09-19 17:11:27.351123-05	installer@localhost	2010-09-19 17:11:27.351123-05	installer@localhost
Lane/CORE/Business Day Start Time	00:00	\N	\N	2010-09-19 17:11:27.351123-05	installer@localhost	2010-09-19 17:11:27.351123-05	installer@localhost
register-ecancel-5	#-*-Perl-*-\n#this code cancels the purchase\n\n&main::infoPrint("Please wait, canceling the credit card transaction...");\n\nmy %dta;\nmy $str = SysString->new;\nif(!$str->open('ccauth-tclink-custid'))\n{\n print STDERR "register-eauth-5 couldn't load the ccauth-tclink-custid from the database\\n";\n return 0;\n}\n$dta{'custid'} = $str->{'data'};\nif(!$str->open('ccauth-tclink-password'))\n{\n print STDERR "register-eauth-5 couldn't load the ccauth-tclink-password from the database\\n";\n return 0;\n}\n$dta{'password'} = $str->{'data'};\n$dta{'transid'} = $ccAuth;\n$dta{'action'} = 'credit';\n\nmy %result = Net::TCLink::send(%dta);\n\nif($result{'status'} ne 'accepted')\n{\n   #tell the clerk what the problem is\n   &main::infoPrint("Cancelation Failed.\\n\\n");\n    my($key, $value);\n    print STDERR "%result\\n";\n    while(($key, $value) = each %result)\n     {\n\tprint STDERR "\\t$key=$value\\n";\n     }\n   return 0;\n}\n\n&main::infoPrint("");\n#print an extra ticket for the person to sign\n    my($key, $value);\n    print STDERR "%result\\n";\n    while(($key, $value) = each %result)\n     {\n\tprint STDERR "\\t$key=$value\\n";\n     }\nreturn 1;\n	\N	\N	2010-09-19 17:11:27.351123-05	installer@localhost	2010-09-19 17:11:27.351123-05	installer@localhost
register-eprocess-6	#-*-Perl-*-\n#use the amount up\n$me->{'cust'}->chargeToAcct($me->{'lc'}->extFmt($amt));\n\n#this code prints a amount remaining ticket\n\nreturn 0 if(!$me->{'string'}->open('debit-remaining-ticket'));\n&main::receiptPrint("Remaining on Card " . $me->{'lc'}->moneyFmt($me->{'cust'}{'creditRmn'} * 100));\nmy $t = $me->{'string'}{'data'};\n$t =~ s/<balance>/$me->{'lc'}->moneyFmt($me->{'cust'}->{'creditRmn'} * 100)/eg;\n$t =~ s/<acctId>/$me->{'cust'}{'id'}/g;\n$t =~ s/<customer>/sprintf("%-40.40s\n%-40.40s\n%-40.40s\n%-40.40s\n", $me->{'cust'}->getName(), $me->{'cust'}{'billAddr1'}, $me->{'cust'}{'billAddr2'}, $me->{'cust'}{'billCity'} . ", " . $me->{'cust'}{'billSt'} . " " . $me->{'cust'}{'billZip'})/eg;\n$main::printer->printFormatted($t);\n$main::printer->finishReceipt();\nreturn 1;\n\n	\N	\N	2010-09-19 17:11:27.351123-05	installer@localhost	2010-09-19 17:11:27.351123-05	installer@localhost
register-eprocess-5	#-*-Perl-*-\n#this code finalizes the purchase w/tclink\n\n&main::infoPrint("Please wait, finalizing the credit card transaction...");\n\nmy %dta;\nmy $str = SysString->new;\nif(!$str->open('ccauth-tclink-custid'))\n{\n print STDERR "register-process-5 couldn't load the ccauth-tclink-custid from the database\\n";\n return 0;\n}\n$dta{'custid'} = $str->{'data'};\nif(!$str->open('ccauth-tclink-password'))\n{\n print STDERR "register-eauth-5 couldn't load the ccauth-tclink-password from the database\\n";\n return 0;\n}\n$dta{'password'} = $str->{'data'};\n$dta{'transid'} = $ccAuth;\n$dta{'action'} = 'postauth';\n\nmy %result = Net::TCLink::send(%dta);\n\nif($result{'status'} ne 'accepted')\n{\n   #tell the clerk what the problem is\n   &main::infoPrint("Finalization Failed.\\n\\nReason: %result");\n    my($key, $value);\n    print STDERR "%result\\n";\n    while(($key, $value) = each %result)\n     {\n\tprint STDERR "\\t$key=$value\\n";\n     }\n   return 0;\n}\n\n&main::infoPrint("");\n#print an extra ticket for the person to sign\n#$main::reg->reprintProcess($tend->{'id'}, sprintf("%-40.40s\\n%-40.40s\\n%-40.40s\\n", "Card Number: \n$main::reg->reprintProcess(5, sprintf("%-40.40s\\n%-40.40s\\n%-40.40s\\n", "Card Number: $ccNum","Type: $ccType", "Authorization: $ccAuth"));\n    my($key, $value);\n    print STDERR "%result\\n";\n    while(($key, $value) = each %result)\n     {\n\tprint STDERR "\\t$key=$value\\n";\n     }\nreturn 1;\n\n	\N	\N	2010-09-19 17:11:27.351123-05	installer@localhost	2010-09-19 17:11:27.351123-05	installer@localhost
register-eauth-6	#-*-Perl-*-\n#this code makes sure the customer has the\n#credit available to make the purchase\n\nif($me->{'cust'}{'id'} eq '')\n{\n\t&main::infoPrint('A customer must be open for Debit Card sales.');\n\treturn 0;\n}\nreturn 1 if $me->{'cust'}{'creditRmn'} * 100 >= $amt;\n&main::infoPrint('This customer only has ' . $me->{'lc'}->moneyFmt($me->{'cust'}{'creditRmn'} * 100) . " on his/her debit card.");\nreturn 0;	\N	\N	2010-09-19 17:11:27.351123-05	installer@localhost	2010-09-19 17:11:27.351123-05	installer@localhost
register-touch-functionpagesetup	page = Functions\nitem = Error\\nCorrect\nforeground = white\nbackground = red\ncommand = $reg->errCorrectProcess();\nitem = Tax\\nExempt\nforeground = black\nbackground = magenta\ncommand = $reg->exemptProcess();\nitem = Cancel\\nSale\nforeground = white\nbackground = red\ncommand = @main::remoteData = (); $reg->cancelProcess();\nitem = Cash\nforeground = black\nbackground = green\ncommand = $reg->tenderProcess(0, $amt);\nitem = Check\nforeground = black\nbackground = green\ncommand = $reg->tenderProcess(1, $amt);\nitem = House\\nAcct\nforeground = black\nbackground = green\ncommand = $reg->tenderProcess(2, $amt);\nitem = Recv\\nAcct\nforeground = white\nbackground = brown\ncommand = $reg->raProcess('', $amt);\nitem = Customer\nforeground = white\nbackground = blue\ncommand = $reg->custProcess('', $amt);\nitem = Subtotal\nforeground = black\nbackground = yellow\ncommand = $reg->subtProcess();\nitem = Credit\\nCard\nforeground = black\nbackground = green\ncommand = $reg->tenderProcess(5, $amt);\nitem = Debit\\nCard\nforeground = black\nbackground = green\ncommand = $reg->tenderProcess(6, $amt);\nitem = $5\nforeground = black\nbackground = green\ncommand = $reg->tenderProcess(0, 500);\nitem = Open %\\nDiscount\nforeground = white\nbackground = red\ncommand = $reg->discProcess(1, $amt);\nitem = 10%\\nQty\\nDiscount\nforeground = white\nbackground = red\ncommand = $reg->discProcess(2, $amt);\nitem = Suspend\\nTicket\nforeground = white\nbackground = brown\ncommand = $reg->suspendProcess();\nitem = Resume\\nTicket\nforeground = white\nbackground = brown\ncommand = $reg->resumeProcess('', $amt);\nitem = $10\nforeground = black\nbackground = green\ncommand = $reg->tenderProcess(0, 1000);\nitem = $20\nforeground = black\nbackground = green\ncommand = $reg->tenderProcess(0, 2000);\nitem = Clerk\\nLogout\nforeground = black\nbackground = magenta\ncommand = $reg->clerkSignin() if $#{$reg->{'sale'}{'items'}} == -1;\nitem = \ncommand = 1;\nitem = \ncommand = 1;\nitem = \ncommand = 1;\nitem = \ncommand = 1;\nitem = Foreign\\nCurrency\nforeground = black\nbackground = green\ncommand = $reg->tenderProcess(8, $amt);\nend\n	\N	\N	2010-09-19 17:11:27.351123-05	installer@localhost	2010-09-19 17:11:27.351123-05	installer@localhost
Lane/CORE/Dataset/Version	3	\N	\N	2010-09-19 17:11:27.351123-05	installer@localhost	2010-10-05 08:06:28.692221-05	lanedbadmin@localhost
register-eauth-5	#-*-Perl-*-\n#this code makes sure the customer has the\n#credit available to make the purchase\n\n#this sample version uses the GPL client from\n#http://www.trustcommerce.com/\n#you need to install their TCLink perl client\n\n#this doesn't use avs\n\n#If other processors/gateways have open source or public domain clients,\n#I'm willing to write wrappers like this for them, as well.\n\nuse Net::TCLink; #this is the trustcommerce.com client\n\nmy %dta;\n\nmy $str = SysString->new;\nif(!$str->open('ccauth-tclink-custid'))\n{\n print STDERR "register-eauth-5 couldn't load the ccauth-tclink-custid from the database\\n";\n return 0;\n}\n$dta{'custid'} = $str->{'data'};\n\nif(!$str->open('ccauth-tclink-password'))\n{\n print STDERR "register-eauth-5 couldn't load the ccauth-tclink-custid from the database\\n";\n return 0;\n}\n$dta{'password'} = $str->{'data'};\n\n$ccNum = "";\n$ccType = "";\nmy $r;\n($r) = main::getResponses("show", "Swipe card or enter card number");\n&main::clearEntry;\nif($r =~ /=/)\n{\n #this is a swipe\n $dta{'track2'} = $r; \n $r =~ /^(\\d*)=/;\n $ccNum = $1;\n $dta{'cc'} = $ccNum;\n $r =~ /(=)(\\d{2})(\\d{2})/;\n $dta{'exp'} = "$3$2";\n}\nelse\n{\n #this is a manual entry\n if(!($r =~ /^\\d{13,16}$/))\n {\n   &main::infoPrint("Incorrect number of digits for a card number.\\n\\nRe-tender.");\n   return 0;\n }\n $ccNum = $r;\n ($r) = main::getResponses("show", "Enter the expiration date (MMYY)\\n\\nOr press \\"No\\" to cancel");\n &main::clearEntry;\n if(!($r =~ /^\\d{4}$/))\n {\n   &main::infoPrint("Incorrect number of digits for an expiration date or tender canceled.\\n\\nRe-tender.");\n   return 0;\n }\n $dta{'cc'} = $ccNum;\n $dta{'exp'} = $r;\n}\n\n$dta{'amount'} = $amt;\n$dta{'action'} = 'preauth';\n\n&main::infoPrint("Please wait, authorizing the transaction...");\nmy %result = Net::TCLink::send(%dta);\nif($result{'status'} ne 'approved')\n{\n   #tell the clerk what the problem is\n   my $decline;\n   $decline = 'Declined (Possibly NSF)' if $result{'declinetype'} eq 'decline';\n   $decline = 'Declined (Call for Auth is unsupported)' if $result{'declinetype'} eq 'call';\n   $decline = 'Card Number Error (Possibly a Typo)' if $result{'declinetype'} eq 'carderror';\n   $decline = 'Merchant Limit Reached' if $result{'declinetype'} =~ /limit$/;\n\n   &main::infoPrint("Authorization Failed.\\n\\nReason: $decline");\n    my($key, $value);\n    print STDERR "%result\\n";\n    while(($key, $value) = each %result)\n     {\n\tprint STDERR "\\t$key=$value\\n";\n     }\n   return 0;\n}\n$ccAuth = $result{'transid'};\n&main::infoPrint("");\n#print the card info on the customer's receipt\nif($ccNum =~ /^4/)\n{\n  $ccType = "Visa";\n}\nelsif($ccNum =~ /^5/)\n{\n  $ccType = "Master Card";\n}\nelsif($ccNum =~ /^34/ or $ccNum =~ /^37/)\n{\n  $ccType = "American Express"; \n}\nelsif($ccNum =~ /^30/ or $ccNum =~ /^36/ or  $ccNum =~ /^38/)\n{\n  $ccType = "Diners Club";\n}\nelsif($ccNum =~ /^6011/)\n{\n  $ccType = "Discover/Novus";\n}\nelsif($ccNum =~ /^35/)\n{\n  $ccType = "JCB Card";\n}\nelse\n{\n  $ccType = "Unknown";\n}\n$main::printer->printFormatted(sprintf("%-40.40s\\n%-40.40s\\n%-40.40s\\n", "Card Number: $ccNum","Type: $ccType", "Authorization: $ccAuth"));\n#it's authorized\n    my($key, $value);\n    print STDERR "%result\\n";\n    while(($key, $value) = each %result)\n     {\n\tprint STDERR "\\t$key=$value\\n";\n     }\nreturn 1;\n	\N	\N	2010-09-19 17:11:27.351123-05	installer@localhost	2010-09-19 17:11:27.351123-05	installer@localhost
register-initMachine-default	#-*-Perl-*-\n\n#fix the x key mappings on wm-less terminals\n#system($ENV{'LaneRoot'} . "/register/retailTk/common.X.sh &") if $main::thisIsAnXInterface;\n\n#printer init first, as many other devices are chained off of it\nuse IO::File;\nmy $io = new IO::File;\n$io->open(">/dev/lp0");\n$io->autoflush(1);\n\n#put serial port setup here\nuse LanePOS::Devices::Epson::TMT88;\n$printer = TMT88->new($io, $me->{"lc"});\nprint STDERR "register-initMachine-default: done with printer/device init" if $ENV{'LaneDebug'};\n\n*printer2 = *printer;\n*pole = *printer;\n*drawer = *printer;\n\n#endorse is a printer alias\n*endorse = *printer;\n1;	\N	\N	2010-09-19 17:11:27.351123-05	installer@localhost	2010-09-19 17:11:27.351123-05	installer@localhost
Lane/CORE/Configuration/Site	#this file was created by /home/lanedbadmin/working/LanePOS/backOffice/utilities/installer/../../../backOffice/utilities/installer/installer.pl at Fri Aug 20 13:25:48 2004\n\n$ENV{'LaneDSN'} = 'dbname=lanebmstest';\n$ENV{'LaneLang'} = 'en-US';\n#$ENV{'LaneDebug'} = 'moneyFmt()';\n$ENV{'PGCLIENTENCODING'} = 'LATIN1';\n	\N	\N	2010-09-19 17:11:27.351123-05	installer@localhost	2010-09-19 17:11:27.351123-05	installer@localhost
Lane/Sale/Void/Voidable Time Window	2 weeks	\N	\N	2010-09-19 17:11:27.351123-05	installer@localhost	2010-09-19 17:11:27.351123-05	installer@localhost
\.


--
-- Data for Name: sysstrings_rev; Type: TABLE DATA; Schema: public; Owner: lanedbadmin
--

COPY sysstrings_rev (id, data, voidat, voidby, created, createdby, modified, modifiedby, r) FROM stdin;
company-customer-id	us	\N	\N	2010-09-19 17:11:27.351123-05	installer@localhost	2010-09-19 17:11:27.351123-05	installer@localhost	1
register-printSecond-2	1	\N	\N	2010-09-19 17:11:27.351123-05	installer@localhost	2010-09-19 17:11:27.351123-05	installer@localhost	2
earlypay-disc-tender	7	\N	\N	2010-09-19 17:11:27.351123-05	installer@localhost	2010-09-19 17:11:27.351123-05	installer@localhost	3
earlypay-disc-id	10	\N	\N	2010-09-19 17:11:27.351123-05	installer@localhost	2010-09-19 17:11:27.351123-05	installer@localhost	4
register-eauth-3	$amt = $main::fsTotal if $amt > $main::fsTotal;\n   #remove the tax from the fstax\n   #!!!!HARD-CODED TAX 2\n   my $tx = Tax->new;\n   my $i = 1;\n   $tx->open($i);\n   $me->{'sale'}->{'due'} -= $me->{'sale'}->{'taxes'};\n   $me->{'sale'}->{'taxable'}[$i - 1] -= $amt;\n   $me->{'Taxes'}[$i - 1] = $tx->applyTax($me->{'sale'}->{'taxable'}[$i - 1]);\n   $me->{'sale'}->{'taxes'} = 0;\n   for(my $j = 0; $j <= $#{$me->{'Taxes'}}; $j++)\n   {\n\t$me->{'sale'}->{'taxes'} += $me->{'Taxes'}[$j];\n   }\n\n   $main::fsTotal -= $amt;\n   $me->{'sale'}->{'due'} += $me->{'sale'}->{'taxes'};\n   #$me->{'sale'}->updateTotals;\n   &main::writeSummaryArea();\n   return 1;\n\n	\N	\N	2010-09-19 17:11:27.351123-05	installer@localhost	2010-09-19 17:11:27.351123-05	installer@localhost	5
register-eauth-4	$amt = $main::wicTotal;\n$main::wicTotal = 0;\n#remove the tax from the wictax, but remove the amt from fstax so we don't over remove the tax\n   $main::fsTotal -= $amt;\n   my $tx = Tax->new;\n   my $i = 1;\n   $tx->open($i);\n   $me->{'sale'}->{'due'} -= $me->{'sale'}->{'taxes'};\n   $me->{'sale'}->{'taxable'}[$i - 1] -= $amt;\n   $me->{'Taxes'}[$i - 1] = $tx->applyTax($me->{'sale'}->{'taxable'}[$i - 1]);\n   $me->{'sale'}->{'taxes'} = 0;\n   for(my $j = 0; $j <= $#{$me->{'Taxes'}}; $j++)\n   {\n\t$me->{'sale'}->{'taxes'} += $me->{'Taxes'}[$j];\n   }\n   $me->{'sale'}->{'due'} += $me->{'sale'}->{'taxes'};\n   #$me->{'sale'}->updateTotals;\n   &main::writeSummaryArea();\n\nreturn 1;	\N	\N	2010-09-19 17:11:27.351123-05	installer@localhost	2010-09-19 17:11:27.351123-05	installer@localhost	6
Lane/CORE/Business Day Start Time	00:00	\N	\N	2010-09-19 17:11:27.351123-05	installer@localhost	2010-09-19 17:11:27.351123-05	installer@localhost	7
register-ecancel-5	#-*-Perl-*-\n#this code cancels the purchase\n\n&main::infoPrint("Please wait, canceling the credit card transaction...");\n\nmy %dta;\nmy $str = SysString->new;\nif(!$str->open('ccauth-tclink-custid'))\n{\n print STDERR "register-eauth-5 couldn't load the ccauth-tclink-custid from the database\\n";\n return 0;\n}\n$dta{'custid'} = $str->{'data'};\nif(!$str->open('ccauth-tclink-password'))\n{\n print STDERR "register-eauth-5 couldn't load the ccauth-tclink-password from the database\\n";\n return 0;\n}\n$dta{'password'} = $str->{'data'};\n$dta{'transid'} = $ccAuth;\n$dta{'action'} = 'credit';\n\nmy %result = Net::TCLink::send(%dta);\n\nif($result{'status'} ne 'accepted')\n{\n   #tell the clerk what the problem is\n   &main::infoPrint("Cancelation Failed.\\n\\n");\n    my($key, $value);\n    print STDERR "%result\\n";\n    while(($key, $value) = each %result)\n     {\n\tprint STDERR "\\t$key=$value\\n";\n     }\n   return 0;\n}\n\n&main::infoPrint("");\n#print an extra ticket for the person to sign\n    my($key, $value);\n    print STDERR "%result\\n";\n    while(($key, $value) = each %result)\n     {\n\tprint STDERR "\\t$key=$value\\n";\n     }\nreturn 1;\n	\N	\N	2010-09-19 17:11:27.351123-05	installer@localhost	2010-09-19 17:11:27.351123-05	installer@localhost	8
register-eprocess-6	#-*-Perl-*-\n#use the amount up\n$me->{'cust'}->chargeToAcct($me->{'lc'}->extFmt($amt));\n\n#this code prints a amount remaining ticket\n\nreturn 0 if(!$me->{'string'}->open('debit-remaining-ticket'));\n&main::receiptPrint("Remaining on Card " . $me->{'lc'}->moneyFmt($me->{'cust'}{'creditRmn'} * 100));\nmy $t = $me->{'string'}{'data'};\n$t =~ s/<balance>/$me->{'lc'}->moneyFmt($me->{'cust'}->{'creditRmn'} * 100)/eg;\n$t =~ s/<acctId>/$me->{'cust'}{'id'}/g;\n$t =~ s/<customer>/sprintf("%-40.40s\n%-40.40s\n%-40.40s\n%-40.40s\n", $me->{'cust'}->getName(), $me->{'cust'}{'billAddr1'}, $me->{'cust'}{'billAddr2'}, $me->{'cust'}{'billCity'} . ", " . $me->{'cust'}{'billSt'} . " " . $me->{'cust'}{'billZip'})/eg;\n$main::printer->printFormatted($t);\n$main::printer->finishReceipt();\nreturn 1;\n\n	\N	\N	2010-09-19 17:11:27.351123-05	installer@localhost	2010-09-19 17:11:27.351123-05	installer@localhost	9
Lane/CORE/Dataset/Version	2	\N	\N	2010-09-19 17:11:27.351123-05	installer@localhost	2010-09-19 17:11:27.351123-05	installer@localhost	10
register-eprocess-5	#-*-Perl-*-\n#this code finalizes the purchase w/tclink\n\n&main::infoPrint("Please wait, finalizing the credit card transaction...");\n\nmy %dta;\nmy $str = SysString->new;\nif(!$str->open('ccauth-tclink-custid'))\n{\n print STDERR "register-process-5 couldn't load the ccauth-tclink-custid from the database\\n";\n return 0;\n}\n$dta{'custid'} = $str->{'data'};\nif(!$str->open('ccauth-tclink-password'))\n{\n print STDERR "register-eauth-5 couldn't load the ccauth-tclink-password from the database\\n";\n return 0;\n}\n$dta{'password'} = $str->{'data'};\n$dta{'transid'} = $ccAuth;\n$dta{'action'} = 'postauth';\n\nmy %result = Net::TCLink::send(%dta);\n\nif($result{'status'} ne 'accepted')\n{\n   #tell the clerk what the problem is\n   &main::infoPrint("Finalization Failed.\\n\\nReason: %result");\n    my($key, $value);\n    print STDERR "%result\\n";\n    while(($key, $value) = each %result)\n     {\n\tprint STDERR "\\t$key=$value\\n";\n     }\n   return 0;\n}\n\n&main::infoPrint("");\n#print an extra ticket for the person to sign\n#$main::reg->reprintProcess($tend->{'id'}, sprintf("%-40.40s\\n%-40.40s\\n%-40.40s\\n", "Card Number: \n$main::reg->reprintProcess(5, sprintf("%-40.40s\\n%-40.40s\\n%-40.40s\\n", "Card Number: $ccNum","Type: $ccType", "Authorization: $ccAuth"));\n    my($key, $value);\n    print STDERR "%result\\n";\n    while(($key, $value) = each %result)\n     {\n\tprint STDERR "\\t$key=$value\\n";\n     }\nreturn 1;\n\n	\N	\N	2010-09-19 17:11:27.351123-05	installer@localhost	2010-09-19 17:11:27.351123-05	installer@localhost	11
register-eauth-6	#-*-Perl-*-\n#this code makes sure the customer has the\n#credit available to make the purchase\n\nif($me->{'cust'}{'id'} eq '')\n{\n\t&main::infoPrint('A customer must be open for Debit Card sales.');\n\treturn 0;\n}\nreturn 1 if $me->{'cust'}{'creditRmn'} * 100 >= $amt;\n&main::infoPrint('This customer only has ' . $me->{'lc'}->moneyFmt($me->{'cust'}{'creditRmn'} * 100) . " on his/her debit card.");\nreturn 0;	\N	\N	2010-09-19 17:11:27.351123-05	installer@localhost	2010-09-19 17:11:27.351123-05	installer@localhost	12
register-touch-functionpagesetup	page = Functions\nitem = Error\\nCorrect\nforeground = white\nbackground = red\ncommand = $reg->errCorrectProcess();\nitem = Tax\\nExempt\nforeground = black\nbackground = magenta\ncommand = $reg->exemptProcess();\nitem = Cancel\\nSale\nforeground = white\nbackground = red\ncommand = @main::remoteData = (); $reg->cancelProcess();\nitem = Cash\nforeground = black\nbackground = green\ncommand = $reg->tenderProcess(0, $amt);\nitem = Check\nforeground = black\nbackground = green\ncommand = $reg->tenderProcess(1, $amt);\nitem = House\\nAcct\nforeground = black\nbackground = green\ncommand = $reg->tenderProcess(2, $amt);\nitem = Recv\\nAcct\nforeground = white\nbackground = brown\ncommand = $reg->raProcess('', $amt);\nitem = Customer\nforeground = white\nbackground = blue\ncommand = $reg->custProcess('', $amt);\nitem = Subtotal\nforeground = black\nbackground = yellow\ncommand = $reg->subtProcess();\nitem = Credit\\nCard\nforeground = black\nbackground = green\ncommand = $reg->tenderProcess(5, $amt);\nitem = Debit\\nCard\nforeground = black\nbackground = green\ncommand = $reg->tenderProcess(6, $amt);\nitem = $5\nforeground = black\nbackground = green\ncommand = $reg->tenderProcess(0, 500);\nitem = Open %\\nDiscount\nforeground = white\nbackground = red\ncommand = $reg->discProcess(1, $amt);\nitem = 10%\\nQty\\nDiscount\nforeground = white\nbackground = red\ncommand = $reg->discProcess(2, $amt);\nitem = Suspend\\nTicket\nforeground = white\nbackground = brown\ncommand = $reg->suspendProcess();\nitem = Resume\\nTicket\nforeground = white\nbackground = brown\ncommand = $reg->resumeProcess('', $amt);\nitem = $10\nforeground = black\nbackground = green\ncommand = $reg->tenderProcess(0, 1000);\nitem = $20\nforeground = black\nbackground = green\ncommand = $reg->tenderProcess(0, 2000);\nitem = Clerk\\nLogout\nforeground = black\nbackground = magenta\ncommand = $reg->clerkSignin() if $#{$reg->{'sale'}{'items'}} == -1;\nitem = \ncommand = 1;\nitem = \ncommand = 1;\nitem = \ncommand = 1;\nitem = \ncommand = 1;\nitem = Foreign\\nCurrency\nforeground = black\nbackground = green\ncommand = $reg->tenderProcess(8, $amt);\nend\n	\N	\N	2010-09-19 17:11:27.351123-05	installer@localhost	2010-09-19 17:11:27.351123-05	installer@localhost	13
register-eauth-5	#-*-Perl-*-\n#this code makes sure the customer has the\n#credit available to make the purchase\n\n#this sample version uses the GPL client from\n#http://www.trustcommerce.com/\n#you need to install their TCLink perl client\n\n#this doesn't use avs\n\n#If other processors/gateways have open source or public domain clients,\n#I'm willing to write wrappers like this for them, as well.\n\nuse Net::TCLink; #this is the trustcommerce.com client\n\nmy %dta;\n\nmy $str = SysString->new;\nif(!$str->open('ccauth-tclink-custid'))\n{\n print STDERR "register-eauth-5 couldn't load the ccauth-tclink-custid from the database\\n";\n return 0;\n}\n$dta{'custid'} = $str->{'data'};\n\nif(!$str->open('ccauth-tclink-password'))\n{\n print STDERR "register-eauth-5 couldn't load the ccauth-tclink-custid from the database\\n";\n return 0;\n}\n$dta{'password'} = $str->{'data'};\n\n$ccNum = "";\n$ccType = "";\nmy $r;\n($r) = main::getResponses("show", "Swipe card or enter card number");\n&main::clearEntry;\nif($r =~ /=/)\n{\n #this is a swipe\n $dta{'track2'} = $r; \n $r =~ /^(\\d*)=/;\n $ccNum = $1;\n $dta{'cc'} = $ccNum;\n $r =~ /(=)(\\d{2})(\\d{2})/;\n $dta{'exp'} = "$3$2";\n}\nelse\n{\n #this is a manual entry\n if(!($r =~ /^\\d{13,16}$/))\n {\n   &main::infoPrint("Incorrect number of digits for a card number.\\n\\nRe-tender.");\n   return 0;\n }\n $ccNum = $r;\n ($r) = main::getResponses("show", "Enter the expiration date (MMYY)\\n\\nOr press \\"No\\" to cancel");\n &main::clearEntry;\n if(!($r =~ /^\\d{4}$/))\n {\n   &main::infoPrint("Incorrect number of digits for an expiration date or tender canceled.\\n\\nRe-tender.");\n   return 0;\n }\n $dta{'cc'} = $ccNum;\n $dta{'exp'} = $r;\n}\n\n$dta{'amount'} = $amt;\n$dta{'action'} = 'preauth';\n\n&main::infoPrint("Please wait, authorizing the transaction...");\nmy %result = Net::TCLink::send(%dta);\nif($result{'status'} ne 'approved')\n{\n   #tell the clerk what the problem is\n   my $decline;\n   $decline = 'Declined (Possibly NSF)' if $result{'declinetype'} eq 'decline';\n   $decline = 'Declined (Call for Auth is unsupported)' if $result{'declinetype'} eq 'call';\n   $decline = 'Card Number Error (Possibly a Typo)' if $result{'declinetype'} eq 'carderror';\n   $decline = 'Merchant Limit Reached' if $result{'declinetype'} =~ /limit$/;\n\n   &main::infoPrint("Authorization Failed.\\n\\nReason: $decline");\n    my($key, $value);\n    print STDERR "%result\\n";\n    while(($key, $value) = each %result)\n     {\n\tprint STDERR "\\t$key=$value\\n";\n     }\n   return 0;\n}\n$ccAuth = $result{'transid'};\n&main::infoPrint("");\n#print the card info on the customer's receipt\nif($ccNum =~ /^4/)\n{\n  $ccType = "Visa";\n}\nelsif($ccNum =~ /^5/)\n{\n  $ccType = "Master Card";\n}\nelsif($ccNum =~ /^34/ or $ccNum =~ /^37/)\n{\n  $ccType = "American Express"; \n}\nelsif($ccNum =~ /^30/ or $ccNum =~ /^36/ or  $ccNum =~ /^38/)\n{\n  $ccType = "Diners Club";\n}\nelsif($ccNum =~ /^6011/)\n{\n  $ccType = "Discover/Novus";\n}\nelsif($ccNum =~ /^35/)\n{\n  $ccType = "JCB Card";\n}\nelse\n{\n  $ccType = "Unknown";\n}\n$main::printer->printFormatted(sprintf("%-40.40s\\n%-40.40s\\n%-40.40s\\n", "Card Number: $ccNum","Type: $ccType", "Authorization: $ccAuth"));\n#it's authorized\n    my($key, $value);\n    print STDERR "%result\\n";\n    while(($key, $value) = each %result)\n     {\n\tprint STDERR "\\t$key=$value\\n";\n     }\nreturn 1;\n	\N	\N	2010-09-19 17:11:27.351123-05	installer@localhost	2010-09-19 17:11:27.351123-05	installer@localhost	14
register-initMachine-default	#-*-Perl-*-\n\n#fix the x key mappings on wm-less terminals\n#system($ENV{'LaneRoot'} . "/register/retailTk/common.X.sh &") if $main::thisIsAnXInterface;\n\n#printer init first, as many other devices are chained off of it\nuse IO::File;\nmy $io = new IO::File;\n$io->open(">/dev/lp0");\n$io->autoflush(1);\n\n#put serial port setup here\nuse LanePOS::Devices::Epson::TMT88;\n$printer = TMT88->new($io, $me->{"lc"});\nprint STDERR "register-initMachine-default: done with printer/device init" if $ENV{'LaneDebug'};\n\n*printer2 = *printer;\n*pole = *printer;\n*drawer = *printer;\n\n#endorse is a printer alias\n*endorse = *printer;\n1;	\N	\N	2010-09-19 17:11:27.351123-05	installer@localhost	2010-09-19 17:11:27.351123-05	installer@localhost	15
Lane/CORE/Configuration/Site	#this file was created by /home/lanedbadmin/working/LanePOS/backOffice/utilities/installer/../../../backOffice/utilities/installer/installer.pl at Fri Aug 20 13:25:48 2004\n\n$ENV{'LaneDSN'} = 'dbname=lanebmstest';\n$ENV{'LaneLang'} = 'en-US';\n#$ENV{'LaneDebug'} = 'moneyFmt()';\n$ENV{'PGCLIENTENCODING'} = 'LATIN1';\n	\N	\N	2010-09-19 17:11:27.351123-05	installer@localhost	2010-09-19 17:11:27.351123-05	installer@localhost	16
Lane/Sale/Void/Voidable Time Window	2 weeks	\N	\N	2010-09-19 17:11:27.351123-05	installer@localhost	2010-09-19 17:11:27.351123-05	installer@localhost	17
Lane/Sale/Void/Earliest Voidable Timestamp	1776-07-04 00:00	\N	\N	2010-09-19 17:12:15.683993-05	lanedbadmin@localhost	2010-09-19 17:12:15.683993-05	lanedbadmin@localhost	18
Lane/CORE/Dataset/Version	3	\N	\N	2010-09-19 17:11:27.351123-05	installer@localhost	2010-10-05 08:06:28.692221-05	lanedbadmin@localhost	19
\.


--
-- Data for Name: taxes; Type: TABLE DATA; Schema: public; Owner: lanedbadmin
--

COPY taxes (id, descr, amount, voidat, voidby, created, createdby, modified, modifiedby) FROM stdin;
2	Quebec Sales Tax	7.5000	\N	\N	2010-09-19 17:11:34.635924-05	installer@localhost	2010-09-19 17:11:34.635924-05	installer@localhost
1	IL Sales Tax	6.2500	\N	\N	2010-09-19 17:11:34.635924-05	installer@localhost	2010-09-19 17:11:34.635924-05	installer@localhost
\.


--
-- Data for Name: taxes_rev; Type: TABLE DATA; Schema: public; Owner: lanedbadmin
--

COPY taxes_rev (id, descr, amount, voidat, voidby, created, createdby, modified, modifiedby, r) FROM stdin;
2	Quebec Sales Tax	7.5000	\N	\N	2010-09-19 17:11:34.635924-05	installer@localhost	2010-09-19 17:11:34.635924-05	installer@localhost	1
1	IL Sales Tax	6.2500	\N	\N	2010-09-19 17:11:34.635924-05	installer@localhost	2010-09-19 17:11:34.635924-05	installer@localhost	2
\.


--
-- Data for Name: tenders; Type: TABLE DATA; Schema: public; Owner: lanedbadmin
--

COPY tenders (id, descr, allowchange, mandatoryamt, opendrawer, pays, eprocess, eauth, allowzero, allowneg, allowpos, requireitems, voidat, voidby, created, createdby, modified, modifiedby) FROM stdin;
0	Cash	t	f	t	t	f	f	t	t	t	a	\N	\N	2010-09-19 17:11:36.972609-05	installer@localhost	2010-09-19 17:11:36.972609-05	installer@localhost
2	House Acct	f	f	f	f	f	f	t	t	t	a	\N	\N	2010-09-19 17:11:36.972609-05	installer@localhost	2010-09-19 17:11:36.972609-05	installer@localhost
1	Check	f	f	f	t	f	f	t	t	t	a	\N	\N	2010-09-19 17:11:36.972609-05	installer@localhost	2010-09-19 17:11:36.972609-05	installer@localhost
7	Disc Loss	f	t	f	t	f	f	t	t	t	a	\N	\N	2010-09-19 17:11:36.972609-05	installer@localhost	2010-09-19 17:11:36.972609-05	installer@localhost
5	Crdt Card	f	f	f	t	t	t	t	t	t	a	\N	\N	2010-09-19 17:11:36.972609-05	installer@localhost	2010-09-19 17:11:36.972609-05	installer@localhost
3	Food Stamp	f	f	f	t	f	t	t	t	t	a	\N	\N	2010-09-19 17:11:36.972609-05	installer@localhost	2010-09-19 17:11:36.972609-05	installer@localhost
4	WIC	f	f	f	t	f	t	t	t	t	a	\N	\N	2010-09-19 17:11:36.972609-05	installer@localhost	2010-09-19 17:11:36.972609-05	installer@localhost
6	Debit Card	f	f	f	t	t	t	t	t	t	a	\N	\N	2010-09-19 17:11:36.972609-05	installer@localhost	2010-09-19 17:11:36.972609-05	installer@localhost
8	Foreign	t	t	t	t	f	t	t	t	t	a	\N	\N	2010-09-19 17:11:36.972609-05	installer@localhost	2010-09-19 17:11:36.972609-05	installer@localhost
\.


--
-- Data for Name: tenders_rev; Type: TABLE DATA; Schema: public; Owner: lanedbadmin
--

COPY tenders_rev (id, descr, allowchange, mandatoryamt, opendrawer, pays, eprocess, eauth, allowzero, allowneg, allowpos, requireitems, voidat, voidby, created, createdby, modified, modifiedby, r) FROM stdin;
0	Cash	t	f	t	t	f	f	t	t	t	a	\N	\N	2010-09-19 17:11:36.972609-05	installer@localhost	2010-09-19 17:11:36.972609-05	installer@localhost	1
2	House Acct	f	f	f	f	f	f	t	t	t	a	\N	\N	2010-09-19 17:11:36.972609-05	installer@localhost	2010-09-19 17:11:36.972609-05	installer@localhost	2
1	Check	f	f	f	t	f	f	t	t	t	a	\N	\N	2010-09-19 17:11:36.972609-05	installer@localhost	2010-09-19 17:11:36.972609-05	installer@localhost	3
7	Disc Loss	f	t	f	t	f	f	t	t	t	a	\N	\N	2010-09-19 17:11:36.972609-05	installer@localhost	2010-09-19 17:11:36.972609-05	installer@localhost	4
5	Crdt Card	f	f	f	t	t	t	t	t	t	a	\N	\N	2010-09-19 17:11:36.972609-05	installer@localhost	2010-09-19 17:11:36.972609-05	installer@localhost	5
3	Food Stamp	f	f	f	t	f	t	t	t	t	a	\N	\N	2010-09-19 17:11:36.972609-05	installer@localhost	2010-09-19 17:11:36.972609-05	installer@localhost	6
4	WIC	f	f	f	t	f	t	t	t	t	a	\N	\N	2010-09-19 17:11:36.972609-05	installer@localhost	2010-09-19 17:11:36.972609-05	installer@localhost	7
6	Debit Card	f	f	f	t	t	t	t	t	t	a	\N	\N	2010-09-19 17:11:36.972609-05	installer@localhost	2010-09-19 17:11:36.972609-05	installer@localhost	8
8	Foreign	t	t	t	t	f	t	t	t	t	a	\N	\N	2010-09-19 17:11:36.972609-05	installer@localhost	2010-09-19 17:11:36.972609-05	installer@localhost	9
\.


--
-- Data for Name: terms; Type: TABLE DATA; Schema: public; Owner: lanedbadmin
--

COPY terms (id, descr, duedays, finrate, discdays, discrate, createdby, created, voidat, voidby, modified, modifiedby) FROM stdin;
cod	Cash on Delivery	0	1.5000	0	0.0000	installer@localhost	1999-05-26 00:00:00-05	\N	\N	2010-09-19 17:09:12.865923-05	installer@localhost
21030	2% 10 / Net 30 Days	30	1.5000	10	2.0000	installer@localhost	1999-05-26 00:00:00-05	\N	\N	2010-09-19 17:09:12.865923-05	installer@localhost
n30	Net 30 days	30	1.5000	0	0.0000	installer@localhost	1999-05-27 00:00:00-05	\N	\N	2010-09-19 17:09:12.865923-05	installer@localhost
n45	Net 45 Days	45	1.5000	0	0.0000	installer@localhost	1999-05-27 00:00:00-05	\N	\N	2010-09-19 17:09:12.865923-05	installer@localhost
n7	Net 7 Days	7	1.5000	0	0.0000	installer@localhost	1999-05-27 00:00:00-05	\N	\N	2010-09-19 17:09:12.865923-05	installer@localhost
n1	Net 1 Day	1	1.5000	0	0.0000	installer@localhost	2001-07-12 09:44:08-05	\N	\N	2010-09-19 17:09:12.865923-05	installer@localhost
\.


--
-- Data for Name: terms_rev; Type: TABLE DATA; Schema: public; Owner: lanedbadmin
--

COPY terms_rev (id, descr, duedays, finrate, discdays, discrate, createdby, created, voidat, voidby, modified, modifiedby, r) FROM stdin;
cod	Cash on Delivery	0	1.5000	0	0.0000	installer@localhost	1999-05-26 00:00:00-05	\N	\N	2010-09-19 17:09:12.865923-05	installer@localhost	1
21030	2% 10 / Net 30 Days	30	1.5000	10	2.0000	installer@localhost	1999-05-26 00:00:00-05	\N	\N	2010-09-19 17:09:12.865923-05	installer@localhost	2
n30	Net 30 days	30	1.5000	0	0.0000	installer@localhost	1999-05-27 00:00:00-05	\N	\N	2010-09-19 17:09:12.865923-05	installer@localhost	3
n45	Net 45 Days	45	1.5000	0	0.0000	installer@localhost	1999-05-27 00:00:00-05	\N	\N	2010-09-19 17:09:12.865923-05	installer@localhost	4
n7	Net 7 Days	7	1.5000	0	0.0000	installer@localhost	1999-05-27 00:00:00-05	\N	\N	2010-09-19 17:09:12.865923-05	installer@localhost	5
n1	Net 1 Day	1	1.5000	0	0.0000	installer@localhost	2001-07-12 09:44:08-05	\N	\N	2010-09-19 17:09:12.865923-05	installer@localhost	6
\.


--
-- Data for Name: testgl; Type: TABLE DATA; Schema: public; Owner: lanedbadmin
--

COPY testgl (id, parent) FROM stdin;
\.


--
-- Data for Name: timeclock; Type: TABLE DATA; Schema: public; Owner: lanedbadmin
--

COPY timeclock (clerk, punch, forced, created, createdby, modified, modifiedby, voidat, voidby) FROM stdin;
\.


--
-- Data for Name: timeclock_rev; Type: TABLE DATA; Schema: public; Owner: lanedbadmin
--

COPY timeclock_rev (clerk, punch, forced, created, createdby, modified, modifiedby, voidat, voidby, r) FROM stdin;
\.


--
-- Data for Name: vendors; Type: TABLE DATA; Schema: public; Owner: lanedbadmin
--

COPY vendors (id, coname, cntfirst, cntlast, billaddr1, billaddr2, billcity, billst, billzip, billcountry, billphone, billfax, shipaddr1, shipaddr2, shipcity, shipst, shipzip, shipcountry, shipphone, shipfax, email, creditlmt, balance, creditrmn, lastsale, lastpay, terms, notes, createdby, created, taxes, voidat, voidby, modified, modifiedby) FROM stdin;
\.


--
-- Data for Name: vendors_rev; Type: TABLE DATA; Schema: public; Owner: lanedbadmin
--

COPY vendors_rev (id, coname, cntfirst, cntlast, billaddr1, billaddr2, billcity, billst, billzip, billcountry, billphone, billfax, shipaddr1, shipaddr2, shipcity, shipst, shipzip, shipcountry, shipphone, shipfax, email, creditlmt, balance, creditrmn, lastsale, lastpay, terms, notes, createdby, created, taxes, voidat, voidby, modified, modifiedby, r) FROM stdin;
\.


--
-- Name: clerks_pkey; Type: CONSTRAINT; Schema: public; Owner: lanedbadmin; Tablespace: 
--

ALTER TABLE ONLY clerks
    ADD CONSTRAINT clerks_pkey PRIMARY KEY (id);


--
-- Name: clerks_rev_pkey; Type: CONSTRAINT; Schema: public; Owner: lanedbadmin; Tablespace: 
--

ALTER TABLE ONLY clerks_rev
    ADD CONSTRAINT clerks_rev_pkey PRIMARY KEY (id, r);


--
-- Name: customers_pkey; Type: CONSTRAINT; Schema: public; Owner: lanedbadmin; Tablespace: 
--

ALTER TABLE ONLY customers
    ADD CONSTRAINT customers_pkey PRIMARY KEY (id);


--
-- Name: customers_rev_pkey; Type: CONSTRAINT; Schema: public; Owner: lanedbadmin; Tablespace: 
--

ALTER TABLE ONLY customers_rev
    ADD CONSTRAINT customers_rev_pkey PRIMARY KEY (id, r);


--
-- Name: discounts_pkey; Type: CONSTRAINT; Schema: public; Owner: lanedbadmin; Tablespace: 
--

ALTER TABLE ONLY discounts
    ADD CONSTRAINT discounts_pkey PRIMARY KEY (id);


--
-- Name: discounts_rev_pkey; Type: CONSTRAINT; Schema: public; Owner: lanedbadmin; Tablespace: 
--

ALTER TABLE ONLY discounts_rev
    ADD CONSTRAINT discounts_rev_pkey PRIMARY KEY (id, r);


--
-- Name: locale_pkey; Type: CONSTRAINT; Schema: public; Owner: lanedbadmin; Tablespace: 
--

ALTER TABLE ONLY locale
    ADD CONSTRAINT locale_pkey PRIMARY KEY (lang, id);


--
-- Name: machines_pkey; Type: CONSTRAINT; Schema: public; Owner: lanedbadmin; Tablespace: 
--

ALTER TABLE ONLY machines
    ADD CONSTRAINT machines_pkey PRIMARY KEY (make, model, sn);


--
-- Name: machines_rev_pkey; Type: CONSTRAINT; Schema: public; Owner: lanedbadmin; Tablespace: 
--

ALTER TABLE ONLY machines_rev
    ADD CONSTRAINT machines_rev_pkey PRIMARY KEY (make, model, sn, r);


--
-- Name: po2vendor_pkey; Type: CONSTRAINT; Schema: public; Owner: lanedbadmin; Tablespace: 
--

ALTER TABLE ONLY po2vendor
    ADD CONSTRAINT po2vendor_pkey PRIMARY KEY (vendor);


--
-- Name: po_pkey; Type: CONSTRAINT; Schema: public; Owner: lanedbadmin; Tablespace: 
--

ALTER TABLE ONLY po
    ADD CONSTRAINT po_pkey PRIMARY KEY (id);


--
-- Name: poitems_pkey; Type: CONSTRAINT; Schema: public; Owner: lanedbadmin; Tablespace: 
--

ALTER TABLE ONLY poitems
    ADD CONSTRAINT poitems_pkey PRIMARY KEY (id, lineno);


--
-- Name: pricetables_pkey; Type: CONSTRAINT; Schema: public; Owner: lanedbadmin; Tablespace: 
--

ALTER TABLE ONLY pricetables
    ADD CONSTRAINT pricetables_pkey PRIMARY KEY (id);


--
-- Name: pricetables_rev_pkey; Type: CONSTRAINT; Schema: public; Owner: lanedbadmin; Tablespace: 
--

ALTER TABLE ONLY pricetables_rev
    ADD CONSTRAINT pricetables_rev_pkey PRIMARY KEY (id, r);


--
-- Name: products_pkey; Type: CONSTRAINT; Schema: public; Owner: lanedbadmin; Tablespace: 
--

ALTER TABLE ONLY products
    ADD CONSTRAINT products_pkey PRIMARY KEY (id);


--
-- Name: products_rev_pkey; Type: CONSTRAINT; Schema: public; Owner: lanedbadmin; Tablespace: 
--

ALTER TABLE ONLY products_rev
    ADD CONSTRAINT products_rev_pkey PRIMARY KEY (id, r);


--
-- Name: purchaseorders_pkey; Type: CONSTRAINT; Schema: public; Owner: lanedbadmin; Tablespace: 
--

ALTER TABLE ONLY purchaseorders
    ADD CONSTRAINT purchaseorders_pkey PRIMARY KEY (id);


--
-- Name: purchaseorders_rev_pkey; Type: CONSTRAINT; Schema: public; Owner: lanedbadmin; Tablespace: 
--

ALTER TABLE ONLY purchaseorders_rev
    ADD CONSTRAINT purchaseorders_rev_pkey PRIMARY KEY (id, r);


--
-- Name: purchaseordersordereditems_pkey; Type: CONSTRAINT; Schema: public; Owner: lanedbadmin; Tablespace: 
--

ALTER TABLE ONLY purchaseordersordereditems
    ADD CONSTRAINT purchaseordersordereditems_pkey PRIMARY KEY (id, lineno);


--
-- Name: purchaseordersordereditems_rev_pkey; Type: CONSTRAINT; Schema: public; Owner: lanedbadmin; Tablespace: 
--

ALTER TABLE ONLY purchaseordersordereditems_rev
    ADD CONSTRAINT purchaseordersordereditems_rev_pkey PRIMARY KEY (id, lineno, r);


--
-- Name: purchaseordersreceiveditems_pkey; Type: CONSTRAINT; Schema: public; Owner: lanedbadmin; Tablespace: 
--

ALTER TABLE ONLY purchaseordersreceiveditems
    ADD CONSTRAINT purchaseordersreceiveditems_pkey PRIMARY KEY (id, lineno);


--
-- Name: purchaseordersreceiveditems_rev_pkey; Type: CONSTRAINT; Schema: public; Owner: lanedbadmin; Tablespace: 
--

ALTER TABLE ONLY purchaseordersreceiveditems_rev
    ADD CONSTRAINT purchaseordersreceiveditems_rev_pkey PRIMARY KEY (id, lineno, r);


--
-- Name: qwo_pkey; Type: CONSTRAINT; Schema: public; Owner: lanedbadmin; Tablespace: 
--

ALTER TABLE ONLY qwo
    ADD CONSTRAINT qwo_pkey PRIMARY KEY (id);


--
-- Name: qwo_rev_pkey; Type: CONSTRAINT; Schema: public; Owner: lanedbadmin; Tablespace: 
--

ALTER TABLE ONLY qwo_rev
    ADD CONSTRAINT qwo_rev_pkey PRIMARY KEY (id, r);


--
-- Name: qwostatus_pkey; Type: CONSTRAINT; Schema: public; Owner: lanedbadmin; Tablespace: 
--

ALTER TABLE ONLY qwostatuses
    ADD CONSTRAINT qwostatus_pkey PRIMARY KEY (id, status);


--
-- Name: qwostatuses_rev_pkey; Type: CONSTRAINT; Schema: public; Owner: lanedbadmin; Tablespace: 
--

ALTER TABLE ONLY qwostatuses_rev
    ADD CONSTRAINT qwostatuses_rev_pkey PRIMARY KEY (id, status, r);


--
-- Name: sales_pkey; Type: CONSTRAINT; Schema: public; Owner: lanedbadmin; Tablespace: 
--

ALTER TABLE ONLY sales
    ADD CONSTRAINT sales_pkey PRIMARY KEY (id);


--
-- Name: sales_rev_pkey; Type: CONSTRAINT; Schema: public; Owner: lanedbadmin; Tablespace: 
--

ALTER TABLE ONLY sales_rev
    ADD CONSTRAINT sales_rev_pkey PRIMARY KEY (id, r);


--
-- Name: salesitems_pkey; Type: CONSTRAINT; Schema: public; Owner: lanedbadmin; Tablespace: 
--

ALTER TABLE ONLY salesitems
    ADD CONSTRAINT salesitems_pkey PRIMARY KEY (id, lineno);


--
-- Name: salesitems_rev_pkey; Type: CONSTRAINT; Schema: public; Owner: lanedbadmin; Tablespace: 
--

ALTER TABLE ONLY salesitems_rev
    ADD CONSTRAINT salesitems_rev_pkey PRIMARY KEY (id, lineno, r);


--
-- Name: salespayments_pkey; Type: CONSTRAINT; Schema: public; Owner: lanedbadmin; Tablespace: 
--

ALTER TABLE ONLY salespayments
    ADD CONSTRAINT salespayments_pkey PRIMARY KEY (id, lineno);


--
-- Name: salespayments_rev_pkey; Type: CONSTRAINT; Schema: public; Owner: lanedbadmin; Tablespace: 
--

ALTER TABLE ONLY salespayments_rev
    ADD CONSTRAINT salespayments_rev_pkey PRIMARY KEY (id, lineno, r);


--
-- Name: salestaxes_pkey; Type: CONSTRAINT; Schema: public; Owner: lanedbadmin; Tablespace: 
--

ALTER TABLE ONLY salestaxes
    ADD CONSTRAINT salestaxes_pkey PRIMARY KEY (id, taxid);


--
-- Name: salestaxes_rev_pkey; Type: CONSTRAINT; Schema: public; Owner: lanedbadmin; Tablespace: 
--

ALTER TABLE ONLY salestaxes_rev
    ADD CONSTRAINT salestaxes_rev_pkey PRIMARY KEY (id, taxid, r);


--
-- Name: salestenders_pkey; Type: CONSTRAINT; Schema: public; Owner: lanedbadmin; Tablespace: 
--

ALTER TABLE ONLY salestenders
    ADD CONSTRAINT salestenders_pkey PRIMARY KEY (id, lineno);


--
-- Name: salestenders_rev_pkey; Type: CONSTRAINT; Schema: public; Owner: lanedbadmin; Tablespace: 
--

ALTER TABLE ONLY salestenders_rev
    ADD CONSTRAINT salestenders_rev_pkey PRIMARY KEY (id, lineno, r);


--
-- Name: strings_pkey; Type: CONSTRAINT; Schema: public; Owner: lanedbadmin; Tablespace: 
--

ALTER TABLE ONLY strings
    ADD CONSTRAINT strings_pkey PRIMARY KEY (id);


--
-- Name: strings_rev_pkey; Type: CONSTRAINT; Schema: public; Owner: lanedbadmin; Tablespace: 
--

ALTER TABLE ONLY strings_rev
    ADD CONSTRAINT strings_rev_pkey PRIMARY KEY (id, r);


--
-- Name: sysstrings_pkey; Type: CONSTRAINT; Schema: public; Owner: lanedbadmin; Tablespace: 
--

ALTER TABLE ONLY sysstrings
    ADD CONSTRAINT sysstrings_pkey PRIMARY KEY (id);


--
-- Name: sysstrings_rev_pkey; Type: CONSTRAINT; Schema: public; Owner: lanedbadmin; Tablespace: 
--

ALTER TABLE ONLY sysstrings_rev
    ADD CONSTRAINT sysstrings_rev_pkey PRIMARY KEY (id, r);


--
-- Name: taxes_pkey; Type: CONSTRAINT; Schema: public; Owner: lanedbadmin; Tablespace: 
--

ALTER TABLE ONLY taxes
    ADD CONSTRAINT taxes_pkey PRIMARY KEY (id);


--
-- Name: taxes_rev_pkey; Type: CONSTRAINT; Schema: public; Owner: lanedbadmin; Tablespace: 
--

ALTER TABLE ONLY taxes_rev
    ADD CONSTRAINT taxes_rev_pkey PRIMARY KEY (id, r);


--
-- Name: tenders_pkey; Type: CONSTRAINT; Schema: public; Owner: lanedbadmin; Tablespace: 
--

ALTER TABLE ONLY tenders
    ADD CONSTRAINT tenders_pkey PRIMARY KEY (id);


--
-- Name: tenders_rev_pkey; Type: CONSTRAINT; Schema: public; Owner: lanedbadmin; Tablespace: 
--

ALTER TABLE ONLY tenders_rev
    ADD CONSTRAINT tenders_rev_pkey PRIMARY KEY (id, r);


--
-- Name: terms_pkey; Type: CONSTRAINT; Schema: public; Owner: lanedbadmin; Tablespace: 
--

ALTER TABLE ONLY terms
    ADD CONSTRAINT terms_pkey PRIMARY KEY (id);


--
-- Name: terms_rev_pkey; Type: CONSTRAINT; Schema: public; Owner: lanedbadmin; Tablespace: 
--

ALTER TABLE ONLY terms_rev
    ADD CONSTRAINT terms_rev_pkey PRIMARY KEY (id, r);


--
-- Name: testgl_pkey; Type: CONSTRAINT; Schema: public; Owner: lanedbadmin; Tablespace: 
--

ALTER TABLE ONLY testgl
    ADD CONSTRAINT testgl_pkey PRIMARY KEY (id);


--
-- Name: timeclock_pkey; Type: CONSTRAINT; Schema: public; Owner: lanedbadmin; Tablespace: 
--

ALTER TABLE ONLY timeclock
    ADD CONSTRAINT timeclock_pkey PRIMARY KEY (clerk, punch);


--
-- Name: timeclock_rev_pkey; Type: CONSTRAINT; Schema: public; Owner: lanedbadmin; Tablespace: 
--

ALTER TABLE ONLY timeclock_rev
    ADD CONSTRAINT timeclock_rev_pkey PRIMARY KEY (clerk, punch, r);


--
-- Name: vendors_pkey; Type: CONSTRAINT; Schema: public; Owner: lanedbadmin; Tablespace: 
--

ALTER TABLE ONLY vendors
    ADD CONSTRAINT vendors_pkey PRIMARY KEY (id);


--
-- Name: vendors_rev_pkey; Type: CONSTRAINT; Schema: public; Owner: lanedbadmin; Tablespace: 
--

ALTER TABLE ONLY vendors_rev
    ADD CONSTRAINT vendors_rev_pkey PRIMARY KEY (id, r);


--
-- Name: customerscnt_ndx; Type: INDEX; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE INDEX customerscnt_ndx ON customers USING btree (cntlast, cntfirst);


--
-- Name: customersconame_ndx; Type: INDEX; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE INDEX customersconame_ndx ON customers USING btree (coname);


--
-- Name: customerslastpay; Type: INDEX; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE INDEX customerslastpay ON customers USING btree (lastpay);


--
-- Name: customerslastsale; Type: INDEX; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE INDEX customerslastsale ON customers USING btree (lastsale);


--
-- Name: machinescontract_ndx; Type: INDEX; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE INDEX machinescontract_ndx ON machines USING btree (oncontract, contractends);


--
-- Name: machinesowner_ndx; Type: INDEX; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE INDEX machinesowner_ndx ON machines USING btree (owner);


--
-- Name: purchaseorders_completelyreceived; Type: INDEX; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE INDEX purchaseorders_completelyreceived ON purchaseorders USING btree (completelyreceived);


--
-- Name: purchaseorders_orderat; Type: INDEX; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE INDEX purchaseorders_orderat ON purchaseorders USING btree (orderedat);


--
-- Name: purchaseorders_rev_completelyreceived; Type: INDEX; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE INDEX purchaseorders_rev_completelyreceived ON purchaseorders_rev USING btree (completelyreceived);


--
-- Name: purchaseorders_rev_orderat; Type: INDEX; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE INDEX purchaseorders_rev_orderat ON purchaseorders_rev USING btree (orderedat);


--
-- Name: purchaseorders_rev_vendor; Type: INDEX; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE INDEX purchaseorders_rev_vendor ON purchaseorders_rev USING btree (vendor);


--
-- Name: purchaseorders_vendor; Type: INDEX; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE INDEX purchaseorders_vendor ON purchaseorders USING btree (vendor);


--
-- Name: purchaseordersordereditems_plu; Type: INDEX; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE INDEX purchaseordersordereditems_plu ON purchaseordersordereditems USING btree (plu);


--
-- Name: purchaseordersordereditems_rev_plu; Type: INDEX; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE INDEX purchaseordersordereditems_rev_plu ON purchaseordersordereditems_rev USING btree (plu);


--
-- Name: purchaseordersreceiveditems_plu; Type: INDEX; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE INDEX purchaseordersreceiveditems_plu ON purchaseordersreceiveditems USING btree (plu);


--
-- Name: purchaseordersreceiveditems_rev_plu; Type: INDEX; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE INDEX purchaseordersreceiveditems_rev_plu ON purchaseordersreceiveditems_rev USING btree (plu);


--
-- Name: qwo_customer_ndx; Type: INDEX; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE INDEX qwo_customer_ndx ON qwo USING btree (customer);


--
-- Name: qwo_dateissued_ndx; Type: INDEX; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE INDEX qwo_dateissued_ndx ON qwo USING btree (dateissued);


--
-- Name: qwo_make_model_sn_ndx; Type: INDEX; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE INDEX qwo_make_model_sn_ndx ON qwo USING btree (make, model, sn);


--
-- Name: qwo_status_ndx; Type: INDEX; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE INDEX qwo_status_ndx ON qwo USING btree (status);


--
-- Name: qwo_type_ndx; Type: INDEX; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE INDEX qwo_type_ndx ON qwo USING btree (type);


--
-- Name: sales_bal_ndx; Type: INDEX; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE INDEX sales_bal_ndx ON sales USING btree (balance);


--
-- Name: sales_cust_ndx; Type: INDEX; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE INDEX sales_cust_ndx ON sales USING btree (customer);


--
-- Name: sales_server_ndx; Type: INDEX; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE INDEX sales_server_ndx ON sales USING btree (server);


--
-- Name: sales_tranzdate_index; Type: INDEX; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE INDEX sales_tranzdate_index ON sales USING btree (tranzdate);


--
-- Name: termsdescr_ndx; Type: INDEX; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE INDEX termsdescr_ndx ON terms USING btree (descr);


--
-- Name: timeclock_clerk; Type: INDEX; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE INDEX timeclock_clerk ON timeclock USING btree (clerk);


--
-- Name: timeclock_getbusinessdayfor; Type: INDEX; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE INDEX timeclock_getbusinessdayfor ON timeclock USING btree (getbusinessdayfor(punch));


--
-- Name: timeclock_rev_clerk; Type: INDEX; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE INDEX timeclock_rev_clerk ON timeclock_rev USING btree (clerk);


--
-- Name: timeclock_rev_getbusinessdayfor; Type: INDEX; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE INDEX timeclock_rev_getbusinessdayfor ON timeclock_rev USING btree (getbusinessdayfor(punch));


--
-- Name: vendorscnt_ndx; Type: INDEX; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE INDEX vendorscnt_ndx ON vendors USING btree (cntlast, cntfirst);


--
-- Name: vendorsconame_ndx; Type: INDEX; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE INDEX vendorsconame_ndx ON vendors USING btree (coname);


--
-- Name: vendorslastpay; Type: INDEX; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE INDEX vendorslastpay ON vendors USING btree (lastpay);


--
-- Name: vendorslastsale; Type: INDEX; Schema: public; Owner: lanedbadmin; Tablespace: 
--

CREATE INDEX vendorslastsale ON vendors USING btree (lastsale);


--
-- Name: disallowchangesclerks_rev; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER disallowchangesclerks_rev
    BEFORE DELETE OR UPDATE ON clerks_rev
    FOR EACH STATEMENT
    EXECUTE PROCEDURE disallowchanges();


--
-- Name: disallowchangescustomers_rev; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER disallowchangescustomers_rev
    BEFORE DELETE OR UPDATE ON customers_rev
    FOR EACH STATEMENT
    EXECUTE PROCEDURE disallowchanges();


--
-- Name: disallowchangesdiscounts_rev; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER disallowchangesdiscounts_rev
    BEFORE DELETE OR UPDATE ON discounts_rev
    FOR EACH STATEMENT
    EXECUTE PROCEDURE disallowchanges();


--
-- Name: disallowchangesifparentisvoidsalesitems; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER disallowchangesifparentisvoidsalesitems
    BEFORE INSERT OR UPDATE ON salesitems
    FOR EACH ROW
    EXECUTE PROCEDURE disallowchangesifparentisvoid('sales');


--
-- Name: disallowchangesifparentisvoidsalestaxes; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER disallowchangesifparentisvoidsalestaxes
    BEFORE INSERT OR UPDATE ON salestaxes
    FOR EACH ROW
    EXECUTE PROCEDURE disallowchangesifparentisvoid('sales');


--
-- Name: disallowchangesifparentisvoidsalestenders; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER disallowchangesifparentisvoidsalestenders
    BEFORE INSERT OR UPDATE ON salestenders
    FOR EACH ROW
    EXECUTE PROCEDURE disallowchangesifparentisvoid('sales');


--
-- Name: disallowchangesmachines_rev; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER disallowchangesmachines_rev
    BEFORE DELETE OR UPDATE ON machines_rev
    FOR EACH STATEMENT
    EXECUTE PROCEDURE disallowchanges();


--
-- Name: disallowchangespricetables_rev; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER disallowchangespricetables_rev
    BEFORE DELETE OR UPDATE ON pricetables_rev
    FOR EACH STATEMENT
    EXECUTE PROCEDURE disallowchanges();


--
-- Name: disallowchangesproducts_rev; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER disallowchangesproducts_rev
    BEFORE DELETE OR UPDATE ON products_rev
    FOR EACH STATEMENT
    EXECUTE PROCEDURE disallowchanges();


--
-- Name: disallowchangespurchaseorders_rev; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER disallowchangespurchaseorders_rev
    BEFORE DELETE OR UPDATE ON purchaseorders_rev
    FOR EACH STATEMENT
    EXECUTE PROCEDURE disallowchanges();


--
-- Name: disallowchangespurchaseordersordereditems_rev; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER disallowchangespurchaseordersordereditems_rev
    BEFORE DELETE OR UPDATE ON purchaseordersordereditems_rev
    FOR EACH STATEMENT
    EXECUTE PROCEDURE disallowchanges();


--
-- Name: disallowchangespurchaseordersreceiveditems_rev; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER disallowchangespurchaseordersreceiveditems_rev
    BEFORE DELETE OR UPDATE ON purchaseordersreceiveditems_rev
    FOR EACH STATEMENT
    EXECUTE PROCEDURE disallowchanges();


--
-- Name: disallowchangesqwo_rev; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER disallowchangesqwo_rev
    BEFORE DELETE OR UPDATE ON qwo_rev
    FOR EACH STATEMENT
    EXECUTE PROCEDURE disallowchanges();


--
-- Name: disallowchangesqwostatuses_rev; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER disallowchangesqwostatuses_rev
    BEFORE DELETE OR UPDATE ON qwostatuses_rev
    FOR EACH STATEMENT
    EXECUTE PROCEDURE disallowchanges();


--
-- Name: disallowchangessales_rev; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER disallowchangessales_rev
    BEFORE DELETE OR UPDATE ON sales_rev
    FOR EACH STATEMENT
    EXECUTE PROCEDURE disallowchanges();


--
-- Name: disallowchangessalesitems_rev; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER disallowchangessalesitems_rev
    BEFORE DELETE OR UPDATE ON salesitems_rev
    FOR EACH STATEMENT
    EXECUTE PROCEDURE disallowchanges();


--
-- Name: disallowchangessalestaxes_rev; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER disallowchangessalestaxes_rev
    BEFORE DELETE OR UPDATE ON salestaxes_rev
    FOR EACH STATEMENT
    EXECUTE PROCEDURE disallowchanges();


--
-- Name: disallowchangessalestenders_rev; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER disallowchangessalestenders_rev
    BEFORE DELETE OR UPDATE ON salestenders_rev
    FOR EACH STATEMENT
    EXECUTE PROCEDURE disallowchanges();


--
-- Name: disallowchangesstrings_rev; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER disallowchangesstrings_rev
    BEFORE DELETE OR UPDATE ON strings_rev
    FOR EACH STATEMENT
    EXECUTE PROCEDURE disallowchanges();


--
-- Name: disallowchangessysstrings_rev; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER disallowchangessysstrings_rev
    BEFORE DELETE OR UPDATE ON sysstrings_rev
    FOR EACH STATEMENT
    EXECUTE PROCEDURE disallowchanges();


--
-- Name: disallowchangestaxes_rev; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER disallowchangestaxes_rev
    BEFORE DELETE OR UPDATE ON taxes_rev
    FOR EACH STATEMENT
    EXECUTE PROCEDURE disallowchanges();


--
-- Name: disallowchangestenders_rev; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER disallowchangestenders_rev
    BEFORE DELETE OR UPDATE ON tenders_rev
    FOR EACH STATEMENT
    EXECUTE PROCEDURE disallowchanges();


--
-- Name: disallowchangesterms_rev; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER disallowchangesterms_rev
    BEFORE DELETE OR UPDATE ON terms_rev
    FOR EACH STATEMENT
    EXECUTE PROCEDURE disallowchanges();


--
-- Name: disallowchangestimeclock_rev; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER disallowchangestimeclock_rev
    BEFORE DELETE OR UPDATE ON timeclock_rev
    FOR EACH STATEMENT
    EXECUTE PROCEDURE disallowchanges();


--
-- Name: disallowchangesvendors_rev; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER disallowchangesvendors_rev
    BEFORE DELETE OR UPDATE ON vendors_rev
    FOR EACH STATEMENT
    EXECUTE PROCEDURE disallowchanges();


--
-- Name: disallowdeleteontimeclock; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER disallowdeleteontimeclock
    BEFORE DELETE ON timeclock
    FOR EACH ROW
    EXECUTE PROCEDURE disallowdelete();


--
-- Name: discountsreferencedinsale_revcheck; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER discountsreferencedinsale_revcheck
    BEFORE DELETE OR UPDATE ON discounts
    FOR EACH ROW
    EXECUTE PROCEDURE discountsreferenced('salesitems_rev');


--
-- Name: discountsreferencedinsalecheck; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER discountsreferencedinsalecheck
    BEFORE DELETE OR UPDATE ON discounts
    FOR EACH ROW
    EXECUTE PROCEDURE discountsreferenced('salesitems');


--
-- Name: populatekidzrevpurchaseordersordereditems; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER populatekidzrevpurchaseordersordereditems
    AFTER INSERT OR UPDATE ON purchaseordersordereditems
    FOR EACH ROW
    EXECUTE PROCEDURE populatekidzrevpurchaseordersordereditems();


--
-- Name: populatekidzrevpurchaseordersreceiveditems; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER populatekidzrevpurchaseordersreceiveditems
    AFTER INSERT OR UPDATE ON purchaseordersreceiveditems
    FOR EACH ROW
    EXECUTE PROCEDURE populatekidzrevpurchaseordersreceiveditems();


--
-- Name: populatekidzrevqwostatuses; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER populatekidzrevqwostatuses
    AFTER INSERT OR UPDATE ON qwostatuses
    FOR EACH ROW
    EXECUTE PROCEDURE populatekidzrevqwostatuses();


--
-- Name: populatekidzrevsalesitems; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER populatekidzrevsalesitems
    AFTER INSERT OR UPDATE ON salesitems
    FOR EACH ROW
    EXECUTE PROCEDURE populatekidzrevsalesitems();


--
-- Name: populatekidzrevsalespayments; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER populatekidzrevsalespayments
    AFTER INSERT OR UPDATE ON salespayments
    FOR EACH ROW
    EXECUTE PROCEDURE populatekidzrevsalespayments();


--
-- Name: populatekidzrevsalestaxes; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER populatekidzrevsalestaxes
    AFTER INSERT OR UPDATE ON salestaxes
    FOR EACH ROW
    EXECUTE PROCEDURE populatekidzrevsalestaxes();


--
-- Name: populatekidzrevsalestenders; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER populatekidzrevsalestenders
    AFTER INSERT OR UPDATE ON salestenders
    FOR EACH ROW
    EXECUTE PROCEDURE populatekidzrevsalestenders();


--
-- Name: populaterevclerks; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER populaterevclerks
    AFTER INSERT OR UPDATE ON clerks
    FOR EACH ROW
    EXECUTE PROCEDURE populaterevclerks();


--
-- Name: populaterevcustomers; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER populaterevcustomers
    AFTER INSERT OR UPDATE ON customers
    FOR EACH ROW
    EXECUTE PROCEDURE populaterevcustomers();


--
-- Name: populaterevdiscounts; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER populaterevdiscounts
    AFTER INSERT OR UPDATE ON discounts
    FOR EACH ROW
    EXECUTE PROCEDURE populaterevdiscounts();


--
-- Name: populaterevmachines; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER populaterevmachines
    AFTER INSERT OR UPDATE ON machines
    FOR EACH ROW
    EXECUTE PROCEDURE populaterevmachines();


--
-- Name: populaterevpricetables; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER populaterevpricetables
    AFTER INSERT OR UPDATE ON pricetables
    FOR EACH ROW
    EXECUTE PROCEDURE populaterevpricetables();


--
-- Name: populaterevproducts; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER populaterevproducts
    AFTER INSERT OR UPDATE ON products
    FOR EACH ROW
    EXECUTE PROCEDURE populaterevproducts();


--
-- Name: populaterevpurchaseorders; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER populaterevpurchaseorders
    AFTER INSERT OR UPDATE ON purchaseorders
    FOR EACH ROW
    EXECUTE PROCEDURE populaterevpurchaseorders();


--
-- Name: populaterevqwo; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER populaterevqwo
    AFTER INSERT OR UPDATE ON qwo
    FOR EACH ROW
    EXECUTE PROCEDURE populaterevqwo();


--
-- Name: populaterevsales; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER populaterevsales
    AFTER INSERT OR UPDATE ON sales
    FOR EACH ROW
    EXECUTE PROCEDURE populaterevsales();


--
-- Name: populaterevstrings; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER populaterevstrings
    AFTER INSERT OR UPDATE ON strings
    FOR EACH ROW
    EXECUTE PROCEDURE populaterevstrings();


--
-- Name: populaterevsysstrings; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER populaterevsysstrings
    AFTER INSERT OR UPDATE ON sysstrings
    FOR EACH ROW
    EXECUTE PROCEDURE populaterevsysstrings();


--
-- Name: populaterevtaxes; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER populaterevtaxes
    AFTER INSERT OR UPDATE ON taxes
    FOR EACH ROW
    EXECUTE PROCEDURE populaterevtaxes();


--
-- Name: populaterevtenders; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER populaterevtenders
    AFTER INSERT OR UPDATE ON tenders
    FOR EACH ROW
    EXECUTE PROCEDURE populaterevtenders();


--
-- Name: populaterevterms; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER populaterevterms
    AFTER INSERT OR UPDATE ON terms
    FOR EACH ROW
    EXECUTE PROCEDURE populaterevterms();


--
-- Name: populaterevtimeclock; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER populaterevtimeclock
    AFTER INSERT OR UPDATE ON timeclock
    FOR EACH ROW
    EXECUTE PROCEDURE populaterevtimeclock();


--
-- Name: populaterevvendors; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER populaterevvendors
    AFTER INSERT OR UPDATE ON vendors
    FOR EACH ROW
    EXECUTE PROCEDURE populaterevvendors();


--
-- Name: productsreferencedinsale_revcheck; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER productsreferencedinsale_revcheck
    BEFORE DELETE OR UPDATE ON products
    FOR EACH ROW
    EXECUTE PROCEDURE productsreferenced('salesitems_rev');


--
-- Name: productsreferencedinsalecheck; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER productsreferencedinsalecheck
    BEFORE DELETE OR UPDATE ON products
    FOR EACH ROW
    EXECUTE PROCEDURE productsreferenced('salesitems');


--
-- Name: purchaseorders_revdisallowdelete; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER purchaseorders_revdisallowdelete
    BEFORE DELETE ON purchaseorders_rev
    FOR EACH STATEMENT
    EXECUTE PROCEDURE disallowdelete();


--
-- Name: purchaseordersdefault; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER purchaseordersdefault
    BEFORE INSERT OR UPDATE ON purchaseorders
    FOR EACH ROW
    EXECUTE PROCEDURE purchaseorderssetuserinfo();


--
-- Name: purchaseordersdisallowdelete; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER purchaseordersdisallowdelete
    BEFORE DELETE ON purchaseorders
    FOR EACH STATEMENT
    EXECUTE PROCEDURE disallowdelete();


--
-- Name: purchaseordersordereditems_revdisallowdelete; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER purchaseordersordereditems_revdisallowdelete
    BEFORE DELETE ON purchaseordersordereditems_rev
    FOR EACH STATEMENT
    EXECUTE PROCEDURE disallowdelete();


--
-- Name: purchaseordersordereditemsdefault; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER purchaseordersordereditemsdefault
    BEFORE INSERT OR UPDATE ON purchaseordersordereditems
    FOR EACH ROW
    EXECUTE PROCEDURE purchaseorderssubparts();


--
-- Name: purchaseordersordereditemsdisallowdelete; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER purchaseordersordereditemsdisallowdelete
    BEFORE DELETE ON purchaseordersordereditems
    FOR EACH STATEMENT
    EXECUTE PROCEDURE disallowdelete();


--
-- Name: purchaseordersreceiveditems_revdisallowdelete; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER purchaseordersreceiveditems_revdisallowdelete
    BEFORE DELETE ON purchaseordersreceiveditems_rev
    FOR EACH STATEMENT
    EXECUTE PROCEDURE disallowdelete();


--
-- Name: purchaseordersreceiveditemsdefault; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER purchaseordersreceiveditemsdefault
    BEFORE INSERT OR UPDATE ON purchaseordersreceiveditems
    FOR EACH ROW
    EXECUTE PROCEDURE purchaseorderssubparts();


--
-- Name: purchaseordersreceiveditemsdisallowdelete; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER purchaseordersreceiveditemsdisallowdelete
    BEFORE DELETE ON purchaseordersreceiveditems
    FOR EACH STATEMENT
    EXECUTE PROCEDURE disallowdelete();


--
-- Name: salesitems_revreferencesinsale_revcheck; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER salesitems_revreferencesinsale_revcheck
    BEFORE INSERT OR UPDATE ON salesitems_rev
    FOR EACH ROW
    EXECUTE PROCEDURE salesitemsreferences();


--
-- Name: salesitemsreferencesinsalecheck; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER salesitemsreferencesinsalecheck
    BEFORE INSERT OR UPDATE ON salesitems
    FOR EACH ROW
    EXECUTE PROCEDURE salesitemsreferences();


--
-- Name: setadditionalsalesinfo; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER setadditionalsalesinfo
    BEFORE INSERT OR UPDATE ON sales
    FOR EACH ROW
    EXECUTE PROCEDURE setadditionalsalesinfo();


--
-- Name: setadditionalsalesinfopostcommit; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER setadditionalsalesinfopostcommit
    AFTER INSERT OR UPDATE ON salestenders
    FOR EACH ROW
    EXECUTE PROCEDURE setadditionalsalesinfopostcommit();


--
-- Name: setadditionaltimeclockinfo; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER setadditionaltimeclockinfo
    BEFORE INSERT OR UPDATE ON timeclock
    FOR EACH ROW
    EXECUTE PROCEDURE setadditionaltimeclockinfo();


--
-- Name: setuserinfoclerks; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER setuserinfoclerks
    BEFORE INSERT OR UPDATE ON clerks
    FOR EACH ROW
    EXECUTE PROCEDURE setuserinfo();


--
-- Name: setuserinfocustomers; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER setuserinfocustomers
    BEFORE INSERT OR UPDATE ON customers
    FOR EACH ROW
    EXECUTE PROCEDURE setuserinfo();


--
-- Name: setuserinfodiscounts; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER setuserinfodiscounts
    BEFORE INSERT OR UPDATE ON discounts
    FOR EACH ROW
    EXECUTE PROCEDURE setuserinfo();


--
-- Name: setuserinfomachines; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER setuserinfomachines
    BEFORE INSERT OR UPDATE ON machines
    FOR EACH ROW
    EXECUTE PROCEDURE setuserinfo();


--
-- Name: setuserinfopricetables; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER setuserinfopricetables
    BEFORE INSERT OR UPDATE ON pricetables
    FOR EACH ROW
    EXECUTE PROCEDURE setuserinfo();


--
-- Name: setuserinfoproducts; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER setuserinfoproducts
    BEFORE INSERT OR UPDATE ON products
    FOR EACH ROW
    EXECUTE PROCEDURE setuserinfo();


--
-- Name: setuserinfoqwo; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER setuserinfoqwo
    BEFORE INSERT OR UPDATE ON qwo
    FOR EACH ROW
    EXECUTE PROCEDURE setuserinfo();


--
-- Name: setuserinfoqwostatuses; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER setuserinfoqwostatuses
    BEFORE INSERT OR UPDATE ON qwostatuses
    FOR EACH ROW
    EXECUTE PROCEDURE setuserinfo();


--
-- Name: setuserinfosales; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER setuserinfosales
    BEFORE INSERT OR UPDATE ON sales
    FOR EACH ROW
    EXECUTE PROCEDURE setuserinfo();


--
-- Name: setuserinfostrings; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER setuserinfostrings
    BEFORE INSERT OR UPDATE ON strings
    FOR EACH ROW
    EXECUTE PROCEDURE setuserinfo();


--
-- Name: setuserinfosysstrings; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER setuserinfosysstrings
    BEFORE INSERT OR UPDATE ON sysstrings
    FOR EACH ROW
    EXECUTE PROCEDURE setuserinfo();


--
-- Name: setuserinfotaxes; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER setuserinfotaxes
    BEFORE INSERT OR UPDATE ON taxes
    FOR EACH ROW
    EXECUTE PROCEDURE setuserinfo();


--
-- Name: setuserinfotenders; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER setuserinfotenders
    BEFORE INSERT OR UPDATE ON tenders
    FOR EACH ROW
    EXECUTE PROCEDURE setuserinfo();


--
-- Name: setuserinfoterms; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER setuserinfoterms
    BEFORE INSERT OR UPDATE ON terms
    FOR EACH ROW
    EXECUTE PROCEDURE setuserinfo();


--
-- Name: setuserinfotimeclock; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER setuserinfotimeclock
    BEFORE INSERT OR UPDATE ON timeclock
    FOR EACH ROW
    EXECUTE PROCEDURE setuserinfotimeclockonly();


--
-- Name: setuserinfovendors; Type: TRIGGER; Schema: public; Owner: lanedbadmin
--

CREATE TRIGGER setuserinfovendors
    BEFORE INSERT OR UPDATE ON vendors
    FOR EACH ROW
    EXECUTE PROCEDURE setuserinfo();


--
-- Name: clerks_rev_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE ONLY clerks_rev
    ADD CONSTRAINT clerks_rev_id_fkey FOREIGN KEY (id) REFERENCES clerks(id);


--
-- Name: customers_rev_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE ONLY customers_rev
    ADD CONSTRAINT customers_rev_id_fkey FOREIGN KEY (id) REFERENCES customers(id);


--
-- Name: customers_rev_terms_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE ONLY customers_rev
    ADD CONSTRAINT customers_rev_terms_fkey FOREIGN KEY (terms) REFERENCES terms(id);


--
-- Name: customers_terms_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE ONLY customers
    ADD CONSTRAINT customers_terms_fkey FOREIGN KEY (terms) REFERENCES terms(id);


--
-- Name: discounts_rev_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE ONLY discounts_rev
    ADD CONSTRAINT discounts_rev_id_fkey FOREIGN KEY (id) REFERENCES discounts(id);


--
-- Name: machines_owner_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE ONLY machines
    ADD CONSTRAINT machines_owner_fkey FOREIGN KEY (owner) REFERENCES customers(id);


--
-- Name: machines_rev_make_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE ONLY machines_rev
    ADD CONSTRAINT machines_rev_make_fkey FOREIGN KEY (make, model, sn) REFERENCES machines(make, model, sn);


--
-- Name: machines_rev_owner_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE ONLY machines_rev
    ADD CONSTRAINT machines_rev_owner_fkey FOREIGN KEY (owner) REFERENCES customers(id);


--
-- Name: pricetables_rev_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE ONLY pricetables_rev
    ADD CONSTRAINT pricetables_rev_id_fkey FOREIGN KEY (id) REFERENCES pricetables(id);


--
-- Name: products_caseid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE ONLY products
    ADD CONSTRAINT products_caseid_fkey FOREIGN KEY (caseid) REFERENCES products(id);


--
-- Name: products_rev_caseid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE ONLY products_rev
    ADD CONSTRAINT products_rev_caseid_fkey FOREIGN KEY (caseid) REFERENCES products(id);


--
-- Name: products_rev_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE ONLY products_rev
    ADD CONSTRAINT products_rev_id_fkey FOREIGN KEY (id) REFERENCES products(id);


--
-- Name: products_rev_vendor_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE ONLY products_rev
    ADD CONSTRAINT products_rev_vendor_fkey FOREIGN KEY (vendor) REFERENCES vendors(id);


--
-- Name: products_vendor_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE ONLY products
    ADD CONSTRAINT products_vendor_fkey FOREIGN KEY (vendor) REFERENCES vendors(id);


--
-- Name: purchaseorders_rev_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE ONLY purchaseorders_rev
    ADD CONSTRAINT purchaseorders_rev_id_fkey FOREIGN KEY (id) REFERENCES purchaseorders(id);


--
-- Name: purchaseorders_rev_vendor_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE ONLY purchaseorders_rev
    ADD CONSTRAINT purchaseorders_rev_vendor_fkey FOREIGN KEY (vendor) REFERENCES vendors(id);


--
-- Name: purchaseorders_vendor_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE ONLY purchaseorders
    ADD CONSTRAINT purchaseorders_vendor_fkey FOREIGN KEY (vendor) REFERENCES vendors(id);


--
-- Name: purchaseordersordereditems_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE ONLY purchaseordersordereditems
    ADD CONSTRAINT purchaseordersordereditems_id_fkey FOREIGN KEY (id) REFERENCES purchaseorders(id);


--
-- Name: purchaseordersordereditems_plu_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE ONLY purchaseordersordereditems
    ADD CONSTRAINT purchaseordersordereditems_plu_fkey FOREIGN KEY (plu) REFERENCES products(id);


--
-- Name: purchaseordersordereditems_rev_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE ONLY purchaseordersordereditems_rev
    ADD CONSTRAINT purchaseordersordereditems_rev_id_fkey FOREIGN KEY (id, r) REFERENCES purchaseorders_rev(id, r);


--
-- Name: purchaseordersordereditems_rev_id_fkey1; Type: FK CONSTRAINT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE ONLY purchaseordersordereditems_rev
    ADD CONSTRAINT purchaseordersordereditems_rev_id_fkey1 FOREIGN KEY (id, lineno) REFERENCES purchaseordersordereditems(id, lineno);


--
-- Name: purchaseordersordereditems_rev_plu_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE ONLY purchaseordersordereditems_rev
    ADD CONSTRAINT purchaseordersordereditems_rev_plu_fkey FOREIGN KEY (plu) REFERENCES products(id);


--
-- Name: purchaseordersreceiveditems_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE ONLY purchaseordersreceiveditems
    ADD CONSTRAINT purchaseordersreceiveditems_id_fkey FOREIGN KEY (id) REFERENCES purchaseorders(id);


--
-- Name: purchaseordersreceiveditems_plu_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE ONLY purchaseordersreceiveditems
    ADD CONSTRAINT purchaseordersreceiveditems_plu_fkey FOREIGN KEY (plu) REFERENCES products(id);


--
-- Name: purchaseordersreceiveditems_rev_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE ONLY purchaseordersreceiveditems_rev
    ADD CONSTRAINT purchaseordersreceiveditems_rev_id_fkey FOREIGN KEY (id, r) REFERENCES purchaseorders_rev(id, r);


--
-- Name: purchaseordersreceiveditems_rev_id_fkey1; Type: FK CONSTRAINT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE ONLY purchaseordersreceiveditems_rev
    ADD CONSTRAINT purchaseordersreceiveditems_rev_id_fkey1 FOREIGN KEY (id, lineno) REFERENCES purchaseordersreceiveditems(id, lineno);


--
-- Name: purchaseordersreceiveditems_rev_plu_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE ONLY purchaseordersreceiveditems_rev
    ADD CONSTRAINT purchaseordersreceiveditems_rev_plu_fkey FOREIGN KEY (plu) REFERENCES products(id);


--
-- Name: qwo_rev_customer_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE ONLY qwo_rev
    ADD CONSTRAINT qwo_rev_customer_fkey FOREIGN KEY (customer) REFERENCES customers(id);


--
-- Name: qwo_rev_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE ONLY qwo_rev
    ADD CONSTRAINT qwo_rev_id_fkey FOREIGN KEY (id) REFERENCES qwo(id);


--
-- Name: qwostatuses_rev_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE ONLY qwostatuses_rev
    ADD CONSTRAINT qwostatuses_rev_id_fkey FOREIGN KEY (id, r) REFERENCES qwo_rev(id, r);


--
-- Name: sales_clerk_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE ONLY sales
    ADD CONSTRAINT sales_clerk_fkey FOREIGN KEY (clerk) REFERENCES clerks(id);


--
-- Name: sales_customer_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE ONLY sales
    ADD CONSTRAINT sales_customer_fkey FOREIGN KEY (customer) REFERENCES customers(id);


--
-- Name: sales_rev_clerk_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE ONLY sales_rev
    ADD CONSTRAINT sales_rev_clerk_fkey FOREIGN KEY (clerk) REFERENCES clerks(id);


--
-- Name: sales_rev_customer_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE ONLY sales_rev
    ADD CONSTRAINT sales_rev_customer_fkey FOREIGN KEY (customer) REFERENCES customers(id);


--
-- Name: sales_rev_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE ONLY sales_rev
    ADD CONSTRAINT sales_rev_id_fkey FOREIGN KEY (id) REFERENCES sales(id);


--
-- Name: sales_rev_server_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE ONLY sales_rev
    ADD CONSTRAINT sales_rev_server_fkey FOREIGN KEY (server) REFERENCES clerks(id);


--
-- Name: sales_server_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE ONLY sales
    ADD CONSTRAINT sales_server_fkey FOREIGN KEY (server) REFERENCES clerks(id);


--
-- Name: salesitems_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE ONLY salesitems
    ADD CONSTRAINT salesitems_id_fkey FOREIGN KEY (id) REFERENCES sales(id);


--
-- Name: salesitems_rev_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE ONLY salesitems_rev
    ADD CONSTRAINT salesitems_rev_id_fkey FOREIGN KEY (id, r) REFERENCES sales_rev(id, r);


--
-- Name: salespayments_raid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE ONLY salespayments
    ADD CONSTRAINT salespayments_raid_fkey FOREIGN KEY (raid) REFERENCES sales(id);


--
-- Name: salespayments_rev_raid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE ONLY salespayments_rev
    ADD CONSTRAINT salespayments_rev_raid_fkey FOREIGN KEY (raid) REFERENCES sales(id);


--
-- Name: salestaxes_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE ONLY salestaxes
    ADD CONSTRAINT salestaxes_id_fkey FOREIGN KEY (id) REFERENCES sales(id);


--
-- Name: salestaxes_rev_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE ONLY salestaxes_rev
    ADD CONSTRAINT salestaxes_rev_id_fkey FOREIGN KEY (id, r) REFERENCES sales_rev(id, r);


--
-- Name: salestaxes_rev_taxid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE ONLY salestaxes_rev
    ADD CONSTRAINT salestaxes_rev_taxid_fkey FOREIGN KEY (taxid) REFERENCES taxes(id);


--
-- Name: salestaxes_taxid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE ONLY salestaxes
    ADD CONSTRAINT salestaxes_taxid_fkey FOREIGN KEY (taxid) REFERENCES taxes(id);


--
-- Name: salestenders_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE ONLY salestenders
    ADD CONSTRAINT salestenders_id_fkey FOREIGN KEY (id) REFERENCES sales(id);


--
-- Name: salestenders_rev_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE ONLY salestenders_rev
    ADD CONSTRAINT salestenders_rev_id_fkey FOREIGN KEY (id, r) REFERENCES sales_rev(id, r);


--
-- Name: salestenders_rev_tender_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE ONLY salestenders_rev
    ADD CONSTRAINT salestenders_rev_tender_fkey FOREIGN KEY (tender) REFERENCES tenders(id);


--
-- Name: salestenders_tender_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE ONLY salestenders
    ADD CONSTRAINT salestenders_tender_fkey FOREIGN KEY (tender) REFERENCES tenders(id);


--
-- Name: strings_rev_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE ONLY strings_rev
    ADD CONSTRAINT strings_rev_id_fkey FOREIGN KEY (id) REFERENCES strings(id);


--
-- Name: sysstrings_rev_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE ONLY sysstrings_rev
    ADD CONSTRAINT sysstrings_rev_id_fkey FOREIGN KEY (id) REFERENCES sysstrings(id);


--
-- Name: taxes_rev_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE ONLY taxes_rev
    ADD CONSTRAINT taxes_rev_id_fkey FOREIGN KEY (id) REFERENCES taxes(id);


--
-- Name: tenders_rev_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE ONLY tenders_rev
    ADD CONSTRAINT tenders_rev_id_fkey FOREIGN KEY (id) REFERENCES tenders(id);


--
-- Name: terms_rev_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE ONLY terms_rev
    ADD CONSTRAINT terms_rev_id_fkey FOREIGN KEY (id) REFERENCES terms(id);


--
-- Name: timeclock_clerk_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE ONLY timeclock
    ADD CONSTRAINT timeclock_clerk_fkey FOREIGN KEY (clerk) REFERENCES clerks(id);


--
-- Name: timeclock_rev_clerk_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE ONLY timeclock_rev
    ADD CONSTRAINT timeclock_rev_clerk_fkey FOREIGN KEY (clerk) REFERENCES clerks(id);


--
-- Name: timeclock_rev_clerk_fkey1; Type: FK CONSTRAINT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE ONLY timeclock_rev
    ADD CONSTRAINT timeclock_rev_clerk_fkey1 FOREIGN KEY (clerk, punch) REFERENCES timeclock(clerk, punch);


--
-- Name: vendors_rev_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE ONLY vendors_rev
    ADD CONSTRAINT vendors_rev_id_fkey FOREIGN KEY (id) REFERENCES vendors(id);


--
-- Name: vendors_rev_terms_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE ONLY vendors_rev
    ADD CONSTRAINT vendors_rev_terms_fkey FOREIGN KEY (terms) REFERENCES terms(id);


--
-- Name: vendors_terms_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lanedbadmin
--

ALTER TABLE ONLY vendors
    ADD CONSTRAINT vendors_terms_fkey FOREIGN KEY (terms) REFERENCES terms(id);


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- Name: clerks; Type: ACL; Schema: public; Owner: lanedbadmin
--

REVOKE ALL ON TABLE clerks FROM PUBLIC;
REVOKE ALL ON TABLE clerks FROM lanedbadmin;
GRANT ALL ON TABLE clerks TO lanedbadmin;
GRANT SELECT ON TABLE clerks TO registersys;
GRANT INSERT,UPDATE ON TABLE clerks TO bizmgr;


--
-- Name: clerks_rev; Type: ACL; Schema: public; Owner: lanedbadmin
--

REVOKE ALL ON TABLE clerks_rev FROM PUBLIC;
REVOKE ALL ON TABLE clerks_rev FROM lanedbadmin;
GRANT ALL ON TABLE clerks_rev TO lanedbadmin;
GRANT SELECT,INSERT ON TABLE clerks_rev TO bizmgr;


--
-- Name: clerks_rev_r_seq; Type: ACL; Schema: public; Owner: lanedbadmin
--

REVOKE ALL ON SEQUENCE clerks_rev_r_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE clerks_rev_r_seq FROM lanedbadmin;
GRANT ALL ON SEQUENCE clerks_rev_r_seq TO lanedbadmin;
GRANT SELECT,UPDATE ON SEQUENCE clerks_rev_r_seq TO bizmgr;


--
-- Name: customers; Type: ACL; Schema: public; Owner: lanedbadmin
--

REVOKE ALL ON TABLE customers FROM PUBLIC;
REVOKE ALL ON TABLE customers FROM lanedbadmin;
GRANT ALL ON TABLE customers TO lanedbadmin;
GRANT SELECT,UPDATE ON TABLE customers TO registersys;
GRANT INSERT ON TABLE customers TO bizmgr;


--
-- Name: customers_rev; Type: ACL; Schema: public; Owner: lanedbadmin
--

REVOKE ALL ON TABLE customers_rev FROM PUBLIC;
REVOKE ALL ON TABLE customers_rev FROM lanedbadmin;
GRANT ALL ON TABLE customers_rev TO lanedbadmin;
GRANT SELECT,INSERT ON TABLE customers_rev TO registersys;
GRANT SELECT ON TABLE customers_rev TO bizmgr;


--
-- Name: customers_rev_r_seq; Type: ACL; Schema: public; Owner: lanedbadmin
--

REVOKE ALL ON SEQUENCE customers_rev_r_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE customers_rev_r_seq FROM lanedbadmin;
GRANT ALL ON SEQUENCE customers_rev_r_seq TO lanedbadmin;
GRANT SELECT,UPDATE ON SEQUENCE customers_rev_r_seq TO registersys;


--
-- Name: discounts; Type: ACL; Schema: public; Owner: lanedbadmin
--

REVOKE ALL ON TABLE discounts FROM PUBLIC;
REVOKE ALL ON TABLE discounts FROM lanedbadmin;
GRANT ALL ON TABLE discounts TO lanedbadmin;
GRANT SELECT ON TABLE discounts TO registersys;
GRANT INSERT,UPDATE ON TABLE discounts TO bizmgr;


--
-- Name: discounts_rev; Type: ACL; Schema: public; Owner: lanedbadmin
--

REVOKE ALL ON TABLE discounts_rev FROM PUBLIC;
REVOKE ALL ON TABLE discounts_rev FROM lanedbadmin;
GRANT ALL ON TABLE discounts_rev TO lanedbadmin;
GRANT SELECT,INSERT ON TABLE discounts_rev TO bizmgr;


--
-- Name: discounts_rev_r_seq; Type: ACL; Schema: public; Owner: lanedbadmin
--

REVOKE ALL ON SEQUENCE discounts_rev_r_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE discounts_rev_r_seq FROM lanedbadmin;
GRANT ALL ON SEQUENCE discounts_rev_r_seq TO lanedbadmin;
GRANT SELECT,UPDATE ON SEQUENCE discounts_rev_r_seq TO bizmgr;


--
-- Name: locale; Type: ACL; Schema: public; Owner: lanedbadmin
--

REVOKE ALL ON TABLE locale FROM PUBLIC;
REVOKE ALL ON TABLE locale FROM lanedbadmin;
GRANT ALL ON TABLE locale TO lanedbadmin;
GRANT SELECT ON TABLE locale TO PUBLIC;
GRANT SELECT ON TABLE locale TO registersys;


--
-- Name: machines; Type: ACL; Schema: public; Owner: lanedbadmin
--

REVOKE ALL ON TABLE machines FROM PUBLIC;
REVOKE ALL ON TABLE machines FROM lanedbadmin;
GRANT ALL ON TABLE machines TO lanedbadmin;
GRANT SELECT ON TABLE machines TO registersys;
GRANT INSERT,UPDATE ON TABLE machines TO bizmgr;


--
-- Name: machines_rev; Type: ACL; Schema: public; Owner: lanedbadmin
--

REVOKE ALL ON TABLE machines_rev FROM PUBLIC;
REVOKE ALL ON TABLE machines_rev FROM lanedbadmin;
GRANT ALL ON TABLE machines_rev TO lanedbadmin;
GRANT SELECT,INSERT ON TABLE machines_rev TO bizmgr;


--
-- Name: machines_rev_r_seq; Type: ACL; Schema: public; Owner: lanedbadmin
--

REVOKE ALL ON SEQUENCE machines_rev_r_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE machines_rev_r_seq FROM lanedbadmin;
GRANT ALL ON SEQUENCE machines_rev_r_seq TO lanedbadmin;
GRANT SELECT,UPDATE ON SEQUENCE machines_rev_r_seq TO bizmgr;


--
-- Name: pricetables; Type: ACL; Schema: public; Owner: lanedbadmin
--

REVOKE ALL ON TABLE pricetables FROM PUBLIC;
REVOKE ALL ON TABLE pricetables FROM lanedbadmin;
GRANT ALL ON TABLE pricetables TO lanedbadmin;
GRANT SELECT ON TABLE pricetables TO registersys;
GRANT INSERT,UPDATE ON TABLE pricetables TO bizmgr;


--
-- Name: pricetables_rev; Type: ACL; Schema: public; Owner: lanedbadmin
--

REVOKE ALL ON TABLE pricetables_rev FROM PUBLIC;
REVOKE ALL ON TABLE pricetables_rev FROM lanedbadmin;
GRANT ALL ON TABLE pricetables_rev TO lanedbadmin;
GRANT SELECT,INSERT ON TABLE pricetables_rev TO bizmgr;


--
-- Name: pricetables_rev_r_seq; Type: ACL; Schema: public; Owner: lanedbadmin
--

REVOKE ALL ON SEQUENCE pricetables_rev_r_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE pricetables_rev_r_seq FROM lanedbadmin;
GRANT ALL ON SEQUENCE pricetables_rev_r_seq TO lanedbadmin;
GRANT SELECT,UPDATE ON SEQUENCE pricetables_rev_r_seq TO bizmgr;


--
-- Name: products; Type: ACL; Schema: public; Owner: lanedbadmin
--

REVOKE ALL ON TABLE products FROM PUBLIC;
REVOKE ALL ON TABLE products FROM lanedbadmin;
GRANT ALL ON TABLE products TO lanedbadmin;
GRANT SELECT,UPDATE ON TABLE products TO registersys;
GRANT INSERT ON TABLE products TO bizmgr;


--
-- Name: products_rev; Type: ACL; Schema: public; Owner: lanedbadmin
--

REVOKE ALL ON TABLE products_rev FROM PUBLIC;
REVOKE ALL ON TABLE products_rev FROM lanedbadmin;
GRANT ALL ON TABLE products_rev TO lanedbadmin;
GRANT SELECT,INSERT ON TABLE products_rev TO registersys;
GRANT SELECT ON TABLE products_rev TO bizmgr;


--
-- Name: products_rev_r_seq; Type: ACL; Schema: public; Owner: lanedbadmin
--

REVOKE ALL ON SEQUENCE products_rev_r_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE products_rev_r_seq FROM lanedbadmin;
GRANT ALL ON SEQUENCE products_rev_r_seq TO lanedbadmin;
GRANT SELECT,UPDATE ON SEQUENCE products_rev_r_seq TO registersys;


--
-- Name: purchaseorders; Type: ACL; Schema: public; Owner: lanedbadmin
--

REVOKE ALL ON TABLE purchaseorders FROM PUBLIC;
REVOKE ALL ON TABLE purchaseorders FROM lanedbadmin;
GRANT ALL ON TABLE purchaseorders TO lanedbadmin;
GRANT SELECT,INSERT,UPDATE ON TABLE purchaseorders TO bizmgr;


--
-- Name: purchaseorders_id_seq; Type: ACL; Schema: public; Owner: lanedbadmin
--

REVOKE ALL ON SEQUENCE purchaseorders_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE purchaseorders_id_seq FROM lanedbadmin;
GRANT ALL ON SEQUENCE purchaseorders_id_seq TO lanedbadmin;
GRANT SELECT,UPDATE ON SEQUENCE purchaseorders_id_seq TO bizmgr;


--
-- Name: purchaseorders_rev; Type: ACL; Schema: public; Owner: lanedbadmin
--

REVOKE ALL ON TABLE purchaseorders_rev FROM PUBLIC;
REVOKE ALL ON TABLE purchaseorders_rev FROM lanedbadmin;
GRANT ALL ON TABLE purchaseorders_rev TO lanedbadmin;
GRANT SELECT,INSERT ON TABLE purchaseorders_rev TO bizmgr;


--
-- Name: purchaseorders_rev_r_seq; Type: ACL; Schema: public; Owner: lanedbadmin
--

REVOKE ALL ON SEQUENCE purchaseorders_rev_r_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE purchaseorders_rev_r_seq FROM lanedbadmin;
GRANT ALL ON SEQUENCE purchaseorders_rev_r_seq TO lanedbadmin;
GRANT SELECT,UPDATE ON SEQUENCE purchaseorders_rev_r_seq TO bizmgr;


--
-- Name: purchaseordersordereditems; Type: ACL; Schema: public; Owner: lanedbadmin
--

REVOKE ALL ON TABLE purchaseordersordereditems FROM PUBLIC;
REVOKE ALL ON TABLE purchaseordersordereditems FROM lanedbadmin;
GRANT ALL ON TABLE purchaseordersordereditems TO lanedbadmin;
GRANT SELECT,INSERT,UPDATE ON TABLE purchaseordersordereditems TO bizmgr;


--
-- Name: purchaseordersordereditems_rev; Type: ACL; Schema: public; Owner: lanedbadmin
--

REVOKE ALL ON TABLE purchaseordersordereditems_rev FROM PUBLIC;
REVOKE ALL ON TABLE purchaseordersordereditems_rev FROM lanedbadmin;
GRANT ALL ON TABLE purchaseordersordereditems_rev TO lanedbadmin;
GRANT SELECT,INSERT ON TABLE purchaseordersordereditems_rev TO bizmgr;


--
-- Name: purchaseordersreceiveditems; Type: ACL; Schema: public; Owner: lanedbadmin
--

REVOKE ALL ON TABLE purchaseordersreceiveditems FROM PUBLIC;
REVOKE ALL ON TABLE purchaseordersreceiveditems FROM lanedbadmin;
GRANT ALL ON TABLE purchaseordersreceiveditems TO lanedbadmin;
GRANT SELECT,INSERT,UPDATE ON TABLE purchaseordersreceiveditems TO bizmgr;


--
-- Name: purchaseordersreceiveditems_rev; Type: ACL; Schema: public; Owner: lanedbadmin
--

REVOKE ALL ON TABLE purchaseordersreceiveditems_rev FROM PUBLIC;
REVOKE ALL ON TABLE purchaseordersreceiveditems_rev FROM lanedbadmin;
GRANT ALL ON TABLE purchaseordersreceiveditems_rev TO lanedbadmin;
GRANT SELECT,INSERT ON TABLE purchaseordersreceiveditems_rev TO bizmgr;


--
-- Name: qwo; Type: ACL; Schema: public; Owner: lanedbadmin
--

REVOKE ALL ON TABLE qwo FROM PUBLIC;
REVOKE ALL ON TABLE qwo FROM lanedbadmin;
GRANT ALL ON TABLE qwo TO lanedbadmin;
GRANT SELECT ON TABLE qwo TO registersys;
GRANT INSERT,UPDATE ON TABLE qwo TO bizmgr;


--
-- Name: qwo_id_seq; Type: ACL; Schema: public; Owner: lanedbadmin
--

REVOKE ALL ON SEQUENCE qwo_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE qwo_id_seq FROM lanedbadmin;
GRANT ALL ON SEQUENCE qwo_id_seq TO lanedbadmin;
GRANT SELECT,UPDATE ON SEQUENCE qwo_id_seq TO bizmgr;


--
-- Name: qwo_rev; Type: ACL; Schema: public; Owner: lanedbadmin
--

REVOKE ALL ON TABLE qwo_rev FROM PUBLIC;
REVOKE ALL ON TABLE qwo_rev FROM lanedbadmin;
GRANT ALL ON TABLE qwo_rev TO lanedbadmin;
GRANT SELECT,INSERT ON TABLE qwo_rev TO bizmgr;


--
-- Name: qwo_rev_r_seq; Type: ACL; Schema: public; Owner: lanedbadmin
--

REVOKE ALL ON SEQUENCE qwo_rev_r_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE qwo_rev_r_seq FROM lanedbadmin;
GRANT ALL ON SEQUENCE qwo_rev_r_seq TO lanedbadmin;
GRANT SELECT,UPDATE ON SEQUENCE qwo_rev_r_seq TO bizmgr;


--
-- Name: qwostatuses; Type: ACL; Schema: public; Owner: lanedbadmin
--

REVOKE ALL ON TABLE qwostatuses FROM PUBLIC;
REVOKE ALL ON TABLE qwostatuses FROM lanedbadmin;
GRANT ALL ON TABLE qwostatuses TO lanedbadmin;
GRANT SELECT ON TABLE qwostatuses TO registersys;
GRANT INSERT,UPDATE ON TABLE qwostatuses TO bizmgr;


--
-- Name: qwostatuses_rev; Type: ACL; Schema: public; Owner: lanedbadmin
--

REVOKE ALL ON TABLE qwostatuses_rev FROM PUBLIC;
REVOKE ALL ON TABLE qwostatuses_rev FROM lanedbadmin;
GRANT ALL ON TABLE qwostatuses_rev TO lanedbadmin;
GRANT SELECT,INSERT ON TABLE qwostatuses_rev TO bizmgr;


--
-- Name: sales; Type: ACL; Schema: public; Owner: lanedbadmin
--

REVOKE ALL ON TABLE sales FROM PUBLIC;
REVOKE ALL ON TABLE sales FROM lanedbadmin;
GRANT ALL ON TABLE sales TO lanedbadmin;
GRANT SELECT,INSERT,UPDATE ON TABLE sales TO registersys;


--
-- Name: sales_id_seq; Type: ACL; Schema: public; Owner: lanedbadmin
--

REVOKE ALL ON SEQUENCE sales_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE sales_id_seq FROM lanedbadmin;
GRANT ALL ON SEQUENCE sales_id_seq TO lanedbadmin;
GRANT SELECT,UPDATE ON SEQUENCE sales_id_seq TO registersys;


--
-- Name: sales_rev; Type: ACL; Schema: public; Owner: lanedbadmin
--

REVOKE ALL ON TABLE sales_rev FROM PUBLIC;
REVOKE ALL ON TABLE sales_rev FROM lanedbadmin;
GRANT ALL ON TABLE sales_rev TO lanedbadmin;
GRANT SELECT,INSERT ON TABLE sales_rev TO registersys;
GRANT SELECT ON TABLE sales_rev TO bizmgr;


--
-- Name: sales_rev_r_seq; Type: ACL; Schema: public; Owner: lanedbadmin
--

REVOKE ALL ON SEQUENCE sales_rev_r_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE sales_rev_r_seq FROM lanedbadmin;
GRANT ALL ON SEQUENCE sales_rev_r_seq TO lanedbadmin;
GRANT SELECT,UPDATE ON SEQUENCE sales_rev_r_seq TO registersys;


--
-- Name: salesitems; Type: ACL; Schema: public; Owner: lanedbadmin
--

REVOKE ALL ON TABLE salesitems FROM PUBLIC;
REVOKE ALL ON TABLE salesitems FROM lanedbadmin;
GRANT ALL ON TABLE salesitems TO lanedbadmin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE salesitems TO registersys;


--
-- Name: salesitems_rev; Type: ACL; Schema: public; Owner: lanedbadmin
--

REVOKE ALL ON TABLE salesitems_rev FROM PUBLIC;
REVOKE ALL ON TABLE salesitems_rev FROM lanedbadmin;
GRANT ALL ON TABLE salesitems_rev TO lanedbadmin;
GRANT SELECT,INSERT ON TABLE salesitems_rev TO registersys;
GRANT SELECT ON TABLE salesitems_rev TO bizmgr;


--
-- Name: salestaxes; Type: ACL; Schema: public; Owner: lanedbadmin
--

REVOKE ALL ON TABLE salestaxes FROM PUBLIC;
REVOKE ALL ON TABLE salestaxes FROM lanedbadmin;
GRANT ALL ON TABLE salestaxes TO lanedbadmin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE salestaxes TO registersys;


--
-- Name: salestaxes_rev; Type: ACL; Schema: public; Owner: lanedbadmin
--

REVOKE ALL ON TABLE salestaxes_rev FROM PUBLIC;
REVOKE ALL ON TABLE salestaxes_rev FROM lanedbadmin;
GRANT ALL ON TABLE salestaxes_rev TO lanedbadmin;
GRANT SELECT,INSERT ON TABLE salestaxes_rev TO registersys;
GRANT SELECT ON TABLE salestaxes_rev TO bizmgr;


--
-- Name: salestenders; Type: ACL; Schema: public; Owner: lanedbadmin
--

REVOKE ALL ON TABLE salestenders FROM PUBLIC;
REVOKE ALL ON TABLE salestenders FROM lanedbadmin;
GRANT ALL ON TABLE salestenders TO lanedbadmin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE salestenders TO registersys;


--
-- Name: salestenders_rev; Type: ACL; Schema: public; Owner: lanedbadmin
--

REVOKE ALL ON TABLE salestenders_rev FROM PUBLIC;
REVOKE ALL ON TABLE salestenders_rev FROM lanedbadmin;
GRANT ALL ON TABLE salestenders_rev TO lanedbadmin;
GRANT SELECT,INSERT ON TABLE salestenders_rev TO registersys;
GRANT SELECT ON TABLE salestenders_rev TO bizmgr;


--
-- Name: strings; Type: ACL; Schema: public; Owner: lanedbadmin
--

REVOKE ALL ON TABLE strings FROM PUBLIC;
REVOKE ALL ON TABLE strings FROM lanedbadmin;
GRANT ALL ON TABLE strings TO lanedbadmin;
GRANT SELECT ON TABLE strings TO registersys;
GRANT INSERT,UPDATE ON TABLE strings TO bizmgr;


--
-- Name: strings_rev; Type: ACL; Schema: public; Owner: lanedbadmin
--

REVOKE ALL ON TABLE strings_rev FROM PUBLIC;
REVOKE ALL ON TABLE strings_rev FROM lanedbadmin;
GRANT ALL ON TABLE strings_rev TO lanedbadmin;
GRANT SELECT,INSERT ON TABLE strings_rev TO bizmgr;


--
-- Name: strings_rev_r_seq; Type: ACL; Schema: public; Owner: lanedbadmin
--

REVOKE ALL ON SEQUENCE strings_rev_r_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE strings_rev_r_seq FROM lanedbadmin;
GRANT ALL ON SEQUENCE strings_rev_r_seq TO lanedbadmin;
GRANT SELECT,UPDATE ON SEQUENCE strings_rev_r_seq TO bizmgr;


--
-- Name: sysstrings; Type: ACL; Schema: public; Owner: lanedbadmin
--

REVOKE ALL ON TABLE sysstrings FROM PUBLIC;
REVOKE ALL ON TABLE sysstrings FROM lanedbadmin;
GRANT ALL ON TABLE sysstrings TO lanedbadmin;
GRANT SELECT ON TABLE sysstrings TO PUBLIC;
GRANT SELECT ON TABLE sysstrings TO registersys;


--
-- Name: taxes; Type: ACL; Schema: public; Owner: lanedbadmin
--

REVOKE ALL ON TABLE taxes FROM PUBLIC;
REVOKE ALL ON TABLE taxes FROM lanedbadmin;
GRANT ALL ON TABLE taxes TO lanedbadmin;
GRANT SELECT ON TABLE taxes TO registersys;
GRANT INSERT,UPDATE ON TABLE taxes TO bizmgr;


--
-- Name: taxes_rev; Type: ACL; Schema: public; Owner: lanedbadmin
--

REVOKE ALL ON TABLE taxes_rev FROM PUBLIC;
REVOKE ALL ON TABLE taxes_rev FROM lanedbadmin;
GRANT ALL ON TABLE taxes_rev TO lanedbadmin;
GRANT SELECT,INSERT ON TABLE taxes_rev TO bizmgr;


--
-- Name: taxes_rev_r_seq; Type: ACL; Schema: public; Owner: lanedbadmin
--

REVOKE ALL ON SEQUENCE taxes_rev_r_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE taxes_rev_r_seq FROM lanedbadmin;
GRANT ALL ON SEQUENCE taxes_rev_r_seq TO lanedbadmin;
GRANT SELECT,UPDATE ON SEQUENCE taxes_rev_r_seq TO bizmgr;


--
-- Name: tenders; Type: ACL; Schema: public; Owner: lanedbadmin
--

REVOKE ALL ON TABLE tenders FROM PUBLIC;
REVOKE ALL ON TABLE tenders FROM lanedbadmin;
GRANT ALL ON TABLE tenders TO lanedbadmin;
GRANT SELECT ON TABLE tenders TO PUBLIC;
GRANT SELECT ON TABLE tenders TO registersys;
GRANT INSERT,UPDATE ON TABLE tenders TO bizmgr;


--
-- Name: tenders_rev; Type: ACL; Schema: public; Owner: lanedbadmin
--

REVOKE ALL ON TABLE tenders_rev FROM PUBLIC;
REVOKE ALL ON TABLE tenders_rev FROM lanedbadmin;
GRANT ALL ON TABLE tenders_rev TO lanedbadmin;
GRANT SELECT,INSERT ON TABLE tenders_rev TO bizmgr;


--
-- Name: tenders_rev_r_seq; Type: ACL; Schema: public; Owner: lanedbadmin
--

REVOKE ALL ON SEQUENCE tenders_rev_r_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE tenders_rev_r_seq FROM lanedbadmin;
GRANT ALL ON SEQUENCE tenders_rev_r_seq TO lanedbadmin;
GRANT SELECT,UPDATE ON SEQUENCE tenders_rev_r_seq TO bizmgr;


--
-- Name: terms; Type: ACL; Schema: public; Owner: lanedbadmin
--

REVOKE ALL ON TABLE terms FROM PUBLIC;
REVOKE ALL ON TABLE terms FROM lanedbadmin;
GRANT ALL ON TABLE terms TO lanedbadmin;
GRANT SELECT ON TABLE terms TO registersys;
GRANT INSERT,UPDATE ON TABLE terms TO bizmgr;


--
-- Name: terms_rev; Type: ACL; Schema: public; Owner: lanedbadmin
--

REVOKE ALL ON TABLE terms_rev FROM PUBLIC;
REVOKE ALL ON TABLE terms_rev FROM lanedbadmin;
GRANT ALL ON TABLE terms_rev TO lanedbadmin;
GRANT SELECT,INSERT ON TABLE terms_rev TO bizmgr;


--
-- Name: terms_rev_r_seq; Type: ACL; Schema: public; Owner: lanedbadmin
--

REVOKE ALL ON SEQUENCE terms_rev_r_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE terms_rev_r_seq FROM lanedbadmin;
GRANT ALL ON SEQUENCE terms_rev_r_seq TO lanedbadmin;
GRANT SELECT,UPDATE ON SEQUENCE terms_rev_r_seq TO bizmgr;


--
-- Name: timeclock; Type: ACL; Schema: public; Owner: lanedbadmin
--

REVOKE ALL ON TABLE timeclock FROM PUBLIC;
REVOKE ALL ON TABLE timeclock FROM lanedbadmin;
GRANT ALL ON TABLE timeclock TO lanedbadmin;
GRANT SELECT,INSERT,UPDATE ON TABLE timeclock TO registersys;


--
-- Name: timeclock_rev; Type: ACL; Schema: public; Owner: lanedbadmin
--

REVOKE ALL ON TABLE timeclock_rev FROM PUBLIC;
REVOKE ALL ON TABLE timeclock_rev FROM lanedbadmin;
GRANT ALL ON TABLE timeclock_rev TO lanedbadmin;
GRANT SELECT,INSERT ON TABLE timeclock_rev TO registersys;
GRANT SELECT ON TABLE timeclock_rev TO bizmgr;


--
-- Name: timeclock_rev_r_seq; Type: ACL; Schema: public; Owner: lanedbadmin
--

REVOKE ALL ON SEQUENCE timeclock_rev_r_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE timeclock_rev_r_seq FROM lanedbadmin;
GRANT ALL ON SEQUENCE timeclock_rev_r_seq TO lanedbadmin;
GRANT SELECT,UPDATE ON SEQUENCE timeclock_rev_r_seq TO registersys;


--
-- Name: vendors; Type: ACL; Schema: public; Owner: lanedbadmin
--

REVOKE ALL ON TABLE vendors FROM PUBLIC;
REVOKE ALL ON TABLE vendors FROM lanedbadmin;
GRANT ALL ON TABLE vendors TO lanedbadmin;
GRANT SELECT,INSERT,UPDATE ON TABLE vendors TO bizmgr;


--
-- Name: vendors_rev; Type: ACL; Schema: public; Owner: lanedbadmin
--

REVOKE ALL ON TABLE vendors_rev FROM PUBLIC;
REVOKE ALL ON TABLE vendors_rev FROM lanedbadmin;
GRANT ALL ON TABLE vendors_rev TO lanedbadmin;
GRANT SELECT,INSERT ON TABLE vendors_rev TO bizmgr;


--
-- Name: vendors_rev_r_seq; Type: ACL; Schema: public; Owner: lanedbadmin
--

REVOKE ALL ON SEQUENCE vendors_rev_r_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE vendors_rev_r_seq FROM lanedbadmin;
GRANT ALL ON SEQUENCE vendors_rev_r_seq TO lanedbadmin;
GRANT SELECT,UPDATE ON SEQUENCE vendors_rev_r_seq TO bizmgr;


--
-- PostgreSQL database dump complete
--

