select object_schema_name(sys.indexes.object_id) + '.' + object_name(sys.indexes.object_id) as objectName,
         sys.indexes.name, case when is_unique = 1 then 'UNIQUE ' else '' end + sys.indexes.type_desc, 
         ddius.user_seeks, ddius.user_scans, ddius.user_lookups, ddius.user_updates
from sys.indexes
               left outer join sys.dm_db_index_usage_stats ddius
                        on sys.indexes.object_id = ddius.object_id
                             and sys.indexes.index_id = ddius.index_id
                             and ddius.database_id = db_id()
order by ddius.user_seeks + ddius.user_scans + ddius.user_lookups desc