CREATE PROCEDURE [MoveData].[usp_MigratePenaltyBillsAndPayments]
    @IdaraId bigint,
    @RollbackAfterTest bit = 1
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.Idara WHERE idaraID=@IdaraId)
        THROW 56500, N'The supplied IdaraId does not exist.', 1;
    IF @IdaraId NOT BETWEEN 0 AND 2147483647
        THROW 56501, N'IdaraId cannot fit in int payment columns.', 1;
    IF EXISTS
    (
        SELECT 1
        FROM KFMC.Housing.OccupantCustodyAction c
        LEFT JOIN Housing.BuildingAction a ON a.buildingActionID=CONVERT(bigint,c.buildingActionID_FK)
        WHERE a.buildingActionID IS NULL
    )
        THROW 56502, N'Run MoveData.usp_MigrateBuildingActions before migrating penalties.', 1;
    IF EXISTS
    (
        SELECT 1 FROM KFMC.Housing.OccupantCustodyAction
        WHERE occupantCustodyActionPenalty IS NULL OR occupantCustodyActionPenalty<=0
    )
        THROW 56503, N'KFMC contains a penalty with an invalid amount.', 1;
    IF EXISTS
    (
        SELECT 1 FROM KFMC.Housing.OccupantCustodyAction
        WHERE Paid=1 AND
             (PaidPaymentType IS NULL OR TRY_CONVERT(datetime2(3),RIGHT(PaidBy,23),121) IS NULL)
    )
        THROW 56504, N'KFMC contains a paid penalty without payment type or parseable payment date.', 1;

    DECLARE @BillsInserted bigint=0,@SettlementListsInserted bigint=0,@PaymentsInserted bigint=0;

    BEGIN TRY
        BEGIN TRANSACTION;

        /* Every old custody penalty becomes a charge-type 5 bill. Inactive rows remain archived bills. */
        INSERT INTO Housing.Bills
        (
            BillsUID,BillChargeTypeID_FK,BillTypeID_FK,PeriodMonth,PeriodYear,
            buildingDetailsNo,buildingDetailsID,residentInfoID_FK,generalNo_FK,
            PRICE,PRICETAX,TotalPrice,BillsFromDate,BillsToDate,PenaltyReason,
            BillActive,CanceledBy,idaraID_FK,entryDate,entryData,hostName
        )
        SELECT
            CONVERT(uniqueidentifier,HASHBYTES('MD5',CONCAT(N'PENALTY-BILL|',c.occupantCustodyActionID))),
            5,3,MONTH(c.entryDate),YEAR(c.entryDate),a.buildingDetailsNo,
            CONVERT(int,a.buildingDetailsID_FK),a.residentInfoID_FK,a.generalNo_FK,
            c.occupantCustodyActionPenalty,0,c.occupantCustodyActionPenalty,
            c.entryDate,c.entryDate,c.occupantCustodyActionNote,
            c.occupantCustodyActionActive,c.canceldBy,@IdaraId,
            c.entryDate,[MoveData].[fn_MapEntryData](c.entryData),[MoveData].[fn_MapHostName](c.hostName, c.entryData)
        FROM KFMC.Housing.OccupantCustodyAction c
        JOIN Housing.BuildingAction a ON a.buildingActionID=CONVERT(bigint,c.buildingActionID_FK)
        WHERE NOT EXISTS
        (
            SELECT 1 FROM Housing.Bills b
            WHERE b.BillsUID=CONVERT(uniqueidentifier,HASHBYTES('MD5',CONCAT(N'PENALTY-BILL|',c.occupantCustodyActionID)))
        );
        SET @BillsInserted=@@ROWCOUNT;

        /* One active opening-settlement list for each payment month and payment method. */
        INSERT INTO Housing.DeductList
        (
            deductTypeID_FK,deductUID,deductName,paymentTypeID_FK,
            issueMonth,issueYear,paymentDate,description,deductActive,
            BillChargeTypeID_FK,IdaraId_FK,entryDate,entryData,hostName
        )
        SELECT DISTINCT
            6,
            CONVERT(uniqueidentifier,HASHBYTES('MD5',CONCAT(N'PENALTY-LIST|',YEAR(p.PaidDate),N'|',MONTH(p.PaidDate),N'|',p.PaidPaymentType))),
            CONCAT(N'تسوية افتتاحية لسداد الغرامات - ',YEAR(p.PaidDate),N'/',RIGHT(N'0'+CONVERT(nvarchar(2),MONTH(p.PaidDate)),2),N' - طريقة ',p.PaidPaymentType),
            p.PaidPaymentType,MONTH(p.PaidDate),YEAR(p.PaidDate),DATEFROMPARTS(YEAR(p.PaidDate),MONTH(p.PaidDate),1),
            N'مسير ترحيل لسدادات الغرامات التاريخية',1,5,@IdaraId,
            p.entryDate,[MoveData].[fn_MapEntryData](p.entryData),[MoveData].[fn_MapHostName](p.hostName, p.entryData)
        FROM
        (
            SELECT PaidPaymentType,TRY_CONVERT(datetime2(3),RIGHT(PaidBy,23),121) PaidDate,
                   entryDate,entryData,hostName,
                   ROW_NUMBER() OVER
                   (
                       PARTITION BY PaidPaymentType,
                                    YEAR(TRY_CONVERT(datetime2(3),RIGHT(PaidBy,23),121)),
                                    MONTH(TRY_CONVERT(datetime2(3),RIGHT(PaidBy,23),121))
                       ORDER BY occupantCustodyActionID
                   ) rowNumber
            FROM KFMC.Housing.OccupantCustodyAction WHERE Paid=1
        ) p
        WHERE p.rowNumber=1
          AND NOT EXISTS
        (
            SELECT 1 FROM Housing.DeductList d
            WHERE d.deductUID=CONVERT(uniqueidentifier,HASHBYTES('MD5',CONCAT(N'PENALTY-LIST|',YEAR(p.PaidDate),N'|',MONTH(p.PaidDate),N'|',p.PaidPaymentType)))
        );
        SET @SettlementListsInserted=@@ROWCOUNT;

        INSERT INTO Housing.BuildingPayment
        (
            PaymentUID,buildingPaymentTypeID_FK,generalNo_FK,IDNumber,residentInfoID_FK,
            buildingDetailsID_FK,amount,deductListID_FK,buildingPayementActive,
            BillChargeTypeID_FK,IdaraId_FK,entryDate,entryData,hostName,paymentLinkNote
        )
        SELECT
            CONVERT(uniqueidentifier,HASHBYTES('MD5',CONCAT(N'PENALTY-PAYMENT|',c.occupantCustodyActionID))),
            c.PaidPaymentType,a.generalNo_FK,r.NationalID,a.residentInfoID_FK,
            CONVERT(nvarchar(400),a.buildingDetailsID_FK),c.occupantCustodyActionPenalty,
            d.deductListID,1,5,CONVERT(int,@IdaraId),c.entryDate,
            [MoveData].[fn_MapEntryData](c.entryData),[MoveData].[fn_MapHostName](c.hostName, c.entryData),
            CONCAT(N'KFMC OccupantCustodyAction #',c.occupantCustodyActionID,
                   CASE WHEN NULLIF(c.PaidNumber,N'') IS NULL THEN N'' ELSE CONCAT(N'; PaidNumber=',c.PaidNumber) END)
        FROM KFMC.Housing.OccupantCustodyAction c
        JOIN Housing.BuildingAction a ON a.buildingActionID=CONVERT(bigint,c.buildingActionID_FK)
        LEFT JOIN Housing.ResidentInfo r ON r.residentInfoID=a.residentInfoID_FK
        CROSS APPLY (SELECT TRY_CONVERT(datetime2(3),RIGHT(c.PaidBy,23),121) PaidDate) p
        JOIN Housing.DeductList d ON d.deductUID=
            CONVERT(uniqueidentifier,HASHBYTES('MD5',CONCAT(N'PENALTY-LIST|',YEAR(p.PaidDate),N'|',MONTH(p.PaidDate),N'|',c.PaidPaymentType)))
        WHERE c.Paid=1
          AND NOT EXISTS
          (
              SELECT 1 FROM Housing.BuildingPayment bp
              WHERE bp.PaymentUID=CONVERT(uniqueidentifier,HASHBYTES('MD5',CONCAT(N'PENALTY-PAYMENT|',c.occupantCustodyActionID)))
          );
        SET @PaymentsInserted=@@ROWCOUNT;

        SELECT @RollbackAfterTest RollbackAfterTest,
               @BillsInserted PenaltyBillsInserted,
               @SettlementListsInserted PenaltySettlementListsInserted,
               @PaymentsInserted PenaltyPaymentsInserted,
               (SELECT COUNT_BIG(*) FROM Housing.Bills WHERE BillChargeTypeID_FK=5) PenaltyBillsCount,
               (SELECT SUM(TotalPrice) FROM Housing.Bills WHERE BillChargeTypeID_FK=5) AllPenaltyBillsTotal,
               (SELECT SUM(TotalPrice) FROM Housing.Bills WHERE BillChargeTypeID_FK=5 AND BillActive=1) ActivePenaltyBillsTotal,
               (SELECT SUM(amount) FROM Housing.BuildingPayment WHERE BillChargeTypeID_FK=5 AND buildingPayementActive=1) PenaltyPaymentsTotal,
               (SELECT SUM(Remaining) FROM Housing.V_SumBillsTotalPriceAndTotalPaidForResident WHERE BillChargeTypeID=5) PenaltyRemainingFromView;

        IF @RollbackAfterTest=1 ROLLBACK TRANSACTION; ELSE COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;