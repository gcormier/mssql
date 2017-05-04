-- Works on SQL2000 but is much slower.
select cast(OBJECT_NAME(object_id) as varchar(40)) as 'Object', 
forwarded_record_count, page_count,
'CREATE CLUSTERED INDEX TmpClustInd on ' + OBJECT_NAME(object_id) + '(' + col_name(object_id, 2) + ') 
with (ONLINE=ON); DROP INDEX ' + OBJECT_NAME(object_id) + '.TmpClustInd;' as ONLINErebuild,
'CREATE CLUSTERED INDEX TmpClustInd on ' + OBJECT_NAME(object_id) + '(' + col_name(object_id, 2) + ') 
with (ONLINE=OFF); DROP INDEX ' + OBJECT_NAME(object_id) + '.TmpClustInd;' as OFFLINErebuild
from sys.dm_db_index_physical_stats(26, null, null, null, 'detailed')
where forwarded_record_count > 0 and database_id = DB_ID()
order by forwarded_record_count desc



-- SQL 2005+ only, shows the number of fetches done.
SELECT
DB_NAME(database_id) AS database_name
, OBJECT_NAME(OBJECT_ID) AS OBJECT_NAME
, forwarded_fetch_count,
'CREATE CLUSTERED INDEX TmpClustInd on ' + OBJECT_NAME(object_id) + '(' + col_name(object_id, 2) + ') 
with (ONLINE=ON); DROP INDEX ' + OBJECT_NAME(object_id) + '.TmpClustInd;' as ONLINErebuild
FROM sys.dm_db_index_operational_stats (DB_ID(), OBJECT_ID('dbo.Details'), NULL, NULL)
where database_id=DB_ID()
order by forwarded_fetch_count desc