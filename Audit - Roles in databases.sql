set NOCOUNT on

select name as 'Database Name', suser_sname(owner_sid) as 'Owned by', collation_name as 'Collation', recovery_model_desc as 'Recovery Model'
from sys.databases
where name not in ('model', 'msdb', 'master', 'tempdb')
order by name

CREATE TABLE ##roleUserAudit (DatabaseName nvarchar(256), DatabaseUser nvarchar(256), DatabaseRole nvarchar(256));

EXEC sp_MSForEachDB 'INSERT INTO ##roleUserAudit 
						SELECT ''?'' as DatabaseName, su1.name as DatabaseUser, su2.name as DatabaseRole
						
						FROM [?].sys.database_role_members r
							INNER JOIN [?]..sysusers su1 ON su1.[uid] = r.member_principal_id
							INNER JOIN [?]..sysusers su2 ON su2.[uid] = r.role_principal_id
							
						WHERE su2.name IN(''db_owner'') AND su1.name NOT IN(''dbo'') '


select * from ##roleUserAudit

drop table ##roleuseraudit

select ssprin.name as Login,ssprole.name as 'Role Name'
from sys.server_principals ssprin 
JOIN sys.server_role_members srm on ssprin.principal_id=srm.member_principal_id 
and ssprin.type IN('S','U','G')
JOIN sys.server_principals ssprole  on ssprole.principal_id=srm.role_principal_id
where ssprin.name not in ('sa', 'NT AUTHORITY\SYSTEM', 'NT SERVICE\MSSQLSERVER', 'NT SERVICE\SQLSERVERAGENT', 'NT SERVICE\MSSQL$TESTINST', 'NT SERVICE\SQLAgent$TESTINST')
order by ssprole.name 