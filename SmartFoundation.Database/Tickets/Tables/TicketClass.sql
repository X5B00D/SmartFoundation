CREATE TABLE [Tickets].[TicketClass] (
    [ticketClassID]          INT             IDENTITY (1, 1) NOT NULL,
    [IdaraID_FK]             BIGINT          NOT NULL,
    [ticketClassCode]        NVARCHAR (50)   NULL,
    [ticketClassName_A]      NVARCHAR (200)  NULL,
    [ticketClassName_E]      NVARCHAR (200)  NULL,
    [ticketClassDescription] NVARCHAR (1000) NULL,
    [ticketClassActive]      BIT             NULL,
    CONSTRAINT [PK_TicketClass] PRIMARY KEY CLUSTERED ([ticketClassID] ASC),
    CONSTRAINT [FK_TicketClass_Idara] FOREIGN KEY ([IdaraID_FK]) REFERENCES [dbo].[Idara] ([idaraID])
);

