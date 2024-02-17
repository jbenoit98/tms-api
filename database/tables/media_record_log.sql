create table media_record_log(
	record_id 		 integer identity primary key,
	process_id		 integer not null,
	media_master_id  integer not null,
	tms_record_id    integer not null,
	asset_id		 nvarchar(40) not null,
	table_id		 integer not null,
	action			 nvarchar(40) not null,
	created_date     datetime not null default current_timestamp);

go
ALTER TABLE media_record_log
   ADD CONSTRAINT FK_process_record
   FOREIGN KEY (process_id) REFERENCES media_process_log (process_id);
go
create index media_record_log_i1 on media_record_log (process_id);
