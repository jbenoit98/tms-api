create procedure [dbo].[process_media]
as
declare 
    @l_tms_record_id          int,
    @l_created_date           datetime,
    @l_updated_date           datetime,
    @l_deleted_date           datetime,
    @l_image_size             int,
    @l_file_name              nvarchar(200),
    @l_media_path_id          int,
    @l_media_status_id        int,
    @l_media_status           nvarchar(200),
    @l_media_type             nvarchar(30),
    @l_media_format           nvarchar(30),
    @l_restrictions           nvarchar(max),
    @l_description            nvarchar(max),
    @l_primary_display        int,
    @l_department             nvarchar(100),
    @l_department_id          int,
    @l_pixel_width            int,
    @l_pixel_height           int,
    @l_asset_external_id      nvarchar(100),
    @l_approved_for_web       int,
    @l_image_url              nvarchar(300),
    @l_asset_id               nvarchar(40),
    @l_image_source           nvarchar(100),
    @l_thumbnail_binary       varbinary(max),
    @l_thumbnail_size         int,
    --application variables
    @l_media_master_pk       int,
    @l_media_rendition_pk    int,
    @l_media_file_pk         int,
    @l_media_xref_pk         int,
    @l_media_records_count   int,
    @l_table_id              int,
    @l_rendition_number      nvarchar(64),
    @l_sort_number           nvarchar(80),
    @l_media_type_id         int,
    @l_media_format_id       int,
    @l_credit_line_repro     nvarchar(max),
    @l_rank                  int,
    @l_action                nvarchar(10),
    @l_flag                  int = 0,
    @l_last_tms_update       datetime,
    --logging variables
    @l_log_record_count      int = 0,
    @l_log_success_count     int = 0,
    @l_log_fail_count        int = 0,
    @l_log_bypass_count      int = 0,
    @l_error                 nvarchar(max),
    @l_message               nvarchar(max)

    -- additional data as needed.
    ;

------------------------------------------------------------------------------------------------------
-- Declare cursor to return records
------------------------------------------------------------------------------------------------------
declare c1 cursor
for select * from media_staging;

-- start process
exec [dbo].[log_media_process]  @p_type             = 'PROCESS',
                                @p_name             = 'PROCESS_MEDIA'

------------------------------------------------------------------------------------------------------
-- Open cursor and fetch one at a time into variables
------------------------------------------------------------------------------------------------------                                           
open c1;
fetch next from c1 into 
    @l_tms_record_id,
    @l_created_date,
    @l_updated_date,
    @l_deleted_date,
    @l_image_size,
    @l_file_name,
    @l_media_status,
    @l_media_type,
    @l_media_format,
    @l_restrictions,
    @l_description,
    @l_primary_display,
    @l_department,
    @l_pixel_width,
    @l_pixel_height,
    @l_asset_external_id,
    @l_approved_for_web,
    @l_image_url,
    @l_asset_id,
    @l_image_source,
    @l_thumbnail_binary,
    @l_thumbnail_size
    -- additional data as needed.
    ;

while @@fetch_status = 0
begin
  begin try
    begin transaction
        set @l_log_record_count = @l_log_record_count + 1
        -------------------------------------------------------------------------------------------
        -- Get Media Path ID and filename based on the url
        -------------------------------------------------------------------------------------------
        exec  [dbo].[get_media_path] @l_image_url, @l_media_path_id output,@l_file_name output
        if @l_media_path_id is null
            begin
                exec [dbo].[log_media_process]      @p_type             = 'ERROR',
                                                    @p_name             = 'PROCESS_MEDIA',
                                                    @p_tms_record_id    = @l_tms_record_id,
                                                    @p_asset_id         = @l_asset_id,
                                                    @p_error            = 'Media Path is null. Avoiding corrupt media record.'
                set @l_log_fail_count = @l_log_fail_count + 1
                continue
            end
        exec [dbo].[get_media_department] @l_department, @l_department_id output
        exec [dbo].[get_media_status] @l_media_status, @l_media_status_id output
        -------------------------------------------------------------------------------------------
        -- Translate media status to rank
        -------------------------------------------------------------------------------------------
        if @l_media_status = 'Publication Quality'
            begin
                set @l_rank = 1
            end
        else if @l_media_status = 'Internal Use Only'
            begin
                set @l_rank = 2
            end
        
        -------------------------------------------------------------------------------------------
        -- Additional lookup routines for foreign keys. 
        -- Will not create, but will fallback to 0 to avoid errors.
        -------------------------------------------------------------------------------------------
        select @l_media_type_id=media_type_id,
               @l_media_format_id=media_format_id
        from [dbo].[get_media_type_format](@l_media_type,@l_media_format)
        -------------------------------------------------------------------------------------------
        -- Gets next available rendition number and sort number based on existing mws mediarecords.
        -------------------------------------------------------------------------------------------
        select @l_rendition_number=rendition_number,@l_sort_number=sort_number
        from [dbo].[get_rendition_number]()
        -------------------------------------------------------------------------------------------
        -- Get action. determines UPDATE/INSERT/DELETE action
        -------------------------------------------------------------------------------------------
        select  @l_action=action,
                @l_media_master_pk=media_master_id,
                @l_asset_id=asset_id,
                @l_tms_record_id=tms_record_id,
                @l_table_id=table_id,
                @l_last_tms_update=last_update
        from get_action(@l_asset_id,@l_tms_record_id,108,@l_deleted_date)
        -------------------------------------------------------------------------------------------
        -- Get number of media records for the current object for modifying syncing primary/order 
        -------------------------------------------------------------------------------------------
        select @l_media_records_count = count(*) 
        from mediaxrefs 
        where tableid = 108
        and id = @l_tms_record_id 
        -------------------------------------------------------------------------------------------
        -- This block of code is for inserting new records
        -------------------------------------------------------------------------------------------
        if @l_action = 'INSERT'
            begin 
                -----------------------------------------------------------------------------------
                -- Insert mediamaster record
                -----------------------------------------------------------------------------------
                insert into mediamaster (
                                         displayrendid,
                                         primaryrendid,
                                         mediaview,
                                         description,
                                         publicaccess,
                                         publiccaption,
                                         remarks,
                                         loginid,
                                         copyright,
                                         approvedforweb,
                                         departmentid)
                values                  (
                                         0,
                                         0, 
                                         null,
                                         @l_description, 
                                         1, 
                                         @l_credit_line_repro, 
                                         null, 
                                         'amanita', 
                                         null,
                                         @l_approved_for_web,
                                         @l_department_id);

                set @l_media_master_pk = scope_identity()
                -----------------------------------------------------------------------------------
                -- Insert mediarendition record
                -----------------------------------------------------------------------------------
                insert into mediarenditions (
                                             mediamasterid,
                                             primaryfileid,
                                             parentrendid,
                                             mediatypeid,
                                             mediastatusid,
                                             mediastatusdate,
                                             renditionnumber,
                                             sortnumber,
                                             renditiondate,
                                             mediasizeid,
                                             technique,
                                             duration,
                                             iscolor,
                                             quality,
                                             qualitydate,
                                             qualityconid,
                                             remarks,
                                             thumbblob,
                                             thumbpathid,
                                             thumbfilename,
                                             thumbextensionid,
                                             thumbblobsize,
                                             loctermid,
                                             quantitymade,
                                             quantityavailable,
                                             loginid)
                values                      (
                                             @l_media_master_pk,
                                             0,
                                             -1,
                                             @l_media_type_id, 
                                             @l_media_status_id,
                                             null,
                                             @l_rendition_number,
                                             @l_sort_number,
                                             convert(varchar, getdate(), 23),
                                             0,
                                             null, --'technique'
                                             null,
                                             0, --'iscolor',
                                             null,
                                             null,
                                             null,
                                             null,--'remarks'
                                             @l_thumbnail_binary,
                                             null,
                                             null,
                                             null,
                                             @l_thumbnail_size,
                                             null
                                             ,1
                                             ,null
                                             ,'amanita');

                set @l_media_rendition_pk = scope_identity()

                -----------------------------------------------------------------------------------
                -- Sets the newly created mediarendition as the primary 
                -- and display rendition for the mediamaster record.
                -----------------------------------------------------------------------------------
                update mediamaster
                set displayrendid = @l_media_rendition_pk, primaryrendid = @l_media_rendition_pk
                where mediamasterid = @l_media_master_pk;
                -----------------------------------------------------------------------------------
                -- Inserts mediafiles record
                -----------------------------------------------------------------------------------
                insert into mediafiles(
                                       renditionid,
                                       pathid,
                                       filename,
                                       formatid,
                                       pixelh,
                                       pixelw,
                                       colordepthid,
                                       duration,
                                       filesize,
                                       memorysize,
                                       loginid,
                                       filedate)
                values                (
                                       @l_media_rendition_pk,
                                       @l_media_path_id,
                                       @l_file_name,
                                       @l_media_format_id,
                                       @l_pixel_height,
                                       @l_pixel_width,
                                       0,
                                       0,
                                       @l_image_size,
                                       0,
                                       'amanita',
                                       @l_created_date
                                       );

                set @l_media_file_pk = scope_identity()
                -----------------------------------------------------------------------------------
                -- Sets the fileid as the primaryfileid
                -----------------------------------------------------------------------------------
                update mediarenditions
                set primaryfileid = @l_media_file_pk
                where renditionid = @l_media_rendition_pk;
                -----------------------------------------------------------------------------------
                -- Insert mediaxrefs record
                -----------------------------------------------------------------------------------
                insert into mediaxrefs(
                                       mediamasterid,
                                       id,
                                       tableid,
                                       primarydisplay,
                                       rank,
                                       loginid)
                values                (
                                       @l_media_master_pk,
                                       @l_tms_record_id,
                                       108, -- change in the future to allow other module media
                                       @l_primary_display,
                                       coalesce(@l_rank,0),
                                       'amanita');

                set @l_media_xref_pk = scope_identity()
                -----------------------------------------------------------------------------------
                -- if statement to update existing media records 
                -- for the object if the current media record is the primary.
                -----------------------------------------------------------------------------------
                if @l_media_records_count > 0 and @l_primary_display = 1
                    begin
                        update mediaxrefs
                        set primarydisplay = 0 -- make others not primary
                        where primarydisplay != 0
                        and mediamasterid != @l_media_master_pk
                        and id = @l_tms_record_id
                        and tableid = 108;
                    end
                
                set @l_flag = 1
            end;
        -------------------------------------------------------------------------------------------
        -- This block of code is for updating existing media records created by this app
        -------------------------------------------------------------------------------------------            
        else if @l_action = 'UPDATE'
            begin
                -----------------------------------------------------------------------------------
                -- Only update if the widen last update is newer
                -----------------------------------------------------------------------------------
                if @l_updated_date > @l_last_tms_update
                    begin
                        update    mediamaster
                        set       departmentid    = @l_department_id,
                                  approvedforweb  = @l_approved_for_web,
                                  PublicCaption   = @l_credit_line_repro
                        where     mediamasterid   = @l_media_master_pk

                        update    mediarenditions
                        set       mediastatusid   = @l_media_status_id 
                        where     mediamasterid   = @l_media_master_pk

                        update    mediaxrefs 
                        set       primarydisplay  = @l_primary_display
                        where     mediamasterid   = @l_media_master_pk
                        ---------------------------------------------------------------------------
                        -- IF statement to update existing media records for the object 
                        -- if the current media record is the primary.
                        ---------------------------------------------------------------------------
                        if @l_media_records_count > 0 and @l_primary_display = 1
                            begin
                                update mediaxrefs
                                set    primarydisplay   = 0 -- make others not primary
                                where  primarydisplay   != 0
                                and    mediamasterid    != @l_media_master_pk
                                and    id               = @l_tms_record_id
                                and    tableid          = 108;
                            end
                        set @l_flag = 1
                    end
            end;
        -------------------------------------------------------------------------------------------
        -- This block of code is for deleting tms media records 
        -- that have been deleted (soft) from DAMs
        -------------------------------------------------------------------------------------------
        else if @l_action = 'DELETE'
            begin
                delete from mediamaster 
                where mediamasterid = @l_media_master_pk
                -----------------------------------------------------------------------------------
                -- Updates mediaxrefs to set one of the remaining object media to the Primary
                -- Assumes the newest remaining record is the primary
                -----------------------------------------------------------------------------------
                update mediaxrefs
                set primarydisplay = 1
                where mediaxrefid in 
                    (select top 1 mediaxrefid
                     from mediaxrefs 
                     where id = @l_tms_record_id
                     and tableid = 108
                     and mediamasterid != @l_media_master_pk
                     order by entereddate desc);
                set @l_flag = 1
            end;
    -------------------------------------------------------------------------------------------
    -- Log successful media record
    -------------------------------------------------------------------------------------------
    if @l_flag = 1
        begin
            exec [dbo].[log_media_process]  @p_type             = 'RECORD',
                                            @p_name             = 'PROCESS_MEDIA',
                                            @p_media_master_id  = @l_media_master_pk,
                                            @p_tms_record_id    = @l_tms_record_id,
                                            @p_widen_id         = @l_asset_id,
                                            @p_table_id         = 108, -- change in future
                                            @p_action           = @l_action
        end
    
    delete from media_staging
    where asset_id = @l_asset_id
    and tms_record_id = @l_tms_record_id
    --and table_id = 108 -- maybe add support later
    -----------------------------------------------------------------------------------------------
    -- commit the transaction
    -----------------------------------------------------------------------------------------------
    commit;
    if @l_flag = 0
        begin
            set @l_log_bypass_count = @l_log_bypass_count + 1
            set @l_log_fail_count = @l_log_fail_count + 1
        end
    else
        begin
            set @l_log_success_count = @l_log_success_count + 1
        end

END TRY
---------------------------------------------------------------------------------------------------
-- Any exceptions are caught here. logged and the full process is rolled back.
---------------------------------------------------------------------------------------------------
BEGIN CATCH
    set @l_log_fail_count = @l_log_fail_count + 1
    declare @l_xstate int;
    select @l_error = ERROR_NUMBER(), @l_message = ERROR_MESSAGE() + 
    ' occurred at Line_Number: ' + CAST(ERROR_LINE() AS VARCHAR(50)), @l_xstate = XACT_STATE();
    --log error message for media record
    exec [dbo].[log_media_process]      @p_type             = 'ERROR',
                                        @p_name             = 'PROCESS_MEDIA',
                                        @p_error            = @l_message,
                                        @p_tms_record_id    = @l_tms_record_id,
                                        @p_widen_id         = @l_asset_id,
                                        @p_table_id         = 108
    

END CATCH

    fetch next from c1 into @l_tms_record_id,
                            @l_created_date,
                            @l_updated_date,
                            @l_deleted_date,
                            @l_image_size,
                            @l_file_name,
                            @l_media_status,
                            @l_media_type,
                            @l_media_format,
                            @l_restrictions,
                            @l_description,
                            @l_primary_display,
                            @l_department,
                            @l_pixel_width,
                            @l_pixel_height,
                            @l_asset_external_id,
                            @l_approved_for_web,
                            @l_image_url,
                            @l_asset_id,
                            @l_image_source,
                            @l_thumbnail_binary,
                            @l_thumbnail_size
                            -- additional data as needed.
                            ;
end
---------------------------------------------------------------------------------------------------
-- If it get's here, all records have been processed.
-- An update of success/fail counts will be logged
---------------------------------------------------------------------------------------------------
if @l_log_bypass_count > 0
    begin
        set @l_message = cast(@l_log_bypass_count as nvarchar(10)) + ' Records bypassed - No changes detected' 
    end
else if @l_log_record_count = 0
    begin
        set @l_message = '0 total records - No records were staged'
    end
else if @l_log_record_count = @l_log_success_count
    begin
        set @l_message = 'All records loaded successfully'
    end

exec [dbo].[log_media_process]  @p_type             = 'UPDATE',
                                @p_name             = 'PROCESS_MEDIA',
                                @p_total            = @l_log_record_count,
                                @p_success          = @l_log_success_count,
                                @p_failed           = @l_log_fail_count,
                                @p_error            = @l_message


exec [dbo].[log_media_process]  @p_type             = 'END',
                                @p_name             = 'PROCESS_MEDIA'

close c1;
deallocate c1;


            
GO

