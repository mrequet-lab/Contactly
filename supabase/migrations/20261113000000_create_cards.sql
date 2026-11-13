-- Applied automatically by the Supabase GitHub integration on push to main.
-- Safe to re-run: it won't duplicate or delete anything if you already ran setup.sql by hand.


create table if not exists public.cards (
  id          uuid primary key default gen_random_uuid(),
  name        text not null check (char_length(name) between 1 and 100),
  company     text check (char_length(company) <= 100),
  bio         text check (char_length(bio) <= 200),
  email       text check (char_length(email) <= 200),
  phone       text check (char_length(phone) <= 40),
  linkedin    text not null check (linkedin ~* '^https?://' and char_length(linkedin) <= 300),
  website     text check (website ~* '^https?://' and char_length(website) <= 300),
  tags        text[] not null default '{}'
              check (cardinality(tags) <= 5 and char_length(array_to_string(tags, ',')) <= 200),
  photo       text check (photo ~ '^data:image/jpeg;base64,[A-Za-z0-9+/=]+$' and char_length(photo) <= 150000),
  hidden      boolean not null default false,   -- set to true in the Table Editor to hide a card
  edit_token  uuid not null default gen_random_uuid(),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

alter table public.cards enable row level security;
revoke all on table public.cards from anon, authenticated;

-- Read: every visible card, without private columns
create or replace function public.list_cards()
returns table (id uuid, name text, company text, bio text, email text, phone text,
               linkedin text, website text, tags text[], photo text, created_at timestamptz)
language sql stable security definer set search_path = public
as $$
  select c.id, c.name, c.company, c.bio, c.email, c.phone, c.linkedin, c.website,
         c.tags, c.photo, c.created_at
  from public.cards c
  where not c.hidden
  order by lower(c.name);
$$;

-- Create: returns the new card's id and its private edit token
create or replace function public.create_card(
  p_name text, p_company text, p_bio text, p_email text, p_phone text,
  p_linkedin text, p_website text, p_tags text[], p_photo text
) returns json
language plpgsql security definer set search_path = public
as $$
declare r public.cards;
begin
  insert into public.cards (name, company, bio, email, phone, linkedin, website, tags, photo)
  values (trim(p_name), nullif(trim(p_company), ''), nullif(trim(p_bio), ''),
          nullif(trim(p_email), ''), nullif(trim(p_phone), ''), trim(p_linkedin),
          nullif(trim(p_website), ''), coalesce(p_tags, '{}'), nullif(p_photo, ''))
  returning * into r;
  return json_build_object('id', r.id, 'edit_token', r.edit_token);
end $$;

-- Edit: only works with the matching edit token
create or replace function public.update_card(
  p_id uuid, p_token uuid,
  p_name text, p_company text, p_bio text, p_email text, p_phone text,
  p_linkedin text, p_website text, p_tags text[], p_photo text
) returns boolean
language plpgsql security definer set search_path = public
as $$
begin
  update public.cards set
    name = trim(p_name), company = nullif(trim(p_company), ''), bio = nullif(trim(p_bio), ''),
    email = nullif(trim(p_email), ''), phone = nullif(trim(p_phone), ''),
    linkedin = trim(p_linkedin), website = nullif(trim(p_website), ''),
    tags = coalesce(p_tags, '{}'), photo = nullif(p_photo, ''), updated_at = now()
  where id = p_id and edit_token = p_token;
  return found;
end $$;

-- Delete: only works with the matching edit token
create or replace function public.delete_card(p_id uuid, p_token uuid)
returns boolean
language plpgsql security definer set search_path = public
as $$
begin
  delete from public.cards where id = p_id and edit_token = p_token;
  return found;
end $$;

revoke all on function public.list_cards() from public;
revoke all on function public.create_card(text, text, text, text, text, text, text, text[], text) from public;
revoke all on function public.update_card(uuid, uuid, text, text, text, text, text, text, text, text[], text) from public;
revoke all on function public.delete_card(uuid, uuid) from public;

grant execute on function public.list_cards() to anon, authenticated;
grant execute on function public.create_card(text, text, text, text, text, text, text, text[], text) to anon, authenticated;
grant execute on function public.update_card(uuid, uuid, text, text, text, text, text, text, text, text[], text) to anon, authenticated;
grant execute on function public.delete_card(uuid, uuid) to anon, authenticated;
