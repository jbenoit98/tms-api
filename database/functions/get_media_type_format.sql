create FUNCTION [dbo].[get_media_type_format](@p_media_type nvarchar(30),
																							@p_media_format nvarchar(30))
RETURNS @data table (
					 media_type_id int,
					 media_format_id int
					)  
AS 
BEGIN
  declare @l_media_type_id int, @l_media_format_id int
  
    if @p_media_format = 'TIFFDocument'
	  begin
	    set @p_media_format = 'TIFF'
	  end
	
	select @l_media_type_id = mediatypeid
	from   mediatypes 
	where  mediatype = @p_media_type;

	if @l_media_type_id is not null
	  begin
		select @l_media_format_id = formatid
		from   mediaformats 
		where  format = @p_media_format;

		if @l_media_format_id is null
		  begin
			set @l_media_format_id = 0
		  end
	  end
	else
	  begin
	    set @l_media_type_id = 0
	    set @l_media_format_id = 0
	  end

	insert into @data 	(media_format_id,media_type_id)
	values 				(@l_media_format_id,@l_media_type_id)

	RETURN 

END
GO
