drop table if exists parameters;
create table parameters (
	id        integer      not null auto_increment,
	section   enum('genome', 'database', 'search', 'group', 'family', 'sequence', 'species', 'other') not null,
	others    varchar(128),
	reference integer      not null,
	name      varchar(64) not null,
	value     varchar(255),
	updated     timestamp    not null,

	primary key (id),
	        key (section, others, reference, name)
) type=innodb;
