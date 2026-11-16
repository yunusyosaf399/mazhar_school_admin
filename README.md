# Mazhar School — Supabase Keep-Alive

This repository's active branch contains only a scheduled GitHub Actions workflow for lightweight Supabase API activity. The application source code has been removed from the active branch.

**Important:** Removing files from the active branch does **not** remove their contents from previous Git commits. Review or rewrite the repository history before changing the repository to public.

## Schedule

The workflow runs every day at **01:17, 09:17 and 17:17 UTC** (three requests daily), supports manual runs, and runs on workflow-file updates for verification.

## Configuration

Keep these existing values in **Settings → Secrets and variables → Actions**:

- `SUPABASE_URL` — your Supabase project API URL.
- `SUPABASE_SERVICE_KEY` — your existing service-role key, stored only as a GitHub Actions secret. Never paste this key into code, commit history, issues or logs.

The workflow performs an HTTP GET to the `results` table with a one-row limit. It fails for missing secrets, HTTP errors, network failures and an unavailable Supabase project; it does not print database records.

A successful API request is not a guarantee that Supabase will never pause a Free Plan project. If the project is already paused, restore it in the Supabase dashboard first.
