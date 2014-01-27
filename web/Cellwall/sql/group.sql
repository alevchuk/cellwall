drop table if exists groups;
create table groups (
	id      integer      not null auto_increment,
	parent  integer,
	rank    integer      not null,
	name    varchar(128) not null,
	updated timestamp    not null,

	primary key (id),
	unique  key (name),

	foreign key (parent) references groups(id)
		on delete cascade
		on update cascade
) type=innodb;
