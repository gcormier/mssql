-- Executes DBCC CHECKDB PHYSICAL_ONLY during the week, does a full checkdb on the weekend.

declare @today nvarchar(64);

select @today =datename(WEEKDAY, GETDATE());

if @today in ('Sunday')
begin
-- Weekend (technically Saturday night/early sunday morning)
print 'Weekend - FULL CHECKS.'
exec sp_MSforeachDB 'DBCC CHECKDB (?) WITH NO_INFOMSGS';
end
else
begin
-- Weekday
print 'Weekday - PHYSICAL_ONLY CHECKS.'
exec sp_MSforeachDB 'DBCC CHECKDB (?) WITH NO_INFOMSGS, PHYSICAL_ONLY';

end