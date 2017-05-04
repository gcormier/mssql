-- Compress the biggest bizflow tables
-- Add MAXDOP if you want to scale the usage. Default of 4 will consume 50% CPU of the server while this rebuilds online.
-- Sept 4, 2012

USE [bizflow]
ALTER TABLE [dbo].[param] REBUILD PARTITION = ALL WITH  (DATA_COMPRESSION = PAGE )
ALTER TABLE [dbo].act REBUILD PARTITION = ALL WITH  (DATA_COMPRESSION = PAGE )
ALTER TABLE [dbo].cond REBUILD PARTITION = ALL WITH  (DATA_COMPRESSION = PAGE )
ALTER TABLE [dbo].auditinfo REBUILD PARTITION = ALL WITH  (DATA_COMPRESSION = PAGE )
ALTER TABLE [dbo].trans REBUILD PARTITION = ALL WITH  (DATA_COMPRESSION = PAGE )
ALTER TABLE [dbo].rlvntdata REBUILD PARTITION = ALL WITH  (DATA_COMPRESSION = PAGE )
ALTER TABLE [dbo].resp REBUILD PARTITION = ALL WITH  (DATA_COMPRESSION = PAGE )
ALTER TABLE [dbo].auditinfo REBUILD PARTITION = ALL WITH  (DATA_COMPRESSION = PAGE )
ALTER TABLE [dbo].prtcp REBUILD PARTITION = ALL WITH  (DATA_COMPRESSION = PAGE )

ALTER TABLE [dbo].procs REBUILD PARTITION = ALL WITH  (DATA_COMPRESSION = PAGE , ONLINE = ON)


ALTER TABLE [dbo].witem REBUILD PARTITION = ALL WITH  (DATA_COMPRESSION = PAGE , ONLINE = ON )
ALTER TABLE [dbo].excpt REBUILD PARTITION = ALL WITH  (DATA_COMPRESSION = PAGE , ONLINE = ON )
ALTER TABLE [dbo].MECTS_Comments REBUILD PARTITION = ALL WITH  (DATA_COMPRESSION = PAGE , ONLINE = ON )
ALTER TABLE [dbo].MECTS_History REBUILD PARTITION = ALL WITH  (DATA_COMPRESSION = PAGE , ONLINE = ON )


-- Running in DEV took :  45 minutes. ETA for prod - 90 minutes.