CREATE procedure get_media_path (
	@p_path nvarchar(max),
	@p_path_id integer output) 
as
begin
declare
	@l_path    nvarchar(300)
	if @p_path is null
		begin
			return null
		end
	--extract media path from url
	set @l_path = SUBSTRING(@p_path,1,CHARINDEX('/', @p_path, CHARINDEX('/',@p_path, (CHARINDEX('/',@p_path,(CHARINDEX('/',@p_path,(CHARINDEX('/',@p_path)+1))+1))+1))+1))
	--lookup existing media path for id
	select @p_path_id = pathid
	from mediapaths 
	where path = @l_path;

	if @p_path_id is null
		begin
			--insert new path if doesn't exist
			insert into mediapaths (path,physicalpath,loginid)
			values (@l_path,@l_path,'amanita')
			set @p_path_id = scope_identity()
		end

end
	
GO


