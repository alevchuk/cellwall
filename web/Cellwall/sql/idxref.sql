drop table if exists idxref;
create table idxref (
	sequence    integer      not null,
	accession   varchar(255) not null,

	        key (sequence),
	 unique key (accession),

	foreign key (sequence)  references sequence(id)
		on delete cascade
		on update cascade
) type=innodb;
