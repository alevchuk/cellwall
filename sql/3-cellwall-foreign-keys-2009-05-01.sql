-------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Foreign key definitions
-------------------------------------------------------------------------------------------------------------------------------------------------------------

alter table cellwall.blast_hit add constraint fk_blast_hit_search foreign key (search) references cellwall.search(id) on update cascade on delete cascade;
alter table cellwall.blast_hit add constraint fk_blast_hit_species foreign key (species) references cellwall.species(id) on update cascade;

-- alter table cellwall.blast_hsp add constraint blast_hsp_ibfk_1 foreign key (query) references cellwall.sequence (id) on delete cascade on update cascade;
alter table cellwall.blast_hsp add constraint blast_hsp_ibfk_2 foreign key (hit) references cellwall.blast_hit (id) on delete cascade on update cascade;

-- alter table cellwall.comment add constraint comment_ibfk_1 foreign key (sequence_id) references cellwall.sequence(id) on update cascade;
alter table cellwall.comment add constraint comment_ibfk_2 foreign key (user_id) references cellwall.users(id) on delete cascade on update cascade;

alter table cellwall.db add constraint db_ibfk_1 foreign key (genome) references cellwall.genome(id) on delete cascade on update cascade;

-- alter table cellwall.dblink add constraint dblink_ibfk_1 foreign key (sequence) references cellwall.sequence(id) on delete cascade on update cascade;

alter table cellwall.family add constraint family_ibfk_1 foreign key (grp) references cellwall.groups(id) on delete cascade on update cascade;

alter table cellwall.groups add constraint groups_ibfk_1 foreign key(parent) references cellwall.groups(id) on delete cascade on update cascade;

-- alter table cellwall.idxref add  constraint idxref_ibfk_1 foreign key (sequence) references cellwall.sequence(id) on delete cascade on update cascade;

alter table cellwall.search add constraint search_ibfk_1 foreign key(db) references cellwall.db(id) on delete cascade on update cascade;

-- alter table cellwall.seqfeature add constraint seqfeature_ibfk_1 foreign key (sequence) references cellwall.sequence(id) on delete cascade on update cascade;

alter table cellwall.seqlocation add constraint seqlocation_ibfk_1 foreign key (seqfeature) references cellwall.seqfeature (id) on delete cascade on update cascade;

alter table cellwall.seqtags add constraint seqtags_ibfk_1 foreign key(feature) references cellwall.seqfeature(id) on delete cascade on update cascade;

alter table cellwall.subfamily add constraint subfamily_ibfk_1 foreign key (family) references cellwall.family (id) on delete cascade on update cascade;

alter table cellwall.sequence add constraint sequence_ibfk_1 foreign key (db) references cellwall.db(id) on delete cascade on update cascade;
alter table cellwall.sequence add constraint sequence_ibfk_2 foreign key (family) references cellwall.family(id) on delete cascade on update cascade;
alter table cellwall.sequence add constraint sequence_ibfk_3 foreign key (species) references cellwall.species(id) on update cascade;

-------------------------------------------------------------------------------------------------------------------------------------------------------------

