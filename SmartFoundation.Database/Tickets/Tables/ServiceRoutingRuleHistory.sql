CREATE TABLE [Tickets].[ServiceRoutingRuleHistory] (
    [serviceRoutingRuleHistoryID] BIGINT          IDENTITY (1, 1) NOT NULL,
    [IdaraID_FK]                  BIGINT          NULL,
    [serviceRoutingRuleID_FK]     BIGINT          NULL,
    [serviceID_FK]                BIGINT          NULL,
    [historyActionCode]           NVARCHAR (100)  NULL,
    [oldTargetDSDID_FK]           BIGINT          NULL,
    [newTargetDSDID_FK]           BIGINT          NULL,
    [oldArbitratorDSDID_FK]       BIGINT          NULL,
    [newArbitratorDSDID_FK]       BIGINT          NULL,
    [performedByUsersID_FK]       BIGINT          NULL,
    [historyNotes]                NVARCHAR (4000) NULL,
    [performedAt]                 DATETIME        NULL,
    CONSTRAINT [PK_ServiceRoutingRuleHistory] PRIMARY KEY CLUSTERED ([serviceRoutingRuleHistoryID] ASC),
    CONSTRAINT [FK_ServiceRoutingRuleHistory_Idara] FOREIGN KEY ([IdaraID_FK]) REFERENCES [dbo].[Idara] ([idaraID]),
    CONSTRAINT [FK_ServiceRoutingRuleHistory_Service] FOREIGN KEY ([serviceID_FK]) REFERENCES [Tickets].[Service] ([serviceID]),
    CONSTRAINT [FK_ServiceRoutingRuleHistory_ServiceRoutingRule] FOREIGN KEY ([serviceRoutingRuleID_FK]) REFERENCES [Tickets].[ServiceRoutingRule] ([serviceRoutingRuleID])
);

