---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- check sequence
-- usage: select gfam.check_sequence('PROTEIN',a.sequence), a.* from <table> a where gfam.check_sequence('PROTEIN',a.sequence) not null
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

create or replace function gfam.check_sequence(p_alphabet character varying, p_sequence character varying) returns character varying as $$
declare
  result        varchar := null;
  alphabet      varchar := null;
  i             integer := 0;
  seq_pos_value varchar := null;
  pos           integer := 0;
begin

  if upper(p_alphabet) = 'PROTEIN' then

     alphabet := 'ABCDEFGHIJKLMNPQRSTVWUYXZ*';

  end if;

  if upper(p_alphabet) = 'DNA' then

     alphabet := 'ATCG';

  end if;

  if alphabet is not null then

     for i in 1..char_length(p_sequence) loop

         seq_pos_value := substring(p_sequence from i for 1); 
         pos := position( seq_pos_value in alphabet );

         if ( pos = 0 ) then

            result := coalesce(result, '') || '{' || trim(to_char(i, '999999')) || '|' || seq_pos_value || '}';

         end if;

     end loop;

  else 

     result := 'Undefined alphabet.';

  end if;

  return result;
  
end;
$$ language 'plpgsql';

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- get_seguid
-- comment: the procedure assumes that the sequences comply with the standard defined in the ... procedure
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

create or replace function gfam.get_seguid(p_sequence varchar) returns varchar as $$
declare
  result varchar := null;
  x      integer;
begin

  select encode(gfam.digest(p_sequence, 'sha1'), 'base64')
  into   result;

  x := length(result);
  if substring(result from x for 1) = '=' then

     result := substring( result from 1 for x-1 );

  end if;

  return result;

end;
$$ language 'plpgsql';

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- family tree menu view
-- usage: select a.*, repeat(' ', 4 * (length(a.preorder_code)-1)) || b.family_tree_node_name, b.family_tree_node_abrev 
          from   gfam.get_preorder_hierarchy(1) a, gfam.family_tree_node b
          where  a.family_tree_node_id = b.family_tree_node_id
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

create or replace function gfam.get_parent_preorder_code(p_parent_node_id integer, p_family_tree_id integer) returns varchar as $$
declare
  result varchar := null;
begin

  select preorder_code 
  into   result
  from   gfam.family_tree_instance
  where      family_tree_id   = p_family_tree_id
         and instance_node_id = p_parent_node_id;

  return result;

end;
$$ language 'plpgsql';

create or replace function gfam.get_preorder_hierarchy(p_family_tree_id integer) returns setof gfam.family_tree_instance as
'
declare
  r gfam.family_tree_instance%rowtype;
  x integer;
begin

  update gfam.family_tree_instance set preorder_code = null
  where family_tree_id = p_family_tree_id; 

  update gfam.family_tree_instance set preorder_code = chr(rank + 64)
  where      parent_node_id is null
         and family_tree_id = p_family_tree_id;

  loop

    update gfam.family_tree_instance 
           set preorder_code = (case when gfam.get_parent_preorder_code(parent_node_id, family_tree_id) is null then null 
                                     else gfam.get_parent_preorder_code(parent_node_id, family_tree_id) || chr(rank + 64)
                                end)
    where     family_tree_id = p_family_tree_id
          and preorder_code is null;

    select count(*)
    into   x
    from   gfam.family_tree_instance
    where      family_tree_id = p_family_tree_id
           and preorder_code is null;

    if x = 0 then 

       exit;

    end if;   

  end loop; 

  for r in select * from gfam.family_tree_instance where family_tree_id = p_family_tree_id order by preorder_code loop
      return next r;
  end loop;

  return;
  
end
'
language 'plpgsql';

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
