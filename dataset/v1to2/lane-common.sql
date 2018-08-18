--lane-common.sql
--Copyright 2005-2010 Jason Burrell
--This file is part of L'ane. See COPYING for licensing information.
--$Id: lane-common.sql 1141 2010-09-22 20:53:52Z jason $

--These are various functions, triggers, etc used by multiple L'ane tables.

create or replace function disallowdelete() returns "trigger" as $_$
begin
        if TG_OP = 'DELETE' then
                raise exception 'You may not delete % rows.', TG_RELNAME;
                --insert some sort of security accounting here
        end if;
        return new;
end;
$_$ language plpgsql immutable;

create or replace function setNonPersonUsername(text) returns boolean as $_$
begin
        /*this needs to make use of various integrity checks*/
        perform tablename from pg_tables where tablename='lanenonpersonusername';
        if not found then
           create temporary table lanenonpersonusername (id text);
        end if;
        delete from lanenonpersonusername;
        insert into lanenonpersonusername (id) values ($1);
        return true;
end;
$_$ language plpgsql volatile;

create or replace function clearNonPersonUsername() returns boolean as $_$
begin
	perform tablename from pg_tables where tablename='lanenonpersonusername';
        if not found then
           return true;
        end if;
	drop table lanenonpersonusername;
       	return true;
end;
$_$ language plpgsql volatile;

create or replace function laneusername() returns text as $_$
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
$_$ language plpgsql stable;

--the timeclock version of this function is similar, but it allows voidAt to be turned on/off (as the time is unique, you can't simply make a new record for the same time)
--SO, if you change something here, be sure to change it there too
create or replace function setUserInfo() returns "trigger" as $_$
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
$_$ language plpgsql stable;

create or replace function disallowChangesIfParentIsVoid() returns "trigger" as $_$
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
$_$ language plpgsql stable;

---------------------------------------------------------------------
---------------------------------------------------------------------
-- WARNING! This function isn't actually IMMUTABLE, but PostgreSQL --
-- doesn't allow STABLE functions to be used to create indexes.    --
---------------------------------------------------------------------
-- This may mean you have to dump and reload a DB if you change    --
-- SysString:'Lane/CORE/Business Day Start Time'. At a minimum,    --
-- you should restart the DB server.                               --
---------------------------------------------------------------------
---------------------------------------------------------------------
CREATE or replace FUNCTION getbusinessdayfor(timestamp with time zone) RETURNS date
    AS $_$select case when $1::time < data::time then ($1::date - '1 day'::interval)::date else $1::date end from sysStrings where id='Lane/CORE/Business Day Start Time'$_$
    LANGUAGE sql IMMUTABLE;

--if there isn't already a value for this parameter, it should be midnight
insert into SysStrings (id, data) values ('Lane/CORE/Business Day Start Time', '00:00');

----------------------------------------------------------------------
----------------------------------------------------------------------
-- NOTE: To use the revisioning code,                               --
--       1. Make a _rev table with the exact same definitions as    --
--          your original table with the additional 'r bigserial'   --
--          added TO THE END. (Use foreign key references!)         --
--       2. Populate it with the basic data                         --
--          [insert into ... select * from ...]                     --
--       3. Create a trigger on the _rev table to prevent           --
--          everything but inserts                                  --
--          [create trigger disallowChanges_ before update or       --
--           delete on _ for each statement execute procedure       --
--           disallowChanges();]                                    --
--       4. Install the base triggers                               --
--          [select installPopulateRevTable(BASETABLENAME)]         --
--       5. For any child/subtables install the Kidz triggers       --
--          [select installPopulateKidzRevTable(KIDTABLE,           --
--                                              PARENTSEQNAME)]     --
--                                                                  --
-- The trigger should now maintain the revision table itself.       --
----------------------------------------------------------------------
----------------------------------------------------------------------

--This trigger should be used by revisioned/audit-enabled tables to ensure than not even DBAs can accidentally modify DB.
create or replace function disallowChanges() returns "trigger" as $_$
begin
        raise exception 'The table "%" does not allow % operations. Consider using "void" or balancing transactions.', tg_table_name, tg_op;
end;
$_$ language plpgsql immutable;

--automatic revision table populating
--
--this must be dynamically created as we can't use new.* in dynamically named tables
create or replace function installPopulateRevTable(name) returns void as $func$
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
$func$ language plpgsql volatile;

--for dependent subtables (like salesItems) which need to use their parents' sequence
-- use
create or replace function installPopulateKidzRevTable(name, name) returns void as $func$
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
$func$ language plpgsql volatile;

