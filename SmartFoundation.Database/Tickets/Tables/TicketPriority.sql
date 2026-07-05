CREATE TABLE [Tickets].[TicketPriority] (
    [ticketPriorityID]        INT            IDENTITY (1, 1) NOT NULL,
    [IdaraID_FK]              BIGINT         NULL,
    [ticketPriorityCode]      NVARCHAR (50)  NULL,
    [ticketPriorityName_A]    NVARCHAR (200) NULL,
    [ticketPriorityName_E]    NVARCHAR (200) NULL,
    [ticketPrioritySortOrder] INT            NULL,
    [ticketPriorityColor]     NVARCHAR (30)  NULL,
    [ticketPriorityActive]    BIT            NULL,
    CONSTRAINT [PK_TicketPriority] PRIMARY KEY CLUSTERED ([ticketPriorityID] ASC),
    CONSTRAINT [FK_TicketPriority_Idara] FOREIGN KEY ([IdaraID_FK]) REFERENCES [dbo].[Idara] ([idaraID])
);

