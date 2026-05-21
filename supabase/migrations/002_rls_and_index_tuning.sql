drop policy if exists "Users can read own profile" on public.user_profiles;
drop policy if exists "Users can update own profile" on public.user_profiles;
drop policy if exists "Users can read own meals" on public.meals;
drop policy if exists "Users can insert own meals" on public.meals;
drop policy if exists "Users can delete own meals" on public.meals;
drop policy if exists "Users can read own meal items" on public.meal_items;

create policy "Users can read own profile"
  on public.user_profiles for select
  using ((select auth.uid()) = id);

create policy "Users can update own profile"
  on public.user_profiles for update
  using ((select auth.uid()) = id);

create policy "Users can read own meals"
  on public.meals for select
  using ((select auth.uid()) = user_id);

create policy "Users can insert own meals"
  on public.meals for insert
  with check ((select auth.uid()) = user_id);

create policy "Users can delete own meals"
  on public.meals for delete
  using ((select auth.uid()) = user_id);

create policy "Users can read own meal items"
  on public.meal_items for select
  using (
    exists (
      select 1 from public.meals
      where meals.id = meal_items.meal_id
      and meals.user_id = (select auth.uid())
    )
  );

create policy "Clients cannot access food search cache"
  on public.food_search_cache for all
  using (false)
  with check (false);

create policy "Clients cannot access import logs"
  on public.fatsecret_import_log for all
  using (false)
  with check (false);

create index meal_items_meal_id_idx on public.meal_items (meal_id);
create index meal_items_food_id_idx on public.meal_items (food_id);
