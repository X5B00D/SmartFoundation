CREATE TABLE [Tickets].[QualityReviewResult] (
    [qualityReviewResultID]          INT             IDENTITY (1, 1) NOT NULL,
    [IdaraID_FK]                     BIGINT          NULL,
    [qualityReviewResultCode]        NVARCHAR (50)   NULL,
    [qualityReviewResultName_A]      NVARCHAR (200)  NULL,
    [qualityReviewResultName_E]      NVARCHAR (200)  NULL,
    [qualityReviewResultDescription] NVARCHAR (1000) NULL,
    [qualityReviewResultActive]      BIT             NULL,
    CONSTRAINT [PK_QualityReviewResult] PRIMARY KEY CLUSTERED ([qualityReviewResultID] ASC),
    CONSTRAINT [FK_QualityReviewResult_Idara] FOREIGN KEY ([IdaraID_FK]) REFERENCES [dbo].[Idara] ([idaraID])
);

