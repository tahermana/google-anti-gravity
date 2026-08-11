-- Supabase security hardening for the original Macro AI schema.
-- Run this after the existing schema migration.

create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_profiles_updated_at on public.profiles;
create trigger set_profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists set_daily_summaries_updated_at on public.daily_summaries;
create trigger set_daily_summaries_updated_at
before update on public.daily_summaries
for each row execute function public.set_updated_at();

alter table public.profiles enable row level security;
alter table public.meals enable row level security;
alter table public.daily_summaries enable row level security;
alter table public.weight_entries enable row level security;

revoke all on public.profiles from anon;
revoke all on public.meals from anon;
revoke all on public.daily_summaries from anon;
revoke all on public.weight_entries from anon;

grant usage on schema public to authenticated;
grant select, insert, update, delete on public.profiles to authenticated;
grant select, insert, update, delete on public.meals to authenticated;
grant select, insert, update, delete on public.daily_summaries to authenticated;
grant select, insert, update, delete on public.weight_entries to authenticated;

drop policy if exists "profiles are owned by the signed-in user" on public.profiles;
create policy "profiles are owned by the signed-in user"
on public.profiles
for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "meals are owned by the signed-in user" on public.meals;
create policy "meals are owned by the signed-in user"
on public.meals
for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "daily summaries are owned by the signed-in user" on public.daily_summaries;
create policy "daily summaries are owned by the signed-in user"
on public.daily_summaries
for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "weight entries are owned by the signed-in user" on public.weight_entries;
create policy "weight entries are owned by the signed-in user"
on public.weight_entries
for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create index if not exists meals_user_logged_at_idx
on public.meals (user_id, logged_at desc);

create index if not exists daily_summaries_user_summary_on_idx
on public.daily_summaries (user_id, summary_on desc);

create index if not exists weight_entries_user_logged_on_idx
on public.weight_entries (user_id, logged_on desc);
