CREATE TABLE [Tickets].[TicketHistory] (
    [ticketHistoryID]         BIGINT          IDENTITY (1, 1) NOT NULL,
    [IdaraID_FK]              BIGINT          NULL,
    [TicketID_FK]             BIGINT          NULL,
    [historyActionCode]       NVARCHAR (100)  NULL,
    [oldTicketStatusID_FK]    INT             NULL,
    [newTicketStatusID_FK]    INT             NULL,
    [oldDSDID_FK]             BIGINT          NULL,
    [newDSDID_FK]             BIGINT          NULL,
    [oldAssignedToUsersID_FK] BIGINT          NULL,
    [newAssignedToUsersID_FK] BIGINT          NULL,
    [performedByUsersID_FK]   BIGINT          NULL,
    [historyNotes]            NVARCHAR (4000) NULL,
    [performedAt]             DATETIME        NULL,
    CONSTRAINT [PK_TicketHistory] PRIMARY KEY CLUSTERED ([ticketHistoryID] ASC),
    CONSTRAINT [FK_TicketHistory_Idara] FOREIGN KEY ([IdaraID_FK]) REFERENCES [dbo].[Idara] ([idaraID]),
    CONSTRAINT [FK_TicketHistory_Ticket] FOREIGN KEY ([TicketID_FK]) REFERENCES [Tickets].[Ticket] ([ticketID]),
    CONSTRAINT [FK_TicketHistory_TicketStatus] FOREIGN KEY ([oldTicketStatusID_FK]) REFERENCES [Tickets].[TicketStatus] ([ticketStatusID]),
    CONSTRAINT [FK_TicketHistory_TicketStatus1] FOREIGN KEY ([newTicketStatusID_FK]) REFERENCES [Tickets].[TicketStatus] ([ticketStatusID])
);

