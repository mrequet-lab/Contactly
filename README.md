# Contactly

One site and one database serve every event. Attendees add a contact card (headshot, LinkedIn, email, phone, website, topics) and search everyone else's at the same event.

Each event has its own link:

```
https://<your-username>.github.io/contactly/?event=<event-slug>
```

## Add a new event

In Supabase, open Table Editor, select `events`, and insert a row:

| Column    | What to enter |
| --------- | ------------- |
| `slug`    | The link name: lowercase letters, numbers, and hyphens, such as `spring-mixer-2027` |
| `name`    | The title shown at the top, such as `Spring Mixer` |
| `details` | Date and location shown under the title |
| `is_open` | Leave as `true` |

Share the link ending in `?event=<slug>`. That's all it takes, with no code changes.

## Close or remove an event

- Set `is_open` to `false` to stop new cards. The directory stays visible, and people can still edit or remove their own card.
- Deleting the event's row deletes the event **and all of its cards**. Export them first if you want a copy.

## Moderate and export cards

In Table Editor, open `cards` and filter by `event_slug`. Set `hidden` to true to hide a card, delete a row to remove it, or export the filtered rows to CSV.

## Settings in index.html

- `SUPABASE_URL` and `SUPABASE_KEY` connect to the database. Use the **publishable** (anon) key. Never commit the secret (service_role) key or the database password.
- `DEFAULT_EVENT` is empty, so the plain link with no `?event=` shows the Contactly home page. Put an event's slug there to open that event instead.

## Changing things

- **Page:** edit `index.html` and commit to `main`. GitHub Pages republishes in a minute or two.
- **Database:** add a new file in `supabase/migrations/` with a later timestamp in its name. Don't edit a migration that has already been applied.
