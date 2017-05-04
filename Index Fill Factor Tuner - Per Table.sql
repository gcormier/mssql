-- Greg Cormier
-- May 2013
-- Ballpark estimates for index fill factors based on read/writes.

-- This script does estimates and operates on tables as a whole for read/write ratios and adjusts all the indexes
-- See the other script to analyze per-index read/write ratios.

select	object_name(usage.object_id) TableName, /*ind.name as IndexName, */
		--ind.type_desc,
		sum(part.in_row_reserved_page_count * 8 / 1024) as DataUsedMB,  
		replace(convert(varchar(128), cast((sum(usage.user_seeks) + sum(usage.user_scans) + sum(usage.user_lookups)) as money), 1), '.00', '') TotalReads,
		replace(convert(varchar(128), cast(sum (usage.user_updates) as money), 1), '.00', '') TotalWrites,

		cast((sum(usage.user_updates) / (sum(usage.user_seeks) + sum(usage.user_scans) + sum(usage.user_lookups) + 1.0)) as decimal(12,3)) Ratio,

CASE 
WHEN sum(usage.user_updates) / (sum(usage.user_seeks) + sum(usage.user_scans) + sum(usage.user_lookups) + 1.0) > 100 THEN
'ALTER INDEX ALL ON ' + object_name(usage.object_id) + ' REBUILD WITH (FILLFACTOR = 30, ONLINE=ON);'
WHEN sum(usage.user_updates) / (sum(usage.user_seeks) + sum(usage.user_scans) + sum(usage.user_lookups) + 1.0) > 50 THEN
'ALTER INDEX ALL ON ' + object_name(usage.object_id) + ' REBUILD WITH (FILLFACTOR = 40, ONLINE=ON);'
WHEN sum(usage.user_updates) / (sum(usage.user_seeks) + sum(usage.user_scans) + sum(usage.user_lookups) + 1.0) > 25 THEN
'ALTER INDEX ALL ON ' + object_name(usage.object_id) + ' REBUILD WITH (FILLFACTOR = 50, ONLINE=ON);'
WHEN sum(usage.user_updates) / (sum(usage.user_seeks) + sum(usage.user_scans) + sum(usage.user_lookups) + 1.0) > 1 THEN
'ALTER INDEX ALL ON ' + object_name(usage.object_id) + ' REBUILD WITH (FILLFACTOR = 60, ONLINE=ON);'
WHEN sum(usage.user_updates) / (sum(usage.user_seeks) + sum(usage.user_scans) + sum(usage.user_lookups) + 1.0) > 0.5 THEN
'ALTER INDEX ALL ON ' + object_name(usage.object_id) + ' REBUILD WITH (FILLFACTOR = 70, ONLINE=ON);'
WHEN sum(usage.user_updates) / (sum(usage.user_seeks) + sum(usage.user_scans) + sum(usage.user_lookups) + 1.0) > 0.1 THEN
'ALTER INDEX ALL ON ' + object_name(usage.object_id) + ' REBUILD WITH (FILLFACTOR = 80, ONLINE=ON);'
WHEN sum(usage.user_updates) / (sum(usage.user_seeks) + sum(usage.user_scans) + sum(usage.user_lookups) + 1.0) > 0.01 THEN
'ALTER INDEX ALL ON ' + object_name(usage.object_id) + ' REBUILD WITH (FILLFACTOR = 90, ONLINE=ON);'
ELSE
'ALTER INDEX ALL ON ' + object_name(usage.object_id) + ' REBUILD WITH (FILLFACTOR = 0, ONLINE=ON);'
END



from	sys.dm_db_index_usage_stats usage, 
		sys.indexes ind,
		sys.dm_db_partition_stats part
		
where	ind.index_id = usage.index_id and ind.object_id = usage.object_id
		and part.object_id = usage.object_id and part.index_id = usage.index_id
		and usage.database_id = DB_ID()
		--and type_desc <> 'HEAP'
		and ind.is_disabled = 0	
group by object_name(usage.object_id)
-- Biggest indexes first.
order by DataUsedMB desc





