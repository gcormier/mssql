/* to increase performance add these indexes once */
USE MSDB
GO
create index BACKUPSET_I01 ON BACKUPSET (MEDIA_SET_ID)
GO
create index BACKUPSET_I02 ON BACKUPSET (BACKUP_SET_ID,MEDIA_SET_ID)
GO

/* delete the history */
USE MSDB
declare @DaysToKeep int
declare @TempDate datetime
set @DaysToKeep = 30
set @TempDate = getdate() - @DaysToKeep
exec sp_delete_backuphistory @oldest_date = @TempDate 
GO

/* delete a chunck of history */
USE MSDB
exec sp_delete_backuphistory @oldest_date = '2009/01/01' 
GO