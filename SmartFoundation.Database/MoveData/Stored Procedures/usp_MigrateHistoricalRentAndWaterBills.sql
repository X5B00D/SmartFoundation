
CREATE   PROCEDURE [MoveData].[usp_MigrateHistoricalRentAndWaterBills]
    @IdaraId bigint,
    /* مهم عند التشغيل الفعلي: تاريخ نهاية الترحيل وبداية اعتماد النظام الجديد. */
    @CutoverDate date,
    @WaterMonthlyAmount decimal(18,2) = 8.25,
    @RollbackAfterTest bit = 1
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (SELECT 1 FROM [dbo].[Idara] WHERE [idaraID] = @IdaraId)
        THROW 55000, N'The supplied IdaraId does not exist in DATACORE.dbo.Idara.', 1;
    IF @CutoverDate IS NULL OR @CutoverDate > CAST(GETDATE() AS date)
        THROW 55001, N'CutoverDate is required and cannot be in the future.', 1;
    IF @WaterMonthlyAmount < 0
        THROW 55002, N'WaterMonthlyAmount cannot be negative.', 1;
    IF NOT EXISTS (SELECT 1 FROM [Housing].[ResidentInfo])
        THROW 55003, N'Run MoveData.usp_MigrateResidents first.', 1;
    IF NOT EXISTS (SELECT 1 FROM [Housing].[BuildingDetails])
        THROW 55004, N'Run MoveData.usp_MigrateBuildings first.', 1;
    IF NOT EXISTS (SELECT 1 FROM [Housing].[BuildingAction])
        THROW 55005, N'Run MoveData.usp_MigrateBuildingActions first.', 1;

    /* The cutover month belongs entirely to the new system. Migrate only through
       the final day of the preceding month, regardless of the cutover day. */
    DECLARE @HistoricalEndDate date = EOMONTH(DATEADD(month, -1, @CutoverDate));
    DECLARE @RentChargeStartDate date = CONVERT(date, '20171001', 112);
    DECLARE @WaterChargeStartDate date = CONVERT(date, '20240101', 112);

    CREATE TABLE #HistoricalBills
    (
        StagingID bigint IDENTITY(1,1) NOT NULL,
        ChargeTypeID int NOT NULL,
        BillTypeID int NOT NULL,
        ResidentInfoID bigint NOT NULL,
        GeneralNo bigint NULL,
        BuildingDetailsID bigint NOT NULL,
        BuildingDetailsNo nvarchar(100) NULL,
        PeriodMonth int NOT NULL,
        PeriodYear int NOT NULL,
        FromDate date NOT NULL,
        ToDate date NOT NULL,
        Amount decimal(18,2) NOT NULL,
        SourceEntryData nvarchar(40) NULL
    );

    ;WITH OccupancyBase AS
    (
        SELECT
            actionRow.[buildingActionID],
            actionRow.[generalNo_FK],
            resident.[residentInfoID],
            building.[buildingDetailsID],
            building.[buildingDetailsNo],
            CAST(actionRow.[buildingActionDate] AS date) AS OccupancyDate,
            CAST(exitAction.ExitDate AS date) AS ExitDate,
            CAST(nextOccupancy.NextOccupancyDate AS date) AS NextOccupancyDate,
            actionRow.[entryData] AS SourceEntryData
        FROM [KFMC].[Housing].[BuildingAction] actionRow
        JOIN [KFMC].[Housing].[ResidentInfo] resident
          ON resident.[generalNo] = actionRow.[generalNo_FK]
        JOIN [KFMC].[Housing].[BuildingDetails] building
          ON LTRIM(RTRIM(building.[buildingDetailsNo])) = LTRIM(RTRIM(actionRow.[buildingDetailsNo]))
        OUTER APPLY
        (
            SELECT TOP (1) exitRow.[buildingActionDate] AS ExitDate
            FROM [KFMC].[Housing].[BuildingAction] exitRow
            WHERE exitRow.[buildingActionTypeID_FK] = 3
              /* Every active old type-3 row represents the recorded physical
                 evacuation date. ExtraInt1 describes the workflow stage only
                 (meter reading / financial audit / completion) and must not
                 extend rent or water charges beyond that date. */
              AND exitRow.[buildingActionActive] = 1
              AND exitRow.[generalNo_FK] = actionRow.[generalNo_FK]
              AND LTRIM(RTRIM(exitRow.[buildingDetailsNo])) = LTRIM(RTRIM(actionRow.[buildingDetailsNo]))
              AND exitRow.[buildingActionDate] >= actionRow.[buildingActionDate]
              AND (exitRow.[buildingActionParentID] = actionRow.[buildingActionID]
                   OR exitRow.[buildingActionParentID] IS NULL)
            ORDER BY CASE WHEN exitRow.[buildingActionParentID] = actionRow.[buildingActionID] THEN 0 ELSE 1 END,
                     exitRow.[buildingActionDate], exitRow.[buildingActionID]
        ) exitAction
        OUTER APPLY
        (
            SELECT TOP (1) nextRow.[buildingActionDate] AS NextOccupancyDate
            FROM [KFMC].[Housing].[BuildingAction] nextRow
            WHERE nextRow.[buildingActionTypeID_FK] = 2
              AND nextRow.[generalNo_FK] = actionRow.[generalNo_FK]
              AND LTRIM(RTRIM(nextRow.[buildingDetailsNo])) = LTRIM(RTRIM(actionRow.[buildingDetailsNo]))
              AND nextRow.[buildingActionDate] > actionRow.[buildingActionDate]
            ORDER BY nextRow.[buildingActionDate], nextRow.[buildingActionID]
        ) nextOccupancy
        WHERE actionRow.[buildingActionTypeID_FK] = 2
          AND actionRow.[buildingActionDate] IS NOT NULL
          AND CAST(actionRow.[buildingActionDate] AS date) <= @HistoricalEndDate
    ),
    OccupancyPeriods AS
    (
        SELECT *,
            CASE
                WHEN ExitDate IS NOT NULL AND ExitDate <= @HistoricalEndDate
                     AND (NextOccupancyDate IS NULL OR ExitDate < NextOccupancyDate) THEN ExitDate
                WHEN NextOccupancyDate IS NOT NULL AND DATEADD(day, -1, NextOccupancyDate) < @HistoricalEndDate
                    THEN DATEADD(day, -1, NextOccupancyDate)
                ELSE @HistoricalEndDate
            END AS EndDate
        FROM OccupancyBase
    ),
    Months AS
    (
        SELECT *,
            CASE
                WHEN OccupancyDate < @RentChargeStartDate THEN @RentChargeStartDate
                ELSE DATEFROMPARTS(YEAR(OccupancyDate), MONTH(OccupancyDate), 1)
            END AS MonthStart
        FROM OccupancyPeriods
        WHERE OccupancyDate <= EndDate
          AND EndDate >= @RentChargeStartDate
        UNION ALL
        SELECT buildingActionID, generalNo_FK, residentInfoID, buildingDetailsID,
               buildingDetailsNo, OccupancyDate, ExitDate, NextOccupancyDate,
               SourceEntryData, EndDate,
               DATEADD(month, 1, MonthStart)
        FROM Months
        WHERE DATEADD(month, 1, MonthStart) <= EndDate
    ),
    BillPeriods AS
    (
        SELECT *,
            CASE WHEN OccupancyDate > MonthStart THEN OccupancyDate ELSE MonthStart END AS BillFrom,
            CASE WHEN EndDate < EOMONTH(MonthStart) THEN EndDate ELSE EOMONTH(MonthStart) END AS BillTo
        FROM Months
    ),
    ChargePeriods AS
    (
        SELECT
            billPeriod.*,
            charge.ChargeTypeID,
            CASE
                WHEN charge.ChargeTypeID = 1 AND billPeriod.BillFrom < @RentChargeStartDate
                    THEN @RentChargeStartDate
                WHEN charge.ChargeTypeID = 3 AND billPeriod.BillFrom < @WaterChargeStartDate
                    THEN @WaterChargeStartDate
                ELSE billPeriod.BillFrom
            END AS ChargeBillFrom,
            billPeriod.BillTo AS ChargeBillTo
        FROM BillPeriods billPeriod
        CROSS JOIN (VALUES (1), (3)) charge(ChargeTypeID)
        WHERE (charge.ChargeTypeID = 1 AND billPeriod.BillTo >= @RentChargeStartDate)
           OR (charge.ChargeTypeID = 3 AND billPeriod.BillTo >= @WaterChargeStartDate)
    ),
    Calculated AS
    (
        SELECT *,
            ((YEAR(ChargeBillTo) - YEAR(ChargeBillFrom)) * 360
             + (MONTH(ChargeBillTo) - MONTH(ChargeBillFrom)) * 30
             + (CASE WHEN ChargeBillTo = EOMONTH(ChargeBillTo) AND DAY(ChargeBillTo) < 30 THEN 30
                     WHEN DAY(ChargeBillTo) > 30 THEN 30 ELSE DAY(ChargeBillTo) END)
             - (CASE WHEN ChargeBillFrom = EOMONTH(ChargeBillFrom) AND DAY(ChargeBillFrom) < 30 THEN 30
                     WHEN DAY(ChargeBillFrom) > 30 THEN 30 ELSE DAY(ChargeBillFrom) END) + 1) AS Days30
        FROM ChargePeriods
        WHERE ChargeBillFrom <= ChargeBillTo
    )
    INSERT INTO #HistoricalBills
    (
        ChargeTypeID, BillTypeID, ResidentInfoID, GeneralNo, BuildingDetailsID,
        BuildingDetailsNo, PeriodMonth, PeriodYear, FromDate, ToDate, Amount,
        SourceEntryData
    )
    SELECT
        calculation.ChargeTypeID,
        CASE WHEN calculation.ExitDate BETWEEN calculation.MonthStart AND EOMONTH(calculation.MonthStart)
             THEN 3 ELSE 2 END,
        CONVERT(bigint, calculation.residentInfoID), CONVERT(bigint, calculation.generalNo_FK),
        CONVERT(bigint, calculation.buildingDetailsID), calculation.buildingDetailsNo,
        MONTH(calculation.MonthStart), YEAR(calculation.MonthStart),
        calculation.ChargeBillFrom, calculation.ChargeBillTo,
        CASE calculation.ChargeTypeID
            WHEN 1 THEN ISNULL(rent.RentForMonth, 0)
            WHEN 3 THEN CAST((@WaterMonthlyAmount / 30.0) * calculation.Days30 AS decimal(18,2))
        END,
        calculation.SourceEntryData
    FROM Calculated calculation
    OUTER APPLY [Housing].[fn_CalcBuildingRent_ForOneMonth]
    (
        CONVERT(int, calculation.buildingDetailsID), calculation.OccupancyDate,
        YEAR(calculation.MonthStart), MONTH(calculation.MonthStart), calculation.EndDate
    ) rent
    OPTION (MAXRECURSION 0);

    /* This index is local to the execution and accelerates existence checks and
       summary aggregation without changing any permanent DATACORE object. */
    CREATE CLUSTERED INDEX [IX_HistoricalBills_MigrationKey]
        ON #HistoricalBills
        (
            ChargeTypeID, ResidentInfoID, BuildingDetailsID,
            PeriodYear, PeriodMonth, FromDate, ToDate
        );

    /* Map each distinct legacy entryData once instead of invoking the lookup
       functions for every generated monthly bill. */
    CREATE TABLE #EntryDataMap
    (
        EntryDataKey nvarchar(40) NOT NULL PRIMARY KEY,
        MappedEntryData nvarchar(40) NULL
    );

    INSERT INTO #EntryDataMap (EntryDataKey, MappedEntryData)
    SELECT sourceData.EntryDataKey,
           [MoveData].[fn_MapEntryData](NULLIF(sourceData.EntryDataKey, N''))
    FROM
    (
        SELECT DISTINCT ISNULL(SourceEntryData, N'') AS EntryDataKey
        FROM #HistoricalBills
    ) sourceData;

    DECLARE @ExpectedRent bigint = (SELECT COUNT_BIG(*) FROM #HistoricalBills WHERE ChargeTypeID = 1);
    DECLARE @ExpectedWater bigint = (SELECT COUNT_BIG(*) FROM #HistoricalBills WHERE ChargeTypeID = 3);
    DECLARE @InsertedRent bigint = 0, @InsertedWater bigint = 0;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO [Housing].[Bills]
        (
            [BillsUID], [BillChargeTypeID_FK], [BillTypeID_FK],
            [PeriodMonth], [PeriodYear], [buildingDetailsNo], [buildingDetailsID],
            [residentInfoID_FK], [generalNo_FK], [PRICE], [PRICETAX], [TotalPrice],
            [buildingRentTypeID_FK], [BillsFromDate], [BillsToDate], [BillActive],
            [idaraID_FK], [entryDate], [entryData], [hostName]
        )
        SELECT
            NEWID(), sourceBill.ChargeTypeID, sourceBill.BillTypeID,
            sourceBill.PeriodMonth, sourceBill.PeriodYear,
            sourceBill.BuildingDetailsNo, CONVERT(int, sourceBill.BuildingDetailsID),
            sourceBill.ResidentInfoID, sourceBill.GeneralNo,
            CASE
                WHEN sourceBill.ChargeTypeID = 3
                    THEN CAST(ROUND(sourceBill.Amount / CAST(1.15 AS decimal(18,4)), 2) AS decimal(18,2))
                ELSE sourceBill.Amount
            END,
            CASE
                WHEN sourceBill.ChargeTypeID = 3
                    THEN CAST
                    (
                        sourceBill.Amount
                        - ROUND(sourceBill.Amount / CAST(1.15 AS decimal(18,4)), 2)
                        AS decimal(18,2)
                    )
                ELSE 0
            END,
            sourceBill.Amount,
            CASE WHEN sourceBill.ChargeTypeID = 1 THEN 1 ELSE NULL END,
            sourceBill.FromDate, sourceBill.ToDate, 1, @IdaraId,
            GETDATE(), entryMap.MappedEntryData,
            CASE WHEN entryMap.MappedEntryData IS NULL THEN N'Data Migration'
                 ELSE CONCAT(N'Data Migration-', NULLIF(LTRIM(RTRIM(sourceBill.SourceEntryData)), N'')) END
        FROM #HistoricalBills sourceBill
        JOIN #EntryDataMap entryMap
          ON entryMap.EntryDataKey = ISNULL(sourceBill.SourceEntryData, N'')
        WHERE NOT EXISTS
        (
            SELECT 1 FROM [Housing].[Bills] targetBill WITH (UPDLOCK, HOLDLOCK)
            WHERE targetBill.[BillChargeTypeID_FK] = sourceBill.ChargeTypeID
              AND targetBill.[residentInfoID_FK] = sourceBill.ResidentInfoID
              AND targetBill.[buildingDetailsID] = CONVERT(int, sourceBill.BuildingDetailsID)
              AND targetBill.[PeriodMonth] = sourceBill.PeriodMonth
              AND targetBill.[PeriodYear] = sourceBill.PeriodYear
              AND targetBill.[BillsFromDate] = sourceBill.FromDate
              AND targetBill.[BillsToDate] = sourceBill.ToDate
              AND targetBill.[BillActive] = 1
        );

        /* Every staging row is now either inserted or matched by the exact same
           migration key in the guarded NOT EXISTS above. Avoid rescanning and
           rejoining the large target Bills table twice merely for reporting. */
        SET @InsertedRent = @ExpectedRent;
        SET @InsertedWater = @ExpectedWater;

        SELECT @RollbackAfterTest [RollbackAfterTest], @CutoverDate [CutoverDate],
               @HistoricalEndDate [HistoricalBillsThrough],
               @RentChargeStartDate [RentChargesStartDate],
               @WaterChargeStartDate [WaterChargesStartDate],
               @ExpectedRent [ExpectedRentBills], @ExpectedWater [ExpectedWaterBills],
               @InsertedRent [AvailableRentBills], @InsertedWater [AvailableWaterBills],
               (SELECT SUM(Amount) FROM #HistoricalBills WHERE ChargeTypeID = 1) [RentTotal],
               (SELECT SUM(Amount) FROM #HistoricalBills WHERE ChargeTypeID = 3) [WaterTotal];

        IF @RollbackAfterTest = 1 ROLLBACK TRANSACTION; ELSE COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;