grant all on table cellwall.blast_hit to <USER>;
grant all on table cellwall.blast_hsp to <USER>;
grant all on table cellwall.comment to <USER>;
grant all on table cellwall.db to <USER>;
grant all on table cellwall.dblink to <USER>;
grant all on table cellwall.family to <USER>;
grant all on table cellwall.genome to <USER>;
grant all on table cellwall.groups to <USER>;
grant all on table cellwall.idxref to <USER>;
grant all on table cellwall.parameters to <USER>;
grant all on table cellwall.search to <USER>;
grant all on table cellwall.seqfeature to <USER>;
grant all on table cellwall.seqlocation to <USER>;
grant all on table cellwall.seqtags to <USER>;
grant all on table cellwall.sequence to <USER>;
grant all on table cellwall.species to <USER>;
grant all on table cellwall.subfamily to <USER>;
grant all on table cellwall.users to <USER>;



-- Sequences generated with
--  SELECT 'GRANT ALL ON TABLE cellwall.' || sequence_name || ' TO <USER>' FROM information_schema.sequences

--
GRANT ALL ON TABLE cellwall.dblink_id_seq TO <USER>;
GRANT ALL ON TABLE cellwall.blast_hit_id_seq TO <USER>;
GRANT ALL ON TABLE cellwall.blast_hsp_id_seq TO <USER>;
GRANT ALL ON TABLE cellwall.comment_id_seq TO <USER>;
GRANT ALL ON TABLE cellwall.db_id_seq TO <USER>;
GRANT ALL ON TABLE cellwall.family_id_seq TO <USER>;
GRANT ALL ON TABLE cellwall.genome_id_seq TO <USER>;
GRANT ALL ON TABLE cellwall.groups_id_seq TO <USER>;
GRANT ALL ON TABLE cellwall.parameters_id_seq TO <USER>;
GRANT ALL ON TABLE cellwall.search_id_seq TO <USER>;
GRANT ALL ON TABLE cellwall.seqfeature_id_seq TO <USER>;
GRANT ALL ON TABLE cellwall.seqlocation_id_seq TO <USER>;
GRANT ALL ON TABLE cellwall.seqtags_id_seq TO <USER>;
GRANT ALL ON TABLE cellwall.species_id_seq TO <USER>;
GRANT ALL ON TABLE cellwall.subfamily_id_seq TO <USER>;
GRANT ALL ON TABLE cellwall.users_id_seq TO <USER>;
GRANT ALL ON TABLE cellwall.sequence_id_seq TO <USER>;


ALTER <USER> cellwallweb SET search_path TO cellwall;
GRANT EXECUTE ON FUNCTION cellwall.replace_into_idxref(numeric, character varying) TO <USER>;

