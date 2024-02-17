CREATE procedure log_media_process
	@p_type 			nvarchar(40),
	@p_name 			nvarchar(40),
	@p_error			nvarchar(max)   = null,
	@p_media_master_id  integer 		= null, 
	@p_tms_record_id    integer 		= null, 
	@p_asset_id		 	nvarchar(40) 	= null, 
	@p_table_id		 	integer 		= null,
	@p_action			nvarchar(40)	= null,
	@p_total			integer			= null,
	@p_success			integer			= null,
	@p_failed 			integer			= null
as
declare
	@l_process_id int

	if @p_type = 'PROCESS'
		begin
			insert into media_process_log  (process_name)
			values (@p_name);
		end;

	if @p_type = 'UPDATE'
		begin
			select @l_process_id=max(process_id) 
			from media_process_log
			where process_name = @p_name;

			update media_process_log
			set records_succeeded = @p_success,
				records_failed = @p_failed,
			    records_total = @p_total
			where process_id = @l_process_id;
		end;
	if @p_type = 'END'
		begin
			
			select @l_process_id=max(process_id) 
			from media_process_log
			where process_name = @p_name;

			update media_process_log
			set end_date = getdate()
			where process_id = @l_process_id;

		end;


	if @p_type = 'ERROR'
		begin
			
			select @l_process_id=max(process_id) 
			from media_process_log
			where process_name = @p_name;

			insert into media_error_log (process_id,tms_record_id,asset_id,error_msg)
			values (@l_process_id,@p_tms_record_id,@p_asset_id,@p_error)

		end;

	if @p_type = 'RECORD'
		begin
			select @l_process_id=max(process_id) 
			from media_process_log
			where process_name = @p_name;
			--confirm all required fields have a value
			if coalesce(@p_media_master_id,@p_tms_record_id,@p_asset_id,@p_table_id) is not null
				begin
					insert into media_record_log
					(process_id,media_master_id,tms_record_id,asset_id,table_id,action)
					values
					(@l_process_id,@p_media_master_id,@p_tms_record_id,@p_asset_id,@p_table_id,@p_action)
				end
				--raise error
		end;


GO
