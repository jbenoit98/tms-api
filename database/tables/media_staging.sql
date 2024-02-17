CREATE TABLE [dbo].[mws_media_staging](
	[tms_record_id] [int] NOT NULL,
	[created_date] [datetime] NULL,
	[updated_date] [datetime] NULL,
	[deleted_date] [datetime] NULL,
	[image_size] [int] NOT NULL,
	[file_name] [nvarchar](200) NOT NULL,
	[media_status] [nvarchar](200) NOT NULL,
	[media_type] [nvarchar](100) NOT NULL,
	[media_format] [nvarchar](100) NOT NULL,
	[restrictions] [nvarchar](max) NULL,
	[description] [nvarchar](max) NULL,
	[primary_display] [int] NOT NULL,
	[department] [nvarchar](200) NOT NULL,
	[pixel_width] [int] NOT NULL,
	[pixel_height] [int] NOT NULL,
	[external_id] [nvarchar](100) NOT NULL,
	[approved_for_web] [int] NOT NULL,
	[image_url] [nvarchar](200) NOT NULL,
	[asset_id] [nvarchar](100) NOT NULL,
	[image_source] [nvarchar](100) NULL,
	[thumbnail] [varbinary](max) NOT NULL,
	[thumbnail_size] [int] NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[media_staging] ADD  CONSTRAINT [DF_media_staging_department]  DEFAULT (N'(not assigned)') FOR [department]
GO
create unique index media_staging_i1 on media_staging (tms_record_id,asset_id) with (IGNORE_DUP_KEY = ON);
go
