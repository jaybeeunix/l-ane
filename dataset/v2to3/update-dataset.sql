--update-dataset.sql

--Copyright 2010 Jason Burrell.

\echo
\echo
\echo To use this script, you must be in $LaneRoot/dataset/v2to3/!

\prompt 'Press Enter to continue or Ctrl+C to cancel.' affirmed

\echo ***********************************
\echo UPDATING with update-dataset.sql!
\echo ***********************************

\echo **************************
\echo installing sales-delta.sql
\echo **************************

\i sales-delta.sql

\echo *******************************
\echo installing customers-delta.sql
\echo *******************************

\i customers-delta.sql

\echo **************************
\echo installing lane-common.sql
\echo **************************

\i lane-common.sql

\echo ******************************
\echo loading the locale data
\echo ******************************

\cd ../locale-datasets
\i all-locales.sql

\echo ******************************
\echo setting the dataset version...
update SysStrings set data='3' where id='Lane/CORE/Dataset/Version' and data::integer < 3;
\echo ******************************

\echo ******************************
\echo DONE with update-dataset.sql!
\echo ******************************
