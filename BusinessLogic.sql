use MyKindergarden;
GO
create view Only_visit_dates as
	(select * from VisitDate where IsVisitDate != 0)
GO
create function Is_workday(@d date)
	returns bit
	as
	begin
	if(DATEPART(dw, @d) < 6)
		return 1;
	return 0;
	end;
GO
create procedure Insert_date
	@d date
as
	if @d not in (select VisitDate.Date from VisitDate)
		insert VisitDate(Date, IsVisitDate) values (@d, dbo.Is_workday(@d));
GO
create procedure Insert_dates 
	@d1 date,
	@d2 date
as
	declare @buff date;
	set @buff = @d1;
	while @buff <= @d2
	begin
		execute Insert_date @buff;
		SET @buff=DATEADD(DAY,1,@buff);
	end;
GO
create function MinDate (@d1 date, @d2 date) 
	returns date
	as
	begin
	return case 
		when @d1 = null then @d2
		when @d2 = null then @d1
		when @d1 > @d2 then @d2
		else @d1
		end
	end;

GO

create trigger ClientUsrPwdConstraint ON Client after INSERT, UPDATE 
AS
	IF EXISTS(select * from inserted where Len(Username) < 5 or Len(inserted.Password) < 5)
		BEGIN  
		RAISERROR ('Length of Username and Password must be more than 6 characters', 16, 1);  
		ROLLBACK TRANSACTION;  
		RETURN   
		END;
GO
create trigger ClientTypeChangeBlock ON Client after UPDATE 
AS
	IF EXISTS(select inserted.* from inserted join deleted on inserted.Id = deleted.Id where inserted.ClientType != deleted.Id)
		BEGIN  
			RAISERROR ('ClientType can`t be changed', 16, 1);  
			ROLLBACK TRANSACTION;  
			RETURN   
		END;
GO

create trigger VisitDateUpdateBlock on VisitDate after UPDATE
as
	if exists(select inserted.* from inserted join deleted on deleted.Id = inserted.Id and deleted.Date != inserted.Date)
		RAISERROR ('Date can`t be updated', 16, 1);  
		ROLLBACK TRANSACTION;  
	RETURN
GO
create trigger VisitDateUpdate on VisitDate after UPDATE
as
	delete from VisitNote 
		where VisitNote.Date in
		(select inserted.Id from inserted where inserted.IsVisitDate = 0);
	insert into VisitNote(Child, Date, Visited)
		select chld.Id, inserted.Id, 0 
		from (select inserted.* from inserted join deleted 
				on deleted.Id = inserted.Id 
				and inserted.IsVisitDate = 1 
				and deleted.IsVisitDate = 0) as inserted
		cross join Child chld  
			where inserted.Date between chld.VisitStart and chld.VisitEnd;
GO
create trigger VisitDateInsert on VisitDate after INSERT
as
	insert into VisitNote(Child, Date, Visited)
		select chld.Id, inserted.Id, 0 from (select * from inserted where inserted.IsVisitDate = 1) as inserted
		cross join Child chld  
			where inserted.Date between chld.VisitStart and chld.VisitEnd;
GO


create trigger VisitNoteUpdateBlock ON VisitNote after UPDATE 
AS
	if exists(select inserted.* from inserted join deleted on inserted.Id = deleted.Id 
				and (inserted.Date != deleted.Date or inserted.Child != deleted.Child))
	BEGIN  
		RAISERROR ('Attributes Child and Date can`t be updated', 16, 1);  
		ROLLBACK TRANSACTION;  
		RETURN   
	END;
GO
create trigger VisitDuplicateBlock ON VisitNote after INSERT, UPDATE 
AS
	if exists(select * from VisitNote group by VisitNote.Child, VisitNote.Date having count(VisitNote.Date) > 1)
	BEGIN  
		RAISERROR ('Dates for one child can`t duplicate.', 16, 1);  
		ROLLBACK TRANSACTION;  
		RETURN   
	END;
GO

create trigger VisitNoteDateDelete ON Child after UPDATE 
AS
	delete from VisitNote where Id = 
		(
			select VisitNote.Id from VisitNote 
				join VisitDate on VisitDate.Id = VisitNote.Date
				join inserted on inserted.Id = VisitNote.Child 
				and VisitDate.Date not between inserted.VisitStart and inserted.VisitEnd
		);	
GO
create trigger UpdateVisitNoteAddition ON Child after UPDATE 
AS
	insert into VisitNote(Child, Date, Visited)
		select inserted.Id, vdate.Id, 0 from 
			(select inserted.* from inserted join deleted 
				on deleted.Id = inserted.Id
				and (deleted.VisitStart != inserted.VisitStart or deleted.VisitEnd != inserted.VisitEnd)) inserted
		cross join Only_visit_dates as vdate 
			where vdate.Date between inserted.VisitStart and inserted.VisitEnd
			and not exists(select * from VisitNote where VisitNote.Date = vdate.Id and VisitNote.Child = inserted.Id);
GO
create trigger InsertVisitNoteAddition ON Child after INSERT
AS
	insert into VisitNote(Child, Date, Visited)
		select inserted.Id, vdate.Id from inserted
		cross join Only_visit_dates as vdate 
			where vdate.Date between inserted.VisitStart and inserted.VisitEnd;
GO

