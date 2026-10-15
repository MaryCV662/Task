# Task Tracker

A shared task tracker in one HTML file: no build step, no framework. Tasks sync live across devices through Supabase, and the app can be installed on a phone or desktop.

## Features

- Quick add with due date, priority and project (press **N** to jump to it)
- **List view** grouped into Overdue, Today, Next 7 days, Later and No due date
- **Board view** with To do / In progress / Done columns (drag cards, or use the arrows on a phone)
- Search and filter by project or priority
- Counts for open, due today, overdue and done this week
- Undo after completing or deleting a task
- Live sync between devices, with a local-only fallback until the database is set up

## Setup

1. In Supabase, open **SQL Editor → New query**, paste [setup.sql](setup.sql) and click **Run**.
2. Reload the app. The status under the title should read "Shared · synced".

Until step 1 is done, tasks are saved in that browser only.

## Deploy

Static files, so any host works. With Vercel:

```bash
vercel link --yes --project task-tracker
vercel deploy --yes --prod
```
