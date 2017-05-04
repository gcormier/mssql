SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
GO

Select COUNT(1) AS NumberOfSplits, AllocUnitName , Context
From fn_dblog(NULL,NULL)
Where operation = 'LOP_DELETE_SPLIT'
Group By AllocUnitName, Context
Order by NumberOfSplits desc 