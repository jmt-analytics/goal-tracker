-- =====================================================================
-- Goal Tracker — database schema for Supabase (PostgreSQL)
-- Run this once in Supabase: SQL Editor -> New query -> paste -> Run.
-- It is safe to re-run: it only creates what doesn't exist yet.
-- =====================================================================

-- ---------------------------------------------------------------------
-- GOALS
-- One row per goal.
--   timeframe = 'yearly'  -> one goal for the whole year
--   timeframe = 'monthly' -> recurrence 'recurring' (repeats every month
--                            from start_month to end_month)
--                            or 'once' (belongs to a single month)
--   measure   = 'numeric'  -> progress is a number toward `target`
--   measure   = 'checkbox' -> progress is done / not done
-- ---------------------------------------------------------------------
create table if not exists public.goals (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null default auth.uid() references auth.users(id) on delete cascade,
  year         int  not null check (year between 2000 and 2100),
  title        text not null check (length(title) between 1 and 200),
  description  text,
  category     text,
  timeframe    text not null check (timeframe in ('yearly','monthly')),
  recurrence   text check (recurrence in ('once','recurring')),
  month        int  check (month between 1 and 12),          -- for monthly 'once'
  start_month  int  check (start_month between 1 and 12),    -- for monthly 'recurring'
  end_month    int  check (end_month between 1 and 12),      -- for monthly 'recurring'
  measure      text not null check (measure in ('numeric','checkbox')),
  target       numeric check (target is null or target > 0),
  unit         text,
  archived     boolean not null default false,
  sort_order   int not null default 0,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),

  constraint goals_timeframe_shape check (
    (timeframe = 'yearly'  and recurrence is null and month is null)
    or (timeframe = 'monthly' and recurrence = 'once' and month is not null)
    or (timeframe = 'monthly' and recurrence = 'recurring'
        and start_month is not null and end_month is not null and start_month <= end_month)
  ),
  constraint goals_measure_shape check (
    (measure = 'numeric'  and target is not null)
    or (measure = 'checkbox')
  )
);

create index if not exists goals_user_year_idx on public.goals (user_id, year);

-- ---------------------------------------------------------------------
-- PROGRESS ENTRIES
-- Every bit of progress you log is one row.
--   period_month is NULL for yearly goals, 1-12 for monthly goals.
--   For checkbox goals, an entry with amount = 1 means "done" for that period.
-- Deleting a goal deletes its entries.
-- ---------------------------------------------------------------------
create table if not exists public.progress_entries (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null default auth.uid() references auth.users(id) on delete cascade,
  goal_id       uuid not null references public.goals(id) on delete cascade,
  period_year   int  not null,
  period_month  int  check (period_month between 1 and 12),
  entry_date    date not null default current_date,
  amount        numeric not null,
  note          text,
  created_at    timestamptz not null default now()
);

create index if not exists entries_goal_idx on public.progress_entries (goal_id, period_year, period_month);
create index if not exists entries_user_idx on public.progress_entries (user_id, period_year);

-- Keep updated_at current
create or replace function public.touch_updated_at() returns trigger
language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

drop trigger if exists goals_touch on public.goals;
create trigger goals_touch before update on public.goals
  for each row execute function public.touch_updated_at();

-- ---------------------------------------------------------------------
-- ROW-LEVEL SECURITY
-- Only the signed-in owner can see or change their own rows.
-- (You, in the Supabase dashboard / SQL editor, can always see everything.)
-- ---------------------------------------------------------------------
alter table public.goals            enable row level security;
alter table public.progress_entries enable row level security;

drop policy if exists "own goals" on public.goals;
create policy "own goals" on public.goals
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "own entries" on public.progress_entries;
create policy "own entries" on public.progress_entries
  for all using (user_id = auth.uid()) with check (
    user_id = auth.uid()
    and exists (select 1 from public.goals g where g.id = goal_id and g.user_id = auth.uid())
  );

-- ---------------------------------------------------------------------
-- HANDY VIEW for querying in the SQL editor:
-- one row per goal per period, with total progress and % complete.
--   select * from goal_period_summary where year = 2027 order by title, period_month;
-- ---------------------------------------------------------------------
create or replace view public.goal_period_summary
with (security_invoker = true) as
with periods as (
  select g.*, null::int as period_month
  from public.goals g where g.timeframe = 'yearly'
  union all
  select g.*, g.month
  from public.goals g where g.timeframe = 'monthly' and g.recurrence = 'once'
  union all
  select g.*, m
  from public.goals g, generate_series(g.start_month, g.end_month) as m
  where g.timeframe = 'monthly' and g.recurrence = 'recurring'
)
select
  p.id as goal_id, p.year, p.title, p.category, p.timeframe, p.recurrence,
  p.period_month, p.measure, p.target, p.unit, p.archived,
  coalesce(sum(e.amount), 0) as progress,
  case
    when p.measure = 'checkbox' then case when coalesce(sum(e.amount),0) > 0 then 100 else 0 end
    else round(least(coalesce(sum(e.amount),0) / p.target * 100, 100), 1)
  end as pct_complete,
  count(e.id) as entry_count,
  max(e.entry_date) as last_entry
from periods p
left join public.progress_entries e
  on e.goal_id = p.id
 and e.period_year = p.year
 and e.period_month is not distinct from p.period_month
group by p.id, p.year, p.title, p.category, p.timeframe, p.recurrence,
         p.period_month, p.measure, p.target, p.unit, p.archived;
