CREATE TABLE [dbo].[media_process_log](
	[process_id] [int] IDENTITY(1,1) NOT NULL,
	[process_name] [nvarchar](40) NOT NULL,
	[records_succeeded] [int] NULL,
	[records_failed] [int] NULL,
	[records_total] [int] NULL,
	[additional_info] [nvarchar](max) NULL,
	[start_date] [datetime] NOT NULL,
	[end_date] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[process_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[media_process_log] ADD  DEFAULT (getdate()) FOR [start_date]
GO
