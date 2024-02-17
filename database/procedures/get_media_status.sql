CREATE procedure get_media_status (
	@p_media_status nvarchar(200) = null,
	@p_media_status_id integer output) 
as

begin

	if @p_media_status is null
		begin
			select @p_media_status_id = mediastatusid
			from mediastatuses 
			where mediastatus = '(not assigned)'
		end
	else
		begin
			select @p_media_status_id = mediastatusid
			from mediastatuses 
			where mediastatus = @p_media_status;

			if @p_media_status_id is null
				begin
					insert into mediastatuses (mediastatus,loginid)
					values (@p_media_status,'amanita')
					set @p_media_status_id = scope_identity()
				end
		end

end
	
GO