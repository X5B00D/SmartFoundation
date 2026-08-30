CREATE PROCEDURE [MoveData].[usp_MigrateOccupantCustodyActions]
    @RollbackAfterTest bit = 1
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF EXISTS
    (
        SELECT 1
        FROM KFMC.Housing.OccupantCustodyAction sourceRow
        LEFT JOIN Housing.BuildingAction actionRow
          ON actionRow.buildingActionID=CONVERT(bigint,sourceRow.buildingActionID_FK)
        WHERE sourceRow.buildingActionID_FK IS NOT NULL
          AND actionRow.buildingActionID IS NULL
    )
        THROW 56401, N'Run MoveData.usp_MigrateBuildingActions before migrating occupant custody actions.', 1;

    DECLARE @IdentityEnabled bit=0,@InsertedRows bigint=0;

    BEGIN TRY
        BEGIN TRANSACTION;

        SET IDENTITY_INSERT Housing.OccupantCustodyAction ON;
        SET @IdentityEnabled=1;

        INSERT Housing.OccupantCustodyAction
        (
            occupantCustodyActionID,buildingActionID_FK,custodyActionTypeID_FK,
            custodyItemID_FK,custodyStatusID_FK,buildingActionID_Parent,
            occupantCustodyActionID_Parent,occupantCustodyActionActive,
            occupantCustodyActionNote,occupantCustodyActionPenalty,
            custodyOrDamageTypeID_FK,Paid,PaidBy,PaidNumber,PaidPaymentType,
            canceldBy,updatedby,spForAction,entryDate,entryData,hostName
        )
        SELECT
            sourceRow.occupantCustodyActionID,sourceRow.buildingActionID_FK,
            sourceRow.custodyActionTypeID_FK,sourceRow.custodyItemID_FK,
            sourceRow.custodyStatusID_FK,sourceRow.buildingActionID_Parent,
            sourceRow.occupantCustodyActionID_Parent,sourceRow.occupantCustodyActionActive,
            sourceRow.occupantCustodyActionNote,sourceRow.occupantCustodyActionPenalty,
            sourceRow.custodyOrDamageTypeID_FK,sourceRow.Paid,sourceRow.PaidBy,
            sourceRow.PaidNumber,sourceRow.PaidPaymentType,sourceRow.canceldBy,
            sourceRow.updatedby,sourceRow.spForAction,sourceRow.entryDate,
            CONVERT(nvarchar(20),MoveData.fn_MapEntryData(sourceRow.entryData)),
            CONVERT(nvarchar(200),MoveData.fn_MapHostName(sourceRow.hostName,sourceRow.entryData))
        FROM KFMC.Housing.OccupantCustodyAction sourceRow
        WHERE NOT EXISTS
        (
            SELECT 1 FROM Housing.OccupantCustodyAction targetRow
            WHERE targetRow.occupantCustodyActionID=sourceRow.occupantCustodyActionID
        );

        SET @InsertedRows=@@ROWCOUNT;
        SET IDENTITY_INSERT Housing.OccupantCustodyAction OFF;
        SET @IdentityEnabled=0;

        SELECT @RollbackAfterTest RollbackAfterTest,@InsertedRows OccupantCustodyActionsInserted,
               (SELECT COUNT_BIG(*) FROM Housing.OccupantCustodyAction) OccupantCustodyActionsAvailable;

        IF @RollbackAfterTest=1 ROLLBACK TRANSACTION;
        ELSE COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @IdentityEnabled=1 SET IDENTITY_INSERT Housing.OccupantCustodyAction OFF;
        IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
