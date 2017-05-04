declare @MB_Free int
declare @bodytext varchar(1024)

create table #FreeSpace(
 Drive char(1), 
 MB_Free int)

insert into #FreeSpace exec xp_fixeddrives

-- C - System
-- D - Data
-- E - Logs
-- F - Backups

-- C Drive
select @MB_Free = MB_Free from #FreeSpace where Drive = 'C'
if @MB_Free < 4096
	begin
	set @bodytext='C drive has ' + convert(varchar, (@MB_Free/1024)) + 'GB remaining.'
	exec msdb.dbo.sp_notify_operator @profile_name='DFO', 
		@subject='Low Disk Space', 
		@name='Greg Cormier',
		@body=@bodytext
	end
	
-- D Drive
select @MB_Free = MB_Free from #FreeSpace where Drive = 'D'
if @MB_Free < 25000
	begin
	set @bodytext='D drive has ' + convert(varchar, (@MB_Free/1024)) + 'GB remaining.'
	exec msdb.dbo.sp_notify_operator @profile_name='DFO', 
		@subject='Low Disk Space', 
		@name='Greg Cormier',
		@body=@bodytext
	end

-- E Drive
select @MB_Free = MB_Free from #FreeSpace where Drive = 'E'
if @MB_Free < 25000
	begin
	set @bodytext='E drive has ' + convert(varchar, (@MB_Free/1024)) + 'GB remaining.'
	exec msdb.dbo.sp_notify_operator @profile_name='DFO', 
		@subject='Low Disk Space', 
		@name='Greg Cormier',
		@body=@bodytext
	end

-- F Drive
select @MB_Free = MB_Free from #FreeSpace where Drive = 'F'
if @MB_Free < 50000
	begin
	set @bodytext='F drive has ' + convert(varchar, (@MB_Free/1024)) + 'GB remaining.'
	exec msdb.dbo.sp_notify_operator @profile_name='DFO', 
		@subject='Low Disk Space', 
		@name='Greg Cormier',
		@body=@bodytext
	end

drop table #FreeSpace