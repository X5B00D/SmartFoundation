CREATE TABLE [Housing].[MonthlyBillingRun]
(
    [MonthlyBillingRunID] BIGINT IDENTITY(1,1) NOT NULL,
    [IdaraID_FK] BIGINT NOT NULL,
    [PeriodYear] INT NOT NULL,
    [PeriodMonth] INT NOT NULL,
    [BillingType] NVARCHAR(20) NOT NULL,
    [MeterServiceTypeID_FK] INT NOT NULL CONSTRAINT [DF_MonthlyBillingRun_Service] DEFAULT (0),
    [CalculationMethod] NVARCHAR(30) NOT NULL,
    [RunStatus] NVARCHAR(30) NOT NULL,
    [ProposedCount] INT NOT NULL CONSTRAINT [DF_MonthlyBillingRun_Proposed] DEFAULT (0),
    [CreatedCount] INT NOT NULL CONSTRAINT [DF_MonthlyBillingRun_Created] DEFAULT (0),
    [ExistingCount] INT NOT NULL CONSTRAINT [DF_MonthlyBillingRun_Existing] DEFAULT (0),
    [SkippedCount] INT NOT NULL CONSTRAINT [DF_MonthlyBillingRun_Skipped] DEFAULT (0),
    [FailedCount] INT NOT NULL CONSTRAINT [DF_MonthlyBillingRun_Failed] DEFAULT (0),
    [AmountBeforeTax] DECIMAL(18,2) NOT NULL CONSTRAINT [DF_MonthlyBillingRun_Amount] DEFAULT (0),
    [TaxAmount] DECIMAL(18,2) NOT NULL CONSTRAINT [DF_MonthlyBillingRun_Tax] DEFAULT (0),
    [TotalAmount] DECIMAL(18,2) NOT NULL CONSTRAINT [DF_MonthlyBillingRun_Total] DEFAULT (0),
    [StartedAt] DATETIME2(0) NULL,
    [LastHeartbeatAt] DATETIME2(0) NULL,
    [FinishedAt] DATETIME2(0) NULL,
    [AttemptCount] INT NOT NULL CONSTRAINT [DF_MonthlyBillingRun_Attempt] DEFAULT (0),
    [LastError] NVARCHAR(4000) NULL,
    [entryDate] DATETIME NOT NULL CONSTRAINT [DF_MonthlyBillingRun_entryDate] DEFAULT (GETDATE()),
    [entryData] NVARCHAR(20) NULL,
    [hostName] NVARCHAR(200) NULL,
    CONSTRAINT [PK_MonthlyBillingRun] PRIMARY KEY CLUSTERED ([MonthlyBillingRunID]),
    CONSTRAINT [UQ_MonthlyBillingRun_Scope] UNIQUE
    (
        [IdaraID_FK], [PeriodYear], [PeriodMonth], [BillingType],
        [MeterServiceTypeID_FK], [CalculationMethod]
    ),
    CONSTRAINT [CK_MonthlyBillingRun_Month] CHECK ([PeriodMonth] BETWEEN 1 AND 12)
);

GO
CREATE INDEX [IX_MonthlyBillingRun_Status]
ON [Housing].[MonthlyBillingRun] ([RunStatus], [PeriodYear], [PeriodMonth], [IdaraID_FK]);
