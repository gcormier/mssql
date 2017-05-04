SELECT
DB_NAME(database_id) AS database_name
, OBJECT_NAME(OBJECT_ID) AS OBJECT_NAME
, forwarded_fetch_count
FROM sys.dm_db_index_operational_stats (null,null, NULL, NULL)
order by forwarded_fetch_count desc


