-- Multi-event support: one database and one site serve every event.
-- Each event is a row in public.events; every card belongs to one event.
-- Existing cards are moved into the Irish Out West event.

create table if not exists public.events (
  slug        text primary key
              check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$' and char_length(slug) <= 60),
  name        text not null check (char_length(name) between 1 and 120),
  details     text check (char_length(details) <= 200),   -- date and location shown under the name
  is_open     boolean not null default true,              -- false stops new cards; the directory stays visible
  created_at  timestamptz not null default now()
);
alter table public.events enable row level security;
revoke all on table public.events from anon, authenticated;

insert into public.events (slug, name, details)
values ('irish-out-west', 'Irish Out West', 'November 12th, 2026, Irish Times - San Francisco')
on conflict (slug) do nothing;

-- Tie cards to events (deleting an event deletes its cards)
alter table public.cards add column if not exists event_slug text;
update public.cards set event_slug = 'irish-out-west' where event_slug is null;
alter table public.cards alter column event_slug set not null;
do $$ begin
  alter table public.cards add constraint cards_event_slug_fkey
    foreign key (event_slug) references public.events (slug) on update cascade on delete cascade;
exception when duplicate_object then null;
end $$;
create index if not exists cards_event_slug_idx on public.cards (event_slug);

-- Replace the single-event functions
drop function if exists public.list_cards();
drop function if exists public.create_card(text, text, text, text, text, text, text, text[], text);

create or replace function public.get_event(p_slug text)
returns json
language sql stable security definer set search_path = public
as $$
  select json_build_object('slug', e.slug, 'name', e.name, 'details', e.details, 'is_open', e.is_open)
  from public.events e
  where e.slug = lower(trim(p_slug));
$$;

create or replace function public.list_cards(p_event text)
returns table (id uuid, name text, company text, bio text, email text, phone text,
               linkedin text, website text, tags text[], photo text, created_at timestamptz)
language sql stable security definer set search_path = public
as $$
  select c.id, c.name, c.company, c.bio, c.email, c.phone, c.linkedin, c.website,
         c.tags, c.photo, c.created_at
  from public.cards c
  where c.event_slug = lower(trim(p_event)) and not c.hidden
  order by lower(c.name);
$$;

create or replace function public.create_card(
  p_event text,
  p_name text, p_company text, p_bio text, p_email text, p_phone text,
  p_linkedin text, p_website text, p_tags text[], p_photo text
) returns json
language plpgsql security definer set search_path = public
as $$
declare
  v_event text := lower(trim(p_event));
  r public.cards;
begin
  if not exists (select 1 from public.events e where e.slug = v_event and e.is_open) then
    raise exception 'This event is not accepting new cards.';
  end if;
  insert into public.cards (event_slug, name, company, bio, email, phone, linkedin, website, tags, photo)
  values (v_event, trim(p_name), nullif(trim(p_company), ''), nullif(trim(p_bio), ''),
          nullif(trim(p_email), ''), nullif(trim(p_phone), ''), trim(p_linkedin),
          nullif(trim(p_website), ''), coalesce(p_tags, '{}'), nullif(p_photo, ''))
  returning * into r;
  return json_build_object('id', r.id, 'edit_token', r.edit_token);
end $$;

-- update_card and delete_card are unchanged: they work by card id and edit token.

revoke all on function public.get_event(text) from public;
revoke all on function public.list_cards(text) from public;
revoke all on function public.create_card(text, text, text, text, text, text, text, text, text[], text) from public;

grant execute on function public.get_event(text) to anon, authenticated;
grant execute on function public.list_cards(text) to anon, authenticated;
grant execute on function public.create_card(text, text, text, text, text, text, text, text, text[], text) to anon, authenticated;
