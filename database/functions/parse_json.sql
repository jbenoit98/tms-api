CREATE FUNCTION [dbo].[parse_json]( @json nvarchar(max))
RETURNS @data TABLE
	  (
	   tms_record_id		int not null,
	   table_id				int not null,
	   created_date			datetime,
	   updated_date			datetime,
	   deleted_date			datetime,
	   image_size			int,
	   file_name			nvarchar(200),
	   media_status			nvarchar(200),
	   media_type			nvarchar(100),
	   media_format			nvarchar(100),
	   restrictions			nvarchar(max),
	   description			nvarchar(max),
	   primary_display		int not null,
	   department			nvarchar(100),
	   pixel_width			int not null,
	   asset_external_id	nvarchar(100) not null,
	   pixel_height			int not null,
	   approved_for_web		int not null,
	   image_url			nvarchar(200) not null,
	   thumbnail			varbinary(max) null,
	   asset_id				nvarchar(100) not null,
	   image_source			nvarchar(100)
	   )
	AS
	BEGIN
	  DECLARE
		  @hierarchy	TABLE
		  (
		   Element_ID	INT IDENTITY(1, 1) NOT NULL, /* internal surrogate primary key gives the order of parsing and the list order */
		   SequenceNo	int NULL, /* the place in the sequence for the element */
		   Parent_ID	INT null, /* if the element has a parent then it is in this column. The document is the ultimate parent, so you can get the structure from recursing from the document */
		   Object_ID	INT null, /* each list or object has an object id. This ties all elements to a parent. Lists are treated as objects here */
		   Name			NVARCHAR(2000) NULL, /* the Name of the object */
		   StringValue	NVARCHAR(MAX) NULL,/*the string representation of the value of the element. */
		   ValueType	VARCHAR(10) null /* the declared type of the value represented as a string in StringValue*/
		  )
	  DECLARE
	    @FirstObject			INT, --the index of the first open bracket found in the JSON string
	    @OpenDelimiter			INT,--the index of the next open bracket found in the JSON string
	    @NextOpenDelimiter		INT,--the index of subsequent open bracket found in the JSON string
	    @NextCloseDelimiter		INT,--the index of subsequent close bracket found in the JSON string
	    @Type					NVARCHAR(10),--whether it denotes an object or an array
	    @NextCloseDelimiterChar CHAR(1),--either a '}' or a ']'
	    @Contents				NVARCHAR(MAX), --the unparsed contents of the bracketed expression
	    @Start					INT, --index of the start of the token that you are parsing
	    @end					INT,--index of the end of the token that you are parsing
	    @param					INT,--the parameter at the end of the next Object/Array token
	    @EndOfName				INT,--the index of the start of the parameter at end of Object/Array token
	    @token					NVARCHAR(max),--either a string or object
	    @value					NVARCHAR(MAX), -- the value as a string
	    @SequenceNo				int, -- the sequence number within a list
	    @Name					NVARCHAR(200), --the Name as a string
	    @Parent_ID				INT,--the next parent ID to allocate
	    @lenJSON				INT,--the current length of the JSON String
	    @characters				NCHAR(36),--used to convert hex to decimal
	    @result					BIGINT,--the value of the hex symbol being parsed
	    @index					SMALLINT,--used for parsing the hex value
	    @Escape					INT, --the index of the next escape character
	    @ThumbBinary			varbinary(max)

	  DECLARE @Strings	TABLE /* in this temporary table we keep all strings, even the Names of the elements, since they are 'escaped' in a different way, and may contain, unescaped, brackets denoting objects or lists. These are replaced in the JSON string by tokens representing the string */
	    (
	     String_ID		INT IDENTITY(1, 1),
	     StringValue	NVARCHAR(MAX)
	    )
	  SELECT--initialise the characters to convert hex to ascii
	    @characters='0123456789abcdefghijklmnopqrstuvwxyz',
	    @SequenceNo=0, --set the sequence no. to something sensible.
	  /* firstly we process all strings. This is done because [{} and ] aren't escaped in strings, which complicates an iterative parse. */
	    @Parent_ID=0;
	  WHILE 1=1 --forever until there is nothing more to do
	    BEGIN
	      SELECT
	        @start=PATINDEX('%[^a-zA-Z]["]%', @json collate SQL_Latin1_General_CP850_Bin);--next delimited string
	      IF @start=0 BREAK --no more so drop through the WHILE loop
	      IF SUBSTRING(@json, @start+1, 1)='"' 
	        BEGIN --Delimited Name
	          SET @start=@Start+1;
	          SET @end=PATINDEX('%[^\]["]%', RIGHT(@json, LEN(@json+'|')-@start) collate SQL_Latin1_General_CP850_Bin);
	        END
	      IF @end=0 --either the end or no end delimiter to last string
	        BEGIN-- check if ending with a double slash...
             SET @end=PATINDEX('%[\][\]["]%', RIGHT(@json, LEN(@json+'|')-@start) collate SQL_Latin1_General_CP850_Bin);
 		     IF @end=0 --we really have reached the end 
				BEGIN
				BREAK --assume all tokens found
				END
			END 
	      SELECT @token=SUBSTRING(@json, @start+1, @end-1)
	      --now put in the escaped control characters
	      SELECT @token=REPLACE(@token, FromString, ToString)
	      FROM
	        (SELECT           '\b', CHAR(08)
	         UNION ALL SELECT '\f', CHAR(12)
	         UNION ALL SELECT '\n', CHAR(10)
	         UNION ALL SELECT '\r', CHAR(13)
	         UNION ALL SELECT '\t', CHAR(09)
			 UNION ALL SELECT '\"', '"'
	         UNION ALL SELECT '\/', '/'
	        ) substitutions(FromString, ToString)
		SELECT @token=Replace(@token, '\\', '\')
	      SELECT @result=0, @escape=1
	  --Begin to take out any hex escape codes
	      WHILE @escape>0
	        BEGIN
	          SELECT @index=0,
	          --find the next hex escape sequence
	          @escape=PATINDEX('%\x[0-9a-f][0-9a-f][0-9a-f][0-9a-f]%', @token collate SQL_Latin1_General_CP850_Bin)
	          IF @escape>0 --if there is one
	            BEGIN
	              WHILE @index<4 --there are always four digits to a \x sequence   
	                BEGIN
	                  SELECT --determine its value
	                    @result=@result+POWER(16, @index)
	                    *(CHARINDEX(SUBSTRING(@token, @escape+2+3-@index, 1),
	                                @characters)-1), @index=@index+1 ;
	         
	                END
	                -- and replace the hex sequence by its unicode value
	              SELECT @token=STUFF(@token, @escape, 6, NCHAR(@result))
	            END
	        END
	      --now store the string away 
	      INSERT INTO @Strings (StringValue) SELECT @token
	      -- and replace the string with a token
	      SELECT @JSON=STUFF(@json, @start, @end+1,
	                    '@string'+CONVERT(NCHAR(5), @@identity))
	    END
	  -- all strings are now removed. Now we find the first leaf.  
	  WHILE 1=1  --forever until there is nothing more to do
	  BEGIN
	 
	  SELECT @Parent_ID=@Parent_ID+1
	  --find the first object or list by looking for the open bracket
	  SELECT @FirstObject=PATINDEX('%[{[[]%', @json collate SQL_Latin1_General_CP850_Bin)--object or array
	  IF @FirstObject = 0 BREAK
	  IF (SUBSTRING(@json, @FirstObject, 1)='{') 
	    SELECT @NextCloseDelimiterChar='}', @type='object'
	  ELSE 
	    SELECT @NextCloseDelimiterChar=']', @type='array'
	  SELECT @OpenDelimiter=@firstObject
	  WHILE 1=1 --find the innermost object or list...
	    BEGIN
	      SELECT
	        @lenJSON=LEN(@JSON+'|')-1
	  --find the matching close-delimiter proceeding after the open-delimiter
	      SELECT
	        @NextCloseDelimiter=CHARINDEX(@NextCloseDelimiterChar, @json,
	                                      @OpenDelimiter+1)
	  --is there an intervening open-delimiter of either type
	      SELECT @NextOpenDelimiter=PATINDEX('%[{[[]%',
	             RIGHT(@json, @lenJSON-@OpenDelimiter)collate SQL_Latin1_General_CP850_Bin)--object
	      IF @NextOpenDelimiter=0 
	        BREAK
	      SELECT @NextOpenDelimiter=@NextOpenDelimiter+@OpenDelimiter
	      IF @NextCloseDelimiter<@NextOpenDelimiter 
	        BREAK
	      IF SUBSTRING(@json, @NextOpenDelimiter, 1)='{' 
	        SELECT @NextCloseDelimiterChar='}', @type='object'
	      ELSE 
	        SELECT @NextCloseDelimiterChar=']', @type='array'
	      SELECT @OpenDelimiter=@NextOpenDelimiter
	    END
	  ---and parse out the list or Name/value pairs
	  SELECT
	    @contents=SUBSTRING(@json, @OpenDelimiter+1,
	                        @NextCloseDelimiter-@OpenDelimiter-1)
	  SELECT
	    @JSON=STUFF(@json, @OpenDelimiter,
	                @NextCloseDelimiter-@OpenDelimiter+1,
	                '@'+@type+CONVERT(NCHAR(5), @Parent_ID))
	  WHILE (PATINDEX('%[A-Za-z0-9@+.e]%', @contents collate SQL_Latin1_General_CP850_Bin))<>0 
	    BEGIN
	      IF @Type='object' --it will be a 0-n list containing a string followed by a string, number,boolean, or null
	        BEGIN
	          SELECT
	            @SequenceNo=0,@end=CHARINDEX(':', ' '+@contents)--if there is anything, it will be a string-based Name.
	          SELECT  @start=PATINDEX('%[^A-Za-z@][@]%', ' '+@contents collate SQL_Latin1_General_CP850_Bin)--AAAAAAAA
              SELECT @token=RTrim(Substring(' '+@contents, @start+1, @End-@Start-1)),
	            @endofName=PATINDEX('%[0-9]%', @token collate SQL_Latin1_General_CP850_Bin),
	            @param=RIGHT(@token, LEN(@token)-@endofName+1)
	          SELECT
	            @token=LEFT(@token, @endofName-1),
	            @Contents=RIGHT(' '+@contents, LEN(' '+@contents+'|')-@end-1)
	          SELECT  @Name=StringValue FROM @strings
	            WHERE string_id=@param --fetch the Name
	        END
	      ELSE 
	        SELECT @Name=null,@SequenceNo=@SequenceNo+1 
	      SELECT
	        @end=CHARINDEX(',', @contents)-- a string-token, object-token, list-token, number,boolean, or null
                IF @end=0
	          IF ISNUMERIC(@contents) = 1
		    SELECT @end = LEN(@contents) + 1
	          Else
		  SELECT  @end=PATINDEX('%[A-Za-z0-9@+.e][^A-Za-z0-9@+.e]%', @contents+' ' collate SQL_Latin1_General_CP850_Bin) + 1
	       SELECT
	        @start=PATINDEX('%[^A-Za-z0-9@+.e][A-Za-z0-9@+.e]%', ' '+@contents collate SQL_Latin1_General_CP850_Bin)
	      SELECT
	        @Value=RTRIM(SUBSTRING(@contents, @start, @End-@Start)),
	        @Contents=RIGHT(@contents+' ', LEN(@contents+'|')-@end)
	      IF SUBSTRING(@value, 1, 7)='@object' 
	        INSERT INTO @hierarchy
	          (Name, SequenceNo, Parent_ID, StringValue, Object_ID, ValueType)
	          SELECT @Name, @SequenceNo, @Parent_ID, SUBSTRING(@value, 8, 5),
	            SUBSTRING(@value, 8, 5), 'object' 
	      ELSE 
	        IF SUBSTRING(@value, 1, 6)='@array' 
	          INSERT INTO @hierarchy
	            (Name, SequenceNo, Parent_ID, StringValue, Object_ID, ValueType)
	            SELECT @Name, @SequenceNo, @Parent_ID, SUBSTRING(@value, 7, 5),
	              SUBSTRING(@value, 7, 5), 'array' 
	        ELSE 
	          IF SUBSTRING(@value, 1, 7)='@string' 
	            INSERT INTO @hierarchy
	              (Name, SequenceNo, Parent_ID, StringValue, ValueType)
	              SELECT @Name, @SequenceNo, @Parent_ID, StringValue, 'string'
	              FROM @strings
	              WHERE string_id=SUBSTRING(@value, 8, 5)
	          ELSE 
	            IF @value IN ('true', 'false') 
	              INSERT INTO @hierarchy
	                (Name, SequenceNo, Parent_ID, StringValue, ValueType)
	                SELECT @Name, @SequenceNo, @Parent_ID, @value, 'boolean'
	            ELSE
	              IF @value='null' 
	                INSERT INTO @hierarchy
	                  (Name, SequenceNo, Parent_ID, StringValue, ValueType)
	                  SELECT @Name, @SequenceNo, @Parent_ID, null, null
	              ELSE
	                IF PATINDEX('%[^0-9]%', @value collate SQL_Latin1_General_CP850_Bin)>0 
	                  INSERT INTO @hierarchy
	                    (Name, SequenceNo, Parent_ID, StringValue, ValueType)
	                    SELECT @Name, @SequenceNo, @Parent_ID, @value, 'real'
	                ELSE
	                  INSERT INTO @hierarchy
	                    (Name, SequenceNo, Parent_ID, StringValue, ValueType)
	                    SELECT @Name, @SequenceNo, @Parent_ID, @value, 'int'
	      if @Contents=' ' Select @SequenceNo=0
	    END
	  END


insert into @data 
		(tms_record_id, 
		 table_id,
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
		 asset_external_id,
		 pixel_height,
		 approved_for_web,
		 image_url,
		 thumbnail,
		 asset_id,
		 image_source)
	SELECT ObjectId,
	108, -- change in future support for non-object media
	CreatedDate,
	UpdatedDate,
	DeletedDate,
	ImageSizeInKilobytes,
	Filename,
	MediaStatus,
	MediaType,
	MediaFormat,
	ImageRestrictions,
	ImageDescription,
	case IsPrimary when 'true' then 1 else 0 end,
	ImageCreatorsDepartment,
	ImageWidth,
	AssetExternalId,
	ImageHeight,
	case ApprovedForWebsite when 'true' then 1 else 0 end,
	ShareURL,
	CAST(N'' AS xml).value('xs:base64Binary(sql:column("ThumbData"))', 'varbinary(max)'),
	AssetId,
	ImageSource 
	FROM   
	(
		SELECT 
			Name, 
			StringValue,
			parent_id
		FROM 
		   @hierarchy
		where name is not null
		--and parent_id is not null
	) t 
	PIVOT(
		max(stringvalue)
		FOR Name IN (
			ObjectId,
			CreatedDate,
			UpdatedDate,
			DeletedDate,
			ImageSizeInKilobytes,
			Filename,
			MediaStatus,
			MediaType,
			MediaFormat,
			ImageRestrictions,
			ImageDescription,
			IsPrimary,
			ImageCreatorsDepartment,
			ImageWidth,
			AssetExternalId,
			ImageHeight,
			ApprovedForWebsite,
			ShareURL,
			ThumbData,
			AssetId,
			ImageSource)

	) AS pivot_table;
  return
end
GO
