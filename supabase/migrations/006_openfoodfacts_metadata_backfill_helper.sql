create schema if not exists private;

create or replace function private.backfill_openfoodfacts_metadata_batch(batch_size int default 10000)
returns int
language plpgsql
as $$
declare
  updated_count int;
begin
  with batch as (
    select id
    from public.foods
    where source = 'openfoodfacts'
      and raw_source is not null
    order by id
    limit batch_size
  )
  update public.foods foods
  set
    labels = nullif(foods.raw_source->>'labels', ''),
    labels_tags = case
      when nullif(foods.raw_source->>'labels_tags', '') is null then '{}'::text[]
      else string_to_array(foods.raw_source->>'labels_tags', ',')
    end,
    traces = nullif(foods.raw_source->>'traces', ''),
    traces_tags = case
      when nullif(foods.raw_source->>'traces_tags', '') is null then '{}'::text[]
      else string_to_array(foods.raw_source->>'traces_tags', ',')
    end,
    origins = nullif(foods.raw_source->>'origins', ''),
    origins_tags = case
      when nullif(foods.raw_source->>'origins_tags', '') is null then '{}'::text[]
      else string_to_array(foods.raw_source->>'origins_tags', ',')
    end,
    manufacturing_places = nullif(foods.raw_source->>'manufacturing_places', ''),
    stores = nullif(foods.raw_source->>'stores', ''),
    source_creator = nullif(foods.raw_source->>'creator', ''),
    source_created_t = case
      when foods.raw_source->>'created_t' ~ '^[0-9]+$' then (foods.raw_source->>'created_t')::bigint
      else null
    end,
    source_last_modified_t = case
      when foods.raw_source->>'last_modified_t' ~ '^[0-9]+$' then (foods.raw_source->>'last_modified_t')::bigint
      else null
    end,
    ecoscore_score = case
      when foods.raw_source->>'ecoscore_score' ~ '^-?[0-9]+$' then (foods.raw_source->>'ecoscore_score')::int
      else null
    end,
    ecoscore_grade = nullif(foods.raw_source->>'ecoscore_grade', ''),
    food_groups = nullif(foods.raw_source->>'food_groups', ''),
    food_groups_tags = case
      when nullif(foods.raw_source->>'food_groups_tags', '') is null then '{}'::text[]
      else string_to_array(foods.raw_source->>'food_groups_tags', ',')
    end,
    pnns_groups_1 = nullif(foods.raw_source->>'pnns_groups_1', ''),
    pnns_groups_2 = nullif(foods.raw_source->>'pnns_groups_2', ''),
    raw_source = null
  from batch
  where foods.id = batch.id;

  get diagnostics updated_count = row_count;
  return updated_count;
end;
$$;
