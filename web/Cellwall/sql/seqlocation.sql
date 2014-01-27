drop table if exists seqlocation;
create table seqlocation (
	id         integer not null auto_increment,
	seqfeature integer not null,
	rank       integer not null,
	start_pos  integer not null,
	end_pos    integer not null,
	strand     tinyint not null,
	updated     timestamp    not null,
	
	primary key (id),
	 unique key (seqfeature, rank),

	foreign key (seqfeature)  references seqfeature(id)
		on delete cascade
		on update cascade
) type=innodb;
