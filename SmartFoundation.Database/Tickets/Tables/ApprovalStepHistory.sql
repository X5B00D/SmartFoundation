CREATE TABLE [Tickets].[ApprovalStepHistory] (
    [approvalStepHistoryID] BIGINT          IDENTITY (1, 1) NOT NULL,
    [approvalStepID_FK]     BIGINT          NULL,
    [fieldName]             NVARCHAR (100)  NULL,
    [oldValue]              NVARCHAR (4000) NULL,
    [newValue]              NVARCHAR (4000) NULL,
    [changedBy]             NVARCHAR (100)  NULL,
    [changedAt]             DATETIME        NULL,
    CONSTRAINT [PK_ApprovalStepHistory] PRIMARY KEY CLUSTERED ([approvalStepHistoryID] ASC),
    CONSTRAINT [FK_ApprovalStepHistory_ApprovalStep] FOREIGN KEY ([approvalStepID_FK]) REFERENCES [Tickets].[ApprovalStep] ([approvalStepID])
);

