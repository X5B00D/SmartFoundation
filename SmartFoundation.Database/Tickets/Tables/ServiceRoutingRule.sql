CREATE TABLE [Tickets].[ServiceRoutingRule] (
    [serviceRoutingRuleID]            BIGINT   IDENTITY (1, 1) NOT NULL,
    [IdaraID_FK]                      BIGINT   NULL,
    [requesterTypeID_FK]              INT      NULL,
    [TargetDSDID_FK]                  BIGINT   NULL,
    [ArbitratorDSDID_FK]              BIGINT   NULL,
    [ArbitratorDistributorID_FK]      BIGINT   NULL,
    [serviceRoutingRulePriority]      INT      NULL,
    [serviceRoutingRuleEffectiveFrom] DATETIME NULL,
    [serviceRoutingRuleEffectiveTo]   DATETIME NULL,
    [serviceRoutingRuleActive]        BIT      NULL,
    CONSTRAINT [PK_ServiceRoutingRule] PRIMARY KEY CLUSTERED ([serviceRoutingRuleID] ASC),
    CONSTRAINT [FK_ServiceRoutingRule_Idara] FOREIGN KEY ([IdaraID_FK]) REFERENCES [dbo].[Idara] ([idaraID]),
    CONSTRAINT [FK_ServiceRoutingRule_RequesterType] FOREIGN KEY ([requesterTypeID_FK]) REFERENCES [Tickets].[RequesterType] ([requesterTypeID])
);

