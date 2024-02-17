CREATE procedure [dbo].[stage_media] 
	@p_json			nvarchar(max)

as
set nocount on
declare
	@l_error nvarchar(max),
	@l_cnt	int
	BEGIN TRY

		    exec [dbo].[log_media_process]  @p_type             = 'PROCESS',
		                                    @p_name             = 'STAGE_MEDIA'

			insert into media_staging (	tms_record_id,
										created_date,
										updated_date,
										deleted_date,
										image_size,
										file_name,
										media_status,
										media_type,
										media_format,
										restrictions,
										description,
										primary_display,
										department,
										pixel_width,
										pixel_height,
										external_id,
										approved_for_web,
										image_url,
										asset_id,
										image_source,
										thumbnail,
										thumbnail_size)
			select 						tms_record_id,
										created_date,
										updated_date,
										deleted_date,
										image_size,
										file_name,
										media_status,
										media_type,
										media_format,
										restrictions,
										description,
										primary_display,
										department,
										pixel_width,
										pixel_height,
										external_id, -- source identifier
										approved_for_web,
										image_url,
										asset_id,
										image_source,
										thumbnail,
										datalength(thumbnail)
			 from parse_json(@p_json)

	set @l_cnt = @@rowcount
	print('RECORDS STAGED: ' + str(@l_cnt))
    exec [dbo].[log_media_process]  @p_type             = 'UPDATE',
                                    @p_name             = 'STAGE_MEDIA',
                                    @p_success          = @l_cnt


    exec [dbo].[log_media_process]  @p_type             = 'END',
                                    @p_name             = 'STAGE_MEDIA'
	END TRY
	BEGIN CATCH
	    set @l_error = ERROR_MESSAGE()
	    --log error message for media record
	    exec [dbo].[log_media_process]      @p_type             = 'ERROR',
                                            @p_name             = 'STAGE_MEDIA',
                                            @p_error            = @l_error

	END CATCH
GO


