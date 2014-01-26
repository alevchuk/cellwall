copy cellwall.from_mysql_dblink ( id, section, sequence, db, href, updated ) from '/srv/from-mysql-cellwall-dblink.tab';
insert into cellwall.dblink (  id, section, sequence, db, href, updated)
select to_number(id,'99999999999'), section, to_number(sequence,'99999999999'), db, href, to_timestamp(updated,'YYYY-MM-DD HH:MI:SS')
from cellwall.from_mysql_dblink

copy cellwall.from_mysql_db ( id, genome, name, db_type, updated ) from '/srv/from-mysql-cellwall-db.tab';
insert into cellwall.db (  id, genome, name, db_type, updated )
select to_number(id,'99999999999'), to_number(genome,'99999999999'), name, db_type, to_timestamp(updated,'YYYY-MM-DD HH:MI:SS')
from cellwall.from_mysql_db

copy cellwall.from_mysql_family ( id, grp, rank, name, abrev, updated ) from '/srv/from-mysql-cellwall-family.tab';
insert into cellwall.family (  id, grp, rank, name, abrev, updated )
select to_number(id,'99999999999'), to_number(grp,'99999999999'), to_number(rank,'99999999999'), name, abrev, to_timestamp(updated,'YYYY-MM-DD HH:MI:SS')
from cellwall.from_mysql_family

copy cellwall.from_mysql_genome ( id, name, updated ) from '/srv/from-mysql-cellwall-genome.tab';
insert into cellwall.genome (  id, name, updated )
select to_number(id,'99999999999'), name, to_timestamp(updated,'YYYY-MM-DD HH:MI:SS')
from cellwall.from_mysql_genome

copy cellwall.from_mysql_groups ( id, parent, rank, name, updated ) from '/srv/from-mysql-cellwall-groups.tab';
update cellwall.from_mysql_groups set parent = NULL where parent = 'NULL';
insert into cellwall.groups (  id, parent, rank, name, updated )
select to_number(id,'99999999999'), to_number(parent,'99999999999'), to_number(rank,'99999999999'), name, to_timestamp(updated,'YYYY-MM-DD HH:MI:SS')
from cellwall.from_mysql_groups

commit

copy cellwall.from_mysql_idxref ( sequence, accession ) from '/srv/from-mysql-cellwall-idxref.tab';
insert into cellwall.idxref (  sequence, accession )
select to_number(sequence,'99999999999'), accession
from cellwall.from_mysql_idxref


copy cellwall.from_mysql_parameters ( id, section, others, reference, name, value, updated ) from '/srv/from-mysql-cellwall-parameters.tab';
insert into cellwall.parameters (  id, section, others, reference, name, value, updated )
select to_number(id,'99999999999'), section, others, to_number(reference,'99999999999'), name, value, to_timestamp(updated,'YYYY-MM-DD HH:MI:SS')
from cellwall.from_mysql_parameters



copy cellwall.from_mysql_search ( id, name, s_type, genome, db, query, updated ) from '/srv/from-mysql-cellwall-search.tab';
update cellwall.from_mysql_search set genome = NULL where genome = 'NULL';
update cellwall.from_mysql_search set db = NULL where db = 'NULL';
insert into cellwall.search (  id, name, s_type, genome, db, query, updated )
select to_number(id,'99999999999'), name, s_type, to_number(genome,'99999999999'), to_number(db,'99999999999'), query, to_timestamp(updated,'YYYY-MM-DD HH:MI:SS')
from cellwall.from_mysql_search



copy cellwall.from_mysql_species ( id, genus, species, sub_species, common_name, updated ) from '/srv/from-mysql-cellwall-species.tab';
insert into cellwall.species (  id, genus, species, sub_species, common_name, updated )
select to_number(id,'99999999999'), genus, species, sub_species, common_name, to_timestamp(updated,'YYYY-MM-DD HH:MI:SS')
from cellwall.from_mysql_species


commit

copy cellwall.from_mysql_subfamily ( id, family, rank, name, updated ) from '/srv/from-mysql-cellwall-subfamily.tab';
insert into cellwall.subfamily (  id, family, rank, name, updated )
select to_number(id,'99999999999'), to_number(family,'99999999999'), to_number(rank,'99999999999'), name, to_timestamp(updated,'YYYY-MM-DD HH:MI:SS')
from cellwall.from_mysql_subfamily




copy cellwall.from_mysql_users ( id, email, password, first, last, institute, address, updated ) from '/srv/from-mysql-cellwall-users.tab';
insert into cellwall.users (  id, email, password, first, last, institute, address, updated )
select to_number(id,'99999999999'), email, password, first, last, institute, address, to_timestamp(updated,'YYYY-MM-DD HH:MI:SS')
from cellwall.from_mysql_users




-- Done
truncate table cellwall.from_mysql_sequence
copy cellwall.from_mysql_sequence ( id, db, family, species, accession, display, description, length, alphabet, sequence, gene_name, fullname, alt_fullname, symbols, updated ) from '/srv/from-mysql-cellwall-sequence.tab';
insert into cellwall.sequence (  id, db, family, species, accession, display, description, length, alphabet, sequence, gene_name, fullname, alt_fullname, symbols, updated )
select to_number(id,'99999999999'), to_number(db,'99999999999'), to_number(family,'99999999999'), to_number(species,'99999999999'), accession, display, description, to_number(length,'99999999999'), alphabet, sequence, gene_name, fullname, alt_fullname, symbols, to_timestamp(updated,'YYYY-MM-DD HH:MI:SS')
from cellwall.from_mysql_sequence








copy cellwall.from_mysql_seqtags ( id, feature, name, value, updated ) from '/srv/from-mysql-cellwall-seqtags.tab';
insert into cellwall.seqtags (  id, feature, name, value, updated )
select to_number(id,'99999999999'), to_number(feature,'99999999999'), name, value, to_timestamp(updated,'YYYY-MM-DD HH:MI:SS')
from cellwall.from_mysql_seqtags

commit


copy cellwall.from_mysql_seqfeature ( id, sequence, rank, primary_tag, updated ) from '/srv/from-mysql-cellwall-seqfeature.tab';
insert into cellwall.seqfeature (  id, sequence, rank, primary_tag, updated )
select to_number(id,'99999999999'), to_number(sequence,'99999999999'), to_number(rank,'99999999999'), primary_tag, to_timestamp(updated,'YYYY-MM-DD HH:MI:SS')
from cellwall.from_mysql_seqfeature




copy cellwall.from_mysql_seqlocation ( id, seqfeature, rank, start_pos, end_pos, strand, updated ) from '/srv/from-mysql-cellwall-seqlocation.tab';
insert into cellwall.seqlocation (  id, seqfeature, rank, start_pos, end_pos, strand, updated )
select to_number(id,'99999999999'), to_number(seqfeature,'99999999999'), to_number(rank,'99999999999'), to_number(start_pos,'99999999999'), to_number(end_pos,'99999999999'), to_number(strand,'99999999999'), to_timestamp(updated,'YYYY-MM-DD HH:MI:SS')
from cellwall.from_mysql_seqlocation

