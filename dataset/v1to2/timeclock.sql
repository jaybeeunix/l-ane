--timeclock.sql
--Copyright 2005-2010 Jason Burrell.
--This file is part of L'ane, see COPYING for licensing information.
--
--$Id: timeclock.sql 1139 2010-09-21 22:22:04Z jason $
--time clock functions

\echo /timeclock.sql

create or replace function secondsWorkedCompleted(timestamp with time zone[]) returns numeric as $_$
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
$_$ language plpgsql immutable;

create or replace function secondsWorkedEstimated(timestamp with time zone[]) returns numeric as $_$
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
$_$ language plpgsql stable;

drop aggregate secondsWorkedCompleted(timestamp with time zone);
drop aggregate secondsWorkedEstimated(timestamp with time zone);
--this aggregate is from
--PostgreSQL 7.4.7 Documentation, 33.9. User-Defined Aggregates
--example defining polymorphic aggregates "CREATE AGGREGATE array_accum..."
--it works w/the polymorphic version too
create aggregate secondsWorkedCompleted (
    sfunc = array_append,
    basetype = timestamp with time zone,
    stype = timestamp with time zone[],
    finalfunc = secondsWorkedCompleted,
    initcond = '{}'
);
create aggregate secondsWorkedEstimated (
    sfunc = array_append,
    basetype = timestamp with time zone,
    stype = timestamp with time zone[],
    finalfunc = secondsWorkedEstimated,
    initcond = '{}'
);

alter table timeclock set add primary key (clerk, punch);

begin;

create table timeclock (
	clerk smallint not null,
	punch timestamp with time zone not null default current_timestamp,
	forced boolean not null default false,
	created timestamp with time zone not null default current_timestamp, --this is actually set by a trigger, but postgresql gets cranky if it isn't set before the triggers run
	createdBy text not null default ''::text,
	modified timestamp with time zone not null default current_timestamp, --this is actually set by a trigger, but postgresql gets cranky if it isn't set before the triggers run
	modifiedBy text not null default ''::text,
	voidAt timestamp with time zone,
	voidBy text,

	primary key (clerk, punch),
	foreign key (clerk) references clerks (id)
);

CREATE INDEX timeclock_clerk ON timeclock USING btree (clerk);
CREATE INDEX timeclock_getbusinessdayfor ON timeclock USING btree (getbusinessdayfor(punch));
commit;

create or replace function setAdditionalTimeclockInfo() returns "trigger" as $_$
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
$_$ language plpgsql stable;

create or replace function setUserInfoTimeclockOnly() returns "trigger" as $_$
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
$_$ language plpgsql stable;

begin;
create trigger setUserInfoTimeclock before insert or update on timeclock for each row execute procedure setUserInfoTimeclockOnly();
create trigger setAdditionalTimeclockInfo before insert or update on timeclock for each row execute procedure setAdditionalTimeclockInfo();
create trigger disallowDeleteOnTimeclock before delete on timeclock for each row execute procedure disallowdelete();
commit;

\echo bug 1329

begin;

create table timeclock_rev (
	clerk smallint not null,
	punch timestamp with time zone not null default current_timestamp,
	forced boolean not null default false,
	created timestamp with time zone not null default current_timestamp,
	createdBy text not null default ''::text,
	modified timestamp with time zone not null default current_timestamp,
	modifiedBy text not null default ''::text,
	voidAt timestamp with time zone,
	voidBy text,

	r bigserial,

	primary key (clerk, punch, r),
	foreign key (clerk) references clerks (id),
	foreign key (clerk, punch) references timeclock
);

CREATE INDEX timeclock_rev_clerk ON timeclock_rev USING btree (clerk);
CREATE INDEX timeclock_rev_getbusinessdayfor ON timeclock_rev USING btree (getbusinessdayfor(punch));

insert into timeclock_rev select * from timeclock;
create trigger disallowChangesTimeclock_rev before update or delete on timeclock_rev for each statement execute procedure disallowChanges();
select installPopulateRevTable('timeclock');

commit;

\echo /bug 1329

\echo /timeclock.sql
