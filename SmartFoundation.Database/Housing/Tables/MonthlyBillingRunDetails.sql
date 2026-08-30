CREATE TABLE [Housing].[MonthlyBillingRunDetails]
(
    [MonthlyBillingRunDetailsID] BIGINT IDENTITY(1,1) NOT NULL,
    [MonthlyBillingRunID_FK] BIGINT NOT NULL,
    [BillsID_FK] BIGINT NULL,
    [ResidentInfoID_FK] BIGINT NULL,
    [GeneralNo_FK] BIGINT NULL,
    [BuildingDetailsID_FK] BIGINT NULL,
    [MeterID_FK] BIGINT NULL,
    [FromDate] DATE NULL,
    [ToDate] DATE NULL,
    [ResultStatus] NVARCHAR(30) NOT NULL,
    [ReasonCode] NVARCHAR(100) NULL,
    [ReasonMessage] NVARCHAR(1000) NULL,
    [AmountBeforeTax] DECIMAL(18,2) NOT NULL CONSTRAINT [DF_MonthlyBillingRunDetails_Amount] DEFAULT (0),
    [TaxAmount] DECIMAL(18,2) NOT NULL CONSTRAINT [DF_MonthlyBillingRunDetails_Tax] DEFAULT (0),
    [TotalAmount] DECIMAL(18,2) NOT NULL CONSTRAINT [DF_MonthlyBillingRunDetails_Total] DEFAULT (0),
    [entryDate] DATETIME NOT NULL CONSTRAINT [DF_MonthlyBillingRunDetails_entryDate] DEFAULT (GETDATE()),
    CONSTRAINT [PK_MonthlyBillingRunDetails] PRIMARY KEY CLUSTERED ([MonthlyBillingRunDetailsID]),
    CONSTRAINT [FK_MonthlyBillingRunDetails_Run] FOREIGN KEY ([MonthlyBillingRunID_FK])
        REFERENCES [Housing].[MonthlyBillingRun] ([MonthlyBillingRunID]),
    CONSTRAINT [FK_MonthlyBillingRunDetails_Bill] FOREIGN KEY ([BillsID_FK])
        REFERENCES [Housing].[Bills] ([BillsID])
);

GO
CREATE UNIQUE INDEX [UX_MonthlyBillingRunDetails_RunBill]
ON [Housing].[MonthlyBillingRunDetails] ([MonthlyBillingRunID_FK], [BillsID_FK])
WHERE [BillsID_FK] IS NOT NULL;

GO
CREATE INDEX [IX_MonthlyBillingRunDetails_Result]
ON [Housing].[MonthlyBillingRunDetails] ([MonthlyBillingRunID_FK], [ResultStatus], [BuildingDetailsID_FK]);
