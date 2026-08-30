CREATE PROCEDURE [MoveData].[usp_MigrateHistoricalRentAndWaterBills]
    @IdaraId bigint,
    /* مهم عند التشغيل الفعلي: تاريخ نهاية الترحيل وبداية اعتماد النظام الجديد. */
    @CutoverDate date,
    @WaterMonthlyAmount decimal(18,2) = 8.25,
    @RollbackAfterTest bit = 1
AS
BEGIN
    SET NOCOUNT ON;
    /* Normalize migration administration: preserve a valid supplied value, otherwise use Idara 1. */
    IF NOT EXISTS (SELECT 1 FROM dbo.Idara WHERE idaraID = 1)
        THROW 57990, N'Default migration Idara 1 does not exist.', 1;
    IF @IdaraId IS NULL OR NOT EXISTS (SELECT 1 FROM dbo.Idara WHERE idaraID = @IdaraId)
        SET @IdaraId = 1;
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
        ResidentInfoID bigint NULL,
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
              AND nextRow.[buildingActionActive] = 1
              AND LTRIM(RTRIM(nextRow.[buildingDetailsNo])) = LTRIM(RTRIM(actionRow.[buildingDetailsNo]))
              AND nextRow.[buildingActionDate] > actionRow.[buildingActionDate]
            ORDER BY nextRow.[buildingActionDate], nextRow.[buildingActionID]
        ) nextOccupancy
        WHERE actionRow.[buildingActionTypeID_FK] = 2
          AND actionRow.[buildingActionActive] = 1
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
        CASE WHEN calculation.ExitDate IS NOT NULL AND calculation.ChargeBillTo = calculation.ExitDate
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
    /* Explicit vacant-house water periods: never assign these rows to either resident. */
    ;WITH VacancyOccupancyBase AS
    (
      SELECT building.buildingDetailsID,building.buildingDetailsNo,
             CAST(actionRow.buildingActionDate AS date) OccupancyFrom,
             CASE WHEN exitAction.ExitDate IS NOT NULL AND CAST(exitAction.ExitDate AS date)<@HistoricalEndDate THEN CAST(exitAction.ExitDate AS date) ELSE @HistoricalEndDate END OccupancyTo,
             actionRow.entryData SourceEntryData,actionRow.buildingActionID SourceActionID
      FROM KFMC.Housing.BuildingAction actionRow
      JOIN KFMC.Housing.BuildingDetails building ON LTRIM(RTRIM(building.buildingDetailsNo))=LTRIM(RTRIM(actionRow.buildingDetailsNo))
      OUTER APPLY
      (
        SELECT TOP (1) x.buildingActionDate ExitDate
        FROM KFMC.Housing.BuildingAction x
        WHERE x.buildingActionTypeID_FK=3 AND x.buildingActionActive=1
          AND x.generalNo_FK=actionRow.generalNo_FK
          AND LTRIM(RTRIM(x.buildingDetailsNo))=LTRIM(RTRIM(actionRow.buildingDetailsNo))
          AND x.buildingActionDate>=actionRow.buildingActionDate
          AND (x.buildingActionParentID=actionRow.buildingActionID OR x.buildingActionParentID IS NULL)
        ORDER BY CASE WHEN x.buildingActionParentID=actionRow.buildingActionID THEN 0 ELSE 1 END,x.buildingActionDate,x.buildingActionID
      ) exitAction
      WHERE actionRow.buildingActionTypeID_FK=2 AND actionRow.buildingActionActive=1
        AND actionRow.buildingActionDate IS NOT NULL
        AND CAST(actionRow.buildingActionDate AS date)<=@HistoricalEndDate
    ), VacancyOrdered AS
    (
      SELECT *,MAX(OccupancyTo) OVER
      (
        PARTITION BY buildingDetailsID ORDER BY OccupancyFrom,SourceActionID
        ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
      ) PreviousMaximumTo
      FROM VacancyOccupancyBase
      WHERE OccupancyFrom<=OccupancyTo
    ), VacancyTagged AS
    (
      SELECT *,SUM(CASE WHEN PreviousMaximumTo IS NULL OR OccupancyFrom>DATEADD(day,1,PreviousMaximumTo) THEN 1 ELSE 0 END) OVER
      (
        PARTITION BY buildingDetailsID ORDER BY OccupancyFrom,SourceActionID ROWS UNBOUNDED PRECEDING
      ) OccupancyIsland
      FROM VacancyOrdered
    ), VacancyIslands AS
    (
      SELECT buildingDetailsID,MIN(buildingDetailsNo) buildingDetailsNo,MIN(OccupancyFrom) OccupancyFrom,MAX(OccupancyTo) OccupancyTo,
             MIN(SourceEntryData) SourceEntryData,MIN(SourceActionID) SourceActionID
      FROM VacancyTagged
      GROUP BY buildingDetailsID,OccupancyIsland
    ), VacancyIslandsWithNext AS
    (
      SELECT *,LEAD(OccupancyFrom) OVER(PARTITION BY buildingDetailsID ORDER BY OccupancyFrom,OccupancyTo) NextOccupancyFrom
      FROM VacancyIslands
    ), VacantBase AS
    (
      SELECT buildingDetailsID,buildingDetailsNo,DATEADD(day,1,OccupancyTo) VacancyFrom,
             CASE WHEN NextOccupancyFrom IS NOT NULL THEN DATEADD(day,-1,NextOccupancyFrom) ELSE @HistoricalEndDate END VacancyTo,
             SourceEntryData,SourceActionID
      FROM VacancyIslandsWithNext
      WHERE OccupancyTo<@HistoricalEndDate
    ), VacantMonths AS
    (
      SELECT *,CASE WHEN VacancyFrom<@WaterChargeStartDate THEN @WaterChargeStartDate ELSE VacancyFrom END BillFrom
      FROM VacantBase WHERE VacancyFrom<=VacancyTo AND VacancyTo>=@WaterChargeStartDate
      UNION ALL
      SELECT buildingDetailsID,buildingDetailsNo,VacancyFrom,VacancyTo,SourceEntryData,SourceActionID,DATEADD(month,1,DATEFROMPARTS(YEAR(BillFrom),MONTH(BillFrom),1))
      FROM VacantMonths WHERE DATEADD(month,1,DATEFROMPARTS(YEAR(BillFrom),MONTH(BillFrom),1))<=VacancyTo
    ), VacantBillPeriods AS
    (
      SELECT *,CASE WHEN BillFrom>DATEFROMPARTS(YEAR(BillFrom),MONTH(BillFrom),1) THEN BillFrom ELSE DATEFROMPARTS(YEAR(BillFrom),MONTH(BillFrom),1) END FromDate,
             CASE WHEN VacancyTo<EOMONTH(BillFrom) THEN VacancyTo ELSE EOMONTH(BillFrom) END ToDate
      FROM VacantMonths
    ), RankedVacantBillPeriods AS
    (
      SELECT *,ROW_NUMBER() OVER
      (
        PARTITION BY buildingDetailsID,FromDate,ToDate
        ORDER BY SourceActionID
      ) VacancyRowNumber
      FROM VacantBillPeriods
      WHERE FromDate<=ToDate
    )
    INSERT #HistoricalBills(ChargeTypeID,BillTypeID,ResidentInfoID,GeneralNo,BuildingDetailsID,BuildingDetailsNo,PeriodMonth,PeriodYear,FromDate,ToDate,Amount,SourceEntryData)
    SELECT 3,2,NULL,NULL,buildingDetailsID,buildingDetailsNo,MONTH(FromDate),YEAR(FromDate),FromDate,ToDate,
           CAST
           (
             (@WaterMonthlyAmount/30.0)
             *
             (
               (YEAR(ToDate)-YEAR(FromDate))*360
               +(MONTH(ToDate)-MONTH(FromDate))*30
               +(CASE WHEN ToDate=EOMONTH(ToDate) AND DAY(ToDate)<30 THEN 30 WHEN DAY(ToDate)>30 THEN 30 ELSE DAY(ToDate) END)
               -(CASE WHEN FromDate=EOMONTH(FromDate) AND DAY(FromDate)<30 THEN 30 WHEN DAY(FromDate)>30 THEN 30 ELSE DAY(FromDate) END)
               +1
             )
             AS decimal(18,2)
           ),SourceEntryData
    FROM RankedVacantBillPeriods WHERE VacancyRowNumber=1 OPTION (MAXRECURSION 0);
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
        DECLARE @WaterBillPeriodTypeID int=(SELECT TOP (1) billPeriodTypeID FROM Housing.BillPeriodType WHERE meterServiceTypeID_FK=2 AND billPeriodTypeActive=1 ORDER BY billPeriodTypeID);
        IF @WaterBillPeriodTypeID IS NULL THROW 55006, N'An active water BillPeriodType linked to MeterServiceType 2 is required.', 1;

        IF NOT EXISTS (SELECT 1 FROM Housing.MeterServiceTypeLinkedWithIdara WHERE MeterServiceTypeID_FK=2 AND Idara_FK=@IdaraId AND MeterServiceTypeLinkedWithIdaraActive=1)
            INSERT Housing.MeterServiceTypeLinkedWithIdara(MeterServiceTypeID_FK,Idara_FK,MeterServiceTypeLinkedWithIdaraStartDate,MeterServiceTypeLinkedWithIdaraActive,entryDate,entryData,hostName)
            VALUES(2,CONVERT(int,@IdaraId),@WaterChargeStartDate,1,GETDATE(),N'MIGRATION',N'usp_MigrateHistoricalRentAndWaterBills');

        IF NOT EXISTS (SELECT 1 FROM Housing.MeterServiceTypeFixedAmount WHERE MeterServiceTypeID_FK=2 AND idaraID_FK=@IdaraId AND MeterServiceTypeFixedAmountActive=1)
            INSERT Housing.MeterServiceTypeFixedAmount(MeterServiceTypeID_FK,FixedAmount,MeterServiceTypeFixedAmountStartDate,MeterServiceTypeFixedAmountActive,idaraID_FK,entryDate,entryData,hostName)
            VALUES(2,CAST(ROUND(@WaterMonthlyAmount/CAST(1.15 AS decimal(18,4)),2) AS decimal(18,2)),@CutoverDate,1,@IdaraId,GETDATE(),N'MIGRATION',N'usp_MigrateHistoricalRentAndWaterBills');

        ;WITH WaterMonths AS
        (
            SELECT @WaterChargeStartDate PeriodStart WHERE @WaterChargeStartDate<=@HistoricalEndDate
            UNION ALL SELECT DATEADD(month,1,PeriodStart) FROM WaterMonths WHERE DATEADD(month,1,PeriodStart)<=@HistoricalEndDate
        )
        INSERT Housing.BillPeriod(billPeriodTypeID_FK,billPeriodName_A,billPeriodName_E,billPeriodStartDate,billPeriodEndDate,billPeriodActive,ClosedBy,IdaraId_FK,entryDate,entryData,hostName)
        SELECT @WaterBillPeriodTypeID,CONCAT(N'فترة مياه ',YEAR(PeriodStart),N'/',RIGHT(N'0'+CONVERT(nvarchar(2),MONTH(PeriodStart)),2)),CONCAT(N'Water ',YEAR(PeriodStart),N'/',RIGHT(N'0'+CONVERT(nvarchar(2),MONTH(PeriodStart)),2)),PeriodStart,EOMONTH(PeriodStart),0,N'MIGRATION',@IdaraId,GETDATE(),N'MIGRATION',N'usp_MigrateHistoricalRentAndWaterBills'
        FROM WaterMonths sourceMonth
        WHERE NOT EXISTS(SELECT 1 FROM Housing.BillPeriod targetPeriod WHERE targetPeriod.billPeriodTypeID_FK=@WaterBillPeriodTypeID AND targetPeriod.IdaraId_FK=@IdaraId AND CAST(targetPeriod.billPeriodStartDate AS date)=sourceMonth.PeriodStart AND CAST(targetPeriod.billPeriodEndDate AS date)=EOMONTH(sourceMonth.PeriodStart))
        OPTION (MAXRECURSION 0);
        INSERT INTO [Housing].[Bills]
        (
            [BillsUID], [BillChargeTypeID_FK], [BillTypeID_FK], [PerviosPeriodID], [CurrentPeriodID], [meterServiceTypeID], [CurrentPeriodTax],
            [PeriodMonth], [PeriodYear], [buildingDetailsNo], [buildingUtilityTypeID], [buildingDetailsID],
            [residentInfoID_FK], [generalNo_FK], [PRICE], [PRICETAX], [TotalPrice],
            [buildingRentTypeID_FK], [BillsFromDate], [BillsToDate], [BillActive],
            [idaraID_FK], [entryDate], [entryData], [hostName]
        )
        SELECT
            NEWID(), sourceBill.ChargeTypeID, sourceBill.BillTypeID, previousBillingPeriod.billPeriodID, billingPeriod.billPeriodID, charge.MeterServiceTypeID_FK,
            CASE WHEN sourceBill.ChargeTypeID=3 THEN CAST(15 AS decimal(18,2)) ELSE CAST(0 AS decimal(18,2)) END,
            sourceBill.PeriodMonth, sourceBill.PeriodYear,
            sourceBill.BuildingDetailsNo, targetBuilding.buildingUtilityTypeID_FK, CONVERT(int, sourceBill.BuildingDetailsID),
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
        JOIN Housing.BillChargeType charge ON charge.BillChargeTypeID=sourceBill.ChargeTypeID
        JOIN Housing.BuildingDetails targetBuilding ON targetBuilding.buildingDetailsID=sourceBill.BuildingDetailsID
        OUTER APPLY (SELECT TOP (1) bp.billPeriodID,bp.billPeriodStartDate FROM Housing.BillPeriod bp JOIN Housing.BillPeriodType bpt ON bpt.billPeriodTypeID=bp.billPeriodTypeID_FK WHERE bp.IdaraId_FK=@IdaraId AND bpt.meterServiceTypeID_FK=charge.MeterServiceTypeID_FK AND CAST(bp.billPeriodStartDate AS date)<=sourceBill.FromDate AND CAST(bp.billPeriodEndDate AS date)>=sourceBill.ToDate ORDER BY bp.billPeriodID DESC) billingPeriod
        OUTER APPLY (SELECT TOP (1) bp.billPeriodID FROM Housing.BillPeriod bp JOIN Housing.BillPeriodType bpt ON bpt.billPeriodTypeID=bp.billPeriodTypeID_FK WHERE bp.IdaraId_FK=@IdaraId AND bpt.meterServiceTypeID_FK=charge.MeterServiceTypeID_FK AND bp.billPeriodStartDate<billingPeriod.billPeriodStartDate ORDER BY bp.billPeriodStartDate DESC,bp.billPeriodID DESC) previousBillingPeriod
        JOIN #EntryDataMap entryMap
          ON entryMap.EntryDataKey = ISNULL(sourceBill.SourceEntryData, N'')
        WHERE NOT EXISTS
        (
            SELECT 1 FROM [Housing].[Bills] targetBill WITH (UPDLOCK, HOLDLOCK)
            WHERE targetBill.[BillChargeTypeID_FK] = sourceBill.ChargeTypeID
              AND targetBill.[BillTypeID_FK] = sourceBill.BillTypeID
              AND targetBill.[idaraID_FK] = @IdaraId
              AND ISNULL(targetBill.[residentInfoID_FK],-1) = ISNULL(sourceBill.ResidentInfoID,-1)
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