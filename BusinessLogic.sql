use MyKindergarden;
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

create trigger VisitDateUpdateBlock on VisitDate instead of UPDATE
as
	RAISERROR ('VisitDate can`t be updated', 16, 1);  
	ROLLBACK TRANSACTION;  
	RETURN
GO
create trigger VisitDateInsert on VisitDate after INSERT
as
	insert into VisitNote(Child,Date)
		select chld.Id, inserted.Id from inserted
		cross join (select * from Child) chld  
			where inserted.Date between chld.VisitStart and dbo.MinDate(GETDATE(), chld.VisitEnd);
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

create trigger VisitNoteDateUpdate ON Child after UPDATE 
AS
	delete from VisitNote where Id = 
		(
			select VisitNote.Id from VisitNote 
				join VisitDate on VisitDate.Id = VisitNote.Date
				join inserted on inserted.Id = VisitNote.Child 
				and VisitDate.Date not between inserted.VisitStart and dbo.MinDate(GETDATE(), inserted.VisitEnd)
		);	
GO
create trigger UpdateVisitNoteAddition ON Child after UPDATE 
AS
	insert into VisitNote(Child, Date)
		select inserted.Id, vdate.Id from inserted
		cross join VisitDate as vdate 
			where vdate.Date between inserted.VisitStart and dbo.MinDate(GETDATE(), inserted.VisitEnd)
			and not exists(select * from VisitNote where VisitNote.Date = vdate.Id and VisitNote.Child = inserted.Id);
GO
create trigger InsertVisitNoteAddition ON Child after INSERT
AS
	insert into VisitNote(Child, Date)
		select inserted.Id, vdate.Id from inserted
		cross join VisitDate as vdate 
			where vdate.Date between inserted.VisitStart and dbo.MinDate(GETDATE(), inserted.VisitEnd);
GO

