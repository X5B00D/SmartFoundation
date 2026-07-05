CREATE TABLE [Tickets].[PriorityMatrix] (
    [priorityMatrixID]       BIGINT IDENTITY (1, 1) NOT NULL,
    [IdaraID_FK]             BIGINT NULL,
    [ticketImpactID_FK]      INT    NULL,
    [ticketUrgencyID_FK]     INT    NULL,
    [ticketPriorityID_FK]    INT    NULL,
    [isMajorIncidentDefault] BIT    NULL,
    [priorityMatrixActive]   BIT    NULL,
    CONSTRAINT [PK_PriorityMatrix] PRIMARY KEY CLUSTERED ([priorityMatrixID] ASC),
    CONSTRAINT [FK_PriorityMatrix_Idara] FOREIGN KEY ([IdaraID_FK]) REFERENCES [dbo].[Idara] ([idaraID]),
    CONSTRAINT [FK_PriorityMatrix_TicketImpact] FOREIGN KEY ([ticketImpactID_FK]) REFERENCES [Tickets].[TicketImpact] ([ticketImpactID]),
    CONSTRAINT [FK_PriorityMatrix_TicketPriority] FOREIGN KEY ([ticketPriorityID_FK]) REFERENCES [Tickets].[TicketPriority] ([ticketPriorityID]),
    CONSTRAINT [FK_PriorityMatrix_TicketUrgency] FOREIGN KEY ([ticketUrgencyID_FK]) REFERENCES [Tickets].[TicketUrgency] ([ticketUrgencyID])
);

