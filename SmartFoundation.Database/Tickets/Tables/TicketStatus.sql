CREATE TABLE [Tickets].[TicketStatus] (
    [ticketStatusID]        INT            IDENTITY (1, 1) NOT NULL,
    [IdaraID_FK]            BIGINT         NULL,
    [ticketStatusCode]      NVARCHAR (50)  NULL,
    [ticketStatusName_A]    NVARCHAR (200) NULL,
    [ticketStatusName_E]    NVARCHAR (200) NULL,
    [ticketStatusSortOrder] INT            NULL,
    [ticketStatusIsClosed]  BIT            NULL,
    [ticketStatusIsPause]   BIT            NULL,
    [ticketStatusActive]    BIT            NULL,
    CONSTRAINT [PK_TicketStatus] PRIMARY KEY CLUSTERED ([ticketStatusID] ASC),
    CONSTRAINT [FK_TicketStatus_Idara] FOREIGN KEY ([IdaraID_FK]) REFERENCES [dbo].[Idara] ([idaraID])
);

