--purchaseorders-delta.sql
--This file is part of L'ane. See COPYING for licensing information
--Copyright 2002-2010 Jason Burrell.
--$Id: purchaseorders-delta.sql 1139 2010-09-21 22:22:04Z jason $

\echo purchaseorders-delta.sql

\echo creating purchaseorders tables
begin;

CREATE FUNCTION purchaseorderssetuserinfo() RETURNS trigger
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
$$
    LANGUAGE plpgsql;

CREATE FUNCTION purchaseorderssubparts() RETURNS trigger
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
$$
    LANGUAGE plpgsql;

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

CREATE SEQUENCE purchaseorders_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;
ALTER SEQUENCE purchaseorders_id_seq OWNED BY purchaseorders.id;

ALTER TABLE purchaseorders ALTER COLUMN id SET DEFAULT nextval('purchaseorders_id_seq'::regclass);
ALTER TABLE ONLY purchaseorders ADD CONSTRAINT purchaseorders_pkey PRIMARY KEY (id);
ALTER TABLE ONLY purchaseorders ADD CONSTRAINT purchaseorders_vendor_fkey FOREIGN KEY (vendor) REFERENCES vendors(id);

CREATE INDEX purchaseorders_completelyreceived ON purchaseorders USING btree (completelyreceived);
CREATE INDEX purchaseorders_orderat ON purchaseorders USING btree (orderedat);
CREATE INDEX purchaseorders_vendor ON purchaseorders USING btree (vendor);

CREATE TRIGGER purchaseordersdefault
    BEFORE INSERT OR UPDATE ON purchaseorders
    FOR EACH ROW
    EXECUTE PROCEDURE purchaseorderssetuserinfo();

CREATE TRIGGER purchaseordersdisallowdelete
    BEFORE DELETE ON purchaseorders
    FOR EACH STATEMENT
    EXECUTE PROCEDURE disallowdelete();

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

ALTER TABLE ONLY purchaseordersordereditems ADD CONSTRAINT purchaseordersordereditems_pkey PRIMARY KEY (id, lineno);
ALTER TABLE ONLY purchaseordersordereditems ADD CONSTRAINT purchaseordersordereditems_id_fkey FOREIGN KEY (id) REFERENCES purchaseorders;
ALTER TABLE ONLY purchaseordersordereditems ADD CONSTRAINT purchaseordersordereditems_plu_fkey FOREIGN KEY (plu) REFERENCES products(id);

CREATE INDEX purchaseordersordereditems_plu ON purchaseordersordereditems USING btree (plu);

CREATE TRIGGER purchaseordersordereditemsdefault
    BEFORE INSERT OR UPDATE ON purchaseordersordereditems
    FOR EACH ROW
    EXECUTE PROCEDURE purchaseorderssubparts();
CREATE TRIGGER purchaseordersordereditemsdisallowdelete
    BEFORE DELETE ON purchaseordersordereditems
    FOR EACH STATEMENT
    EXECUTE PROCEDURE disallowdelete();

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

ALTER TABLE ONLY purchaseordersreceiveditems ADD CONSTRAINT purchaseordersreceiveditems_pkey PRIMARY KEY (id, lineno);
ALTER TABLE ONLY purchaseordersreceiveditems ADD CONSTRAINT purchaseordersreceiveditems_plu_fkey FOREIGN KEY (plu) REFERENCES products(id);
ALTER TABLE ONLY purchaseordersreceiveditems ADD CONSTRAINT purchaseordersreceiveditems_id_fkey FOREIGN KEY (id) REFERENCES purchaseorders;

CREATE INDEX purchaseordersreceiveditems_plu ON purchaseordersreceiveditems USING btree (plu);

CREATE TRIGGER purchaseordersreceiveditemsdefault
    BEFORE INSERT OR UPDATE ON purchaseordersreceiveditems
    FOR EACH ROW
    EXECUTE PROCEDURE purchaseorderssubparts();
CREATE TRIGGER purchaseordersreceiveditemsdisallowdelete
    BEFORE DELETE ON purchaseordersreceiveditems
    FOR EACH STATEMENT
    EXECUTE PROCEDURE disallowdelete();

commit;
\echo /creating purchaseorders tables

\echo bug 1329
begin;

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

    r bigserial,

    primary key (id, r),
    foreign key (id) references purchaseorders,
    foreign key (vendor) references vendors
);

CREATE INDEX purchaseorders_rev_completelyreceived ON purchaseorders_rev USING btree (completelyreceived);
CREATE INDEX purchaseorders_rev_orderat ON purchaseorders_rev USING btree (orderedat);
CREATE INDEX purchaseorders_rev_vendor ON purchaseorders_rev USING btree (vendor);

CREATE TRIGGER purchaseorders_revdisallowdelete
    BEFORE DELETE ON purchaseorders_rev
    FOR EACH STATEMENT
    EXECUTE PROCEDURE disallowdelete();

insert into purchaseorders_rev select * from purchaseorders;
create trigger disallowChangesPurchaseorders_rev before update or delete on purchaseorders_rev for each statement execute procedure disallowChanges();
select installPopulateRevTable('purchaseorders');

CREATE TABLE purchaseordersordereditems_rev (
    id integer NOT NULL,
    lineno smallint NOT NULL,
    plu character varying(20) NOT NULL,
    qty numeric(20,6) NOT NULL,
    amt integer NOT NULL,
    voidat timestamp with time zone,
    voidby text,
    extended text,

    r bigint,

    primary key (id, lineno, r),
    foreign key (id, r) references purchaseorders_rev,
    --unlike sales, this can refer to the specific items because lines can't be removed from a po
    foreign key (id, lineno) references purchaseordersordereditems,
    foreign key (plu) references products
);

CREATE INDEX purchaseordersordereditems_rev_plu ON purchaseordersordereditems_rev USING btree (plu);

CREATE TRIGGER purchaseordersordereditems_revdisallowdelete
    BEFORE DELETE ON purchaseordersordereditems_rev
    FOR EACH STATEMENT
    EXECUTE PROCEDURE disallowdelete();

insert into purchaseordersordereditems_rev select purchaseordersordereditems.*, r from purchaseordersordereditems, purchaseorders_rev where purchaseorders_rev.id=purchaseordersordereditems.id;
create trigger disallowChangesPurchaseordersordereditems_rev before update or delete on purchaseordersordereditems_rev for each statement execute procedure disallowChanges();
select installPopulateKidzRevTable('purchaseordersordereditems', 'purchaseorders_rev_r_seq');

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

    r bigint,

    primary key (id, lineno, r),
    foreign key (id, r) references purchaseorders_rev,
    --unlike sales, this can refer to the specific items because lines can't be removed from a po
    foreign key (id, lineno) references purchaseordersreceiveditems,
    foreign key (plu) references products
);

CREATE INDEX purchaseordersreceiveditems_rev_plu ON purchaseordersreceiveditems_rev USING btree (plu);

CREATE TRIGGER purchaseordersreceiveditems_revdisallowdelete
    BEFORE DELETE ON purchaseordersreceiveditems_rev
    FOR EACH STATEMENT
    EXECUTE PROCEDURE disallowdelete();

insert into purchaseordersreceiveditems_rev select purchaseordersreceiveditems.*, r from purchaseordersreceiveditems, purchaseorders_rev where purchaseorders_rev.id=purchaseordersreceiveditems.id;
create trigger disallowChangesPurchaseordersreceiveditems_rev before update or delete on purchaseordersreceiveditems_rev for each statement execute procedure disallowChanges();
select installPopulateKidzRevTable('purchaseordersreceiveditems', 'purchaseorders_rev_r_seq');


commit;
\echo /bug 1329

\echo /purchaseorders-delta.sql
