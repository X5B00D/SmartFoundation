CREATE TABLE [Tickets].[TicketSLA] (
    [ticketSLAID]             BIGINT        IDENTITY (1, 1) NOT NULL,
    [IdaraID_FK]              BIGINT        NULL,
    [TicketID_FK]             BIGINT        NULL,
    [serviceSLAPolicyID_FK]   BIGINT        NULL,
    [ticketPriorityID_FK]     INT           NULL,
    [responseTargetMinutes]   INT           NULL,
    [resolutionTargetMinutes] INT           NULL,
    [responseDueAt]           DATETIME      NULL,
    [resolutionDueAt]         DATETIME      NULL,
    [totalPausedMinutes]      INT           NULL,
    [responseBreached]        BIT           NULL,
    [resolutionBreached]      BIT           NULL,
    [slaState]                NVARCHAR (50) NULL,
    [ticketSLAActive]         BIT           NULL,
    CONSTRAINT [PK_TicketSLA] PRIMARY KEY CLUSTERED ([ticketSLAID] ASC),
    CONSTRAINT [FK_TicketSLA_Idara] FOREIGN KEY ([IdaraID_FK]) REFERENCES [dbo].[Idara] ([idaraID]),
    CONSTRAINT [FK_TicketSLA_ServiceSLAPolicy] FOREIGN KEY ([serviceSLAPolicyID_FK]) REFERENCES [Tickets].[ServiceSLAPolicy] ([serviceSLAPolicyID]),
    CONSTRAINT [FK_TicketSLA_Ticket] FOREIGN KEY ([TicketID_FK]) REFERENCES [Tickets].[Ticket] ([ticketID]),
    CONSTRAINT [FK_TicketSLA_TicketPriority] FOREIGN KEY ([ticketPriorityID_FK]) REFERENCES [Tickets].[TicketPriority] ([ticketPriorityID])
);

