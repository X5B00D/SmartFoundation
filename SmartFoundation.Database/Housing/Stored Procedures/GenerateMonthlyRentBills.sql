CREATE PROCEDURE [Housing].[GenerateMonthlyRentBills]
    @Month int,
    @Year int,
    @entrydata nvarchar(20),
    @hostname nvarchar(200),
    @idaraID int
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @InsertedCount int = 0;
    DECLARE @ExpectedCount int = 0;

    DECLARE @Bills TABLE
    (
        residentInfoID bigint,
        buildingDetailsID bigint,
        buildingRentTypeID_FK bigint,
        rentBillsAmount decimal(18,2),
        rentBillsFromDate date,
        rentBillsToDate date,
        rentBillsActive bit,
        idaraID_FK bigint,
        entrydata nvarchar(20),
        hostname nvarchar(200)
    );

    BEGIN TRY
        BEGIN TRAN;

        INSERT INTO @Bills
        EXEC [Housing].[BuildingRentForOneMonth]
             @Month = @Month,
             @Year = @Year,
             @entrydata = @entrydata,
             @hostname = @hostname,
             @idaraID = @idaraID;

        SELECT @ExpectedCount = COUNT(*)
        FROM @Bills;

        INSERT INTO Housing.Bills
        (
              BillsUID
            , BillChargeTypeID_FK
            , PeriodMonth
            , PeriodYear
            , buildingDetailsID
            , residentInfoID_FK
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
            , @Month
            , @Year
            , b.buildingDetailsID
            , b.residentInfoID
            , b.rentBillsAmount
            , 0
            , b.rentBillsAmount
            , b.buildingRentTypeID_FK
            , b.rentBillsFromDate
            , b.rentBillsToDate
            , 1
            , @idaraID
            , GETDATE()
            , @entrydata
            , @hostname
        FROM @Bills b
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM Housing.Bills x WITH (UPDLOCK, HOLDLOCK)
            WHERE x.BillChargeTypeID_FK = 1
              AND x.PeriodMonth = @Month
              AND x.PeriodYear = @Year
              AND x.idaraID_FK = @idaraID
              AND x.residentInfoID_FK = b.residentInfoID
              AND x.buildingDetailsID = b.buildingDetailsID
              AND x.buildingRentTypeID_FK = b.buildingRentTypeID_FK
              AND x.BillActive = 1
        );

        SET @InsertedCount = @@ROWCOUNT;

        COMMIT TRAN;

        SELECT 
              1 AS IsSuccessful
            , CASE 
                WHEN @ExpectedCount = 0 
                    THEN N'لا توجد فواتير إيجار مستحقة لهذا الشهر'
                WHEN @InsertedCount = 0 
                    THEN N'فواتير الإيجار مرصودة مسبقاً لجميع المستحقين'
                ELSE N'تم رصد فواتير الإيجار الناقصة بنجاح'
              END AS Message_
            , @ExpectedCount AS ExpectedCount
            , @InsertedCount AS InsertedCount;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRAN;

        SELECT 
              0 AS IsSuccessful
            , ERROR_MESSAGE() AS Message_
            , @ExpectedCount AS ExpectedCount
            , @InsertedCount AS InsertedCount;
    END CATCH
END
