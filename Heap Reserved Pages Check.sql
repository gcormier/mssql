-- Find wasted space from heaps
select OBJECT_NAME(object_id) as obj, index_Id, reserved_page_count, 
used_page_count, reserved_page_count - used_page_count as WastedPages, 
(reserved_page_count - used_page_count) * 8192 / 1024 / 1024 as WastedMB,
used_page_count * 8192 / 1024 / 1024 as UsedMB
from sys.dm_db_partition_stats
where index_id = 0 and reserved_page_count > used_page_count + 5000