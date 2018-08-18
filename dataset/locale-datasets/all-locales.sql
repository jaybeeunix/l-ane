--load-all-locales.sql
--Copyright 2010 Jason Burrell

--Load all of the official locales.

\echo 
\echo all-locales.sql

\echo *****English*****
\i locale-dataset-en.sql
\echo *****International*****
\i locale-dataset-int.sql
\echo *****Dutch*****
\i locale-dataset-nl.sql
\echo *****Sample*****
\i locale-dataset-sample.sql
\echo *****C*****
begin;
delete from locale where lower(lang)='c';
insert into locale select 'c' as lang, id, data from locale where lower(lang)='sample';

commit;

\echo /all-locales.sql
