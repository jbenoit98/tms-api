CREATE FUNCTION [dbo].[get_action](
    @p_asset_id nvarchar(40),
    @p_tms_record_id int,
	@p_table_id int,
	@p_deleted_date datetime = null
)
RETURNS @data table (
					 action nvarchar(10),
					 media_master_id int,
					 asset_id nvarchar(40),
					 tms_record_id int,
					 table_id int,
					 last_update datetime
					)  
AS 

BEGIN
declare
	@l_action nvarchar(6)
	
	if @p_deleted_date is not null
		begin 
			insert into @data (action, media_master_id,widen_id,tms_record_id,table_id)
			select 'DELETE',
					media_master_id,
					asset_id,
					tms_record_id,
					table_id
				from media_record_log 
				where tms_record_id = @p_tms_record_id 
				and asset_id  = @p_asset_id
				and table_id = @p_table_id
				and action = 'INSERT'
				
			DECLARE @dataCount int = (SELECT COUNT(1) FROM @data)
			IF @dataCount = 0 -- Empty
				begin
					insert into @data (action, media_master_id,asset_id,tms_record_id,table_id)
					values ('IGNORE',null,@p_asset_id,@p_tms_record_id,@p_table_id)
				end
			return
		end
	else
		begin
			insert into @data (action, media_master_id,asset_id,tms_record_id,table_id)
			select	case 
						when count(*) > 0 
						then 'UPDATE' 
					end action,
					media_master_id,
					asset_id,
					tms_record_id,
					table_id
			from media_record_log 
			where tms_record_id = @p_tms_record_id 
			and asset_id  = @p_asset_id
			and table_id = @p_table_id
			and action = 'INSERT'
			and action != 'DELETE'
			group by	media_master_id,
						asset_id,
						tms_record_id,
						table_id

			select @l_action = action from @data
			if @l_action is null
				begin
					insert into @data (action, media_master_id,asset_id,tms_record_id,table_id)
					select 'INSERT',null,@p_asset_id,@p_tms_record_id,@p_table_id
					return
				end

			if @l_action = 'UPDATE'
				begin
					update @data
					set last_update = d.max_update
					from (
					select max(created_date) max_update
					from media_record_log r
					where action != 'DELETE'
					and r.tms_record_id = @p_tms_record_id 
					and r.asset_id  = @p_asset_id
					and r.table_id = @p_table_id ) d
					RETURN 
				end
		end
    return
END 
GO


