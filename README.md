# Goal Tracker

A personal goal tracker that runs in the browser on any device. Year-long and monthly goals, progress logging, pace tracking, and Excel/CSV export, backed by a private Supabase (PostgreSQL) database.

## Features

- **Year goals and monthly goals.** Monthly goals can repeat every month (optionally for a range of months, e.g. March–October) or belong to one specific month.
- **Two kinds of goals.** A number to reach (e.g. 24 books, 600 miles), logged in amounts with a date and note, or a simple done / not done.
- **Pace tracking.** Each progress bar shows where you'd be at an even pace through the period, with an "on pace" / "behind pace" status.
- **Month-by-month view.** Repeating monthly goals show a 12-month strip of results.
- **Full editing.** Add, edit, archive or delete goals, and review or delete individual progress entries.
- **Export.** Excel workbook (Summary, Progress log and Goals sheets) for one year or all years, plus CSV summary and log files.
- **New year rollover.** Copy goals into the next year with progress reset.
- **Demo mode.** Try the app without a database; data stays in that browser only.
- Works on phones, tablets and computers, in light and dark mode.

## How it works

| File | Purpose |
|---|---|
| `index.html` | The entire app: plain HTML, CSS and JavaScript, no build step |
| `config.js` | Supabase project URL and public (anon) key |
| `schema.sql` | Database tables, row-level security rules and a summary view |
| `SETUP.md` | Step-by-step setup guide |

The app is a static page hosted on GitHub Pages. It talks directly to Supabase using [supabase-js](https://github.com/supabase/supabase-js). Sign-in uses Supabase Auth with email and password, and public sign-ups are disabled.

## Security

The key in `config.js` is Supabase's public **anon / publishable** key, which is designed to be visible in web pages. Data is protected by PostgreSQL row-level security: each row can only be read or changed by the signed-in user who owns it.

Never commit the database password or the `service_role` (secret) key to this repository.

## Setup

See [SETUP.md](SETUP.md). In short:

1. Create a Supabase project and run `schema.sql` in the SQL Editor.
2. Create a user under **Authentication → Users** and turn off new sign-ups.
3. Put the project URL and anon key in `config.js`.
4. Enable GitHub Pages: **Settings → Pages → Deploy from a branch → main → / (root)**.
5. Set Supabase's **Authentication → URL Configuration → Site URL** to the Pages address.

To try it locally without a database, open `index.html` and choose **Try demo mode**. If `config.js` is filled in, add `?demo=1` to the address instead.

## Data model

**`goals`**: one row per goal: year, title, notes, category, timeframe (`yearly` / `monthly`), recurrence (`recurring` / `once`), month or month range, measure (`numeric` / `checkbox`), target, unit, archived flag.

**`progress_entries`**: one row per logged entry: goal, period year and month (blank for year goals), date, amount, note. For done / not done goals, an entry of `1` means done.

**`goal_period_summary`** (view): one row per goal per period with total progress and percent complete.

```sql
select * from goal_period_summary where year = 2027 order by timeframe, title, period_month;
```

## License

Personal project; no license granted.
