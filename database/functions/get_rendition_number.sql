create FUNCTION [dbo].[get_rendition_number]()
RETURNS @data table (
					 rendition_number nvarchar(64),
					 sort_number nvarchar(80)
					)  
AS 

BEGIN
	insert into @data (rendition_number,sort_number)
	select z.rendition_number,
		left('R' + space(8),8) +
			substring(rendition_number,3,4) + 
			LEFT(
				RIGHT(space(6) +
					cast(
							cast(
								Substring(z.rendition_number,
											CHARINDEX ('-', z.rendition_number) + 1 ,len(z.rendition_number)
										 )
								as int 
								)
						as nvarchar(60)
						),6) + space(6), 6)
	from (
	select 'R.'+cast(year(getdate()) as nvarchar(4)) + '-' + cast(coalesce(max(cast(seq as int)),0) + 1 as nvarchar(6)) rendition_number
	from (
			select renditionnumber
				  ,case when renditionnumber like '%-%'
						 then right(renditionnumber, charindex('-', reverse(renditionnumber)) - 1)
						 else renditionnumber
					end seq
			from mediarenditions 
			where isnumeric(substring(renditionnumber,3,4)) = 1
			and 'R.' + substring(renditionnumber,3,4) = 'R.' + cast(year(getdate()) as nvarchar(4)) 
			and loginid = 'amanita'
		  ) x ) z

	-- Return the result of the function
	RETURN 

END
GO
