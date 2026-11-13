# Irish Out West attendee directory

Attendees add a contact card (headshot, LinkedIn, email, phone, website, topics) and search everyone else's.

## Layout

- `index.html` is the whole web app, served by GitHub Pages.
- `supabase/migrations/` holds the database setup. The Supabase GitHub integration applies new files here when they're pushed to `main`.

## Settings

Near the top of the script in `index.html`:

- `EVENT` sets the event name, date, and location shown in the header.
- `SUPABASE_URL` and `SUPABASE_KEY` connect to the database. Use the project URL and the **publishable** (anon) key. Never commit the secret (service_role) key or the database password.

## Making changes

- **Page:** edit `index.html` and commit to `main`. GitHub Pages republishes in a minute or two.
- **Database:** add a new file in `supabase/migrations/` named with a later timestamp, such as `20261201000000_add_column.sql`. Don't edit a migration that has already been applied.

## Moderating

In Supabase, open Table Editor and select `cards`. Set `hidden` to true to hide a card, or delete the row.
