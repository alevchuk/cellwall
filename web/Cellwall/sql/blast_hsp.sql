drop table if exists blast_hsp;
create table blast_hsp (
	id               integer not null auto_increment,
	query            integer not null,
	hit              integer not null,
	e                double  not null,
	score            double  not null,
	bits             double  not null,
	query_start      integer not null,
	query_stop       integer not null,
	hit_start        integer not null,
	hit_stop         integer not null,
	query_length     integer not null,
	hit_length       integer not null,
	total_length     integer not null,
	query_identity   double  not null,
	hit_identity     double  not null,
	total_identity   double  not null,
	percent_identity double  not null,
	query_conserved  double  not null,
	hit_conserved    double  not null,
	total_conserved  double  not null,
	updated     timestamp    not null,
	
	primary key (id),
	unique  key (query, hit),
	        key (query),
	        key (hit),
	        key (e),
	        key (score),
		key (bits),
		key (query_length),
		key (hit_length),
		key (total_length),
	
	foreign key (query) references sequence(id)
		on delete cascade
		on update cascade,
	foreign key (hit) references blast_hit(id)
		on delete cascade
		on update cascade
) type=innodb;
