select object_name(usage.object_id) as TableName, ind.name as IndexName, 
ind.type_desc, part.in_row_reserved_page_count * 8 / 1024 as DataUsedMB, 
usage.user_seeks, usage.user_scans, usage.user_lookups, usage.user_updates, is_unique as 'UNIQUE?',
'ALTER INDEX ' + ind.name + ' ON ' + object_name(usage.object_id) + ' DISABLE;' as DisableStatement,
'DROP INDEX ' + ind.name + ' ON ' + object_name(usage.object_id) + ';' as DropStatement


from	sys.dm_db_index_usage_stats usage, 
		sys.indexes ind,
		sys.dm_db_partition_stats part
		
where	ind.index_id = usage.index_id and ind.object_id = usage.object_id
		and part.object_id = usage.object_id and part.index_id = usage.index_id
and usage.database_id = DB_ID()
-- Make sure it's not already disabled!!!
and ind.is_disabled = 0	

-- Find all 0's if you want
--and user_seeks=0 and user_scans=0 and user_lookups=0

-- Biggest indexes first.
order by DataUsedMB desc, user_updates desc




