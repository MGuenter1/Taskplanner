-- Taskplanner: Datenbankschema für Supabase
-- Einmalig im Supabase-Dashboard unter "SQL Editor" einfügen und ausführen.
-- WICHTIG: In der letzten Zeile die eigene E-Mail-Adresse eintragen (wird Besitzer des Boards).

-- ---------- Tabellen ----------

-- Wer Zugriff hat. Der Besitzer trägt E-Mail-Adressen ein; beim ersten Login
-- wird die Zeile automatisch mit dem Konto verknüpft (user_id).
create table public.members (
  email      text primary key check (email = lower(email)),
  user_id    uuid unique references auth.users(id) on delete set null,
  role       text not null default 'editor' check (role in ('owner', 'editor', 'viewer')),
  nickname   text not null default '' check (char_length(nickname) <= 40),
  invited_at timestamptz not null default now(),
  joined_at  timestamptz
);

create table public.tasks (
  id         uuid primary key default gen_random_uuid(),
  title      text not null check (char_length(title) between 1 and 200),
  due        date,
  prio       smallint not null default 2 check (prio between 1 and 3),
  status     text not null default 'open' check (status in ('open', 'doing', 'done')),
  done_at    timestamptz,
  assignee   uuid references auth.users(id) on delete set null,
  created_by uuid default auth.uid() references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create table public.comments (
  id         uuid primary key default gen_random_uuid(),
  task_id    uuid not null references public.tasks(id) on delete cascade,
  text       text not null check (char_length(text) between 1 and 2000),
  author     uuid default auth.uid() references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

-- ---------- Hilfsfunktionen ----------

-- Rolle des angemeldeten Nutzers (null = kein Zugriff).
create function public.my_role() returns text
language sql stable security definer set search_path = '' as $$
  select role from public.members where user_id = auth.uid()
$$;

-- Beim Login aufgerufen: verknüpft die Einladung (per E-Mail) mit dem Konto.
create function public.join_board() returns text
language plpgsql security definer set search_path = '' as $$
declare r text;
begin
  update public.members
     set user_id = auth.uid(), joined_at = coalesce(joined_at, now())
   where email = lower(auth.jwt() ->> 'email')
     and (user_id is null or user_id = auth.uid())
  returning role into r;
  return r;
end $$;

-- Eigenen Anzeigenamen ändern (ohne die eigene Rolle ändern zu können).
create function public.set_nickname(n text) returns void
language sql security definer set search_path = '' as $$
  update public.members set nickname = left(trim(n), 40) where user_id = auth.uid()
$$;

revoke execute on function public.my_role(), public.join_board(), public.set_nickname(text) from public, anon;
grant  execute on function public.my_role(), public.join_board(), public.set_nickname(text) to authenticated;

-- ---------- Zugriffsregeln (Row Level Security) ----------

alter table public.members  enable row level security;
alter table public.tasks    enable row level security;
alter table public.comments enable row level security;

revoke all on public.members, public.tasks, public.comments from anon;
grant select, insert, update, delete on public.members, public.tasks, public.comments to authenticated;

-- Mitglieder: alle Mitglieder sehen die Liste, nur der Besitzer lädt ein / entfernt.
create policy "members: lesen"    on public.members for select to authenticated using (public.my_role() is not null);
create policy "members: einladen" on public.members for insert to authenticated with check (public.my_role() = 'owner' and role <> 'owner');
create policy "members: ändern"   on public.members for update to authenticated using (public.my_role() = 'owner') with check (public.my_role() = 'owner');
create policy "members: entfernen" on public.members for delete to authenticated using (public.my_role() = 'owner' and user_id is distinct from auth.uid());

-- Aufgaben: alle Mitglieder lesen, Besitzer und Bearbeiter schreiben.
create policy "tasks: lesen"     on public.tasks for select to authenticated using (public.my_role() is not null);
create policy "tasks: anlegen"   on public.tasks for insert to authenticated with check (public.my_role() in ('owner', 'editor'));
create policy "tasks: ändern"    on public.tasks for update to authenticated using (public.my_role() in ('owner', 'editor')) with check (public.my_role() in ('owner', 'editor'));
create policy "tasks: löschen"   on public.tasks for delete to authenticated using (public.my_role() in ('owner', 'editor'));

-- Kommentare: alle Mitglieder lesen, Besitzer und Bearbeiter schreiben (nur unter eigenem Namen).
create policy "comments: lesen"   on public.comments for select to authenticated using (public.my_role() is not null);
create policy "comments: anlegen" on public.comments for insert to authenticated with check (public.my_role() in ('owner', 'editor') and author = auth.uid());
create policy "comments: löschen" on public.comments for delete to authenticated using (public.my_role() in ('owner', 'editor'));

-- ---------- Live-Synchronisation ----------

alter publication supabase_realtime add table public.members, public.tasks, public.comments;

-- ---------- Besitzer festlegen ----------
-- Hier die eigene E-Mail-Adresse eintragen, mit der du dich anmelden wirst:
insert into public.members (email, role) values (lower('DEINE-EMAIL@example.de'), 'owner');
