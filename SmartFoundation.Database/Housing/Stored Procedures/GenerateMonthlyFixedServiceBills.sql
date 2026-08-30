CREATE PROCEDURE [Housing].[GenerateMonthlyFixedServiceBills]
(
      @Month INT
    , @Year INT
    , @EntryData NVARCHAR(20)
    , @HostName NVARCHAR(200)
    , @IdaraID BIGINT
    , @MeterServiceTypeID INT = NULL
    , @CalculationMethod NVARCHAR(30) = NULL
    , @ReturnResult BIT = 1
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @Month NOT BETWEEN 1 AND 12 OR @Year NOT BETWEEN 1900 AND 9999 OR @IdaraID IS NULL
    BEGIN
        ;THROW 50001, N'بيانات شهر رصد الخدمات الثابتة غير صحيحة', 1;
    END;

    DECLARE @MonthStart DATE = DATEFROMPARTS(@Year, @Month, 1);
    DECLARE @MonthEnd DATE = EOMONTH(@MonthStart);

    IF @MonthEnd >= EOMONTH(GETDATE())
    BEGIN
        ;THROW 50001, N'لا يمكن رصد الخدمات الثابتة قبل اكتمال شهر الفوترة', 1;
    END;

    DECLARE @ResidentInfoID BIGINT, @GeneralNo BIGINT, @BuildingDetailsID BIGINT,
            @OccupentDate DATE, @ExitDate DATE, @ChargeFromDate DATE, @ChargeToDate DATE;

    DECLARE residentCursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT DISTINCT occupant.residentInfoID, occupant.GeneralNo, occupant.buildingDetailsID,
                    CAST(occupant.OccupentDate AS date), CAST(occupant.ExitDate AS date)
    FROM Housing.V_Occupant occupant
    WHERE occupant.IdaraId = @IdaraID
      AND CAST(occupant.OccupentDate AS date) <= @MonthEnd
      AND (occupant.ExitDate IS NULL OR CAST(occupant.ExitDate AS date) >= @MonthStart)
      AND
      (
          @MeterServiceTypeID IS NULL
          OR @CalculationMethod = N'METER_FIXED'
          OR EXISTS
          (
              SELECT 1
              FROM Housing.BuildingDetailsMeterServices buildingService
              WHERE buildingService.BuildingDetailsID_FK = occupant.buildingDetailsID
                AND buildingService.IdaraId_FK = @IdaraID
                AND buildingService.MeterServicesTypeID_FK = @MeterServiceTypeID
                AND (buildingService.BuildingDetailsMeterServicesActive = 1
                     OR buildingService.BuildingDetailsMeterServicesEndDate IS NOT NULL)
                AND (buildingService.BuildingDetailsMeterServicesStartDate IS NULL
                     OR CAST(buildingService.BuildingDetailsMeterServicesStartDate AS date) <= @MonthEnd)
                AND (buildingService.BuildingDetailsMeterServicesEndDate IS NULL
                     OR CAST(buildingService.BuildingDetailsMeterServicesEndDate AS date) >= @MonthStart)
          )
      )
      AND
      (
          @CalculationMethod IS NULL
          OR (@CalculationMethod = N'METER_FIXED' AND EXISTS
          (
              SELECT 1
              FROM Housing.MeterForBuilding meterLink
              JOIN Housing.Meter meter ON meter.meterID = meterLink.meterID_FK
              JOIN Housing.MeterType meterType ON meterType.meterTypeID = meter.meterTypeID_FK
              WHERE meterLink.buildingDetailsID_FK = occupant.buildingDetailsID
                AND meterLink.IdaraID_FK = @IdaraID
                AND meterType.meterServiceTypeID_FK = @MeterServiceTypeID
                AND meterType.MeterCalculateTypeID_FK = 2
          ))
          OR (@CalculationMethod = N'SERVICE_FIXED' AND NOT EXISTS
          (
              SELECT 1
              FROM Housing.MeterForBuilding meterLink
              JOIN Housing.Meter meter ON meter.meterID = meterLink.meterID_FK
              JOIN Housing.MeterType meterType ON meterType.meterTypeID = meter.meterTypeID_FK
              WHERE meterLink.buildingDetailsID_FK = occupant.buildingDetailsID
                AND meterLink.IdaraID_FK = @IdaraID
                AND meterType.meterServiceTypeID_FK = @MeterServiceTypeID
                AND meterType.MeterCalculateTypeID_FK IN (1,2)
          ))
      );

    BEGIN TRY
        BEGIN TRANSACTION;
        OPEN residentCursor;
        FETCH NEXT FROM residentCursor INTO @ResidentInfoID, @GeneralNo, @BuildingDetailsID, @OccupentDate, @ExitDate;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @ChargeFromDate = CASE WHEN @OccupentDate > @MonthStart THEN @OccupentDate ELSE @MonthStart END;
            SET @ChargeToDate = CASE WHEN @ExitDate IS NOT NULL AND @ExitDate < @MonthEnd THEN @ExitDate ELSE @MonthEnd END;

            EXEC Housing.GenerateFixedServiceBillsForResidentPeriod
                  @ResidentInfoID = @ResidentInfoID, @GeneralNo = @GeneralNo
                , @BuildingDetailsID = @BuildingDetailsID
                , @FromDate = @ChargeFromDate
                , @ToDate = @ChargeToDate
                , @IdaraID = @IdaraID, @EntryData = @EntryData, @HostName = @HostName
                , @MeterServiceTypeID = @MeterServiceTypeID
                , @CalculationMethod = @CalculationMethod;

            FETCH NEXT FROM residentCursor INTO @ResidentInfoID, @GeneralNo, @BuildingDetailsID, @OccupentDate, @ExitDate;
        END;

        CLOSE residentCursor;
        DEALLOCATE residentCursor;
        COMMIT TRANSACTION;

        IF @ReturnResult=1
            SELECT 1 AS IsSuccessful, N'تم رصد فواتير الخدمات الثابتة الناقصة بنجاح' AS Message_;
    END TRY
    BEGIN CATCH
        IF CURSOR_STATUS('local', 'residentCursor') >= 0 CLOSE residentCursor;
        IF CURSOR_STATUS('local', 'residentCursor') >= -1 DEALLOCATE residentCursor;
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
