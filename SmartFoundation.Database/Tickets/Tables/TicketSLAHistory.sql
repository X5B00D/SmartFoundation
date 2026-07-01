CREATE TABLE [Tickets].[TicketSLAHistory] (
    [ticketSLAHistoryID]    BIGINT          IDENTITY (1, 1) NOT NULL,
    [IdaraID_FK]            BIGINT          NULL,
    [TicketID_FK]           BIGINT          NULL,
    [TicketSLAID_FK]        BIGINT          NULL,
    [slaActionCode]         NVARCHAR (100)  NULL,
    [oldSlaState]           NVARCHAR (50)   NULL,
    [newSlaState]           NVARCHAR (50)   NULL,
    [responseDueAt]         DATETIME        NULL,
    [resolutionDueAt]       DATETIME        NULL,
    [totalPausedMinutes]    INT             NULL,
    [performedByUsersID_FK] BIGINT          NULL,
    [performedAt]           DATETIME        NULL,
    [historyNotes]          NVARCHAR (4000) NULL,
    CONSTRAINT [PK_TicketSLAHistory] PRIMARY KEY CLUSTERED ([ticketSLAHistoryID] ASC),
    CONSTRAINT [FK_TicketSLAHistory_Idara] FOREIGN KEY ([IdaraID_FK]) REFERENCES [dbo].[Idara] ([idaraID]),
    CONSTRAINT [FK_TicketSLAHistory_Ticket] FOREIGN KEY ([TicketID_FK]) REFERENCES [Tickets].[Ticket] ([ticketID]),
    CONSTRAINT [FK_TicketSLAHistory_TicketSLA] FOREIGN KEY ([TicketSLAID_FK]) REFERENCES [Tickets].[TicketSLA] ([ticketSLAID])
);

