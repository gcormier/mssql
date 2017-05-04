SELECT DISTINCT [TABLE] = OBJECT_NAME(OBJECT_ID)
FROM SYS.INDEXES
WHERE INDEX_ID = 0
AND OBJECTPROPERTY(OBJECT_ID,'IsUserTable') = 1
ORDER BY [TABLE]
GO