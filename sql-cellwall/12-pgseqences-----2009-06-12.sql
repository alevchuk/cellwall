SELECT 'select setval(''cellwall.' || sequence_name || ', (select max(id)+1 from cellwall.' || sequence_name || '));'
FROM information_schema.sequences



SELECT 'select currval(''cellwall' || sequence_name ||  ''');' FROM information_schema.sequences



GRANT SELECT ON cellwall.dblink_id_seq TO afeher;





insert into cellwall.dblink ( section, sequence, db, href, updated )
select section, sequence, db, href || 'y', updated 
from   cellwall.dblink
where  id = 17828


select setval('cellwall.dblink_id_seq', (select max(id)+1 from cellwall.dblink));
select setval('cellwall.blast_hit_id_seq', (select max(id)+1 from cellwall.blast_hit));
select setval('cellwall.blast_hsp_id_seq', (select max(id)+1 from cellwall.blast_hsp));
select setval('cellwall.comment_id_seq', (select max(id)+1 from cellwall.comment));
select setval('cellwall.db_id_seq', (select max(id)+1 from cellwall.db));
select setval('cellwall.family_id_seq', (select max(id)+1 from cellwall.family));
select setval('cellwall.genome_id_seq', (select max(id)+1 from cellwall.genome));
select setval('cellwall.groups_id_seq', (select max(id)+1 from cellwall.groups));
select setval('cellwall.parameters_id_seq', (select max(id)+1 from cellwall.parameters));
select setval('cellwall.search_id_seq', (select max(id)+1 from cellwall.search));
select setval('cellwall.seqfeature_id_seq', (select max(id)+1 from cellwall.seqfeature));
select setval('cellwall.seqlocation_id_seq', (select max(id)+1 from cellwall.seqlocation));
select setval('cellwall.seqtags_id_seq', (select max(id)+1 from cellwall.seqtags));
select setval('cellwall.species_id_seq', (select max(id)+1 from cellwall.species));
select setval('cellwall.subfamily_id_seq', (select max(id)+1 from cellwall.subfamily));
select setval('cellwall.users_id_seq', (select max(id)+1 from cellwall.users));
select setval('cellwall.sequence_id_seq', (select max(id)+1 from cellwall.sequence));





--select currval('cellwall.dblink_id_seq');
--select currval('cellwall.blast_hit_id_seq');
-- select currval('cellwall.blast_hsp_id_seq');
select currval('cellwall.comment_id_seq');
--select currval('cellwall.db_id_seq');
select currval('cellwall.family_id_seq');
select currval('cellwall.genome_id_seq');
select currval('cellwall.groups_id_seq');
select currval('cellwall.parameters_id_seq');
select currval('cellwall.search_id_seq');
select currval('cellwall.seqfeature_id_seq');
select currval('cellwall.seqlocation_id_seq');
select currval('cellwall.seqtags_id_seq');
select currval('cellwall.species_id_seq');
select currval('cellwall.subfamily_id_seq');
select currval('cellwall.users_id_seq');
select currval('cellwall.sequence_id_seq');



