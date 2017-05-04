USE [bizflow]
-- First, review the transaction log size prior to the shrinking process.
GO 
SELECT * 
FROM sysfiles
WHERE name LIKE '%LOG%' 
GO

-- Second, set the database recovery model to 'simple'.  

USE [bizflow]
GO
ALTER DATABASE [bizflow] SET RECOVERY SIMPLE
GO
 

-- Third, issue a checkpoint against the database to write the records from the transaction log to the database.

USE [bizflow]
GO
CHECKPOINT
GO
 

-- Fourth, truncate the transaction log.

USE [bizflow]
GO
BACKUP LOG [bizflow] WITH NO_LOG
GO
 

-- Fifth, record the logical file name for the transaction log to use in the next step.

USE [bizflow]
GO
SELECT Name
FROM sysfiles
WHERE name LIKE '%LOG%' 
GO 

-- Sixth, to free the unused space in your transaction log and return the space back to the operating system, shrink the transaction log file. 

USE [bizflow]
GO
DBCC SHRINKFILE ([BIZLOG])
GO
 

-- Seven, review the database transaction log size to verify it has been reduced.

USE [bizflow]
GO 
SELECT * 
FROM sysfiles
WHERE name LIKE '%LOG%' 
GO

-- Eight, set the database recovery model back to 'full'.  

USE [bizflow]
GO
ALTER DATABASE [bizflow] SET RECOVERY FULL
GO
