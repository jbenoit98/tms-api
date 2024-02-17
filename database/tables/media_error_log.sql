CREATE TABLE [dbo].[media_error_log](
	[error_id] [int] IDENTITY(1,1) NOT NULL,
	[process_id] [int] NOT NULL,
	[tms_record_id] [int] NOT NULL,
	[asset_id] [nvarchar](40) NOT NULL,
	[error_msg] [nvarchar](1000) NULL,ß
	[error_date] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED ß
(
	[error_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[media_error_log] ADD  DEFAULT (getdate()) FOR [error_date]
GO

ALTER TABLE [dbo].[media_error_log]  WITH CHECK ADD  CONSTRAINT [FK_process_error] FOREIGN KEY([process_id])
REFERENCES [dbo].[media_process_log] ([process_id])
ON DELETE CASCADE
GO

ALTER TABLE [dbo].[media_error_log] CHECK CONSTRAINT [FK_process_error]
GO

CREATE NONCLUSTERED INDEX [media_error_log_i1] ON [dbo].[media_error_log]
(
	[process_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO


