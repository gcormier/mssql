-- Find all log files, shrink them to 256MB and set autogrowth. Useful in DEV and TEST environments where there's no FULL logging.

SELECT Name [Database], Physical_Name [Physical file], size*8 [Size_KB],
'use [' + db_name(database_id) + ']; DBCC SHRINKFILE (N'''+ name + ''' , 256); ALTER DATABASE [' + db_name(database_id) + '] MODIFY FILE ( NAME = N''' + name + ''', FILEGROWTH = 262144KB );'
FROM sys.master_files 
where name like '%_log'
order by size desc

