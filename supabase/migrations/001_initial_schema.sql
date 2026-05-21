create extension if not exists pgcrypto;

create table public.user_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null,
  gender text check (gender in ('female', 'male', 'prefer_not_to_say')),
  age int check (age between 13 and 100),
  height_cm int check (height_cm between 100 and 240),
  weight_kg numeric(5,2) check (weight_kg between 25 and 300),
  target_weight_kg numeric(5,2),
  selected_goal text not null check (selected_goal in ('weight_loss', 'gain_muscle', 'maintain', 'fasting')),
  activity_level text not null check (activity_level in ('sedentary', 'light', 'moderate', 'active')),
  preferred_logging_method text not null check (preferred_logging_method in ('photo', 'text', 'mixed')),
  onboarding_completed boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.foods (
  id uuid primary key default gen_random_uuid(),
  source text not null default 'fatsecret',
  source_food_id text,
  name text not null,
  brand text,
  food_type text,
  region text not null default 'TR',
  language text not null default 'tr',
  image_url text,
  source_url text,
  raw_source jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (source, source_food_id)
);

create table public.food_servings (
  id uuid primary key default gen_random_uuid(),
  food_id uuid not null references public.foods(id) on delete cascade,
  source_serving_id text,
  serving_description text not null,
  metric_amount numeric(10,3),
  metric_unit text,
  calories numeric(10,2) not null default 0,
  protein_gr numeric(10,2) not null default 0,
  carbs_gr numeric(10,2) not null default 0,
  fat_gr numeric(10,2) not null default 0,
  is_default boolean not null default false,
  raw_source jsonb,
  created_at timestamptz not null default now(),
  unique (food_id, source_serving_id)
);

create table public.food_search_cache (
  id uuid primary key default gen_random_uuid(),
  query text not null,
  normalized_query text not null,
  region text not null default 'TR',
  language text not null default 'tr',
  result_food_ids uuid[] not null default '{}',
  source text not null default 'fatsecret',
  source_page int not null default 0,
  total_results int,
  expires_at timestamptz not null default now() + interval '30 days',
  created_at timestamptz not null default now(),
  unique (normalized_query, region, language, source_page)
);

create table public.meals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  meal_type text not null check (meal_type in ('breakfast', 'lunch', 'dinner', 'snack')),
  title text not null,
  total_calories numeric(10,2) not null default 0,
  protein_gr numeric(10,2) not null default 0,
  carbs_gr numeric(10,2) not null default 0,
  fat_gr numeric(10,2) not null default 0,
  logged_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table public.meal_items (
  id uuid primary key default gen_random_uuid(),
  meal_id uuid not null references public.meals(id) on delete cascade,
  food_id uuid references public.foods(id),
  name text not null,
  quantity numeric(10,2) not null default 1,
  unit text not null default 'serving',
  calories numeric(10,2) not null default 0,
  protein_gr numeric(10,2) not null default 0,
  carbs_gr numeric(10,2) not null default 0,
  fat_gr numeric(10,2) not null default 0,
  confidence text check (confidence in ('low', 'medium', 'high')),
  raw_analysis jsonb,
  created_at timestamptz not null default now()
);

create table public.fatsecret_import_log (
  id uuid primary key default gen_random_uuid(),
  request_kind text not null,
  query text,
  status text not null,
  source_status int,
  inserted_food_count int not null default 0,
  error_message text,
  created_at timestamptz not null default now()
);

alter table public.user_profiles enable row level security;
alter table public.meals enable row level security;
alter table public.meal_items enable row level security;
alter table public.foods enable row level security;
alter table public.food_servings enable row level security;
alter table public.food_search_cache enable row level security;
alter table public.fatsecret_import_log enable row level security;

create policy "Users can read own profile"
  on public.user_profiles for select
  using (auth.uid() = id);

create policy "Users can update own profile"
  on public.user_profiles for update
  using (auth.uid() = id);

create policy "Users can read own meals"
  on public.meals for select
  using (auth.uid() = user_id);

create policy "Users can insert own meals"
  on public.meals for insert
  with check (auth.uid() = user_id);

create policy "Users can delete own meals"
  on public.meals for delete
  using (auth.uid() = user_id);

create policy "Users can read own meal items"
  on public.meal_items for select
  using (
    exists (
      select 1 from public.meals
      where meals.id = meal_items.meal_id
      and meals.user_id = auth.uid()
    )
  );

create policy "Users can read food catalog"
  on public.foods for select
  using (true);

create policy "Users can read serving catalog"
  on public.food_servings for select
  using (true);

create index foods_name_idx on public.foods using gin (to_tsvector('simple', name));
create index foods_source_idx on public.foods (source, source_food_id);
create index food_search_cache_query_idx on public.food_search_cache (normalized_query, region, language);
create index meals_user_logged_idx on public.meals (user_id, logged_at desc);
