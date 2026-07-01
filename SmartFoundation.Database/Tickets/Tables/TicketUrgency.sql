CREATE TABLE [Tickets].[TicketUrgency] (
    [ticketUrgencyID]          INT             IDENTITY (1, 1) NOT NULL,
    [IdaraID_FK]               BIGINT          NULL,
    [ticketUrgencyCode]        NVARCHAR (50)   NULL,
    [ticketUrgencyName_A]      NVARCHAR (200)  NULL,
    [ticketUrgencyName_E]      NVARCHAR (200)  NULL,
    [ticketUrgencyScore]       INT             NULL,
    [ticketUrgencyDescription] NVARCHAR (1000) NULL,
    [ticketUrgencyActive]      BIT             NULL,
    CONSTRAINT [PK_TicketUrgency] PRIMARY KEY CLUSTERED ([ticketUrgencyID] ASC),
    CONSTRAINT [FK_TicketUrgency_Idara] FOREIGN KEY ([IdaraID_FK]) REFERENCES [dbo].[Idara] ([idaraID])
);

