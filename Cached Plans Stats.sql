select objtype, 
count(*) as number_of_plans, 
sum(cast(size_in_bytes as bigint))/1024/1024 as size_in_MBs,
avg(usecounts) as avg_use_count,
min(qs.last_execution_time) as last_used
from sys.dm_exec_cached_plans, sys.dm_exec_query_stats qs
where sys.dm_exec_cached_plans.plan_handle = qs.plan_handle
group by objtype