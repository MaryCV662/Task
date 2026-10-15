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
