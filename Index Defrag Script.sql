/* Scroll down to the see notes, disclaimers, and licensing information */

Declare @indexDefragLog_rename      varchar(128)
    , @indexDefragExclusion_rename  varchar(128)
    , @indexDefragStatus_rename     varchar(128);

Select @indexDefragLog_rename       = 'dba_indexDefragLog_obsolete_' + Convert(varchar(10), GetDate(), 112)
    , @indexDefragExclusion_rename  = 'dba_indexDefragExclusion_obsolete_' + Convert(varchar(10), GetDate(), 112)
    , @indexDefragStatus_rename     = 'dba_indexDefragStatus_obsolete_' + Convert(varchar(10), GetDate(), 112);

If Exists(Select [object_id] From sys.tables Where [name] = 'dba_indexDefragLog')
    Execute sp_rename dba_indexDefragLog, @indexDefragLog_rename;

If Exists(Select [object_id] From sys.tables Where [name] = 'dba_indexDefragExclusion')
    Execute sp_rename dba_indexDefragExclusion, @indexDefragExclusion_rename;

If Exists(Select [object_id] From sys.tables Where [name] = 'dba_indexDefragStatus')
    Execute sp_rename dba_indexDefragStatus, @indexDefragStatus_rename;
Go

Create Table dbo.dba_indexDefragLog
(
      indexDefrag_id    int identity(1,1)   Not Null
    , databaseID        int                 Not Null
    , databaseName      nvarchar(128)       Not Null
    , objectID          int                 Not Null
    , objectName        nvarchar(128)       Not Null
    , indexID           int                 Not Null
    , indexName         nvarchar(128)       Not Null
    , partitionNumber   smallint            Not Null
    , fragmentation     float               Not Null
    , page_count        int                 Not Null
    , dateTimeStart     datetime            Not Null
    , dateTimeEnd       datetime            Null
    , durationSeconds   int                 Null
    , sqlStatement      varchar(4000)       Null
    , errorMessage      varchar(1000)       Null
    
    Constraint PK_indexDefragLog_v40
        Primary Key Clustered (indexDefrag_id)
);

Print 'dba_indexDefragLog Table Created';

Create Table dbo.dba_indexDefragExclusion
(
      databaseID        int                 Not Null
    , databaseName      nvarchar(128)       Not Null
    , objectID          int                 Not Null
    , objectName        nvarchar(128)       Not Null
    , indexID           int                 Not Null
    , indexName         nvarchar(128)       Not Null
    , exclusionMask     int                 Not Null
        /* 1=Sunday, 2=Monday, 4=Tuesday, 8=Wednesday, 16=Thursday, 32=Friday, 64=Saturday */

    Constraint PK_indexDefragExclusion_v40
        Primary Key Clustered (databaseID, objectID, indexID)
);

Print 'dba_indexDefragExclusion Table Created';

Create Table dbo.dba_indexDefragStatus
(
      databaseID        int
    , databaseName      nvarchar(128)
    , objectID          int
    , indexID           int
    , partitionNumber   smallint
    , fragmentation     float
    , page_count        int
    , range_scan_count  bigint
    , schemaName        nvarchar(128)   Null
    , objectName        nvarchar(128)   Null
    , indexName         nvarchar(128)   Null
    , scanDate          datetime        
    , defragDate        datetime        Null
    , printStatus       bit             Default(0)
    , exclusionMask     int             Default(0)
    
    Constraint PK_indexDefragStatus_v40
        Primary Key Clustered(databaseID, objectID, indexID, partitionNumber)
);

Print 'dba_indexDefragStatus Table Created';

If ObjectProperty(Object_ID('dbo.dba_indexDefrag_sp'), N'IsProcedure') = 1
Begin
    Drop Procedure dbo.dba_indexDefrag_sp;
    Print 'Procedure dba_indexDefrag_sp dropped';
End;
Go

Create Procedure dbo.dba_indexDefrag_sp

    /* Declare Parameters */
      @minFragmentation     float           = 10.0  
        /* in percent, will not defrag if fragmentation less than specified */
    , @rebuildThreshold     float           = 30.0  
        /* in percent, greater than @rebuildThreshold will result in rebuild instead of reorg */
    , @executeSQL           bit             = 1     
        /* 1 = execute; 0 = print command only */
    , @defragOrderColumn    nvarchar(20)    = 'range_scan_count'
        /* Valid options are: range_scan_count, fragmentation, page_count */
    , @defragSortOrder      nvarchar(4)     = 'DESC'
        /* Valid options are: ASC, DESC */
    , @timeLimit            int             = 720 /* defaulted to 12 hours */
        /* Optional time limitation; expressed in minutes */
    , @database             varchar(128)    = Null
        /* Option to specify a database name; null will return all */
    , @tableName            varchar(4000)   = Null  -- databaseName.schema.tableName
        /* Option to specify a table name; null will return all */
    , @forceRescan          bit             = 0
        /* Whether or not to force a rescan of indexes; 1 = force, 0 = use existing scan, if available */
    , @scanMode             varchar(10)     = N'LIMITED'
        /* Options are LIMITED, SAMPLED, and DETAILED */
    , @minPageCount         int             = 8 
        /*  MS recommends > 1 extent (8 pages) */
    , @maxPageCount         int             = Null
        /* NULL = no limit */
    , @excludeMaxPartition  bit             = 0
        /* 1 = exclude right-most populated partition; 0 = do not exclude; see notes for caveats */
    , @onlineRebuild        bit             = 1     
        /* 1 = online rebuild; 0 = offline rebuild; only in Enterprise */
    , @sortInTempDB         bit             = 1
        /* 1 = perform sort operation in TempDB; 0 = perform sort operation in the index's database */
    , @maxDopRestriction    tinyint         = Null
        /* Option to restrict the number of processors for the operation; only in Enterprise */
    , @printCommands        bit             = 0     
        /* 1 = print commands; 0 = do not print commands */
    , @printFragmentation   bit             = 0
        /* 1 = print fragmentation prior to defrag; 
           0 = do not print */
    , @defragDelay          char(8)         = '00:00:05'
        /* time to wait between defrag commands */
    , @debugMode            bit             = 0
        /* display some useful comments to help determine if/where issues occur */

As
/*********************************************************************************
    Name:       dba_indexDefrag_sp

    Author:     Michelle Ufford, http://sqlfool.com

    Purpose:    Defrags one or more indexes for one or more databases

    Notes:

    CAUTION: TRANSACTION LOG SIZE SHOULD BE MONITORED CLOSELY WHEN DEFRAGMENTING.
             DO NOT RUN UNATTENDED ON LARGE DATABASES DURING BUSINESS HOURS.

      @minFragmentation     defaulted to 10%, will not defrag if fragmentation 
                            is less than that
      
      @rebuildThreshold     defaulted to 30% as recommended by Microsoft in BOL;
                            greater than 30% will result in rebuild instead

      @executeSQL           1 = execute the SQL generated by this proc; 
                            0 = print command only

      @defragOrderColumn    Defines how to prioritize the order of defrags.  Only
                            used if @executeSQL = 1.  
                            Valid options are: 
                            range_scan_count = count of range and table scans on the
                                               index; in general, this is what benefits 
                                               the most from defragmentation
                            fragmentation    = amount of fragmentation in the index;
                                               the higher the number, the worse it is
                            page_count       = number of pages in the index; affects
                                               how long it takes to defrag an index

      @defragSortOrder      The sort order of the ORDER BY clause.
                            Valid options are ASC (ascending) or DESC (descending).

      @timeLimit            Optional, limits how much time can be spent performing 
                            index defrags; expressed in minutes.

                            NOTE: The time limit is checked BEFORE an index defrag
                                  is begun, thus a long index defrag can exceed the
                                  time limitation.

      @database             Optional, specify specific database name to defrag;
                            If not specified, all non-system databases will
                            be defragged.

      @tableName            Specify if you only want to defrag indexes for a 
                            specific table, format = databaseName.schema.tableName;
                            if not specified, all tables will be defragged.

      @forceRescan          Whether or not to force a rescan of indexes.  If set
                            to 0, a rescan will not occur until all indexes have
                            been defragged.  This can span multiple executions.
                            1 = force a rescan
                            0 = use previous scan, if there are indexes left to defrag

      @scanMode             Specifies which scan mode to use to determine
                            fragmentation levels.  Options are:
                            LIMITED - scans the parent level; quickest mode,
                                      recommended for most cases.
                            SAMPLED - samples 1% of all data pages; if less than
                                      10k pages, performs a DETAILED scan.
                            DETAILED - scans all data pages.  Use great care with
                                       this mode, as it can cause performance issues.

      @minPageCount         Specifies how many pages must exist in an index in order 
                            to be considered for a defrag.  Defaulted to 8 pages, as 
                            Microsoft recommends only defragging indexes with more 
                            than 1 extent (8 pages).  

                            NOTE: The @minPageCount will restrict the indexes that
                            are stored in dba_indexDefragStatus table.

      @maxPageCount         Specifies the maximum number of pages that can exist in 
                            an index and still be considered for a defrag.  Useful
                            for scheduling small indexes during business hours and
                            large indexes for non-business hours.

                            NOTE: The @maxPageCount will restrict the indexes that
                            are defragged during the current operation; it will not
                            prevent indexes from being stored in the 
                            dba_indexDefragStatus table.  This way, a single scan
                            can support multiple page count thresholds.

      @excludeMaxPartition  If an index is partitioned, this option specifies whether
                            to exclude the right-most populated partition.  Typically,
                            this is the partition that is currently being written to in
                            a sliding-window scenario.  Enabling this feature may reduce
                            contention.  This may not be applicable in other types of 
                            partitioning scenarios.  Non-partitioned indexes are 
                            unaffected by this option.
                            1 = exclude right-most populated partition
                            0 = do not exclude

      @onlineRebuild        1 = online rebuild; 
                            0 = offline rebuild

      @sortInTempDB         Specifies whether to defrag the index in TEMPDB or in the
                            database the index belongs to.  Enabling this option may
                            result in faster defrags and prevent database file size 
                            inflation.
                            1 = perform sort operation in TempDB
                            0 = perform sort operation in the index's database 

      @maxDopRestriction    Option to specify a processor limit for index rebuilds

      @printCommands        1 = print commands to screen; 
                            0 = do not print commands

      @printFragmentation   1 = print fragmentation to screen;
                            0 = do not print fragmentation

      @defragDelay          Time to wait between defrag commands; gives the
                            server a little time to catch up 

      @debugMode            1 = display debug comments; helps with troubleshooting
                            0 = do not display debug comments

    Called by:  SQL Agent Job or DBA

    ----------------------------------------------------------------------------
    DISCLAIMER: 
    This code and information are provided "AS IS" without warranty of any kind,
    either expressed or implied, including but not limited to the implied 
    warranties or merchantability and/or fitness for a particular purpose.
    ----------------------------------------------------------------------------
    LICENSE: 
    This index defrag script is free to download and use for personal, educational, 
    and internal corporate purposes, provided that this header is preserved. 
    Redistribution or sale of this index defrag script, in whole or in part, is 
    prohibited without the author's express written consent.
    ----------------------------------------------------------------------------
    Date        Initials	Version Description
    ----------------------------------------------------------------------------
    2007-12-18  MFU         1.0     Initial Release
    2008-10-17  MFU         1.1     Added @defragDelay, CIX_temp_indexDefragList
    2008-11-17  MFU         1.2     Added page_count to log table
                                    , added @printFragmentation option
    2009-03-17  MFU         2.0     Provided support for centralized execution
                                    , consolidated Enterprise & Standard versions
                                    , added @debugMode, @maxDopRestriction
                                    , modified LOB and partition logic  
    2009-06-18  MFU         3.0     Fixed bug in LOB logic, added @scanMode option
                                    , added support for stat rebuilds (@rebuildStats)
                                    , support model and msdb defrag
                                    , added columns to the dba_indexDefragLog table
                                    , modified logging to show "in progress" defrags
                                    , added defrag exclusion list (scheduling)
    2009-08-28  MFU         3.1     Fixed read_only bug for database lists
    2010-04-20  MFU         4.0     Added time limit option
                                    , added static table with rescan logic
                                    , added parameters for page count & SORT_IN_TEMPDB
                                    , added try/catch logic and additional debug options
                                    , added options for defrag prioritization
                                    , fixed bug for indexes with allow_page_lock = off
                                    , added option to exclude right-most partition
                                    , removed @rebuildStats option
                                    , refer to http://sqlfool.com for full release notes
*********************************************************************************
    Example of how to call this script:

        Exec dbo.dba_indexDefrag_sp
              @executeSQL           = 1
            , @printCommands        = 1
            , @debugMode            = 1
            , @printFragmentation   = 1
            , @forceRescan          = 1
            , @maxDopRestriction    = 1
            , @minPageCount         = 8
            , @maxPageCount         = Null
            , @minFragmentation     = 1
            , @rebuildThreshold     = 30
            , @defragDelay          = '00:00:05'
            , @defragOrderColumn    = 'page_count'
            , @defragSortOrder      = 'DESC'
            , @excludeMaxPartition  = 1
            , @timeLimit            = Null;
*********************************************************************************/																
Set NoCount On;
Set XACT_Abort On;
Set Quoted_Identifier On;

Begin

    Begin Try

        /* Just a little validation... */
        If @minFragmentation Is Null 
            Or @minFragmentation Not Between 0.00 And 100.0
                Set @minFragmentation = 10.0;

        If @rebuildThreshold Is Null
            Or @rebuildThreshold Not Between 0.00 And 100.0
                Set @rebuildThreshold = 30.0;

        If @defragDelay Not Like '00:[0-5][0-9]:[0-5][0-9]'
            Set @defragDelay = '00:00:05';

        If @defragOrderColumn Is Null
            Or @defragOrderColumn Not In ('range_scan_count', 'fragmentation', 'page_count')
                Set @defragOrderColumn = 'range_scan_count';

        If @defragSortOrder Is Null
            Or @defragSortOrder Not In ('ASC', 'DESC')
                Set @defragSortOrder = 'DESC';

        If @scanMode Not In ('LIMITED', 'SAMPLED', 'DETAILED')
            Set @scanMode = 'LIMITED';

        If @debugMode Is Null
            Set @debugMode = 0;

        If @forceRescan Is Null
            Set @forceRescan = 0;

        If @sortInTempDB Is Null
            Set @sortInTempDB = 1;


        If @debugMode = 1 RaisError('Undusting the cogs and starting up...', 0, 42) With NoWait;

        /* Declare our variables */
        Declare   @objectID                 int
                , @databaseID               int
                , @databaseName             nvarchar(128)
                , @indexID                  int
                , @partitionCount           bigint
                , @schemaName               nvarchar(128)
                , @objectName               nvarchar(128)
                , @indexName                nvarchar(128)
                , @partitionNumber          smallint
                , @fragmentation            float
                , @pageCount                int
                , @sqlCommand               nvarchar(4000)
                , @rebuildCommand           nvarchar(200)
                , @dateTimeStart            datetime
                , @dateTimeEnd              datetime
                , @containsLOB              bit
                , @editionCheck             bit
                , @debugMessage             nvarchar(4000)
                , @updateSQL                nvarchar(4000)
                , @partitionSQL             nvarchar(4000)
                , @partitionSQL_Param       nvarchar(1000)
                , @LOB_SQL                  nvarchar(4000)
                , @LOB_SQL_Param            nvarchar(1000)
                , @indexDefrag_id           int
                , @startDateTime            datetime
                , @endDateTime              datetime
                , @getIndexSQL              nvarchar(4000)
                , @getIndexSQL_Param        nvarchar(4000)
                , @allowPageLockSQL         nvarchar(4000)
                , @allowPageLockSQL_Param   nvarchar(4000)
                , @allowPageLocks           int
                , @excludeMaxPartitionSQL   nvarchar(4000);

        /* Initialize our variables */
        Select @startDateTime = GetDate()
            , @endDateTime = DateAdd(minute, @timeLimit, GetDate());

        /* Create our temporary tables */
        Create Table #databaseList
        (
              databaseID        int
            , databaseName      varchar(128)
            , scanStatus        bit
        );

        Create Table #processor 
        (
              [index]           int
            , Name              varchar(128)
            , Internal_Value    int
            , Character_Value   int
        );

        Create Table #maxPartitionList
        (
              databaseID        int
            , objectID          int
            , indexID           int
            , maxPartition      int
        );

        If @debugMode = 1 RaisError('Beginning validation...', 0, 42) With NoWait;

        /* Make sure we're not exceeding the number of processors we have available */
        Insert Into #processor
        Execute xp_msver 'ProcessorCount';

        If @maxDopRestriction Is Not Null And @maxDopRestriction > (Select Internal_Value From #processor)
            Select @maxDopRestriction = Internal_Value
            From #processor;

        /* Check our server version; 1804890536 = Enterprise, 610778273 = Enterprise Evaluation, -2117995310 = Developer */
        If (Select ServerProperty('EditionID')) In (1804890536, 610778273, -2117995310) 
            Set @editionCheck = 1 -- supports online rebuilds
        Else
            Set @editionCheck = 0; -- does not support online rebuilds

        /* Output the parameters we're working with */
        If @debugMode = 1 
        Begin

            Select @debugMessage = 'Your selected parameters are... 
            Defrag indexes with fragmentation greater than ' + Cast(@minFragmentation As varchar(10)) + ';
            Rebuild indexes with fragmentation greater than ' + Cast(@rebuildThreshold As varchar(10)) + ';
            You' + Case When @executeSQL = 1 Then ' DO' Else ' DO NOT' End + ' want the commands to be executed automatically; 
            You want to defrag indexes in ' + @defragSortOrder + ' order of the ' + UPPER(@defragOrderColumn) + ' value;
            You have' + Case When @timeLimit Is Null Then ' not specified a time limit;' Else ' specified a time limit of ' 
                + Cast(@timeLimit As varchar(10)) End + ' minutes;
            ' + Case When @database Is Null Then 'ALL databases' Else 'The ' + @database + ' database' End + ' will be defragged;
            ' + Case When @tableName Is Null Then 'ALL tables' Else 'The ' + @tableName + ' table' End + ' will be defragged;
            We' + Case When Exists(Select Top 1 * From dbo.dba_indexDefragStatus Where defragDate Is Null)
                And @forceRescan <> 1 Then ' WILL NOT' Else ' WILL' End + ' be rescanning indexes;
            The scan will be performed in ' + @scanMode + ' mode;
            You want to limit defrags to indexes with' + Case When @maxPageCount Is Null Then ' more than ' 
                + Cast(@minPageCount As varchar(10)) Else
                ' between ' + Cast(@minPageCount As varchar(10))
                + ' and ' + Cast(@maxPageCount As varchar(10)) End + ' pages;
            Indexes will be defragged' + Case When @editionCheck = 0 Or @onlineRebuild = 0 Then ' OFFLINE;' Else ' ONLINE;' End + '
            Indexes will be sorted in' + Case When @sortInTempDB = 0 Then ' the DATABASE' Else ' TEMPDB;' End + '
            Defrag operations will utilize ' + Case When @editionCheck = 0 Or @maxDopRestriction Is Null 
                Then 'system defaul