CREATE PROCEDURE [MoveData].[usp_MigrateResidents]
    @IdaraId bigint,
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

    DECLARE @ResidentInfoInserted bigint = 0;
    DECLARE @ResidentDetailsInserted bigint = 0;
    DECLARE @IdentityInsertInfoOn bit = 0;
    DECLARE @IdentityInsertDetailsOn bit = 0;

    IF NOT EXISTS (SELECT 1 FROM [dbo].[Idara] WHERE [idaraID] = @IdaraId)
        THROW 51000, N'The supplied IdaraId does not exist in DATACORE.dbo.Idara.', 1;

    /* Fail before writing if the source cannot be mapped safely. */
    IF EXISTS
    (
        SELECT 1
        FROM [KFMC].[Housing].[ResidentDetails] AS sourceDetails
        LEFT JOIN [KFMC].[Housing].[ResidentInfo] AS sourceInfo
          ON TRY_CONVERT(bigint, sourceInfo.[generalNo]) =
             TRY_CONVERT(bigint, sourceDetails.[generalNo_FK])
        WHERE sourceInfo.[residentInfoID] IS NULL
    )
        THROW 51001, N'KFMC contains ResidentDetails rows that cannot be linked to ResidentInfo.', 1;

    /* ResidentDetails keeps the source military-unit ID; migrate units first. */
    IF EXISTS
    (
        SELECT 1
        FROM [KFMC].[Housing].[ResidentDetails] AS sourceDetails
        LEFT JOIN [dbo].[MilitaryUnit] AS targetUnit
          ON targetUnit.[militaryUnitID] = TRY_CONVERT(bigint, sourceDetails.[militaryUnitID_FK])
        WHERE sourceDetails.[militaryUnitID_FK] IS NOT NULL
          AND targetUnit.[militaryUnitID] IS NULL
    )
        THROW 51005, N'Required military units are missing. Run MoveData.usp_MigrateMilitaryUnits first with RollbackAfterTest = 0.', 1;

    /* Protect existing DATACORE residents from an ID collision. */
    IF EXISTS
    (
        SELECT 1
        FROM [KFMC].[Housing].[ResidentInfo] AS sourceInfo
        JOIN [Housing].[ResidentInfo] AS targetInfo
          ON targetInfo.[residentInfoID] = TRY_CONVERT(bigint, sourceInfo.[residentInfoID])
        WHERE targetInfo.[residentInfoUID] <> sourceInfo.[residentInfoUID]
    )
        THROW 51002, N'A ResidentInfo ID already belongs to a different resident in DATACORE.', 1;

    /* Protect existing DATACORE details from an ID collision. */
    IF EXISTS
    (
        SELECT 1
        FROM [KFMC].[Housing].[ResidentDetails] AS sourceDetails
        JOIN [KFMC].[Housing].[ResidentInfo] AS sourceInfo
          ON TRY_CONVERT(bigint, sourceInfo.[generalNo]) =
             TRY_CONVERT(bigint, sourceDetails.[generalNo_FK])
        JOIN [Housing].[ResidentDetails] AS targetDetails
          ON targetDetails.[residentDetailsID] = TRY_CONVERT(bigint, sourceDetails.[residentDetailsID])
        WHERE targetDetails.[residentInfoID_FK] <> TRY_CONVERT(bigint, sourceInfo.[residentInfoID])
    )
        THROW 51003, N'A ResidentDetails ID already belongs to a different resident in DATACORE.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        SET IDENTITY_INSERT [Housing].[ResidentInfo] ON;
        SET @IdentityInsertInfoOn = 1;

        INSERT INTO [Housing].[ResidentInfo]
        (
            [residentInfoID], [residentInfoUID], [NationalID],
            [residentInfoActive], [entryDate], [entryData], [hostName]
        )
        SELECT
            TRY_CONVERT(bigint, sourceInfo.[residentInfoID]),
            sourceInfo.[residentInfoUID], sourceInfo.[NationalID],
            sourceInfo.[residentInfoActive], sourceInfo.[entryDate],
            [MoveData].[fn_MapEntryData](sourceInfo.[entryData]),
            [MoveData].[fn_MapHostName](sourceInfo.[hostName], sourceInfo.[entryData])
        FROM [KFMC].[Housing].[ResidentInfo] AS sourceInfo
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM [Housing].[ResidentInfo] AS targetInfo
            WHERE targetInfo.[residentInfoID] = TRY_CONVERT(bigint, sourceInfo.[residentInfoID])
        );

        SET @ResidentInfoInserted = @@ROWCOUNT;
        SET IDENTITY_INSERT [Housing].[ResidentInfo] OFF;
        SET @IdentityInsertInfoOn = 0;

        SET IDENTITY_INSERT [Housing].[ResidentDetails] ON;
        SET @IdentityInsertDetailsOn = 1;

        INSERT INTO [Housing].[ResidentDetails]
        (
            [residentDetailsID], [residentInfoID_FK], [generalNo_FK],
            [rankID_FK], [militaryUnitID_FK], [martialStatusID_FK],
            [dependinceCounter], [nationalityID_FK], [genderID_FK],
            [firstName_A], [secondName_A], [thirdName_A], [lastName_A],
            [firstName_E], [secondName_E], [thirdName_E], [lastName_E],
            [note], [birthdate], [residentDetailsStartDate],
            [residentDetailsEndDate], [IdaraId_FK], [residentDetailsActive],
            [entryDate], [entryData], [hostName]
        )
        SELECT
            TRY_CONVERT(bigint, sourceDetails.[residentDetailsID]),
            TRY_CONVERT(bigint, sourceInfo.[residentInfoID]),
            TRY_CONVERT(bigint, sourceDetails.[generalNo_FK]),
            sourceDetails.[rankID_FK], sourceDetails.[militaryUnitID_FK],
            sourceDetails.[martialStatusID_FK], sourceDetails.[dependinceCounter],
            sourceDetails.[nationalityID_FK], sourceDetails.[genderID_FK],
            sourceInfo.[firstName_A], sourceInfo.[secondName_A],
            sourceInfo.[thirdName_A], sourceInfo.[lastName_A],
            sourceInfo.[firstName_E], sourceInfo.[secondName_E],
            sourceInfo.[thirdName_E], sourceInfo.[lastName_E],
            sourceInfo.[note], sourceInfo.[birthdate],
            sourceDetails.[entryDate], NULL, @IdaraId,
            sourceDetails.[residentDetailsActive], sourceDetails.[entryDate],
            [MoveData].[fn_MapEntryData](sourceDetails.[entryData]),
            [MoveData].[fn_MapHostName](sourceDetails.[hostName], sourceDetails.[entryData])
        FROM [KFMC].[Housing].[ResidentDetails] AS sourceDetails
        JOIN [KFMC].[Housing].[ResidentInfo] AS sourceInfo
          ON TRY_CONVERT(bigint, sourceInfo.[generalNo]) =
             TRY_CONVERT(bigint, sourceDetails.[generalNo_FK])
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM [Housing].[ResidentDetails] AS targetDetails
            WHERE targetDetails.[residentDetailsID] = TRY_CONVERT(bigint, sourceDetails.[residentDetailsID])
        );

        SET @ResidentDetailsInserted = @@ROWCOUNT;
        SET IDENTITY_INSERT [Housing].[ResidentDetails] OFF;
        SET @IdentityInsertDetailsOn = 0;

        IF EXISTS
        (
            SELECT 1
            FROM [Housing].[ResidentDetails] AS targetDetails
            LEFT JOIN [Housing].[ResidentInfo] AS targetInfo
              ON targetInfo.[residentInfoID] = targetDetails.[residentInfoID_FK]
            WHERE targetInfo.[residentInfoID] IS NULL
        )
            THROW 51004, N'The test created orphan ResidentDetails rows.', 1;

        SELECT
            @RollbackAfterTest AS [RollbackAfterTest],
            @ResidentInfoInserted AS [ResidentInfoInserted],
            @ResidentDetailsInserted AS [ResidentDetailsInserted],
            (SELECT COUNT_BIG(*) FROM [Housing].[ResidentInfo]) AS [TargetResidentInfoTotal],
            (SELECT COUNT_BIG(*) FROM [Housing].[ResidentDetails]) AS [TargetResidentDetailsTotal];

        IF @RollbackAfterTest = 1 ROLLBACK TRANSACTION;
        ELSE COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @IdentityInsertDetailsOn = 1
            SET IDENTITY_INSERT [Housing].[ResidentDetails] OFF;
        IF @IdentityInsertInfoOn = 1
            SET IDENTITY_INSERT [Housing].[ResidentInfo] OFF;
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;