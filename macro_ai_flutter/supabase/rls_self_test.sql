-- Run after supabase_security_hardening.sql.
-- The test uses two temporary auth users, verifies isolation, then rolls back.

begin;

insert into auth.users (
  id,
  instance_id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at
)
values
  ('00000000-0000-4000-8000-00000000000a', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'macro-ai-user-a@example.com', '', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now()),
  ('00000000-0000-4000-8000-00000000000b', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'macro-ai-user-b@example.com', '', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now())
on conflict (id) do nothing;

set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-00000000000a', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

insert into public.profiles (user_id, user_goal)
values (auth.uid(), 'Lose weight')
on conflict (user_id) do update set user_goal = excluded.user_goal;

insert into public.meals (user_id, name, meal_type, time_text, kcal)
values (auth.uid(), 'User A meal', 'Breakfast', '8:00 AM', 300);

insert into public.daily_summaries (user_id, summary_on, calories)
values (auth.uid(), current_date, 300)
on conflict (user_id, summary_on) do update set calories = excluded.calories;

insert into public.weight_entries (user_id, logged_on, weight_kg)
values (auth.uid(), current_date, 78.5)
on conflict (user_id, logged_on) do update set weight_kg = excluded.weight_kg;

do $$
begin
  if (select count(*) from public.profiles) <> 1 then
    raise exception 'RLS failed: User A cannot see exactly one own profile';
  end if;

  if (select count(*) from public.meals where name = 'User A meal') <> 1 then
    raise exception 'RLS failed: User A cannot see own meal';
  end if;

  if (select count(*) from public.daily_summaries) <> 1 then
    raise exception 'RLS failed: User A cannot see own daily summary';
  end if;

  if (select count(*) from public.weight_entries) <> 1 then
    raise exception 'RLS failed: User A cannot see own weight entry';
  end if;
end $$;

select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-00000000000b', true);

do $$
begin
  if (select count(*) from public.profiles) <> 0 then
    raise exception 'RLS failed: User B can see User A profile';
  end if;

  if (select count(*) from public.meals where name = 'User A meal') <> 0 then
    raise exception 'RLS failed: User B can see User A meal';
  end if;

  if (select count(*) from public.daily_summaries) <> 0 then
    raise exception 'RLS failed: User B can see User A daily summary';
  end if;

  if (select count(*) from public.weight_entries) <> 0 then
    raise exception 'RLS failed: User B can see User A weight entry';
  end if;
end $$;

insert into public.meals (user_id, name, meal_type, time_text, kcal)
values (auth.uid(), 'User B meal', 'Lunch', '1:00 PM', 450);

do $$
begin
  if (select count(*) from public.meals where name = 'User B meal') <> 1 then
    raise exception 'RLS failed: User B cannot insert own meal';
  end if;

  begin
    insert into public.meals (user_id, name, meal_type, time_text, kcal)
    values ('00000000-0000-4000-8000-00000000000a', 'Bad meal', 'Snack', '3:00 PM', 1);
    raise exception 'RLS failed: User B inserted a row owned by User A';
  exception
    when insufficient_privilege then
      null;
    when check_violation then
      null;
  end;
end $$;

reset role;
set local role anon;
select set_config('request.jwt.claim.sub', '', true);
select set_config('request.jwt.claim.role', 'anon', true);

do $$
declare
  visible_meals bigint;
begin
  begin
    select count(*) into visible_meals from public.meals;
    if visible_meals <> 0 then
      raise exception 'RLS failed: anonymous users can read private meals';
    end if;
  exception
    when insufficient_privilege then
      null;
  end;

  begin
    insert into public.meals (user_id, name, meal_type, time_text, kcal)
    values ('00000000-0000-4000-8000-00000000000a', 'Anonymous meal', 'Snack', '4:00 PM', 1);
    raise exception 'RLS failed: anonymous users can insert private meals';
  exception
    when insufficient_privilege then
      null;
    when check_violation then
      null;
    when not_null_violation then
      null;
  end;
end $$;

rollback;
