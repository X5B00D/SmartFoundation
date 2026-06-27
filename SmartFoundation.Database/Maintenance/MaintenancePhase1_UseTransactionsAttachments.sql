USE [DATACORE];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'[Maintenance].[BuildingMaintenanceRequest]', N'U') IS NOT NULL
AND COL_LENGTH(N'Maintenance.BuildingMaintenanceRequest', N'TransactionID_FK') IS NULL
BEGIN
    ALTER TABLE [Maintenance].[BuildingMaintenanceRequest]
    ADD [TransactionID_FK] BIGINT NULL;
END
GO

IF OBJECT_ID(N'[Maintenance].[BuildingMaintenanceRequest]', N'U') IS NOT NULL
AND OBJECT_ID(N'[dbo].[Transactions]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_BuildingMaintenanceRequest_Transactions')
BEGIN
    ALTER TABLE [Maintenance].[BuildingMaintenanceRequest] WITH CHECK
    ADD CONSTRAINT [FK_BuildingMaintenanceRequest_Transactions]
    FOREIGN KEY ([TransactionID_FK])
    REFERENCES [dbo].[Transactions] ([transactionID]);

    ALTER TABLE [Maintenance].[BuildingMaintenanceRequest] CHECK CONSTRAINT [FK_BuildingMaintenanceRequest_Transactions];
END
GO

IF OBJECT_ID(N'[Maintenance].[BuildingMaintenanceRequest]', N'U') IS NOT NULL
AND NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_BuildingMaintenanceRequest_TransactionID_FK'
      AND object_id = OBJECT_ID(N'[Maintenance].[BuildingMaintenanceRequest]')
)
BEGIN
    CREATE INDEX [IX_BuildingMaintenanceRequest_TransactionID_FK]
    ON [Maintenance].[BuildingMaintenanceRequest] ([TransactionID_FK]);
END
GO

IF OBJECT_ID(N'[Maintenance].[BuildingMaintenanceRequestAttachment]', N'U') IS NOT NULL
AND EXISTS (SELECT 1 FROM [Maintenance].[BuildingMaintenanceRequestAttachment])
BEGIN
    THROW 50001, 'Maintenance.BuildingMaintenanceRequestAttachment contains data. Move it to dbo.Attachment through TransactionID_FK before dropping the table.', 1;
END
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_BuildingMaintenanceRequestAttachment_Request')
    ALTER TABLE [Maintenance].[BuildingMaintenanceRequestAttachment] DROP CONSTRAINT [FK_BuildingMaintenanceRequestAttachment_Request];
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_BuildingMaintenanceRequestAttachment_Action')
    ALTER TABLE [Maintenance].[BuildingMaintenanceRequestAttachment] DROP CONSTRAINT [FK_BuildingMaintenanceRequestAttachment_Action];
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_BuildingMaintenanceRequestAttachment_Assignment')
    ALTER TABLE [Maintenance].[BuildingMaintenanceRequestAttachment] DROP CONSTRAINT [FK_BuildingMaintenanceRequestAttachment_Assignment];
GO

IF OBJECT_ID(N'[Maintenance].[BuildingMaintenanceRequestAttachment]', N'U') IS NOT NULL
    DROP TABLE [Maintenance].[BuildingMaintenanceRequestAttachment];
GO
