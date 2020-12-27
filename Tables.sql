create database MyKindergarden;
GO
use MyKindergarden;

create table ClientType
(
	Id int primary key,
	TypeName nvarchar(10) not null unique
);

create table GroupType
(
	Id int primary key,
	TypeName nvarchar(20) not null unique
);

create table Client 
(
	Id int identity(1,1) primary key,
	Username nvarchar(30) not null unique,
	"Password" nvarchar(16) not null,
	FirstName nvarchar(30) not null,
	LastName nvarchar(30) not null,
	MiddleName nvarchar(30) not null,
	IsActive bit not null default 1,
	ClientType int not null default 1,
	foreign key (ClientType) references ClientType(Id)
);

create table KinderGroup
(
	Id int identity(1,1) primary key,
	GroupName nvarchar(30) not null unique,
	GroupType int null,
	IsActive bit null,
	foreign key (GroupType) references GroupType (Id)
);

create table Child
(
	Id int identity(1,1) primary key,
	FirstName nvarchar(30) not null,
	LastName nvarchar(30) not null,
	MiddleName nvarchar(30) not null,
	KinderGroup int null,
	VisitStart date not null,
	VisitEnd date null,
	foreign key (KinderGroup) references KinderGroup (Id) on delete set null
);

create table TeacherGroup
(
	Teacher int not null,
	KinderGroup int not null,
	"Shift" int not null,
	foreign key (Teacher) references Client (Id) on delete cascade,
	foreign key (KinderGroup) references KinderGroup (Id) on delete cascade,
	constraint PK_TeacherGroup primary key clustered (Teacher, KinderGroup)
);

create table VisitDate
(
	Id int identity(1,1) primary key,
	"Date" date not null unique,
	IsVisitDate bit default 0,
);

create table VisitNote
(
	Id int identity(1,1) primary key,
	Child int not null,
	"Date" int not null,
	Visited bit default null,
	Additional nvarchar(100) null,
	foreign key (Child) references Child (Id) on delete cascade,
	foreign key ("Date") references VisitDate (Id) on delete cascade
);