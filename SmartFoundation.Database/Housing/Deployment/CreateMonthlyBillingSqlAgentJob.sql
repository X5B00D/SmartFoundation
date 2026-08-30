USE [msdb];
GO

DECLARE @JobName sysname=N'SmartFoundation - Monthly Housing Billing';
DECLARE @JobID uniqueidentifier;

IF NOT EXISTS (SELECT 1 FROM dbo.sysjobs WHERE name=@JobName)
BEGIN
    EXEC dbo.sp_add_job
          @job_name=@JobName
        , @enabled=0
        , @description=N'يرصد إيجارات وخدمات الشهر السابق لجميع الإدارات يوم 1 من الشهر. ينشأ متوقفاً حتى الاعتماد.'
        , @job_id=@JobID OUTPUT;

    EXEC dbo.sp_add_jobstep
          @job_id=@JobID
        , @step_name=N'Generate previous month bills'
        , @subsystem=N'TSQL'
        , @database_name=N'DATACORE'
        , @command=N'EXEC Housing.GenerateAllAdministrationsMonthlyBills @Month=NULL,@Year=NULL,@EntryData=N''4'',@HostName=N''SQL_AGENT_MONTHLY_BILLING'',@RetryFailed=1;'
        , @retry_attempts=3
        , @retry_interval=15
        , @on_success_action=1
        , @on_fail_action=2;

    EXEC dbo.sp_add_schedule
          @schedule_name=N'SmartFoundation Monthly Billing - Day 1'
        , @enabled=0
        , @freq_type=16
        , @freq_interval=1
        , @freq_recurrence_factor=1
        , @active_start_time=020000;

    EXEC dbo.sp_attach_schedule
          @job_id=@JobID
        , @schedule_name=N'SmartFoundation Monthly Billing - Day 1';

    EXEC dbo.sp_add_jobserver @job_id=@JobID;
END;
GO
