create extension if not exists pgcrypto;

create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  goal integer not null default 2000,
  eaten integer not null default 0,
  burned integer not null default 0,
  protein_current integer not null default 0,
  protein_target integer not null default 150,
  carbs_current integer not null default 0,
  carbs_target integer not null default 200,
  fat_current integer not null default 0,
  fat_target integer not null default 83,
  water_liters numeric not null default 0,
  steps integer not null default 0,
  reminders_enabled boolean not null default true,
  ai_enabled boolean not null default true,
  dark_mode boolean not null default true,
  user_goal text,
  obstacles text[] not null default '{}',
  desired_weight numeric not null default 70,
  has_trainer boolean,
  workout_frequency text,
  sex text,
  birth_month integer not null default 10,
  birth_day integer not null default 16,
  birth_year integer not null default 1999,
  source text,
  current_weight numeric not null default 78,
  height_cm integer not null default 175,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.meals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  meal_type text not null,
  time_text text not null default '',
  kcal integer not null default 0,
  emoji text not null default '',
  protein integer not null default 0,
  carbs integer not null default 0,
  fat integer not null default 0,
  logged_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table if not exists public.daily_summaries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  summary_on date not null default current_date,
  calories integer not null default 0,
  burned integer not null default 0,
  protein integer not null default 0,
  carbs integer not null default 0,
  fat integer not null default 0,
  water_liters numeric not null default 0,
  steps integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, summary_on)
);

create table if not exists public.weight_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  logged_on date not null default current_date,
  weight_kg numeric not null,
  created_at timestamptz not null default now(),
  unique (user_id, logged_on)
);

alter table public.profiles enable row level security;
alter table public.meals enable row level security;
alter table public.daily_summaries enable row level security;
alter table public.weight_entries enable row level security;

grant usage on schema public to authenticated;
grant select, insert, update, delete on
  public.profiles,
  public.meals,
  public.daily_summaries,
  public.weight_entries
to authenticated;

create policy "profiles are owned by the signed-in user"
on public.profiles
for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "meals are owned by the signed-in user"
on public.meals
for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "daily summaries are owned by the signed-in user"
on public.daily_summaries
for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "weight entries are owned by the signed-in user"
on public.weight_entries
for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create index if not exists meals_user_logged_at_idx
  on public.meals (user_id, logged_at);

create index if not exists daily_summaries_user_summary_on_idx
  on public.daily_summaries (user_id, summary_on);

create index if not exists weight_entries_user_logged_on_idx
  on public.weight_entries (user_id, logged_on);
