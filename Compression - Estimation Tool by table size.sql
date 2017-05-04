-- List all UNCOMPRESSED tables in a database, and spit out a statement to evaluate the savings.
-- You can view compressed tables already existing by setting the =0 to <>0
-- DB must be at least SQL2005 or else the dmv's will fail.

-- Typo built in to ALTER to avoid accidental copy/paste.

select object_name(stats.object_id), max(stats.page_count), 'sp_estimate_data_compression_savings NULL, '''+ object_name(stats.object_id) +''', NULL, NULL, ''page''',
'FALTER TABLE ' + object_name(stats.object_id) + ' REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE, ONLINE=ON)'
from sys.dm_db_index_physical_stats(db_id(), null, null, null, null) stats, sys.partitions p
where stats.object_id = p.object_id and p.data_compression = 0
group by object_name(stats.object_id)
order by max(page_count) desc

