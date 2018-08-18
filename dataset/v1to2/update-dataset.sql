--update-dataset.sql

--Copyright 2010 Jason Burrell.

\echo
\echo
\echo To use this script, you must be in $LaneRoot/dataset/v1to2/!

\i check-relations.sql

\echo Ready to modify the database. Make sure you have a backup!
\echo
\prompt 'Press Enter to continue or Ctrl+C to cancel.' affirmed

\echo ***********************************
\echo UPDATING with update-dataset.sql!
\echo ***********************************

\echo ******************************
\echo installing lane-common.sql
\echo ******************************
\i lane-common.sql

\echo ******************************
\echo installing clerks-delta.sql
\echo ******************************
\i clerks-delta.sql

\echo ******************************
\echo installing customers-delta.sql
\echo ******************************
\i customers-delta.sql

\echo ******************************
\echo installing discounts-delta.sql
\echo ******************************
\i discounts-delta.sql

\echo ******************************
\echo installing machines-delta.sql
\echo ******************************
\i machines-delta.sql

\echo ******************************
\echo installing old-lanebms-isms-delta.sql
\echo ******************************
\i old-lanebms-isms-delta.sql

\echo ******************************
\echo installing pricetables-delta.sql
\echo ******************************
\i pricetables-delta.sql

\echo ******************************
\echo installing products-delta.sql
\echo ******************************
\i products-delta.sql

\echo ******************************
\echo installing purchaseorders-delta.sql
\echo ******************************
\i purchaseorders-delta.sql

\echo ******************************
\echo installing qwo-delta.sql
\echo ******************************
\i qwo-delta.sql

\echo ******************************
\echo installing sales-delta.sql
\echo ******************************
\i sales-delta.sql

\echo ******************************
\echo installing strings-delta.sql
\echo ******************************
\i strings-delta.sql

\echo ******************************
\echo installing taxes-delta.sql
\echo ******************************
\i taxes-delta.sql

\echo ******************************
\echo installing tenders-delta.sql
\echo ******************************
\i tenders-delta.sql

\echo ******************************
\echo installing timeclock.sql
\echo ******************************
\i timeclock.sql

\echo ******************************
\echo installing vendors-delta.sql
\echo ******************************
\i vendors-delta.sql

\echo ******************************
\echo installing standard-roles.sql
\echo ******************************
\i standard-roles.sql

\echo ******************************
\echo installing standard-permissions.sql
\echo ******************************
\i standard-permissions.sql

\echo ******************************
\echo setting the dataset version...
update SysStrings set data='2' where id='Lane/CORE/Dataset/Version' and data::integer < 2;
\echo ******************************

\echo ******************************
\echo DONE with update-dataset.sql!
\echo ******************************
