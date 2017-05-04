-- Greg Cormier
-- May 2013
-- Ballpark estimates for index fill factors based on read/writes

-- This script operates on individual indexes. To operate on the entire table, see the other script.

select object_name(usage.object_id) as TableName, ind.name as IndexName, 
ind.type_desc, part.in_row_reserved_page_count * 8 / 1024 as DataUsedMB, 
usage.user_seeks + usage.user_scans + usage.user_lookups TotalReads, usage.user_updates TotalWrites,

cast((usage.user_updates) / (usage.user_seeks + usage.user_scans + usage.user_lookups + 1.0) as decimal(12,3)) as Ratio,

 is_unique as 'UNIQUE?',
CASE 
WHEN (usage.user_updates) / (usage.user_seeks + usage.user_scans + usage.user_lookups + 1.0) > 50 THEN
'ALTER INDEX ' + ind.name + ' ON ' + object_name(usage.object_id) + ' REBUILD WITH (FILLFACTOR = 40, ONLINE=ON);'
WHEN (usage.user_updates) / (usage.user_seeks + usage.user_scans + usage.user_lookups + 1.0) > 25 THEN
'ALTER INDEX ' + ind.name + ' ON ' + object_name(usage.object_id) + ' REBUILD WITH (FILLFACTOR = 50, ONLINE=ON);'
WHEN (usage.user_updates) / (usage.user_seeks + usage.user_scans + usage.user_lookups + 1.0) > 10 THEN
'ALTER INDEX ' + ind.name + ' ON ' + object_name(usage.object_id) + ' REBUILD WITH (FILLFACTOR = 60, ONLINE=ON);'
WHEN (usage.user_updates) / (usage.user_seeks + usage.user_scans + usage.user_lookups + 1.0) > 1 THEN
'ALTER INDEX ' + ind.name + ' ON ' + object_name(usage.object_id) + ' REBUILD WITH (FILLFACTOR = 70, ONLINE=ON);'
WHEN (usage.user_updates) / (usage.user_seeks + usage.user_scans + usage.user_lookups + 1.0) > 0.1 THEN
'ALTER INDEX ' + ind.name + ' ON ' + object_name(usage.object_id) + ' REBUILD WITH (FILLFACTOR = 80, ONLINE=ON);'
WHEN (usage.user_updates) / (usage.user_seeks + usage.user_scans + usage.user_lookups + 1.0) > 0.01 THEN
'ALTER INDEX ' + ind.name + ' ON ' + object_name(usage.object_id) + ' REBUILD WITH (FILLFACTOR = 90, ONLINE=ON);'
ELSE
'ALTER INDEX ' + ind.name + ' ON ' + object_name(usage.object_id) + ' REBUILD WITH (FILLFACTOR = 0, ONLINE=ON);'
END



from	sys.dm_db_index_usage_stats usage, 
		sys.indexes ind,
		sys.dm_db_partition_stats part
		
where	ind.index_id = usage.index_id and ind.object_id = usage.object_id
		and part.object_id = usage.object_id and part.index_id = usage.index_id
		and usage.database_id = DB_ID()
		and type_desc <> 'HEAP'
		and ind.is_disabled = 0	

-- Biggest indexes first.
order by DataUsedMB desc, Ratio desc





