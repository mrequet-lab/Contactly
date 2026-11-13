-- Contactly: the first event is the Irish Out West November Meet Up.
-- Renames the original event; its cards follow automatically (on update cascade).
-- Safe to re-run: does nothing once the rename has happened.

update public.events
set slug = 'irish-out-west-november',
    name = 'Irish Out West November Meet Up'
where slug = 'irish-out-west';
