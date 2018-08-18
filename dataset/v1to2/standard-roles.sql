--standard-roles.sql

--Copyright 2010 Jason Burrell

--This file creates two standard roles, a business manager and a Register system.

--The business manager role is different from the previous DB admin "posmgr" role.

\echo /standard-roles.sql

create role registersys nologin;
create role bizmgr inherit nologin in role registersys;

\echo granting permissions to historic roles... (these may fail)
\echo     register
create user register;
grant registersys to register;
\echo     /register

\echo /standard-roles.sql
