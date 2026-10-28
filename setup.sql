-- Task Tracker: database setup
-- Run this once in the Supabase SQL Editor (Project > SQL Editor > New query > Run).
-- Safe to run again.

create extension if not exists pgcrypto with schema extensions;

create table if not exists tasks (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  notes text not null default '',
  status text not null default 'todo' check (status in ('todo','doing','done')),
  priority text not null default 'normal' check (priority in ('low','normal','high')),
  due date,
  project text not null default '',
  created_at timestamptz not null default now(),
  completed_at timestamptz
);

-- Same approach as the other apps: RLS on, with an open policy so the app's
-- publishable key can read and write. Anyone with the app link can use it.
alter table tasks enable row level security;

drop policy if exists "allow all tasks" on tasks;
create policy "allow all tasks" on tasks for all using (true) with check (true);

-- Live updates between devices.
do $$
begin
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'tasks') then
    alter publication supabase_realtime add table tasks;
  end if;
end $$;

-- ---------- Month end ----------
-- One row per client; clients carry over to every month.
create table if not exists close_clients (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz not null default now()
);

-- One row per client per month: the planned work date, notes, and, once ticked, when it was closed.
create table if not exists close_done (
  client_id uuid not null references close_clients(id) on delete cascade,
  month text not null check (month ~ '^\d{4}-\d{2}$'),
  work_date date,
  done_at timestamptz,
  primary key (client_id, month)
);

-- Upgrades tables made by earlier versions of this script.
alter table close_clients add column if not exists worked_with text not null default '';
alter table close_done add column if not exists work_date date;
alter table close_done alter column done_at drop not null;
alter table close_done alter column done_at drop default;
alter table close_done add column if not exists notes text not null default '';

alter table close_clients enable row level security;
alter table close_done enable row level security;

drop policy if exists "allow all close_clients" on close_clients;
create policy "allow all close_clients" on close_clients for all using (true) with check (true);

drop policy if exists "allow all close_done" on close_done;
create policy "allow all close_done" on close_done for all using (true) with check (true);

do $$
begin
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'close_clients') then
    alter publication supabase_realtime add table close_clients;
  end if;
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'close_done') then
    alter publication supabase_realtime add table close_done;
  end if;
end $$;

notify pgrst, 'reload schema';

-- ---------- Weekly tasks ----------
-- Clients down the side, recurring tasks across the top; each cell is the date last done, or 'na'.
create table if not exists weekly_clients (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  sort int not null default 0,
  created_at timestamptz not null default now()
);
create table if not exists weekly_columns (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  sort int not null default 0,
  created_at timestamptz not null default now()
);
create table if not exists weekly_cells (
  client_id uuid not null references weekly_clients(id) on delete cascade,
  column_id uuid not null references weekly_columns(id) on delete cascade,
  value text not null check (value = 'na' or value ~ '^\d{4}-\d{2}-\d{2}$'),
  updated_at timestamptz not null default now(),
  primary key (client_id, column_id)
);

alter table weekly_clients enable row level security;
alter table weekly_columns enable row level security;
alter table weekly_cells enable row level security;
drop policy if exists "allow all weekly_clients" on weekly_clients;
create policy "allow all weekly_clients" on weekly_clients for all using (true) with check (true);
drop policy if exists "allow all weekly_columns" on weekly_columns;
create policy "allow all weekly_columns" on weekly_columns for all using (true) with check (true);
drop policy if exists "allow all weekly_cells" on weekly_cells;
create policy "allow all weekly_cells" on weekly_cells for all using (true) with check (true);

do $$
declare t text;
begin
  foreach t in array array['weekly_clients','weekly_columns','weekly_cells'] loop
    if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = t) then
      execute format('alter publication supabase_realtime add table %I', t);
    end if;
  end loop;
end $$;

notify pgrst, 'reload schema';
