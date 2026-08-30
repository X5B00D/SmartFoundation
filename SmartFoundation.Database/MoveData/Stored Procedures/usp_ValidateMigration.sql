CREATE PROCEDURE [MoveData].[usp_ValidateMigration]
    @IdaraId bigint = 1,
    @CutoverDate date = NULL,
    @WaterMonthlyAmount decimal(18,2) = 8.25
AS
BEGIN
    SET NOCOUNT ON;
    /* Normalize migration administration: preserve a valid supplied value, otherwise use Idara 1. */
    IF NOT EXISTS (SELECT 1 FROM dbo.Idara WHERE idaraID = 1)
        THROW 57990, N'Default migration Idara 1 does not exist.', 1;
    IF @IdaraId IS NULL OR NOT EXISTS (SELECT 1 FROM dbo.Idara WHERE idaraID = @IdaraId)
        SET @IdaraId = 1;
    SET XACT_ABORT ON;

    DECLARE @Checks TABLE
    (
        CheckOrder int IDENTITY(1,1) PRIMARY KEY,
        Category nvarchar(100) NOT NULL,
        CheckName nvarchar(300) NOT NULL,
        ExpectedValue decimal(38,2) NULL,
        ActualValue decimal(38,2) NULL,
        Difference decimal(38,2) NULL,
        Result varchar(30) NOT NULL,
        Notes nvarchar(1000) NULL
    );
    DECLARE @RentChargeStartDate date = CONVERT(date, '20171001', 112);
    DECLARE @WaterChargeStartDate date = CONVERT(date, '20240101', 112);

    /* Build the same consecutive-duplicate action map used by the migration. */
    ;WITH OrderedSourceActions AS
    (
        SELECT
            sourceAction.*,
            LAG(sourceAction.buildingActionID) OVER
            (
                PARTITION BY
                    sourceAction.generalNo_FK,
                    ISNULL(LTRIM(RTRIM(sourceAction.buildingDetailsNo)),N'')
                ORDER BY sourceAction.buildingActionID
            ) previousEntityActionID
        FROM KFMC.Housing.BuildingAction sourceAction
        WHERE sourceAction.generalNo_FK IS NULL
           OR
           (
               sourceAction.generalNo_FK NOT IN (0,1)
               AND EXISTS
               (
                   SELECT 1 FROM KFMC.Housing.ResidentInfo validResident
                   WHERE validResident.generalNo=sourceAction.generalNo_FK
               )
           )
    )
    SELECT
        currentAction.buildingActionID duplicateActionID,
        previousAction.buildingActionID previousActionID
    INTO #ValidationDuplicateActionEdges
    FROM OrderedSourceActions currentAction
    JOIN KFMC.Housing.BuildingAction previousAction
      ON previousAction.buildingActionID=currentAction.previousEntityActionID
    WHERE NOT EXISTS
    (
        SELECT
            currentAction.buildingActionTypeID_FK,currentAction.buildingStatusID_FK,
            currentAction.generalNo_FK,currentAction.buildingPaymentTypeID_FK,
            currentAction.buildingDetailsNo,currentAction.buildingActionFromDate,
            currentAction.buildingActionToDate,currentAction.buildingActionDate,
            currentAction.buildingActionDate2,currentAction.buildingActionDecisionNo,
            currentAction.buildingActionDecisionDate,currentAction.fromDSD_FK,
            currentAction.toDSD_FK,currentAction.buildingActionFromSourceID_FK,
            currentAction.buildingActionToSourceID_FK,currentAction.buildingActionNote,
            currentAction.buildingActionExtraText1,currentAction.buildingActionExtraText2,
            currentAction.buildingActionExtraText3,currentAction.buildingActionExtraText4,
            currentAction.buildingActionExtraDate1,currentAction.buildingActionExtraDate2,
            currentAction.buildingActionExtraDate3,currentAction.buildingActionExtraFloat1,
            currentAction.buildingActionExtraFloat2,currentAction.buildingActionExtraInt1,
            currentAction.buildingActionExtraInt2,currentAction.buildingActionExtraInt3,
            currentAction.buildingActionExtraInt4,currentAction.buildingActionExtraType1,
            currentAction.buildingActionExtraType2,currentAction.buildingActionExtraType3,
            currentAction.buildingActionActive,currentAction.buildingActionParentID
        EXCEPT
        SELECT
            previousAction.buildingActionTypeID_FK,previousAction.buildingStatusID_FK,
            previousAction.generalNo_FK,previousAction.buildingPaymentTypeID_FK,
            previousAction.buildingDetailsNo,previousAction.buildingActionFromDate,
            previousAction.buildingActionToDate,previousAction.buildingActionDate,
            previousAction.buildingActionDate2,previousAction.buildingActionDecisionNo,
            previousAction.buildingActionDecisionDate,previousAction.fromDSD_FK,
            previousAction.toDSD_FK,previousAction.buildingActionFromSourceID_FK,
            previousAction.buildingActionToSourceID_FK,previousAction.buildingActionNote,
            previousAction.buildingActionExtraText1,previousAction.buildingActionExtraText2,
            previousAction.buildingActionExtraText3,previousAction.buildingActionExtraText4,
            previousAction.buildingActionExtraDate1,previousAction.buildingActionExtraDate2,
            previousAction.buildingActionExtraDate3,previousAction.buildingActionExtraFloat1,
            previousAction.buildingActionExtraFloat2,previousAction.buildingActionExtraInt1,
            previousAction.buildingActionExtraInt2,previousAction.buildingActionExtraInt3,
            previousAction.buildingActionExtraInt4,previousAction.buildingActionExtraType1,
            previousAction.buildingActionExtraType2,previousAction.buildingActionExtraType3,
            previousAction.buildingActionActive,previousAction.buildingActionParentID
    );

    ;WITH DuplicatePaths AS
    (
        SELECT duplicateActionID,previousActionID retainedActionID,1 pathLevel
        FROM #ValidationDuplicateActionEdges

        UNION ALL

        SELECT path.duplicateActionID,edge.previousActionID,path.pathLevel+1
        FROM DuplicatePaths path
        JOIN #ValidationDuplicateActionEdges edge
          ON edge.duplicateActionID=path.retainedActionID
        WHERE path.pathLevel<100
    ),
    RankedPaths AS
    (
        SELECT duplicateActionID,retainedActionID,
               ROW_NUMBER() OVER
               (PARTITION BY duplicateActionID ORDER BY pathLevel DESC) rowNumber
        FROM DuplicatePaths
    )
    SELECT duplicateActionID,retainedActionID
    INTO #ValidationDuplicateActionMap
    FROM RankedPaths
    WHERE rowNumber=1
    OPTION (MAXRECURSION 100);

    CREATE UNIQUE CLUSTERED INDEX IX_ValidationDuplicateActionMap
        ON #ValidationDuplicateActionMap(duplicateActionID);

    /* Build the same valid/de-duplicated assignment set used by migration. */
    ;WITH OrderedAssignments AS
    (
        SELECT sourceAssign.*,
               LAG(sourceAssign.BuildingAssignID) OVER
               (
                   PARTITION BY sourceAssign.GeneralNo,sourceAssign.BuildingActionID_FK
                   ORDER BY sourceAssign.BuildingAssignID
               ) PreviousAssignID
        FROM KFMC.Housing.BuildingAssign sourceAssign
    )
    SELECT currentAssign.*
    INTO #ValidationValidAssign
    FROM OrderedAssignments currentAssign
    JOIN KFMC.Housing.BuildingAction ownerAction
      ON ownerAction.buildingActionID=currentAssign.BuildingActionID_FK
     AND CONVERT(nvarchar(100),ownerAction.generalNo_FK)
         =CONVERT(nvarchar(100),currentAssign.GeneralNo)
     AND ownerAction.generalNo_FK NOT IN (0,1)
     AND EXISTS
     (
         SELECT 1 FROM KFMC.Housing.ResidentInfo validResident
         WHERE validResident.generalNo=ownerAction.generalNo_FK
     )
    LEFT JOIN KFMC.Housing.BuildingAssign previousAssign
      ON previousAssign.BuildingAssignID=currentAssign.PreviousAssignID
    WHERE previousAssign.BuildingAssignID IS NULL
       OR EXISTS
       (
           SELECT currentAssign.BuildingAssignTypeID_FK,currentAssign.ParentBuildingAssignID,
                  currentAssign.BuildingNo,currentAssign.BuildingAssignStatusID_FK,currentAssign.MeterReadValue
           EXCEPT
           SELECT previousAssign.BuildingAssignTypeID_FK,previousAssign.ParentBuildingAssignID,
                  previousAssign.BuildingNo,previousAssign.BuildingAssignStatusID_FK,previousAssign.MeterReadValue
       );

    CREATE UNIQUE CLUSTERED INDEX IX_ValidationValidAssign_ID
        ON #ValidationValidAssign(BuildingAssignID);

    /* Directly copied master and transactional data. Actual means source rows found in target. */
    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Completeness',N'Military units',s.c,t.c,t.c-s.c,
           CASE WHEN s.c=t.c THEN 'PASS' ELSE 'FAIL' END,N'Matched by ID and code.'
    FROM (SELECT COUNT_BIG(*) c FROM KFMC.dbo.MilitaryUnit) s
    CROSS JOIN
    (SELECT COUNT_BIG(*) c FROM KFMC.dbo.MilitaryUnit x JOIN dbo.MilitaryUnit y
       ON y.militaryUnitID=x.militaryUnitID
      AND ISNULL(LTRIM(RTRIM(y.militaryUnitCode)),N'')=ISNULL(LTRIM(RTRIM(x.militaryUnitCode)),N'')) t;

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Completeness',N'ResidentInfo',s.c,t.c,t.c-s.c,
           CASE WHEN s.c=t.c THEN 'PASS' ELSE 'FAIL' END,N'Matched by residentInfoID.'
    FROM (SELECT COUNT_BIG(*) c FROM KFMC.Housing.ResidentInfo) s
    CROSS JOIN (SELECT COUNT_BIG(*) c FROM KFMC.Housing.ResidentInfo x JOIN Housing.ResidentInfo y
                 ON y.residentInfoID=CONVERT(bigint,x.residentInfoID)) t;

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Completeness',N'ResidentDetails',s.c,t.c,t.c-s.c,
           CASE WHEN s.c=t.c THEN 'PASS' ELSE 'FAIL' END,N'Matched by residentDetailsID.'
    FROM (SELECT COUNT_BIG(*) c FROM KFMC.Housing.ResidentDetails) s
    CROSS JOIN (SELECT COUNT_BIG(*) c FROM KFMC.Housing.ResidentDetails x JOIN Housing.ResidentDetails y
                 ON y.residentDetailsID=CONVERT(bigint,x.residentDetailsID)) t;

    /* Legacy Excel runs are identified only by the required name prefix. */
    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Legacy Excel',N'Legacy Excel deduction-list import logs',sourceCount.c,targetCount.c,
           targetCount.c-sourceCount.c,
           CASE WHEN sourceCount.c=targetCount.c THEN 'PASS' ELSE 'FAIL' END,
           N'Active KFMC deduction lists whose trimmed name starts with مسير استقطاع and have both a migrated list and an UploadExcelImportLog row.'
    FROM
    (
        SELECT COUNT_BIG(*) c
        FROM KFMC.Housing.DeductList sourceDeduct
        WHERE sourceDeduct.deductActive=1
          AND LTRIM(RTRIM(sourceDeduct.deductName)) LIKE N'مسير استقطاع%'
    ) sourceCount
    CROSS JOIN
    (
        SELECT COUNT_BIG(*) c
        FROM KFMC.Housing.DeductList sourceDeduct
        JOIN Housing.DeductList targetDeduct
          ON targetDeduct.deductListID=sourceDeduct.deductListID
        JOIN Housing.UploadExcelImportLog importLog
          ON importLog.DeductListID_FK=targetDeduct.deductListID
        WHERE sourceDeduct.deductActive=1
          AND LTRIM(RTRIM(sourceDeduct.deductName)) LIKE N'مسير استقطاع%'
    ) targetCount;

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Legacy Excel',N'Duplicate import logs for one deduction list',0,COUNT_BIG(*),COUNT_BIG(*),
           CASE WHEN COUNT_BIG(*)=0 THEN 'PASS' ELSE 'FAIL' END,
           N'Actual is the number of duplicated non-null DeductListID_FK groups.'
    FROM
    (
        SELECT DeductListID_FK
        FROM Housing.UploadExcelImportLog
        WHERE DeductListID_FK IS NOT NULL
        GROUP BY DeductListID_FK
        HAVING COUNT_BIG(*)>1
    ) duplicateLog;

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Legacy Excel',N'Import logs with missing deduction list',0,COUNT_BIG(*),COUNT_BIG(*),
           CASE WHEN COUNT_BIG(*)=0 THEN 'PASS' ELSE 'FAIL' END,
           N'Normally enforced by FK; retained to detect disabled or untrusted constraints.'
    FROM Housing.UploadExcelImportLog importLog
    LEFT JOIN Housing.DeductList targetDeduct
      ON targetDeduct.deductListID=importLog.DeductListID_FK
    WHERE importLog.DeductListID_FK IS NOT NULL
      AND targetDeduct.deductListID IS NULL;

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Legacy Excel',N'Legacy Excel logs with incorrect InsertedRows',0,COUNT_BIG(*),COUNT_BIG(*),
           CASE WHEN COUNT_BIG(*)=0 THEN 'PASS' ELSE 'FAIL' END,
           N'InsertedRows must equal every BuildingPayment row linked to the migrated deduction list.'
    FROM KFMC.Housing.DeductList sourceDeduct
    JOIN Housing.DeductList targetDeduct
      ON targetDeduct.deductListID=sourceDeduct.deductListID
    JOIN Housing.UploadExcelImportLog importLog
      ON importLog.DeductListID_FK=targetDeduct.deductListID
    CROSS APPLY
    (
        SELECT COUNT_BIG(*) paymentCount
        FROM Housing.BuildingPayment targetPayment
        WHERE targetPayment.deductListID_FK=targetDeduct.deductListID
    ) linkedPayment
    WHERE sourceDeduct.deductActive=1
      AND LTRIM(RTRIM(sourceDeduct.deductName)) LIKE N'مسير استقطاع%'
      AND (importLog.InsertedRows IS NULL
           OR CONVERT(bigint,importLog.InsertedRows)<>linkedPayment.paymentCount);

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Legacy Excel',N'Legacy Excel logs with incorrect synthetic hash',0,COUNT_BIG(*),COUNT_BIG(*),
           CASE WHEN COUNT_BIG(*)=0 THEN 'PASS' ELSE 'FAIL' END,
           N'Hash must be SHA2-256 of LEGACY-KFMC-EXCEL:<deductListID>.'
    FROM KFMC.Housing.DeductList sourceDeduct
    JOIN Housing.UploadExcelImportLog importLog
      ON importLog.DeductListID_FK=sourceDeduct.deductListID
    WHERE sourceDeduct.deductActive=1
      AND LTRIM(RTRIM(sourceDeduct.deductName)) LIKE N'مسير استقطاع%'
      AND importLog.FileHash<>
          LOWER
          (
            CONVERT
            (
              varchar(64),
              HASHBYTES('SHA2_256',CONCAT(N'LEGACY-KFMC-EXCEL:',sourceDeduct.deductListID)),
              2
            )
          );

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Completeness',N'Resident contacts',s.c,t.c,t.c-s.c,
           CASE WHEN s.c=t.c THEN 'PASS' ELSE 'FAIL' END,
           N'Only contacts whose userID exists in KFMC.Housing.ResidentInfo.'
    FROM
    (
        SELECT COUNT_BIG(*) c FROM KFMC.dbo.contactInfo c
        JOIN KFMC.Housing.ResidentInfo r ON r.generalNo=c.userID_FK
    ) s
    CROSS JOIN
    (
        SELECT COUNT_BIG(*) c FROM Housing.ResidentContactInfo c
        JOIN Housing.ResidentInfo r ON r.residentInfoID=c.residentInfoID_FK
    ) t;

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Completeness',N'Buildings',s.c,t.c,t.c-s.c,
           CASE WHEN s.c=t.c THEN 'PASS' ELSE 'FAIL' END,N'Matched by buildingDetailsID.'
    FROM (SELECT COUNT_BIG(*) c FROM KFMC.Housing.BuildingDetails) s
    CROSS JOIN (SELECT COUNT_BIG(*) c FROM KFMC.Housing.BuildingDetails x JOIN Housing.BuildingDetails y
                 ON y.buildingDetailsID=CONVERT(bigint,x.buildingDetailsID)) t;

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Completeness',N'Meters',s.c,t.c,t.c-s.c,
           CASE WHEN s.c=t.c THEN 'PASS' ELSE 'FAIL' END,N'Matched by meterID.'
    FROM (SELECT COUNT_BIG(*) c FROM KFMC.Housing.Meter) s
    CROSS JOIN (SELECT COUNT_BIG(*) c FROM KFMC.Housing.Meter x JOIN Housing.Meter y
                 ON y.meterID=CONVERT(bigint,x.meterID)) t;

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Completeness',N'Meter reads',s.c,t.c,t.c-s.c,
           CASE WHEN s.c=t.c THEN 'PASS' ELSE 'FAIL' END,N'Matched by meterReadID.'
    FROM (SELECT COUNT_BIG(*) c FROM KFMC.Housing.MeterRead) s
    CROSS JOIN (SELECT COUNT_BIG(*) c FROM KFMC.Housing.MeterRead x JOIN Housing.MeterRead y
                 ON y.meterReadID=CONVERT(bigint,x.meterReadID)) t;

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Historical corrections',N'Meter reads linked to corrected residents',s.c,t.c,t.c-s.c,
           CASE WHEN s.c=t.c THEN 'PASS' ELSE 'FAIL' END,
           N'Applies documented mappings 202964->60013013, 404529/1265->10038776, and 306499/B06-5-2->10036016.'
    FROM
    (
        SELECT COUNT_BIG(*) c FROM KFMC.Housing.MeterRead sourceRead
        WHERE sourceRead.generalNo_FK=202964
           OR (sourceRead.generalNo_FK=404529 AND LTRIM(RTRIM(sourceRead.buildingDetailsNo))=N'1265')
           OR (sourceRead.generalNo_FK=306499 AND LTRIM(RTRIM(sourceRead.buildingDetailsNo))=N'B06-5-2')
    ) s
    CROSS JOIN
    (
        SELECT COUNT_BIG(*) c
        FROM KFMC.Housing.MeterRead sourceRead
        JOIN Housing.MeterRead targetRead ON targetRead.meterReadID=sourceRead.meterReadID
        WHERE (sourceRead.generalNo_FK=202964 AND targetRead.generalNo_FK=60013013 AND targetRead.residentInfoID_FK IS NOT NULL)
           OR (sourceRead.generalNo_FK=404529 AND LTRIM(RTRIM(sourceRead.buildingDetailsNo))=N'1265'
               AND targetRead.generalNo_FK=10038776 AND targetRead.residentInfoID_FK IS NOT NULL)
           OR (sourceRead.generalNo_FK=306499 AND LTRIM(RTRIM(sourceRead.buildingDetailsNo))=N'B06-5-2'
               AND targetRead.generalNo_FK=10036016 AND targetRead.residentInfoID_FK IS NOT NULL)
    ) t;

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Historical corrections',N'Meter reads linked to corrected building C07-2-1',s.c,t.c,t.c-s.c,
           CASE WHEN s.c=t.c THEN 'PASS' ELSE 'FAIL' END,
           N'Corrects historical building number C7-2-1 to C07-2-1.'
    FROM (SELECT COUNT_BIG(*) c FROM KFMC.Housing.MeterRead WHERE LTRIM(RTRIM(buildingDetailsNo))=N'C7-2-1') s
    CROSS JOIN
    (
        SELECT COUNT_BIG(*) c
        FROM KFMC.Housing.MeterRead sourceRead
        JOIN Housing.MeterRead targetRead ON targetRead.meterReadID=sourceRead.meterReadID
        WHERE LTRIM(RTRIM(sourceRead.buildingDetailsNo))=N'C7-2-1'
          AND LTRIM(RTRIM(targetRead.buildingDetailsNo))=N'C07-2-1'
          AND targetRead.buildingDetailsID IS NOT NULL
    ) t;

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Completeness',N'Building actions',s.c,t.c,t.c-s.c,
           CASE WHEN s.c=t.c THEN 'PASS' ELSE 'FAIL' END,
           N'Matched by buildingActionID after excluding consecutive identical source actions.'
    FROM
    (
        SELECT COUNT_BIG(*) c
        FROM KFMC.Housing.BuildingAction sourceAction
        WHERE NOT EXISTS
        (
            SELECT 1 FROM #ValidationDuplicateActionMap duplicateAction
            WHERE duplicateAction.duplicateActionID=sourceAction.buildingActionID
        )
          AND
          (
              sourceAction.generalNo_FK IS NULL
              OR
              (
                  sourceAction.generalNo_FK NOT IN (0,1)
                  AND EXISTS
                  (
                      SELECT 1 FROM KFMC.Housing.ResidentInfo validResident
                      WHERE validResident.generalNo=sourceAction.generalNo_FK
                  )
              )
          )
          AND NOT
          (
              sourceAction.buildingActionTypeID_FK=27
              AND EXISTS
              (
                  SELECT 1 FROM KFMC.Housing.BuildingAction letterRoot
                  WHERE letterRoot.buildingActionID=sourceAction.buildingActionParentID
                    AND letterRoot.buildingActionTypeID_FK=7
              )
          )
    ) s
    CROSS JOIN
    (
        SELECT COUNT_BIG(*) c
        FROM KFMC.Housing.BuildingAction x
        JOIN Housing.BuildingAction y ON y.buildingActionID=CONVERT(bigint,x.buildingActionID)
        WHERE
        (
            x.generalNo_FK IS NULL
            OR
            (
                x.generalNo_FK NOT IN (0,1)
                AND EXISTS
                (
                    SELECT 1 FROM KFMC.Housing.ResidentInfo validResident
                    WHERE validResident.generalNo=x.generalNo_FK
                )
            )
        )
        AND NOT
        (
            x.buildingActionTypeID_FK=27
            AND EXISTS
            (
                SELECT 1 FROM KFMC.Housing.BuildingAction letterRoot
                WHERE letterRoot.buildingActionID=x.buildingActionParentID
                  AND letterRoot.buildingActionTypeID_FK=7
            )
        )
    ) t;

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Completeness',N'Building assignments',s.c,t.c,t.c-s.c,
           CASE WHEN s.c=t.c THEN 'PASS' ELSE 'FAIL' END,N'Matched by BuildingAssignID.'
    FROM (SELECT COUNT_BIG(*) c FROM #ValidationValidAssign) s
    CROSS JOIN (SELECT COUNT_BIG(*) c FROM #ValidationValidAssign x JOIN Housing.BuildingAssign y
                 ON y.BuildingAssignID=x.BuildingAssignID) t;

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Allocation migration',N'Historical assignment periods',4,COUNT_BIG(*),COUNT_BIG(*)-4,
           CASE WHEN COUNT_BIG(*)=4 THEN 'PASS' ELSE 'FAIL' END,
           N'Exactly one legacy period is created for each normal waiting class 1,2,3,4.'
    FROM Housing.AssignPeriod
    WHERE IdaraId_FK=@IdaraId
      AND AssignPeriodDescrption LIKE N'Legacy allocation migration - WaitingClass %';

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Allocation migration',N'Old action 18 mapped to first rejection 39',s.c,t.c,t.c-s.c,
           CASE WHEN s.c=t.c THEN 'PASS' ELSE 'FAIL' END,
           N'Legacy direct rejection action 18 becomes first-allocation rejection action 39.'
    FROM
    (
        SELECT COUNT_BIG(*) c
        FROM KFMC.Housing.BuildingAction sourceAction
        WHERE sourceAction.buildingActionTypeID_FK=18
          AND sourceAction.generalNo_FK IS NOT NULL
          AND NOT EXISTS
          (
              SELECT 1 FROM KFMC.Housing.BuildingAction laterAction
              WHERE laterAction.generalNo_FK=sourceAction.generalNo_FK
                AND laterAction.buildingActionID>sourceAction.buildingActionID
          )
    ) s
    CROSS JOIN
    (
        SELECT COUNT_BIG(*) c
        FROM KFMC.Housing.BuildingAction sourceAction
        JOIN Housing.BuildingAction targetAction
          ON targetAction.buildingActionID=CONVERT(bigint,sourceAction.buildingActionID)
         AND targetAction.buildingActionTypeID_FK=39
        WHERE sourceAction.buildingActionTypeID_FK=18
          AND sourceAction.generalNo_FK IS NOT NULL
          AND NOT EXISTS
          (
              SELECT 1 FROM KFMC.Housing.BuildingAction laterAction
              WHERE laterAction.generalNo_FK=sourceAction.generalNo_FK
                AND laterAction.buildingActionID>sourceAction.buildingActionID
          )
    ) t;

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Allocation migration',N'Legacy letter action 27 excluded',0,COUNT_BIG(*),COUNT_BIG(*),
           CASE WHEN COUNT_BIG(*)=0 THEN 'PASS' ELSE 'FAIL' END,
           N'Letter housing follows OtherWaitingListSP and must not retain the old intermediate action 27.'
    FROM KFMC.Housing.BuildingAction sourceAction
    JOIN KFMC.Housing.BuildingAction letterRoot
      ON letterRoot.buildingActionID=sourceAction.buildingActionParentID
     AND letterRoot.buildingActionTypeID_FK=7
    JOIN Housing.BuildingAction targetAction
      ON targetAction.buildingActionID=CONVERT(bigint,sourceAction.buildingActionID)
    WHERE sourceAction.buildingActionTypeID_FK=27;

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Allocation migration',N'Two No_house allocations become action 42',s.c,t.c,t.c-s.c,
           CASE WHEN s.c=t.c THEN 'PASS' ELSE 'FAIL' END,
           N'No fake building or intermediate fake allocation action is created.'
    FROM
    (
        SELECT COUNT_BIG(*) c
        FROM
        (
            SELECT action27.buildingActionID
            FROM KFMC.Housing.BuildingAction action27
            JOIN KFMC.Housing.BuildingAction waitingRoot
              ON waitingRoot.buildingActionID=action27.buildingActionParentID
             AND waitingRoot.buildingActionTypeID_FK=1
            JOIN #ValidationValidAssign virtualOffer
              ON virtualOffer.BuildingActionID_FK=action27.buildingActionID
             AND virtualOffer.BuildingAssignTypeID_FK=1
             AND UPPER(LTRIM(RTRIM(ISNULL(virtualOffer.BuildingNo,N''))))=N'NO_HOUSE'
            WHERE action27.buildingActionTypeID_FK=27
            GROUP BY action27.buildingActionID
            HAVING COUNT_BIG(*)>=2
        ) expectedCancellation
    ) s
    CROSS JOIN
    (
        SELECT COUNT_BIG(*) c
        FROM Housing.BuildingAction
        WHERE buildingActionTypeID_FK=42
          AND buildingActionExtraText4 LIKE N'MoveData:NoHouse2:%'
    ) t;

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Allocation migration',N'No operational No_house building',0,COUNT_BIG(*),COUNT_BIG(*),
           CASE WHEN COUNT_BIG(*)=0 THEN 'PASS' ELSE 'FAIL' END,
           N'No generated action or building may use No_house as a real building number.'
    FROM Housing.BuildingAction
    WHERE buildingActionExtraText4 LIKE N'MoveData:%'
      AND UPPER(LTRIM(RTRIM(ISNULL(buildingDetailsNo,N''))))=N'NO_HOUSE';

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Allocation migration',N'Accepted normal allocations linked to housing through 47',s.c,t.c,t.c-s.c,
           CASE WHEN s.c=t.c THEN 'PASS' ELSE 'FAIL' END,
           N'Every accepted normal allocation that reached housing ends 45->46->47->2.'
    FROM
    (
        SELECT COUNT_BIG(*) c
        FROM #ValidationValidAssign offer
        JOIN KFMC.Housing.BuildingAction action27
          ON action27.buildingActionID=offer.BuildingActionID_FK
         AND action27.buildingActionTypeID_FK=27
        JOIN KFMC.Housing.BuildingAction waitingRoot
          ON waitingRoot.buildingActionID=action27.buildingActionParentID
         AND waitingRoot.buildingActionTypeID_FK=1
        WHERE offer.BuildingAssignTypeID_FK=1
          AND UPPER(LTRIM(RTRIM(ISNULL(offer.BuildingNo,N''))))<>N'NO_HOUSE'
          AND offer.MeterReadValue IS NOT NULL
          AND NOT EXISTS
          (
              SELECT 1 FROM #ValidationValidAssign rejectRow
              WHERE rejectRow.BuildingAssignTypeID_FK=2
                AND rejectRow.ParentBuildingAssignID=offer.BuildingAssignID
          )
          AND EXISTS
          (
              SELECT 1 FROM KFMC.Housing.BuildingAction housingAction
              WHERE housingAction.generalNo_FK=action27.generalNo_FK
                AND housingAction.buildingActionTypeID_FK=2
                AND housingAction.buildingActionID>action27.buildingActionID
                AND UPPER(REPLACE(LTRIM(RTRIM(ISNULL(housingAction.buildingDetailsNo,N''))),N' ',N''))
                    =UPPER(REPLACE(LTRIM(RTRIM(ISNULL(offer.BuildingNo,N''))),N' ',N''))
          )
    ) s
    CROSS JOIN
    (
        SELECT COUNT_BIG(*) c
        FROM Housing.BuildingAction housingAction
        JOIN Housing.BuildingAction action47
          ON action47.buildingActionID=housingAction.buildingActionParentID
         AND action47.buildingActionTypeID_FK=47
         AND action47.buildingActionExtraText4 LIKE N'MoveData:Accept:%:47'
        WHERE housingAction.buildingActionTypeID_FK=2
    ) t;

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Allocation migration',N'Letter housing linked directly 7 to 2',s.c,t.c,t.c-s.c,
           CASE WHEN s.c=t.c THEN 'PASS' ELSE 'FAIL' END,
           N'Existing letter residents bypass allocation minutes and intermediate action 27.'
    FROM
    (
        SELECT COUNT_BIG(*) c
        FROM KFMC.Housing.BuildingAction sourceHousing
        JOIN KFMC.Housing.BuildingAction oldAction27
          ON oldAction27.buildingActionID=sourceHousing.buildingActionParentID
         AND oldAction27.buildingActionTypeID_FK=27
        JOIN KFMC.Housing.BuildingAction letterRoot
          ON letterRoot.buildingActionID=oldAction27.buildingActionParentID
         AND letterRoot.buildingActionTypeID_FK=7
        WHERE sourceHousing.buildingActionTypeID_FK=2
    ) s
    CROSS JOIN
    (
        SELECT COUNT_BIG(*) c
        FROM KFMC.Housing.BuildingAction sourceHousing
        JOIN KFMC.Housing.BuildingAction oldAction27
          ON oldAction27.buildingActionID=sourceHousing.buildingActionParentID
         AND oldAction27.buildingActionTypeID_FK=27
        JOIN KFMC.Housing.BuildingAction letterRoot
          ON letterRoot.buildingActionID=oldAction27.buildingActionParentID
         AND letterRoot.buildingActionTypeID_FK=7
        JOIN Housing.BuildingAction targetHousing
          ON targetHousing.buildingActionID=CONVERT(bigint,sourceHousing.buildingActionID)
         AND targetHousing.buildingActionParentID=CONVERT(bigint,letterRoot.buildingActionID)
        WHERE sourceHousing.buildingActionTypeID_FK=2
    ) t;

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Completeness',N'Extend insurance',s.c,t.c,t.c-s.c,
           CASE WHEN s.c=t.c THEN 'PASS' ELSE 'FAIL' END,
           N'Only residents whose last active action is type 24 with buildingActionExtraType1 = 2 are migrated.'
    FROM
    (
        SELECT COUNT_BIG(*) c
        FROM
        (
            SELECT sourceAction.*,
                   ROW_NUMBER() OVER
                   (
                       PARTITION BY sourceAction.generalNo_FK
                       ORDER BY ISNULL(sourceAction.buildingActionDate, sourceAction.entryDate) DESC,
                                sourceAction.buildingActionID DESC
                   ) rowNumber
            FROM KFMC.Housing.BuildingAction sourceAction
            WHERE sourceAction.generalNo_FK IS NOT NULL
              AND ISNULL(sourceAction.buildingActionActive,1)=1
        ) lastAction
        WHERE lastAction.rowNumber=1
          AND lastAction.buildingActionTypeID_FK=24
          AND lastAction.buildingActionExtraType1=2
    ) s
    CROSS JOIN
    (
        SELECT COUNT_BIG(*) c
        FROM Housing.ExtendInsurance
        WHERE IdaraId_FK=@IdaraId
    ) t;

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Completeness',N'Electricity bills',s.c,t.c,t.c-s.c,
           CASE WHEN s.c=t.c THEN 'PASS' ELSE 'FAIL' END,
           N'Matched by BillsID. Duplicate active 2024/10 bills for the same resident, building, month, year, and amount are intentionally excluded, including NULL generalNo_FK groups.'
    FROM
    (
        SELECT COUNT_BIG(*) c
        FROM
        (
            SELECT
                x.BillsID,
                CASE
                  WHEN ISNULL(x.BillActive,1)=1
                   AND x.PeriodYear=2024
                   AND x.PeriodMonth=10
                  THEN ROW_NUMBER() OVER
                  (
                    PARTITION BY x.generalNo_FK,x.buildingDetailsNo,x.PeriodYear,x.PeriodMonth,
                                 CAST(ISNULL(x.TotalPrice,0) AS decimal(18,2))
                    ORDER BY
                      CASE WHEN EXISTS
                      (
                        SELECT 1
                        FROM KFMC.Housing.BillsDeductListDetails d
                        WHERE d.billsID_FK=x.BillsID
                          AND d.billPaid=1
                          AND d.paidAmount IS NOT NULL
                      ) THEN 1 ELSE 0 END DESC,
                      x.BillsID
                  )
                  ELSE 1
                END AS migrationRowNo
            FROM KFMC.Housing.Bills x
        ) expectedBills
        WHERE expectedBills.migrationRowNo=1
    ) s
    CROSS JOIN
    (
        SELECT COUNT_BIG(*) c
        FROM
        (
            SELECT
                x.BillsID,
                CASE
                  WHEN ISNULL(x.BillActive,1)=1
                   AND x.PeriodYear=2024
                   AND x.PeriodMonth=10
                  THEN ROW_NUMBER() OVER
                  (
                    PARTITION BY x.generalNo_FK,x.buildingDetailsNo,x.PeriodYear,x.PeriodMonth,
                                 CAST(ISNULL(x.TotalPrice,0) AS decimal(18,2))
                    ORDER BY
                      CASE WHEN EXISTS
                      (
                        SELECT 1
                        FROM KFMC.Housing.BillsDeductListDetails d
                        WHERE d.billsID_FK=x.BillsID
                          AND d.billPaid=1
                          AND d.paidAmount IS NOT NULL
                      ) THEN 1 ELSE 0 END DESC,
                      x.BillsID
                  )
                  ELSE 1
                END AS migrationRowNo
            FROM KFMC.Housing.Bills x
        ) x
        JOIN Housing.Bills y ON y.BillsID=CONVERT(bigint,x.BillsID) AND y.BillChargeTypeID_FK=2
        WHERE x.migrationRowNo=1
    ) t;

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Completeness',N'Excluded duplicate electricity bills present',0,COUNT_BIG(*),COUNT_BIG(*),
           CASE WHEN COUNT_BIG(*)=0 THEN 'PASS' ELSE 'FAIL' END,
           N'Active duplicate electricity bills for 2024/10 must not exist in DATACORE after migration, including NULL generalNo_FK groups.'
    FROM
    (
        SELECT
            x.BillsID,
            CASE
              WHEN ISNULL(x.BillActive,1)=1
               AND x.PeriodYear=2024
               AND x.PeriodMonth=10
              THEN ROW_NUMBER() OVER
              (
                PARTITION BY x.generalNo_FK,x.buildingDetailsNo,x.PeriodYear,x.PeriodMonth,
                             CAST(ISNULL(x.TotalPrice,0) AS decimal(18,2))
                ORDER BY
                  CASE WHEN EXISTS
                  (
                    SELECT 1
                    FROM KFMC.Housing.BillsDeductListDetails d
                    WHERE d.billsID_FK=x.BillsID
                      AND d.billPaid=1
                      AND d.paidAmount IS NOT NULL
                  ) THEN 1 ELSE 0 END DESC,
                  x.BillsID
              )
              ELSE 1
            END AS migrationRowNo
        FROM KFMC.Housing.Bills x
    ) excludedBills
    JOIN Housing.Bills y ON y.BillsID=CONVERT(bigint,excludedBills.BillsID)
    WHERE excludedBills.migrationRowNo>1
      AND y.BillChargeTypeID_FK=2;

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Completeness',N'Active rent payments',s.c,t.c,t.c-s.c,
           CASE WHEN s.c=t.c THEN 'PASS' ELSE 'FAIL' END,N'Cancelled source lists and payments are excluded.'
    FROM
    (
        SELECT COUNT_BIG(*) c FROM KFMC.Housing.BuildingPayment p
        JOIN KFMC.Housing.DeductList d ON d.deductListID=p.deductListID_FK
        WHERE p.buildingPayementActive=1 AND d.deductActive=1
    ) s
    CROSS JOIN
    (SELECT COUNT_BIG(*) c FROM Housing.BuildingPayment
     WHERE BillChargeTypeID_FK=1 AND buildingPayementActive=1 AND IdaraId_FK=@IdaraId) t;

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Completeness',N'Penalty bills',s.c,t.c,t.c-s.c,
           CASE WHEN s.c=t.c THEN 'PASS' ELSE 'FAIL' END,N'Every old custody penalty becomes a bill.'
    FROM (SELECT COUNT_BIG(*) c FROM KFMC.Housing.OccupantCustodyAction) s
    CROSS JOIN (SELECT COUNT_BIG(*) c FROM Housing.Bills
                 WHERE BillChargeTypeID_FK=5 AND idaraID_FK=@IdaraId) t;

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Completeness',N'Paid penalties',s.c,t.c,t.c-s.c,
           CASE WHEN s.c=t.c THEN 'PASS' ELSE 'FAIL' END,N'Every old paid penalty becomes a payment.'
    FROM (SELECT COUNT_BIG(*) c FROM KFMC.Housing.OccupantCustodyAction WHERE Paid=1) s
    CROSS JOIN (SELECT COUNT_BIG(*) c FROM Housing.BuildingPayment
                 WHERE BillChargeTypeID_FK=5 AND buildingPayementActive=1 AND IdaraId_FK=@IdaraId) t;

    /* Generated monthly bill invariants. */
    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Generated bills',N'No rent bills before enforcement date',0,COUNT_BIG(*),COUNT_BIG(*),
           CASE WHEN COUNT_BIG(*)=0 THEN 'PASS' ELSE 'FAIL' END,
           N'Migrated rent charges start on 2017-10-01; older occupancy months must not receive rent bills.'
    FROM Housing.Bills
    WHERE BillChargeTypeID_FK=1
      AND idaraID_FK=@IdaraId
      AND BillActive=1
      AND BillsFromDate < @RentChargeStartDate;

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Generated bills',N'No water bills before enforcement date',0,COUNT_BIG(*),COUNT_BIG(*),
           CASE WHEN COUNT_BIG(*)=0 THEN 'PASS' ELSE 'FAIL' END,
           N'Water charges start on 2024-01-01; older occupancy months must not receive water bills.'
    FROM Housing.Bills
    WHERE BillChargeTypeID_FK=3
      AND idaraID_FK=@IdaraId
      AND BillActive=1
      AND BillsFromDate < @WaterChargeStartDate;

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Generated bills',N'Rent or water bills extending beyond evacuation date',
           0,COUNT_BIG(*),COUNT_BIG(*),
           CASE WHEN COUNT_BIG(*)=0 THEN 'PASS' ELSE 'FAIL' END,
           N'Every active KFMC type-3 action ends rent and water charging on its buildingActionDate, regardless of ExtraInt1 workflow stage.'
    FROM Housing.Bills targetBill
    CROSS APPLY
    (
        SELECT TOP (1)
               occupancy.buildingActionID,
               occupancy.buildingActionDate OccupancyDate
        FROM KFMC.Housing.BuildingAction occupancy
        WHERE occupancy.buildingActionTypeID_FK=2
          AND occupancy.generalNo_FK=targetBill.generalNo_FK
          AND LTRIM(RTRIM(occupancy.buildingDetailsNo))=LTRIM(RTRIM(targetBill.buildingDetailsNo))
          AND occupancy.buildingActionDate<=targetBill.BillsFromDate
        ORDER BY occupancy.buildingActionDate DESC,occupancy.buildingActionID DESC
    ) relevantOccupancy
    CROSS APPLY
    (
        SELECT TOP (1) evacuation.buildingActionDate EvacuationDate
        FROM KFMC.Housing.BuildingAction evacuation
        WHERE evacuation.buildingActionTypeID_FK=3
          AND evacuation.buildingActionActive=1
          AND evacuation.generalNo_FK=targetBill.generalNo_FK
          AND LTRIM(RTRIM(evacuation.buildingDetailsNo))=LTRIM(RTRIM(targetBill.buildingDetailsNo))
          AND evacuation.buildingActionDate>=relevantOccupancy.OccupancyDate
          AND evacuation.buildingActionParentID=relevantOccupancy.buildingActionID
        ORDER BY evacuation.buildingActionDate,evacuation.buildingActionID
    ) relevantEvacuation
    WHERE targetBill.BillChargeTypeID_FK IN(1,3)
      AND targetBill.BillActive=1
      AND targetBill.BillsToDate>relevantEvacuation.EvacuationDate;

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Business rules',N'Monthly rent procedure ignores ExitDate',
           0,
           CASE
               WHEN OBJECT_DEFINITION(OBJECT_ID(N'Housing.BuildingRentForOneMonth',N'P')) LIKE N'%CAST(o.ExitDate AS date)%'
                AND OBJECT_DEFINITION(OBJECT_ID(N'Housing.BuildingRentForOneMonth',N'P')) LIKE N'%o.ExitDate IS NULL%'
               THEN 0 ELSE 1
           END,
           CASE
               WHEN OBJECT_DEFINITION(OBJECT_ID(N'Housing.BuildingRentForOneMonth',N'P')) LIKE N'%CAST(o.ExitDate AS date)%'
                AND OBJECT_DEFINITION(OBJECT_ID(N'Housing.BuildingRentForOneMonth',N'P')) LIKE N'%o.ExitDate IS NULL%'
               THEN 0 ELSE 1
           END,
           CASE
               WHEN OBJECT_DEFINITION(OBJECT_ID(N'Housing.BuildingRentForOneMonth',N'P')) LIKE N'%CAST(o.ExitDate AS date)%'
                AND OBJECT_DEFINITION(OBJECT_ID(N'Housing.BuildingRentForOneMonth',N'P')) LIKE N'%o.ExitDate IS NULL%'
               THEN 'PASS' ELSE 'FAIL'
           END,
           N'BuildingRentForOneMonth must pass ExitDate to the rent function and exclude months wholly after evacuation.';

    /* Row-value reconciliation for directly copied entities. */
    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Value reconciliation',N'ResidentInfo value differences',0,COUNT_BIG(*),COUNT_BIG(*),
           CASE WHEN COUNT_BIG(*)=0 THEN 'PASS' ELSE 'FAIL' END,
           N'Compares NationalID and active status for matching IDs.'
    FROM KFMC.Housing.ResidentInfo s JOIN Housing.ResidentInfo t
      ON t.residentInfoID=CONVERT(bigint,s.residentInfoID)
    WHERE ISNULL(t.NationalID,N'')<>ISNULL(s.NationalID,N'')
       OR ISNULL(t.residentInfoActive,0)<>ISNULL(s.residentInfoActive,0);

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Value reconciliation',N'Building value differences',0,COUNT_BIG(*),COUNT_BIG(*),
           CASE WHEN COUNT_BIG(*)=0 THEN 'PASS' ELSE 'FAIL' END,N'Compares normalized building number.'
    FROM KFMC.Housing.BuildingDetails s JOIN Housing.BuildingDetails t
      ON t.buildingDetailsID=CONVERT(bigint,s.buildingDetailsID)
    WHERE ISNULL(LTRIM(RTRIM(t.buildingDetailsNo)),N'')<>
          ISNULL(LTRIM(RTRIM(s.buildingDetailsNo)),N'');

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Value reconciliation',N'Meter value differences',0,COUNT_BIG(*),COUNT_BIG(*),
           CASE WHEN COUNT_BIG(*)=0 THEN 'PASS' ELSE 'FAIL' END,N'Compares normalized meter number.'
    FROM KFMC.Housing.Meter s JOIN Housing.Meter t ON t.meterID=CONVERT(bigint,s.meterID)
    WHERE ISNULL(LTRIM(RTRIM(t.meterNo)),N'')<>ISNULL(LTRIM(RTRIM(s.meterNo)),N'');

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Value reconciliation',N'BuildingAction value differences',0,COUNT_BIG(*),COUNT_BIG(*),
           CASE WHEN COUNT_BIG(*)=0 THEN 'PASS' ELSE 'FAIL' END,
           N'Compares mapped type, parent, active flag, and action date. Old evacuation type 3 maps by ExtraInt1.'
    FROM KFMC.Housing.BuildingAction s JOIN Housing.BuildingAction t
      ON t.buildingActionID=CONVERT(bigint,s.buildingActionID)
    LEFT JOIN #ValidationDuplicateActionMap parentDuplicate
      ON parentDuplicate.duplicateActionID=s.buildingActionParentID
    LEFT JOIN KFMC.Housing.BuildingAction letterAllocationParent
      ON letterAllocationParent.buildingActionID=s.buildingActionParentID
     AND letterAllocationParent.buildingActionTypeID_FK=27
     AND EXISTS
     (
         SELECT 1 FROM KFMC.Housing.BuildingAction letterRoot
         WHERE letterRoot.buildingActionID=letterAllocationParent.buildingActionParentID
           AND letterRoot.buildingActionTypeID_FK=7
     )
    WHERE
      (
       s.generalNo_FK IS NULL
       OR
       (
        s.generalNo_FK NOT IN (0,1)
        AND EXISTS
        (
         SELECT 1 FROM KFMC.Housing.ResidentInfo validResident
         WHERE validResident.generalNo=s.generalNo_FK
        )
       )
      )
      AND
      (
       ISNULL(t.buildingActionTypeID_FK,-1)<>
          ISNULL(CASE
              WHEN s.buildingActionTypeID_FK=3
                   AND s.buildingActionExtraInt1 IS NULL THEN 3
              WHEN s.buildingActionTypeID_FK=3
                   AND s.buildingActionExtraInt1=1 THEN 59
              WHEN s.buildingActionTypeID_FK=3
                   AND s.buildingActionExtraInt1 IN (2,3) THEN 57
              WHEN s.buildingActionTypeID_FK=3
                   AND s.buildingActionExtraInt1=4 THEN 58
              WHEN s.buildingActionTypeID_FK=3
                   AND s.buildingActionExtraInt1=5 THEN 3
              WHEN s.buildingActionTypeID_FK=18
                   AND s.generalNo_FK IS NOT NULL
                   AND NOT EXISTS
                   (
                       SELECT 1 FROM KFMC.Housing.BuildingAction laterAction
                       WHERE laterAction.generalNo_FK=s.generalNo_FK
                         AND laterAction.buildingActionID>s.buildingActionID
                   ) THEN 39
              ELSE s.buildingActionTypeID_FK
          END,-1)
       OR ISNULL(t.buildingActionParentID,-1)<>
          ISNULL(COALESCE
          (
              parentDuplicate.retainedActionID,
              CASE WHEN letterAllocationParent.buildingActionID IS NOT NULL
                   THEN letterAllocationParent.buildingActionParentID END,
              s.buildingActionParentID
          ),-1)
       OR ISNULL(t.buildingActionActive,0)<>ISNULL(s.buildingActionActive,0)
       OR ISNULL(t.buildingActionDate,CONVERT(datetime,'19000101',112))<>
          ISNULL(s.buildingActionDate,CONVERT(datetime,'19000101',112))
      )
      AND NOT
      (
          s.buildingActionTypeID_FK=27
          AND EXISTS
          (
              SELECT 1 FROM KFMC.Housing.BuildingAction letterRoot
              WHERE letterRoot.buildingActionID=s.buildingActionParentID
              AND letterRoot.buildingActionTypeID_FK=7
          )
      )
      AND NOT
      (
          s.buildingActionTypeID_FK=2
          AND EXISTS
          (
              SELECT 1
              FROM Housing.BuildingAction generatedParent
              WHERE generatedParent.buildingActionID=t.buildingActionParentID
                AND generatedParent.buildingActionTypeID_FK=47
                AND generatedParent.buildingActionExtraText4 LIKE N'MoveData:Accept:%:47'
          )
      );

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Integrity',N'Excluded invalid-general-number actions present',
           0,COUNT_BIG(*),COUNT_BIG(*),
           CASE WHEN COUNT_BIG(*)=0 THEN 'PASS' ELSE 'FAIL' END,
           N'Actions with general number 0/1 or a non-NULL number absent from KFMC ResidentInfo must not be migrated. NULL building-only actions remain valid.'
    FROM Housing.BuildingAction targetAction
    JOIN KFMC.Housing.BuildingAction sourceAction
      ON sourceAction.buildingActionID=targetAction.buildingActionID
    WHERE sourceAction.generalNo_FK IN (0,1)
       OR
       (
           sourceAction.generalNo_FK IS NOT NULL
           AND NOT EXISTS
           (
               SELECT 1 FROM KFMC.Housing.ResidentInfo validResident
               WHERE validResident.generalNo=sourceAction.generalNo_FK
           )
       );

    /* Action 27 is an allocation stage, never a workflow root. General numbers
       0 and 1 are retained cancellation/audit rows and are intentionally ignored. */
    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Business rules',N'Meaningful action 27 without parent action 1 or 7',
           0,COUNT_BIG(*),COUNT_BIG(*),
           CASE WHEN COUNT_BIG(*)=0 THEN 'PASS' ELSE 'FAIL' END,
           N'Action 27 must be a child of action 1 or 7. Cancellation rows with general number 0 or 1 are preserved and excluded.'
    FROM Housing.BuildingAction action27
    WHERE action27.buildingActionTypeID_FK=27
      AND action27.buildingActionActive=1
      AND ISNULL(action27.generalNo_FK,0) NOT IN (0,1)
      AND NOT EXISTS
      (
          SELECT 1
          FROM Housing.BuildingAction rootAction
          WHERE rootAction.buildingActionID=action27.buildingActionParentID
            AND rootAction.buildingActionActive=1
            AND rootAction.buildingActionTypeID_FK IN (1,7)
      );

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Business rules',N'Duplicate waiting-list traversal for same final action',
           0,COUNT_BIG(*),COUNT_BIG(*),
           CASE WHEN COUNT_BIG(*)=0 THEN 'PASS' ELSE 'FAIL' END,
           N'V_WaitingList must not traverse the same resident, building, and final action from more than one root.'
    FROM
    (
        SELECT waiting.residentInfoID,waiting.buildingDetailsID,waiting.LastActionID
        FROM Housing.V_WaitingList waiting
        WHERE waiting.IdaraId=@IdaraId
          AND waiting.LastActionID IS NOT NULL
        GROUP BY waiting.residentInfoID,waiting.buildingDetailsID,waiting.LastActionID
        HAVING COUNT_BIG(*)>1
    ) duplicateTraversal;

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Allocation migration',N'Pending legacy allocations hidden from AssignStatusDL',
           0,COUNT_BIG(*),COUNT_BIG(*),
           CASE WHEN COUNT_BIG(*)=0 THEN 'PASS' ELSE 'FAIL' END,
           N'Migration-generated pending actions 38/40 belong to closed historical periods and must have InAssignPeriod = 0.'
    FROM Housing.BuildingAction pendingAllocation
    WHERE pendingAllocation.buildingActionTypeID_FK IN (38,40)
      AND pendingAllocation.buildingActionExtraText4 LIKE N'MoveData:Assign:%'
      AND ISNULL(pendingAllocation.InAssignPeriod,-1)<>0;

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Evacuation actions',N'Evacuation actions completeness',s.c,t.c,t.c-s.c,
           CASE WHEN s.c=t.c THEN 'PASS' ELSE 'FAIL' END,
           N'All old type-3 actions must be migrated, except consecutive identical actions excluded by the migration rule.'
    FROM
    (
        SELECT COUNT_BIG(*) c
        FROM KFMC.Housing.BuildingAction sourceAction
        WHERE sourceAction.buildingActionTypeID_FK=3
          AND NOT EXISTS
          (
              SELECT 1 FROM #ValidationDuplicateActionMap duplicateAction
              WHERE duplicateAction.duplicateActionID=sourceAction.buildingActionID
          )
    ) s
    CROSS JOIN
    (
        SELECT COUNT_BIG(*) c
        FROM KFMC.Housing.BuildingAction sourceAction
        JOIN Housing.BuildingAction targetAction
          ON targetAction.buildingActionID=CONVERT(bigint,sourceAction.buildingActionID)
        WHERE sourceAction.buildingActionTypeID_FK=3
    ) t;

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Evacuation actions',N'Evacuation action type mapping differences',0,COUNT_BIG(*),COUNT_BIG(*),
           CASE WHEN COUNT_BIG(*)=0 THEN 'PASS' ELSE 'FAIL' END,
           N'Old ExtraInt1: NULL/5->3, 1->59, 2/3->57, 4->58.'
    FROM KFMC.Housing.BuildingAction sourceAction
    JOIN Housing.BuildingAction targetAction
      ON targetAction.buildingActionID=CONVERT(bigint,sourceAction.buildingActionID)
    WHERE sourceAction.buildingActionTypeID_FK=3
      AND targetAction.buildingActionTypeID_FK<>
          CASE
              WHEN sourceAction.buildingActionExtraInt1 IS NULL
                   OR sourceAction.buildingActionExtraInt1=5 THEN 3
              WHEN sourceAction.buildingActionExtraInt1=1 THEN 59
              WHEN sourceAction.buildingActionExtraInt1 IN(2,3) THEN 57
              WHEN sourceAction.buildingActionExtraInt1=4 THEN 58
              ELSE -1
          END;

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Evacuation actions',N'Unsupported old evacuation stages',0,COUNT_BIG(*),COUNT_BIG(*),
           CASE WHEN COUNT_BIG(*)=0 THEN 'PASS' ELSE 'FAIL' END,
           N'Only NULL and values 1,2,3,4,5 are supported in old buildingActionExtraInt1.'
    FROM KFMC.Housing.BuildingAction
    WHERE buildingActionTypeID_FK=3
      AND buildingActionExtraInt1 IS NOT NULL
      AND buildingActionExtraInt1 NOT IN(1,2,3,4,5);

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Evacuation actions',N'Evacuation effective-date mapping differences',0,COUNT_BIG(*),COUNT_BIG(*),
           CASE WHEN COUNT_BIG(*)=0 THEN 'PASS' ELSE 'FAIL' END,
           N'Every old type-3 action retains its recorded buildingActionDate as effective ExitDate, regardless of workflow stage.'
    FROM KFMC.Housing.BuildingAction sourceAction
    JOIN Housing.BuildingAction targetAction
      ON targetAction.buildingActionID=CONVERT(bigint,sourceAction.buildingActionID)
    WHERE sourceAction.buildingActionTypeID_FK=3
      AND ISNULL(targetAction.ExitDate,CONVERT(datetime,'19000101',112))<>
          ISNULL(sourceAction.buildingActionDate,CONVERT(datetime,'19000101',112));

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Evacuation actions',N'Evacuation workflow actions missing effective dates',0,COUNT_BIG(*),COUNT_BIG(*),
           CASE WHEN COUNT_BIG(*)=0 THEN 'PASS' ELSE 'FAIL' END,
           N'Workflow status and effective evacuation date are independent; migrated stages 57/58/59 must retain OccupentDate and ExitDate.'
    FROM KFMC.Housing.BuildingAction sourceAction
    JOIN Housing.BuildingAction targetAction
      ON targetAction.buildingActionID=CONVERT(bigint,sourceAction.buildingActionID)
    WHERE sourceAction.buildingActionTypeID_FK=3
      AND sourceAction.buildingActionExtraInt1 IN(1,2,3,4)
      AND (targetAction.ExitDate IS NULL OR targetAction.OccupentDate IS NULL);

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Value reconciliation',N'BuildingAction extend reason differences',0,COUNT_BIG(*),COUNT_BIG(*),
           CASE WHEN COUNT_BIG(*)=0 THEN 'PASS' ELSE 'FAIL' END,
           N'For action type 24: old extra type 2->1, 3->3, 4->2.'
    FROM KFMC.Housing.BuildingAction s
    JOIN Housing.BuildingAction t ON t.buildingActionID=CONVERT(bigint,s.buildingActionID)
    WHERE s.buildingActionTypeID_FK=24
      AND ISNULL(t.ExtendReasonTypeID_FK,-1) <>
          ISNULL(CASE
              WHEN s.buildingActionExtraType1=2 THEN 1
              WHEN s.buildingActionExtraType1=3 THEN 3
              WHEN s.buildingActionExtraType1=4 THEN 2
          END,-1);

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Value reconciliation',N'Extend insurance value differences',0,COUNT_BIG(*),COUNT_BIG(*),
           CASE WHEN COUNT_BIG(*)=0 THEN 'PASS' ELSE 'FAIL' END,
           N'Compares amount, remaining, type, approval flag, number, and date.'
    FROM
    (
        SELECT retainedAction.*
        FROM
        (
            SELECT actionRow.*,
                   ROW_NUMBER() OVER
                   (
                       PARTITION BY actionRow.generalNo_FK
                       ORDER BY ISNULL(actionRow.buildingActionDate, actionRow.entryDate) DESC,
                                actionRow.buildingActionID DESC
                   ) rowNumber
            FROM Housing.BuildingAction actionRow
            WHERE actionRow.generalNo_FK IS NOT NULL
              AND ISNULL(actionRow.buildingActionActive,1)=1
        ) retainedAction
        WHERE retainedAction.rowNumber=1
          AND retainedAction.buildingActionTypeID_FK=24
          AND retainedAction.buildingActionExtraType1=2
    ) s
    JOIN Housing.ExtendInsurance t ON t.buildingActionID_FK=s.buildingActionID
    WHERE CAST(ISNULL(t.InsuranceAmount,0) AS decimal(18,2))<>
          CAST(ISNULL(s.buildingActionExtraFloat1,0) AS decimal(18,2))
       OR ISNULL(t.Remaining,0)<>0
       OR CAST(ISNULL(t.InsuranceAmountWithRemaining,0) AS decimal(18,2))<>
          CAST(ISNULL(s.buildingActionExtraFloat1,0) AS decimal(18,2))
       OR ISNULL(t.ExtendInsuranceNo,N'')<>ISNULL(s.buildingActionDecisionNo,N'')
       OR ISNULL(t.ExtendInsuranceDate,CONVERT(datetime,'19000101',112))<>ISNULL(s.entryDate,CONVERT(datetime,'19000101',112))
       OR ISNULL(t.ExtendInsuranceType,-1)<>1
       OR ISNULL(t.ExtendInsuranceActive,0)<>1
       OR ISNULL(t.ExtendInsuranceApproved,1)<>0;

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Value reconciliation',N'Missing or changed resident contacts',0,COUNT_BIG(*),COUNT_BIG(*),
           CASE WHEN COUNT_BIG(*)=0 THEN 'PASS' ELSE 'FAIL' END,
           N'Compares type, details, dates, and active status for resident contacts.'
    FROM KFMC.dbo.contactInfo sc
    JOIN KFMC.Housing.ResidentInfo sr ON sr.generalNo=sc.userID_FK
    JOIN Housing.ResidentInfo tr ON tr.residentInfoID=CONVERT(bigint,sr.residentInfoID)
    WHERE NOT EXISTS
    (
        SELECT 1 FROM Housing.ResidentContactInfo tc
        WHERE tc.residentInfoID_FK=tr.residentInfoID
          AND ISNULL(tc.residentcontanctTypeID_FK,-1)=ISNULL(sc.contanctTypeID_FK,-1)
          AND ISNULL(tc.residentcontactDetails,N'')=ISNULL(sc.contactDetails,N'')
          AND ISNULL(tc.residentcontactInfoStartDate,CONVERT(datetime,'19000101',112))=
              ISNULL(sc.contactInfoStartDate,CONVERT(datetime,'19000101',112))
          AND ISNULL(tc.residentcontactInfoEndDate,CONVERT(datetime,'19000101',112))=
              ISNULL(sc.contactInfoEndDate,CONVERT(datetime,'19000101',112))
          AND ISNULL(tc.residentcontactInfoActive,0)=ISNULL(sc.contactInfoActive,0)
    );

    /* Generated-bill uniqueness and pairing for occupied periods. */
    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Generated bills',N'Duplicate occupied rent/water monthly bill groups',0,COUNT_BIG(*),COUNT_BIG(*),
           CASE WHEN COUNT_BIG(*)=0 THEN 'PASS' ELSE 'FAIL' END,
           N'One bill per charge type, resident, building, year, and month for occupied periods.'
    FROM
    (
        SELECT BillChargeTypeID_FK,residentInfoID_FK,buildingDetailsID,PeriodYear,PeriodMonth
        FROM Housing.Bills
        WHERE BillChargeTypeID_FK IN(1,3) AND idaraID_FK=@IdaraId AND BillActive=1
          AND residentInfoID_FK IS NOT NULL
        GROUP BY BillChargeTypeID_FK,residentInfoID_FK,buildingDetailsID,PeriodYear,PeriodMonth
        HAVING COUNT_BIG(*)>1
    ) duplicateGroup;

    ;WITH OccupiedMonthlyPairs AS
    (
        SELECT residentInfoID_FK,buildingDetailsID,PeriodYear,PeriodMonth,
               SUM(CASE WHEN BillChargeTypeID_FK=1 THEN 1 ELSE 0 END) RentCount,
               SUM(CASE WHEN BillChargeTypeID_FK=3 THEN 1 ELSE 0 END) WaterCount
        FROM Housing.Bills
        WHERE BillChargeTypeID_FK IN(1,3) AND idaraID_FK=@IdaraId AND BillActive=1
          AND residentInfoID_FK IS NOT NULL
        GROUP BY residentInfoID_FK,buildingDetailsID,PeriodYear,PeriodMonth
    )
    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Generated bills',N'Unpaired occupied monthly rent/water bills',0,COUNT_BIG(*),COUNT_BIG(*),
           CASE WHEN COUNT_BIG(*)=0 THEN 'PASS' ELSE 'FAIL' END,
           N'From 2024-01 onward, every occupied migrated month must contain one rent and one water bill.'
    FROM OccupiedMonthlyPairs
    WHERE DATEFROMPARTS(PeriodYear,PeriodMonth,1)>=@WaterChargeStartDate
      AND (RentCount<>1 OR WaterCount<>1);

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Vacant service bills',N'Rent bills generated for vacant periods',0,COUNT_BIG(*),COUNT_BIG(*),
           CASE WHEN COUNT_BIG(*)=0 THEN 'PASS' ELSE 'FAIL' END,
           N'Vacant periods may receive fixed-service bills but must never receive rent bills.'
    FROM Housing.Bills
    WHERE BillChargeTypeID_FK=1 AND idaraID_FK=@IdaraId AND BillActive=1
      AND residentInfoID_FK IS NULL AND generalNo_FK IS NULL;

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Vacant service bills',N'Duplicate exact vacant-water periods',0,COUNT_BIG(*),COUNT_BIG(*),
           CASE WHEN COUNT_BIG(*)=0 THEN 'PASS' ELSE 'FAIL' END,
           N'Only one active water bill may represent the same building and exact vacant date range.'
    FROM
    (
        SELECT buildingDetailsID,BillsFromDate,BillsToDate
        FROM Housing.Bills
        WHERE BillChargeTypeID_FK=3 AND idaraID_FK=@IdaraId AND BillActive=1
          AND residentInfoID_FK IS NULL AND generalNo_FK IS NULL
        GROUP BY buildingDetailsID,BillsFromDate,BillsToDate
        HAVING COUNT_BIG(*)>1
    ) duplicateVacancy;

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Vacant service bills',N'Overlapping distinct vacant-water periods',0,COUNT_BIG(*),COUNT_BIG(*),
           CASE WHEN COUNT_BIG(*)=0 THEN 'PASS' ELSE 'FAIL' END,
           N'Distinct vacant-water periods for one building must not overlap; separate non-overlapping gaps in one month are valid.'
    FROM Housing.Bills firstBill
    JOIN Housing.Bills secondBill
      ON secondBill.BillsID>firstBill.BillsID
     AND secondBill.buildingDetailsID=firstBill.buildingDetailsID
     AND secondBill.BillChargeTypeID_FK=3
     AND secondBill.idaraID_FK=@IdaraId
     AND secondBill.BillActive=1
     AND secondBill.residentInfoID_FK IS NULL
     AND secondBill.generalNo_FK IS NULL
     AND secondBill.BillsFromDate<=firstBill.BillsToDate
     AND secondBill.BillsToDate>=firstBill.BillsFromDate
     AND NOT (secondBill.BillsFromDate=firstBill.BillsFromDate AND secondBill.BillsToDate=firstBill.BillsToDate)
    WHERE firstBill.BillChargeTypeID_FK=3 AND firstBill.idaraID_FK=@IdaraId
      AND firstBill.BillActive=1 AND firstBill.residentInfoID_FK IS NULL
      AND firstBill.generalNo_FK IS NULL;

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Vacant service bills',N'Vacant water bills carrying a general number',0,COUNT_BIG(*),COUNT_BIG(*),
           CASE WHEN COUNT_BIG(*)=0 THEN 'PASS' ELSE 'FAIL' END,
           N'A water bill without a resident must not retain a general number from a previous or later occupant.'
    FROM Housing.Bills
    WHERE BillChargeTypeID_FK=3 AND idaraID_FK=@IdaraId AND BillActive=1
      AND residentInfoID_FK IS NULL AND generalNo_FK IS NOT NULL;
    ;WITH WaterCalculation AS
    (
        SELECT b.BillsID,b.PRICE,b.PRICETAX,b.TotalPrice,
               ((YEAR(b.BillsToDate)-YEAR(b.BillsFromDate))*360
                +(MONTH(b.BillsToDate)-MONTH(b.BillsFromDate))*30
                +(CASE WHEN b.BillsToDate=EOMONTH(b.BillsToDate) AND DAY(b.BillsToDate)<30 THEN 30
                       WHEN DAY(b.BillsToDate)>30 THEN 30 ELSE DAY(b.BillsToDate) END)
                -(CASE WHEN b.BillsFromDate=EOMONTH(b.BillsFromDate) AND DAY(b.BillsFromDate)<30 THEN 30
                       WHEN DAY(b.BillsFromDate)>30 THEN 30 ELSE DAY(b.BillsFromDate) END)+1) Days30
        FROM Housing.Bills b
        WHERE b.BillChargeTypeID_FK=3 AND b.idaraID_FK=@IdaraId AND b.BillActive=1
    )
    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Generated bills',N'Incorrect water-bill calculations',0,COUNT_BIG(*),COUNT_BIG(*),
           CASE WHEN COUNT_BIG(*)=0 THEN 'PASS' ELSE 'FAIL' END,
           N'Expected amount is WaterMonthlyAmount divided by 30 and multiplied by Days30.'
    FROM WaterCalculation
    WHERE TotalPrice<>CAST((@WaterMonthlyAmount/30.0)*Days30 AS decimal(18,2));

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Generated bills',N'Incorrect water VAT separation',0,COUNT_BIG(*),COUNT_BIG(*),
           CASE WHEN COUNT_BIG(*)=0 THEN 'PASS' ELSE 'FAIL' END,
           N'Water TotalPrice is VAT-inclusive; PRICE is net of 15% VAT and PRICETAX is the separated VAT amount.'
    FROM Housing.Bills waterBill
    WHERE waterBill.BillChargeTypeID_FK=3
      AND waterBill.idaraID_FK=@IdaraId
      AND waterBill.BillActive=1
      AND
      (
          CAST(ISNULL(waterBill.PRICE,0)+ISNULL(waterBill.PRICETAX,0) AS decimal(18,2))
              <>CAST(ISNULL(waterBill.TotalPrice,0) AS decimal(18,2))
          OR CAST(ISNULL(waterBill.PRICE,0) AS decimal(18,2))
              <>CAST(ROUND(ISNULL(waterBill.TotalPrice,0)/CAST(1.15 AS decimal(18,4)),2) AS decimal(18,2))
          OR CAST(ISNULL(waterBill.PRICETAX,0) AS decimal(18,2))
              <>CAST
                (
                    ISNULL(waterBill.TotalPrice,0)
                    -ROUND(ISNULL(waterBill.TotalPrice,0)/CAST(1.15 AS decimal(18,4)),2)
                    AS decimal(18,2)
                )
      );

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Generated bills',N'No migrated rent/water bills in cutover month',0,COUNT_BIG(*),COUNT_BIG(*),
           CASE WHEN COUNT_BIG(*)=0 THEN 'PASS' ELSE 'FAIL' END,
           CASE WHEN @CutoverDate IS NULL THEN N'CutoverDate was not supplied; check skipped.'
                ELSE N'The cutover month must be generated by the new system only.' END
    FROM Housing.Bills
    WHERE @CutoverDate IS NOT NULL
      AND BillChargeTypeID_FK IN (1,3)
      AND idaraID_FK=@IdaraId
      AND PeriodYear=YEAR(@CutoverDate)
      AND PeriodMonth=MONTH(@CutoverDate)
      AND BillActive=1;

    /* New-system billing-period and fixed-service contract. */
    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Billing periods',N'Water bills without current billing period',0,COUNT_BIG(*),COUNT_BIG(*),CASE WHEN COUNT_BIG(*)=0 THEN 'PASS' ELSE 'FAIL' END,N'Every migrated water bill must link to its generated monthly water period.'
    FROM Housing.Bills WHERE BillChargeTypeID_FK=3 AND idaraID_FK=@IdaraId AND BillActive=1 AND CurrentPeriodID IS NULL;

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Billing periods',N'Water bills linked to incorrect billing period',0,COUNT_BIG(*),COUNT_BIG(*),CASE WHEN COUNT_BIG(*)=0 THEN 'PASS' ELSE 'FAIL' END,N'The current period must belong to the same administration, water service, and cover the bill dates.'
    FROM Housing.Bills b
    LEFT JOIN Housing.BillPeriod bp ON bp.billPeriodID=b.CurrentPeriodID
    LEFT JOIN Housing.BillPeriodType bpt ON bpt.billPeriodTypeID=bp.billPeriodTypeID_FK
    WHERE b.BillChargeTypeID_FK=3 AND b.idaraID_FK=@IdaraId AND b.BillActive=1
      AND (bp.billPeriodID IS NULL OR bp.IdaraId_FK<>@IdaraId OR bpt.meterServiceTypeID_FK<>2 OR CAST(bp.billPeriodStartDate AS date)>CAST(b.BillsFromDate AS date) OR CAST(bp.billPeriodEndDate AS date)<CAST(b.BillsToDate AS date));

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Billing periods',N'Water bills missing an available previous period',0,COUNT_BIG(*),COUNT_BIG(*),CASE WHEN COUNT_BIG(*)=0 THEN 'PASS' ELSE 'FAIL' END,N'PreviousPeriodID is required when an earlier water period exists.'
    FROM Housing.Bills b
    JOIN Housing.BillPeriod currentPeriod ON currentPeriod.billPeriodID=b.CurrentPeriodID
    WHERE b.BillChargeTypeID_FK=3 AND b.idaraID_FK=@IdaraId AND b.BillActive=1 AND b.PerviosPeriodID IS NULL
      AND EXISTS(SELECT 1 FROM Housing.BillPeriod previousPeriod JOIN Housing.BillPeriodType previousType ON previousType.billPeriodTypeID=previousPeriod.billPeriodTypeID_FK WHERE previousPeriod.IdaraId_FK=@IdaraId AND previousType.meterServiceTypeID_FK=2 AND previousPeriod.billPeriodStartDate<currentPeriod.billPeriodStartDate);

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Bills',N'Water bills missing available building utility type',0,COUNT_BIG(*),COUNT_BIG(*),CASE WHEN COUNT_BIG(*)=0 THEN 'PASS' ELSE 'FAIL' END,N'Water bills must copy buildingUtilityTypeID_FK from BuildingDetails when it is available.'
    FROM Housing.Bills b JOIN Housing.BuildingDetails building ON building.buildingDetailsID=b.buildingDetailsID
    WHERE b.BillChargeTypeID_FK=3 AND b.idaraID_FK=@IdaraId AND b.BillActive=1 AND building.buildingUtilityTypeID_FK IS NOT NULL AND b.buildingUtilityTypeID IS NULL;

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Fixed services',N'Missing or mismatched active water fixed amount',0,COUNT_BIG(*),COUNT_BIG(*),CASE WHEN COUNT_BIG(*)=0 THEN 'PASS' ELSE 'FAIL' END,N'Water fixed amount is stored net of 15 percent VAT and must reconcile to WaterMonthlyAmount.'
    FROM (SELECT 1 RequiredRow) required
    WHERE NOT EXISTS(SELECT 1 FROM Housing.MeterServiceTypeFixedAmount amount WHERE amount.MeterServiceTypeID_FK=2 AND amount.idaraID_FK=@IdaraId AND amount.MeterServiceTypeFixedAmountActive=1 AND amount.FixedAmount=CAST(ROUND(@WaterMonthlyAmount/CAST(1.15 AS decimal(18,4)),2) AS decimal(18,2)));

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Billing periods',N'Electric bills missing an available previous period',0,COUNT_BIG(*),COUNT_BIG(*),CASE WHEN COUNT_BIG(*)=0 THEN 'PASS' ELSE 'FAIL' END,N'An electricity bill requires PreviousPeriodID when the same meter has an earlier migrated bill.'
    FROM Housing.Bills b
    JOIN Housing.BillPeriod currentPeriod ON currentPeriod.billPeriodID=b.CurrentPeriodID
    WHERE b.BillChargeTypeID_FK=2 AND b.idaraID_FK=@IdaraId AND b.BillActive=1 AND b.meterID IS NOT NULL AND b.PerviosPeriodID IS NULL
      AND EXISTS(SELECT 1 FROM Housing.Bills previousBill JOIN Housing.BillPeriod previousPeriod ON previousPeriod.billPeriodID=previousBill.CurrentPeriodID WHERE previousBill.BillChargeTypeID_FK=2 AND previousBill.idaraID_FK=@IdaraId AND previousBill.BillActive=1 AND previousBill.meterID=b.meterID AND previousBill.BillsID<>b.BillsID AND previousPeriod.billPeriodStartDate<currentPeriod.billPeriodStartDate);

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Billing periods',N'Electric bills linked to invalid previous period',0,COUNT_BIG(*),COUNT_BIG(*),CASE WHEN COUNT_BIG(*)=0 THEN 'PASS' ELSE 'FAIL' END,N'Previous electricity period must belong to the same administration and service and precede the current period.'
    FROM Housing.Bills b
    JOIN Housing.BillPeriod currentPeriod ON currentPeriod.billPeriodID=b.CurrentPeriodID
    LEFT JOIN Housing.BillPeriod previousPeriod ON previousPeriod.billPeriodID=b.PerviosPeriodID
    LEFT JOIN Housing.BillPeriodType previousType ON previousType.billPeriodTypeID=previousPeriod.billPeriodTypeID_FK
    WHERE b.BillChargeTypeID_FK=2 AND b.idaraID_FK=@IdaraId AND b.BillActive=1 AND b.PerviosPeriodID IS NOT NULL
      AND (previousPeriod.billPeriodID IS NULL OR previousPeriod.IdaraId_FK<>@IdaraId OR previousType.meterServiceTypeID_FK<>1 OR previousPeriod.billPeriodStartDate>=currentPeriod.billPeriodStartDate);
    /* Broken relationships and business invariants. Expected value is zero. */
    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Integrity',N'ResidentDetails without ResidentInfo',0,COUNT_BIG(*),COUNT_BIG(*),
           CASE WHEN COUNT_BIG(*)=0 THEN 'PASS' ELSE 'FAIL' END,NULL
    FROM Housing.ResidentDetails d LEFT JOIN Housing.ResidentInfo r
      ON r.residentInfoID=d.residentInfoID_FK WHERE r.residentInfoID IS NULL;

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Integrity',N'ResidentDetails without MilitaryUnit',0,COUNT_BIG(*),COUNT_BIG(*),
           CASE WHEN COUNT_BIG(*)=0 THEN 'PASS' ELSE 'FAIL' END,NULL
    FROM Housing.ResidentDetails d LEFT JOIN dbo.MilitaryUnit u
      ON u.militaryUnitID=d.militaryUnitID_FK
    WHERE d.militaryUnitID_FK IS NOT NULL AND u.militaryUnitID IS NULL;

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Integrity',N'Resident contacts without resident',0,COUNT_BIG(*),COUNT_BIG(*),
           CASE WHEN COUNT_BIG(*)=0 THEN 'PASS' ELSE 'FAIL' END,NULL
    FROM Housing.ResidentContactInfo c LEFT JOIN Housing.ResidentInfo r
      ON r.residentInfoID=c.residentInfoID_FK WHERE r.residentInfoID IS NULL;

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Integrity',N'Extend insurance without action or resident',0,COUNT_BIG(*),COUNT_BIG(*),
           CASE WHEN COUNT_BIG(*)=0 THEN 'PASS' ELSE 'FAIL' END,NULL
    FROM Housing.ExtendInsurance insurance
    LEFT JOIN Housing.BuildingAction actionRow
      ON actionRow.buildingActionID=insurance.buildingActionID_FK
    LEFT JOIN Housing.ResidentInfo resident
      ON resident.residentInfoID=insurance.residentInfoID_FK
    WHERE insurance.IdaraId_FK=@IdaraId
      AND (actionRow.buildingActionID IS NULL OR resident.residentInfoID IS NULL);

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Business rules',N'Active housing actions missing OccupentDate',0,COUNT_BIG(*),COUNT_BIG(*),
           CASE WHEN COUNT_BIG(*)=0 THEN 'PASS' ELSE 'FAIL' END,NULL
    FROM Housing.BuildingAction
    WHERE buildingActionTypeID_FK=2 AND buildingActionActive=1 AND OccupentDate IS NULL;

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Business rules',N'Active exit actions missing dates',0,COUNT_BIG(*),COUNT_BIG(*),
           CASE WHEN COUNT_BIG(*)=0 THEN 'PASS' ELSE 'FAIL' END,NULL
    FROM Housing.BuildingAction
    WHERE buildingActionTypeID_FK=3 AND buildingActionActive=1
      AND (OccupentDate IS NULL OR ExitDate IS NULL);

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Business rules',N'Exit date earlier than occupancy date',0,COUNT_BIG(*),COUNT_BIG(*),
           CASE WHEN COUNT_BIG(*)=0 THEN 'PASS' ELSE 'FAIL' END,NULL
    FROM Housing.BuildingAction WHERE buildingActionTypeID_FK=3 AND OccupentDate>ExitDate;

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Bills',N'Bills without BillNumber',0,COUNT_BIG(*),COUNT_BIG(*),
           CASE WHEN COUNT_BIG(*)=0 THEN 'PASS' ELSE 'FAIL' END,NULL
    FROM Housing.Bills WHERE NULLIF(LTRIM(RTRIM(BillNumber)),N'') IS NULL;

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Bills',N'Duplicate BillNumber values',0,COUNT_BIG(*),COUNT_BIG(*),
           CASE WHEN COUNT_BIG(*)=0 THEN 'PASS' ELSE 'FAIL' END,N'Actual is the number of duplicated bill-number groups.'
    FROM (SELECT BillNumber FROM Housing.Bills GROUP BY BillNumber HAVING COUNT_BIG(*)>1) d;

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Payments',N'Active payments without link status',0,COUNT_BIG(*),COUNT_BIG(*),
           CASE WHEN COUNT_BIG(*)=0 THEN 'PASS' ELSE 'FAIL' END,NULL
    FROM Housing.BuildingPayment
    WHERE buildingPayementActive=1 AND buildingPaymentLinkStatusID_FK IS NULL;

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Payments',N'Status-1 payments missing resident or building',0,COUNT_BIG(*),COUNT_BIG(*),
           CASE WHEN COUNT_BIG(*)=0 THEN 'PASS' ELSE 'FAIL' END,NULL
    FROM Housing.BuildingPayment
    WHERE buildingPayementActive=1 AND buildingPaymentLinkStatusID_FK=1
      AND (residentInfoID_FK IS NULL OR NULLIF(LTRIM(RTRIM(buildingDetailsID_FK)),N'') IS NULL);

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Entry metadata',N'Migration-generated text in entryData',0,SUM(x.BadCount),SUM(x.BadCount),
           CASE WHEN SUM(x.BadCount)=0 THEN 'PASS' ELSE 'FAIL' END,
           N'Values originating in KFMC are preserved exactly; migration literals are forbidden.'
    FROM
    (
        SELECT COUNT_BIG(*) BadCount FROM Housing.Bills WHERE entryData LIKE N'MIGRATION%'
        UNION ALL SELECT COUNT_BIG(*) FROM Housing.BuildingPayment WHERE entryData LIKE N'MIGRATION%'
        UNION ALL SELECT COUNT_BIG(*) FROM Housing.DeductList WHERE entryData LIKE N'MIGRATION%'
    ) x;

    /* Known historical gaps are warnings, not migration failures. */
    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Historical warnings',N'Meter reads without resident',0,COUNT_BIG(*),COUNT_BIG(*),
           CASE WHEN COUNT_BIG(*)=0 THEN 'PASS' ELSE 'WARN' END,N'Preserved historical data.'
    FROM Housing.MeterRead WHERE residentInfoID_FK IS NULL AND generalNo_FK IS NOT NULL;

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Historical warnings',N'Meter reads without building',0,COUNT_BIG(*),COUNT_BIG(*),
           CASE WHEN COUNT_BIG(*)=0 THEN 'PASS' ELSE 'WARN' END,N'Preserved historical data.'
    FROM Housing.MeterRead
    WHERE buildingDetailsID IS NULL AND NULLIF(LTRIM(RTRIM(buildingDetailsNo)),N'') IS NOT NULL;

    INSERT @Checks(Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes)
    SELECT N'Historical warnings',N'Unexpected building actions with unmatched building',0,COUNT_BIG(*),COUNT_BIG(*),
           CASE WHEN COUNT_BIG(*)=0 THEN 'PASS' ELSE 'WARN' END,
           N'Known building-workflow types 4,5,8-17,29-31 are accepted and excluded.'
    FROM Housing.BuildingAction
    WHERE buildingDetailsID_FK IS NULL
      AND generalNo_FK IS NULL
      AND NULLIF(LTRIM(RTRIM(buildingDetailsNo)),N'') IS NOT NULL
      AND (buildingActionTypeID_FK IS NULL
           OR buildingActionTypeID_FK NOT IN (4,5,8,9,10,11,12,13,14,15,16,17,29,30,31));

    /* Overall result first. */
    SELECT
        CASE WHEN EXISTS(SELECT 1 FROM @Checks WHERE Result='FAIL') THEN 'FAIL'
             WHEN EXISTS(SELECT 1 FROM @Checks WHERE Result='WARN') THEN 'PASS_WITH_WARNINGS'
             ELSE 'PASS' END OverallResult,
        SUM(CASE WHEN Result='PASS' THEN 1 ELSE 0 END) PassedChecks,
        SUM(CASE WHEN Result='WARN' THEN 1 ELSE 0 END) WarningChecks,
        SUM(CASE WHEN Result='FAIL' THEN 1 ELSE 0 END) FailedChecks,
        GETDATE() ValidationDate
    FROM @Checks;

    SELECT Category,CheckName,ExpectedValue,ActualValue,Difference,Result,Notes
    FROM @Checks
    ORDER BY CASE Result WHEN 'FAIL' THEN 1 WHEN 'WARN' THEN 2 ELSE 3 END,CheckOrder;

    /* Financial reconciliation used by the new calculation. */
    SELECT chargeType.BillChargeTypeID,chargeType.BillChargeTypeName_A,
           ISNULL(b.TotalBills,0) TotalBills,ISNULL(p.TotalPayments,0) LinkedPayments,
           ISNULL(b.TotalBills,0)-ISNULL(p.TotalPayments,0) Remaining
    FROM Housing.BillChargeType chargeType
    LEFT JOIN
    (
        SELECT BillChargeTypeID_FK,SUM(TotalPrice) TotalBills
        FROM Housing.Bills WHERE BillActive=1 AND idaraID_FK=@IdaraId
        GROUP BY BillChargeTypeID_FK
    ) b ON b.BillChargeTypeID_FK=chargeType.BillChargeTypeID
    LEFT JOIN
    (
        SELECT bp.BillChargeTypeID_FK,SUM(bp.amount) TotalPayments
        FROM Housing.BuildingPayment bp JOIN Housing.DeductList dl
          ON dl.deductListID=bp.deductListID_FK
        WHERE bp.buildingPayementActive=1 AND dl.deductActive=1
          AND bp.buildingPaymentLinkStatusID_FK=1 AND bp.IdaraId_FK=@IdaraId
        GROUP BY bp.BillChargeTypeID_FK
    ) p ON p.BillChargeTypeID_FK=chargeType.BillChargeTypeID
    WHERE chargeType.BillChargeTypeID IN(1,2,3,5)
    ORDER BY chargeType.BillChargeTypeID;

    /* Preserved but not necessarily counted payment balances. */
    SELECT bp.BillChargeTypeID_FK,ct.BillChargeTypeName_A,
           bp.buildingPaymentLinkStatusID_FK,ls.buildingPaymentLinkStatusName_A,
           COUNT_BIG(*) PaymentCount,SUM(bp.amount) PaymentTotal
    FROM Housing.BuildingPayment bp
    LEFT JOIN Housing.BillChargeType ct ON ct.BillChargeTypeID=bp.BillChargeTypeID_FK
    LEFT JOIN Housing.BuildingPaymentLinkStatus ls
      ON ls.buildingPaymentLinkStatusID=bp.buildingPaymentLinkStatusID_FK
    WHERE bp.buildingPayementActive=1 AND bp.IdaraId_FK=@IdaraId
    GROUP BY bp.BillChargeTypeID_FK,ct.BillChargeTypeName_A,
             bp.buildingPaymentLinkStatusID_FK,ls.buildingPaymentLinkStatusName_A
    ORDER BY bp.BillChargeTypeID_FK,bp.buildingPaymentLinkStatusID_FK;

    /* Detailed reconciliation of every old evacuation workflow stage. */
    ;WITH EvacuationStages AS
    (
        SELECT *
        FROM (VALUES
            (0,CONVERT(int,NULL),N'إخلاء نهائي قديم قبل استحداث الفلاج',3),
            (1,1,N'إرسال طلب قراءة العدادات',59),
            (2,2,N'مرسل للتدقيق المالي - مرحلة 2',57),
            (3,3,N'مرسل للتدقيق المالي - مرحلة 3',57),
            (4,4,N'انتهى التدقيق المالي',58),
            (5,5,N'اكتمل الإخلاء نهائيا',3)
        ) stage(StageOrder,OldExtraInt1,StageName,ExpectedTargetActionTypeID)
    )
    SELECT
        stage.OldExtraInt1,
        stage.StageName,
        stage.ExpectedTargetActionTypeID,
        COUNT_BIG(sourceAction.buildingActionID) SourceActionCount,
        SUM(CASE WHEN targetAction.buildingActionID IS NOT NULL THEN 1 ELSE 0 END) TargetActionCount,
        SUM(CASE WHEN sourceAction.buildingActionID IS NOT NULL
                      AND targetAction.buildingActionID IS NULL THEN 1 ELSE 0 END) MissingActionCount,
        SUM(CASE WHEN targetAction.buildingActionID IS NOT NULL
                      AND targetAction.buildingActionTypeID_FK<>
                          stage.ExpectedTargetActionTypeID THEN 1 ELSE 0 END) WrongTargetTypeCount
    FROM EvacuationStages stage
    LEFT JOIN KFMC.Housing.BuildingAction sourceAction
      ON sourceAction.buildingActionTypeID_FK=3
     AND (sourceAction.buildingActionExtraInt1=stage.OldExtraInt1
          OR (sourceAction.buildingActionExtraInt1 IS NULL AND stage.OldExtraInt1 IS NULL))
     AND NOT EXISTS
     (
         SELECT 1 FROM #ValidationDuplicateActionMap duplicateAction
         WHERE duplicateAction.duplicateActionID=sourceAction.buildingActionID
     )
    LEFT JOIN Housing.BuildingAction targetAction
      ON targetAction.buildingActionID=CONVERT(bigint,sourceAction.buildingActionID)
    GROUP BY stage.StageOrder,stage.OldExtraInt1,stage.StageName,
             stage.ExpectedTargetActionTypeID
    ORDER BY stage.StageOrder;

    /* entryData values that could not be resolved to dbo.Users.usersID. */
    CREATE TABLE #UnmatchedEntryDataStats
    (
        TableName nvarchar(300) NOT NULL,
        entryData nvarchar(4000) NOT NULL,
        RowCount_ bigint NOT NULL
    );

    DECLARE @EntryDataTables TABLE
    (
        SchemaName sysname NOT NULL,
        TableName sysname NOT NULL
    );

    INSERT @EntryDataTables(SchemaName,TableName)
    VALUES
        (N'dbo',N'Users'),
        (N'dbo',N'UsersDetails'),
        (N'dbo',N'UsersPassword'),
        (N'dbo',N'MilitaryUnit'),
        (N'Housing',N'ResidentInfo'),
        (N'Housing',N'ResidentDetails'),
        (N'Housing',N'ResidentContactInfo'),
        (N'Housing',N'MilitaryLocation'),
        (N'Housing',N'BuildingDetails'),
        (N'Housing',N'BuildingRent'),
        (N'Housing',N'MeterType'),
        (N'Housing',N'MeterServicePrice'),
        (N'Housing',N'BillPeriod'),
        (N'Housing',N'Meter'),
        (N'Housing',N'MeterForBuilding'),
        (N'Housing',N'MeterRead'),
        (N'Housing',N'BuildingAction'),
        (N'Housing',N'BuildingAssign'),
        (N'Housing',N'ExtendInsurance'),
        (N'Housing',N'Bills'),
        (N'Housing',N'DeductList'),
        (N'Housing',N'BuildingPayment'),
        (N'Housing',N'BillDeductList'),
        (N'Housing',N'BillDeductAction'),
        (N'Housing',N'BillsDeductListDetails');

    DECLARE @EntryDataSchema sysname,
            @EntryDataTable sysname,
            @EntryDataObject nvarchar(517),
            @EntryDataFullName nvarchar(300),
            @EntryDataSql nvarchar(max);

    DECLARE EntryDataCursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT SchemaName, TableName
        FROM @EntryDataTables
        ORDER BY SchemaName, TableName;

    OPEN EntryDataCursor;
    FETCH NEXT FROM EntryDataCursor INTO @EntryDataSchema, @EntryDataTable;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @EntryDataObject = QUOTENAME(@EntryDataSchema) + N'.' + QUOTENAME(@EntryDataTable);
        SET @EntryDataFullName = @EntryDataSchema + N'.' + @EntryDataTable;

        IF OBJECT_ID(@EntryDataObject) IS NOT NULL
           AND COL_LENGTH(@EntryDataObject, 'entryData') IS NOT NULL
        BEGIN
            SET @EntryDataSql = N'
                INSERT INTO #UnmatchedEntryDataStats(TableName, entryData, RowCount_)
                SELECT
                    @FullName,
                    CONVERT(nvarchar(4000), sourceRow.entryData),
                    COUNT_BIG(*)
                FROM ' + @EntryDataObject + N' sourceRow
                WHERE NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(4000), sourceRow.entryData))), N'''') IS NOT NULL
                  AND NOT EXISTS
                  (
                      SELECT 1
                      FROM dbo.Users userRow
                      WHERE userRow.usersID =
                            TRY_CONVERT(bigint, CONVERT(nvarchar(4000), sourceRow.entryData))
                  )
                GROUP BY CONVERT(nvarchar(4000), sourceRow.entryData);';

            EXEC sys.sp_executesql
                @EntryDataSql,
                N'@FullName nvarchar(300)',
                @FullName = @EntryDataFullName;
        END

        FETCH NEXT FROM EntryDataCursor INTO @EntryDataSchema, @EntryDataTable;
    END

    CLOSE EntryDataCursor;
    DEALLOCATE EntryDataCursor;

    SELECT TableName, entryData, RowCount_
    FROM #UnmatchedEntryDataStats
    ORDER BY TableName, RowCount_ DESC, entryData;
END;