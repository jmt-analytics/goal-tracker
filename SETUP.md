# Goal Tracker — setup guide

Your app has four files:

| File | What it is |
|---|---|
| `index.html` | The whole app (works on phone, tablet and computer) |
| `config.js` | Where you paste your two Supabase values |
| `schema.sql` | Creates your database tables, security rules and a summary view |
| `SETUP.md` | This guide |

**Try it first, no setup needed:** open `index.html` in a browser and choose **Try demo mode**, then use **⋯ → Add sample goals**. Demo data stays only in that browser.

Total setup time for the real thing: about 20 minutes. Everything below is on free plans.

---

## 1. Create the database (Supabase)

1. Go to **supabase.com**, sign up, and click **New project**. Pick a name (e.g. `goal-tracker`), set a strong database password (save it in your password manager — you need it for direct database access later), and choose the region closest to you (e.g. *Central US*).
2. When the project is ready, open **SQL Editor → New query**, paste the full contents of `schema.sql`, and click **Run**. You should see "Success. No rows returned."
3. Check **Table Editor**: you should now have `goals` and `progress_entries` tables.

## 2. Create your login

The app has no public sign-up page — only you get in.

1. **Authentication → Users → Add user → Create new user.** Enter your email and a password, and tick **Auto confirm user**.
2. **Authentication → Sign In / Providers** (may be called *Providers* or *Settings*): turn **off** "Allow new users to sign up". This stops anyone else from creating an account.

## 3. Connect the app to the database

1. In Supabase, click **Connect** (top of the project) or go to **Project Settings → API**.
2. Copy the **Project URL** and the **anon / publishable key** (*not* the `service_role` / secret key — never put that one in the app).
3. Open `config.js` in any text editor and paste them between the quotes:

```js
window.GOAL_TRACKER_CONFIG = {
  supabaseUrl: "https://abcdefghijk.supabase.co",
  supabaseAnonKey: "eyJhbGciOi...or sb_publishable_..."
};
```

The publishable key is designed to be public; the row-level security rules in `schema.sql` are what keep your data private.

## 4. Put the app online (so every device can reach it)

**GitHub Pages (chosen host)**
1. Sign up at **github.com** (free).
2. **+ → New repository**, name it `goal-tracker`, leave it **Public** (free Pages needs a public repository), tick **Add a README file**, and click **Create repository**.
3. **Add file → Upload files**: drag in `index.html` and `config.js` (top level, not in a folder) and click **Commit changes**.
4. **Settings → Pages**: Source **Deploy from a branch**, Branch **main**, folder **/ (root)**, then **Save**.
5. After a minute or two the page shows *Your site is live at* `https://YOUR-USERNAME.github.io/goal-tracker/`.
6. To update later, edit a file with the pencil icon or upload a replacement with the same name. The site refreshes within a minute or two.

Never upload your database password or the `service_role` key. The anon/publishable key in `config.js` is meant to be public.

**Alternative — Netlify Drop:** drag the folder onto **app.netlify.com/drop**.

Then, back in Supabase, go to **Authentication → URL Configuration** and set **Site URL** to your new address. This makes "Forgot password?" emails link back to your app.

**On your phone:** open the address, sign in once (it stays signed in), then use *Share → Add to Home Screen* (iPhone) or *⋮ → Add to Home screen* (Android) to get an app icon.

---

## Using the app

- **Year goals** last all year. **Monthly goals** either *repeat each month* (with a fresh target every month, and an optional month range, e.g. Mar–Oct) or belong to *one specific month*.
- Each goal is either **a number to reach** (log amounts as you go) or **done / not done** (one tap).
- **+1** (next to *Log progress* on number goals) adds 1 instantly, with no form. The exact time is saved with the entry; tap **Undo** in the message at the bottom if it was a mis-tap.
- **Reorder goals** by dragging the ⠿ handle at the top-right of a card (works with touch too) within its section. With a keyboard, focus the handle and use the arrow keys. The order is saved and shows on every device.
- The thin grey tick on a progress bar shows where you'd be at an even pace through the period.
- **⋯ on a goal:** edit, see and delete individual progress entries (with the time each was logged), archive (hide but keep history), or delete.
- **⋯ at the top:** download Excel (Summary, Progress log and Goals sheets) or CSV, copy goals into next year, show archived goals, sign out. The Progress log includes a *Logged at* date-and-time column.
- Use a negative amount to correct a mistake, or delete the entry from the goal's history.

## Testing before January 1

1. Set it up now and use it for the rest of 2026 with real or made-up goals. Try it on each device you'll use.
2. When you're ready to start fresh, either:
   - In the app, go to **2026 → ⋯ → Copy goals to 2027** to carry over the goals you liked (copies start with no progress), then
   - Clear out the test year in **SQL Editor**:
     ```sql
     delete from goals where year = 2026;   -- also removes their progress entries
     ```
3. Or simply add your 2027 goals by moving to 2027 with the year arrow — 2026 test data won't appear there.

## Accessing the database yourself

- **Table Editor** — browse and edit rows like a spreadsheet.
- **SQL Editor** — run any query. Useful ones:
  ```sql
  -- every goal and period with progress and % complete
  select * from goal_period_summary where year = 2027 order by timeframe, title, period_month;

  -- everything logged this month, with the time it was logged
  select g.title, e.entry_date, e.created_at at time zone 'America/Chicago' as logged_at, e.amount, e.note
  from progress_entries e join goals g on g.id = e.goal_id
  where e.entry_date >= date_trunc('month', current_date)
  order by e.created_at;

  -- monthly totals per goal for the year
  select g.title, e.period_month, sum(e.amount) as total
  from progress_entries e join goals g on g.id = e.goal_id
  where e.period_year = 2027 and g.timeframe = 'monthly'
  group by 1, 2 order by 1, 2;
  ```
- **From your own tools** (DBeaver, TablePlus, Excel/Power BI, Python): click **Connect** in Supabase for the Postgres connection string, and use the database password from step 1. Use the *Session pooler* string if your network doesn't support IPv6.
- **Backups:** download the *all years* Excel export now and then. Free Supabase projects don't include automatic backups you can restore yourself.

## Things to know about the free plan

- Supabase pauses free projects after about a week with no activity. Using the app regularly keeps it awake; if it does pause, open the project in the Supabase dashboard and click **Restore** — your data is kept.
- Free limits (500 MB database) are far beyond what a goal tracker will ever use.

## How the data is stored

**goals** — one row per goal: `year`, `title`, `description`, `category`, `timeframe` (`yearly`/`monthly`), `recurrence` (`recurring`/`once`, monthly only), `month` (one-off monthly), `start_month`/`end_month` (recurring), `measure` (`numeric`/`checkbox`), `target`, `unit`, `archived`, `sort_order` (the order you dragged goals into).

**progress_entries** — one row per thing you log: `goal_id`, `period_year`, `period_month` (blank for year goals), `entry_date`, `amount` (for done/not-done goals, `1` means done), `note`, `created_at` (exact date and time it was logged).

**goal_period_summary** (view) — one row per goal per period with totals and % complete; this is the same data as the Summary sheet in the Excel download.
