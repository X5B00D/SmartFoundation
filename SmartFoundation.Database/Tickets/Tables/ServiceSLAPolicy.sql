CREATE TABLE [Tickets].[ServiceSLAPolicy] (
    [serviceSLAPolicyID]                          BIGINT   IDENTITY (1, 1) NOT NULL,
    [IdaraID_FK]                                  BIGINT   NULL,
    [serviceID_FK]                                BIGINT   NULL,
    [ticketPriorityID_FK]                         INT      NULL,
    [responseTargetMinutes]                       INT      NULL,
    [resolutionTargetMinutes]                     INT      NULL,
    [serviceSLAPolicyAllowPause]                  BIT      NULL,
    [serviceSLAPolicyRequiresMajorIncidentReview] BIT      NULL,
    [serviceSLAPolicyEffectiveFrom]               DATETIME NULL,
    [serviceSLAPolicyEffectiveTo]                 DATETIME NULL,
    [serviceSLAPolicyActive]                      BIT      NULL,
    CONSTRAINT [PK_ServiceSLAPolicy] PRIMARY KEY CLUSTERED ([serviceSLAPolicyID] ASC),
    CONSTRAINT [FK_ServiceSLAPolicy_Idara] FOREIGN KEY ([IdaraID_FK]) REFERENCES [dbo].[Idara] ([idaraID]),
    CONSTRAINT [FK_ServiceSLAPolicy_Service] FOREIGN KEY ([serviceID_FK]) REFERENCES [Tickets].[Service] ([serviceID]),
    CONSTRAINT [FK_ServiceSLAPolicy_TicketPriority] FOREIGN KEY ([ticketPriorityID_FK]) REFERENCES [Tickets].[TicketPriority] ([ticketPriorityID])
);

