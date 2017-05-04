SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
GO

-- Total # of pages, used_pages, and data_pages for a given heap/clustered index
SELECT 
    t.NAME AS TableName,
    p.rows AS RowCounts,
	sum(ius.user_scans) as UserScans,
    SUM(a.total_pages) AS TotalPages, 
    SUM(a.used_pages) AS UsedPages, 
    (SUM(a.total_pages) - SUM(a.used_pages)) AS UnusedPages
FROM 
    sys.tables t
INNER JOIN      
    sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN 
    sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN 
    sys.allocation_units a ON p.partition_id = a.container_id
INNER JOIN sys.dm_db_index_usage_stats ius ON ius.object_id = i.object_id
WHERE 
    t.is_ms_shipped = 0
    AND i.OBJECT_ID > 255 
	AND i.is_disabled = 0
	and p.rows > 15	------------- Has to have at least 15 rows!
GROUP BY 
    t.Name, p.Rows
ORDER BY 
    sum(ius.user_scans) desc