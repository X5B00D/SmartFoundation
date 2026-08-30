CREATE PROCEDURE [Housing].[GenerateMonthlyRentBillForResident]
(
      @ResidentInfoID    BIGINT
    , @GeneralNo         BIGINT
    , @BuildingDetailsID BIGINT
    , @OccupentDate      DATE
    , @Month             INT
    , @Year              INT
    , @IdaraID           BIGINT
    , @EntryData         NVARCHAR(20)
    , @HostName          NVARCHAR(200)
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @TransactionCount INT = @@TRANCOUNT;
    DECLARE @MonthStart DATE;
    DECLARE @MonthEnd DATE;
    DECLARE @BillingFromDate DATE;
    DECLARE @LastBilledToDate DATE;

    BEGIN TRY
        IF @TransactionCount = 0
            BEGIN TRANSACTION;

        IF @ResidentInfoID IS NULL
           OR @BuildingDetailsID IS NULL
           OR @OccupentDate IS NULL
           OR @IdaraID IS NULL
           OR @Month NOT BETWEEN 1 AND 12
           OR @Year NOT BETWEEN 1900 AND 9999
        BEGIN
            ;THROW 50001, N'بيانات رصد فاتورة الإيجار غير صحيحة', 1;
        END;

        SET @MonthStart = DATEFROMPARTS(@Year, @Month, 1);
        SET @MonthEnd = EOMONTH(@MonthStart);

        SELECT @LastBilledToDate = MAX(CAST(b.BillsToDate AS date))
        FROM Housing.Bills b
        WHERE b.residentInfoID_FK = @ResidentInfoID
          AND b.buildingDetailsID = @BuildingDetailsID
          AND b.idaraID_FK = @IdaraID
          AND b.BillChargeTypeID_FK = 1
          AND b.BillActive = 1
          AND CAST(b.BillsFromDate AS date) <= @MonthEnd
          AND CAST(b.BillsToDate AS date) >= DATEADD(DAY, -1, @MonthStart);

        SET @BillingFromDate =
            CASE
                WHEN @OccupentDate > @MonthStart THEN @OccupentDate
                ELSE @MonthStart
            END;

        IF @LastBilledToDate IS NOT NULL
           AND DATEADD(DAY, 1, @LastBilledToDate) > @BillingFromDate
        BEGIN
            SET @BillingFromDate = DATEADD(DAY, 1, @LastBilledToDate);
        END;

        IF @BillingFromDate <= @MonthEnd
        BEGIN
            ;WITH CalculatedRent AS
            (
                SELECT
                      rent.CalcFromDate
                    , rent.CalcToDate
                    , RentAmount = CAST(rent.RentForMonth AS DECIMAL(18,2))
                FROM Housing.fn_CalcBuildingRent_ForOneMonth
                (
                      @BuildingDetailsID
                    , @BillingFromDate
                    , @Year
                    , @Month
                    , NULL
                ) rent
                OUTER APPLY
                (
                    SELECT
                        ExemptionAmount =
                            CAST
                            (
                                (rent.RentForMonth / NULLIF(rent.Days30InMonth, 0))
                                * SUM(x.ExemptDays30)
                                AS DECIMAL(18,2)
                            )
                    FROM
                    (
                        SELECT
                            ExemptDays30 =
                            (
                                (YEAR(d.ExemptEnd) - YEAR(d.ExemptStart)) * 360
                              + (MONTH(d.ExemptEnd) - MONTH(d.ExemptStart)) * 30
                              + (
                                    CASE
                                        WHEN d.ExemptEnd = EOMONTH(d.ExemptEnd) AND DAY(d.ExemptEnd) < 30 THEN 30
                                        WHEN DAY(d.ExemptEnd) > 30 THEN 30
                                        ELSE DAY(d.ExemptEnd)
                                    END
                                    -
                                    CASE
                                        WHEN d.ExemptStart = EOMONTH(d.ExemptStart) AND DAY(d.ExemptStart) < 30 THEN 30
                                        WHEN DAY(d.ExemptStart) > 30 THEN 30
                                        ELSE DAY(d.ExemptStart)
                                    END
                                )
                              + 1
                            )
                        FROM
                        (
                            SELECT
                                  ExemptStart =
                                      CASE
                                          WHEN CAST(ex.residentRentExemptionStartDate AS date) < rent.CalcFromDate
                                              THEN rent.CalcFromDate
                                          ELSE CAST(ex.residentRentExemptionStartDate AS date)
                                      END
                                , ExemptEnd =
                                      CASE
                                          WHEN ex.residentRentExemptionEndDate IS NULL
                                               OR CAST(ex.residentRentExemptionEndDate AS date) > rent.CalcToDate
                                              THEN rent.CalcToDate
                                          ELSE CAST(ex.residentRentExemptionEndDate AS date)
                                      END
                            FROM Housing.ResidentRentExemption ex
                            WHERE ex.residentInfoID_FK = @ResidentInfoID
                              AND ex.buildingDetailsID_FK = @BuildingDetailsID
                              AND ISNULL(ex.residentRentExemptionActive, 0) = 1
                              AND CAST(ex.residentRentExemptionStartDate AS date) <= rent.CalcToDate
                              AND
                                  (
                                      ex.residentRentExemptionEndDate IS NULL
                                      OR CAST(ex.residentRentExemptionEndDate AS date) >= rent.CalcFromDate
                                  )
                        ) d
                        WHERE d.ExemptStart <= d.ExemptEnd
                    ) x
                ) exm
            )
            INSERT INTO Housing.Bills
            (
                  BillsUID
                , BillChargeTypeID_FK
                , BillTypeID_FK
                , PeriodMonth
                , PeriodYear
                , buildingDetailsID
                , residentInfoID_FK
                , generalNo_FK
                , PRICE
                , PRICETAX
                , TotalPrice
                , buildingRentTypeID_FK
                , BillsFromDate
                , BillsToDate
                , BillActive
                , idaraID_FK
                , entryDate
                , entryData
                , hostName
            )
            SELECT
                  NEWID()
                , 1
                , 2
                , @Month
                , @Year
                , @BuildingDetailsID
                , @ResidentInfoID
                , @GeneralNo
                , rent.RentAmount
                , 0
                , rent.RentAmount
                , 1
                , rent.CalcFromDate
                , rent.CalcToDate
                , 1
                , @IdaraID
                , GETDATE()
                , @EntryData
                , @HostName
            FROM CalculatedRent rent
            WHERE NOT EXISTS
            (
                SELECT 1
                FROM Housing.Bills existingBill WITH (UPDLOCK, HOLDLOCK)
                WHERE existingBill.residentInfoID_FK = @ResidentInfoID
                  AND existingBill.buildingDetailsID = @BuildingDetailsID
                  AND existingBill.idaraID_FK = @IdaraID
                  AND existingBill.BillChargeTypeID_FK = 1
                  AND existingBill.BillActive = 1
                  AND CAST(existingBill.BillsFromDate AS date) <= rent.CalcToDate
                  AND CAST(existingBill.BillsToDate AS date) >= rent.CalcFromDate
            );

            DECLARE @ResidentRentExemptionID BIGINT;
            DECLARE exemptionCursor CURSOR LOCAL FAST_FORWARD FOR
            SELECT exemption.residentRentExemptionID
            FROM Housing.ResidentRentExemption exemption
            WHERE exemption.residentInfoID_FK = @ResidentInfoID
              AND exemption.buildingDetailsID_FK = @BuildingDetailsID
              AND exemption.idaraID_FK = @IdaraID
              AND exemption.residentRentExemptionActive = 1
              AND CAST(exemption.residentRentExemptionStartDate AS date) <= @MonthEnd
              AND
              (
                  exemption.residentRentExemptionEndDate IS NULL
                  OR CAST(exemption.residentRentExemptionEndDate AS date) >= @MonthStart
              );

            OPEN exemptionCursor;
            FETCH NEXT FROM exemptionCursor INTO @ResidentRentExemptionID;

            WHILE @@FETCH_STATUS = 0
            BEGIN
                EXEC Housing.SyncRentExemptionPayments
                      @Action = N'GENERATE'
                    , @ResidentRentExemptionID = @ResidentRentExemptionID
                    , @ThroughDate = @MonthEnd
                    , @SourceType = N'RESIDENT_MONTHLY'
                    , @EntryData = @EntryData
                    , @HostName = @HostName;

                FETCH NEXT FROM exemptionCursor INTO @ResidentRentExemptionID;
            END;

            CLOSE exemptionCursor;
            DEALLOCATE exemptionCursor;
        END;

        IF @TransactionCount = 0
            COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @TransactionCount = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
