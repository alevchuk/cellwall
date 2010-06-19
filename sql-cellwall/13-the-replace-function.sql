CREATE OR REPLACE FUNCTION cellwall.replace_into_idxref( p_sequence_id in numeric, p_accession in varchar ) RETURNS void AS $$
BEGIN
IF EXISTS( SELECT * FROM cellwall.idxref
WHERE accession = p_accession ) THEN
  UPDATE cellwall.idxref
  SET sequence = p_sequence_id WHERE accession = p_accession;
ELSE
  INSERT INTO cellwall.idxref ( sequence, accession ) VALUES( p_sequence_id, p_accession );
  END IF;
  RETURN;
END;
$$ LANGUAGE plpgsql;

CREATE LANGUAGE plpgsql;

select cellwall.replace_into_idxref( ?, ? )

-- testing -----

select * from cellwall.idxref where sequence in (1, 2)

delete from cellwall.idxref where accession = 'testword'
1, "67231.t00008"