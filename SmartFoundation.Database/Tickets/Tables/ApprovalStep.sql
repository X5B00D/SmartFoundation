CREATE TABLE [Tickets].[ApprovalStep] (
    [approvalStepID]             BIGINT         IDENTITY (1, 1) NOT NULL,
    [IdaraID_FK]                 BIGINT         NULL,
    [operationalTypeID_FK]       INT            NULL,
    [serviceID_FK]               BIGINT         NULL,
    [approvalStepOrder]          INT            NULL,
    [approvalStepName_A]         NVARCHAR (200) NULL,
    [approvalStepName_E]         NVARCHAR (200) NULL,
    [approverDSDID_FK]           BIGINT         NULL,
    [approvalStepIsRequired]     BIT            NULL,
    [approvalStepIsAutoApproved] BIT            NULL,
    [approvalStepActive]         BIT            NULL,
    CONSTRAINT [PK_ApprovalStep] PRIMARY KEY CLUSTERED ([approvalStepID] ASC),
    CONSTRAINT [FK_ApprovalStep_Idara] FOREIGN KEY ([IdaraID_FK]) REFERENCES [dbo].[Idara] ([idaraID]),
    CONSTRAINT [FK_ApprovalStep_OperationalType] FOREIGN KEY ([operationalTypeID_FK]) REFERENCES [Tickets].[OperationalType] ([operationalTypeID]),
    CONSTRAINT [FK_ApprovalStep_Service] FOREIGN KEY ([serviceID_FK]) REFERENCES [Tickets].[Service] ([serviceID])
);

