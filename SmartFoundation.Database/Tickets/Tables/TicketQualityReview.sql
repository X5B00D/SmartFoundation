CREATE TABLE [Tickets].[TicketQualityReview] (
    [ticketQualityReviewID]     BIGINT          IDENTITY (1, 1) NOT NULL,
    [IdaraID_FK]                BIGINT          NULL,
    [TicketID_FK]               BIGINT          NULL,
    [qualityReviewResultID_FK]  INT             NULL,
    [ReviewerUsersID_FK]        BIGINT          NULL,
    [reviewNotes]               NVARCHAR (4000) NULL,
    [reviewStartedAt]           DATETIME        NULL,
    [reviewCompletedAt]         DATETIME        NULL,
    [ticketQualityReviewActive] BIT             NULL,
    CONSTRAINT [PK_TicketQualityReview] PRIMARY KEY CLUSTERED ([ticketQualityReviewID] ASC),
    CONSTRAINT [FK_TicketQualityReview_Idara] FOREIGN KEY ([IdaraID_FK]) REFERENCES [dbo].[Idara] ([idaraID]),
    CONSTRAINT [FK_TicketQualityReview_QualityReviewResult] FOREIGN KEY ([qualityReviewResultID_FK]) REFERENCES [Tickets].[QualityReviewResult] ([qualityReviewResultID]),
    CONSTRAINT [FK_TicketQualityReview_Ticket] FOREIGN KEY ([TicketID_FK]) REFERENCES [Tickets].[Ticket] ([ticketID])
);

