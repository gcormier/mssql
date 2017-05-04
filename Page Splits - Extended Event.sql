-- Create extended event to monitor page splits
-------------
CREATE EVENT SESSION Page_Splits
ON SERVER
ADD EVENT
  sqlserver.page_split
  (
    ACTION
     (
       sqlserver.database_id,
	   sqlserver.client_app_name,
	   sqlserver.sql_text
     )
   )
ADD TARGET package0.asynchronous_file_target
( SET filename = 'F:\Backups\track_page_splits.xel',
metadatafile = 'F:\backups\track_page_splits.mta',
max_file_size = 10,
max_rollover_files = 3);
------------------


-- Start the event
-------------
ALTER EVENT SESSION Page_Splits
ON SERVER
STATE = START
GO
--------------


-- Spit out information
------------
DECLARE @xel_filename varchar(256) = 'F:\Backups\track_page_splits_0_130078376109980000.xel'
DECLARE @mta_filename varchar(256) = 'F:\Backups\track_page_splits_0_130078376109980000.mta'

SELECT CONVERT(xml, event_data) as Event_Data
INTO #File_Data
FROM sys.fn_xe_file_target_read_file(@xel_filename, @mta_filename, NULL, NULL)

select * from #File_Data;
drop table #File_Data;
----------



-- Stop
----------
ALTER EVENT SESSION Page_Splits
ON SERVER
STATE = STOP
GO
----------



-- Delete event
DROP EVENT SESSION Page_Splits ON SERVER;