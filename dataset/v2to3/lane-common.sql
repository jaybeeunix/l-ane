--lane-common.sql
--Copyright 2010 Jason Burrell
--This file is part of L'ane. See COPYING for licensing information.

--These are various functions, triggers, etc used by multiple L'ane tables.

create or replace function setNonPersonUsername(text) returns boolean as $_$
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
$_$ language plpgsql volatile;

create or replace function clearNonPersonUsername() returns boolean as $_$
begin
        perform relname from pg_class where relname='lanenonpersonusername' and relnamespace=pg_my_temp_schema();
        if not found then
           return true;
        end if;
	drop table lanenonpersonusername;
       	return true;
end;
$_$ language plpgsql volatile;

