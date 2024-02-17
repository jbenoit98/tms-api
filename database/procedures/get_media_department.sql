CREATE procedure get_media_department (
	@p_department nvarchar(100) = null,
	@p_department_id integer output) 
as

begin
	if @p_department is null
		begin
			select @p_department_id = departmentid
			from departments
			where department = '(not assigned)'
			and maintableid = 318;
			return @p_department_id
		end
	else
		begin
			select @p_department_id = departmentid
			from departments
			where department = @p_department
			and maintableid = 318;

			if @p_department_id is null
				begin
					--insert new path if doesn't exist
					insert into departments (department,maintableid,loginid)
					values (@p_department,318,'amanita')
					set @p_department_id = scope_identity()
					
				end
		end

end
	
GO