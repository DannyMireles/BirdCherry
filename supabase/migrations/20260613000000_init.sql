-- BirdCherry initial schema.
-- Reference data (the ~11k species, photos, audio) comes live from eBird /
-- iNaturalist / xeno-canto, so we only store user-generated data here:
-- profiles, sightings, and the friend graph. Row-Level Security throughout.

-- ---------------------------------------------------------------------------
-- profiles: one row per auth user, created automatically on sign-up.
-- ---------------------------------------------------------------------------
create table public.profiles (
  id         uuid primary key references auth.users (id) on delete cascade,
  name       text not null default 'New birder',
  handle     text unique,
  color      text not null default '#C9473F',     -- avatar tint (hex)
  home       text,                                 -- e.g. "Austin, TX"
  home_lat   double precision,
  home_lng   double precision,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

-- Any signed-in user can read profiles (needed for friends + leaderboard);
-- you can only create/update your own.
create policy "profiles are readable by authenticated users"
  on public.profiles for select
  to authenticated using (true);

create policy "users insert their own profile"
  on public.profiles for insert
  to authenticated with check (id = auth.uid());

create policy "users update their own profile"
  on public.profiles for update
  to authenticated using (id = auth.uid());

-- Auto-create a profile when a new auth user signs up.
create function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, name, handle)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'name', split_part(new.email, '@', 1)),
    null
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- friendships: one row per direction. status = pending (a request) or
-- accepted (mutual friends). requester sends, addressee accepts.
-- ---------------------------------------------------------------------------
create type public.friend_status as enum ('pending', 'accepted');

create table public.friendships (
  requester  uuid not null references public.profiles (id) on delete cascade,
  addressee  uuid not null references public.profiles (id) on delete cascade,
  status     public.friend_status not null default 'pending',
  created_at timestamptz not null default now(),
  primary key (requester, addressee),
  check (requester <> addressee)
);

create index friendships_addressee_idx on public.friendships (addressee, status);

alter table public.friendships enable row level security;

-- Helper: are two users accepted friends (in either direction)?
create function public.are_friends(a uuid, b uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.friendships f
    where f.status = 'accepted'
      and ((f.requester = a and f.addressee = b)
        or (f.requester = b and f.addressee = a))
  );
$$;

create policy "see friendships you are part of"
  on public.friendships for select
  to authenticated using (requester = auth.uid() or addressee = auth.uid());

create policy "send your own friend requests"
  on public.friendships for insert
  to authenticated with check (requester = auth.uid());

-- Accept/decline: the addressee can update the row's status.
create policy "addressee responds to requests"
  on public.friendships for update
  to authenticated using (addressee = auth.uid());

-- Either party can remove the friendship.
create policy "either party removes a friendship"
  on public.friendships for delete
  to authenticated using (requester = auth.uid() or addressee = auth.uid());

-- ---------------------------------------------------------------------------
-- sightings: a logged observation. bird_id is the eBird species code (or a
-- curated id), resolved against the live catalog on the client.
-- ---------------------------------------------------------------------------
create table public.sightings (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles (id) on delete cascade,
  bird_id    text not null,
  seen_at    timestamptz not null default now(),
  lat        double precision,
  lng        double precision,
  place      text,
  note       text,
  created_at timestamptz not null default now()
);

create index sightings_user_idx on public.sightings (user_id);
create index sightings_seen_at_idx on public.sightings (seen_at desc);

alter table public.sightings enable row level security;

-- You can see your own sightings and those of your accepted friends.
create policy "see your own and friends' sightings"
  on public.sightings for select
  to authenticated using (
    user_id = auth.uid() or public.are_friends(auth.uid(), user_id)
  );

create policy "log your own sightings"
  on public.sightings for insert
  to authenticated with check (user_id = auth.uid());

create policy "edit your own sightings"
  on public.sightings for update
  to authenticated using (user_id = auth.uid());

create policy "delete your own sightings"
  on public.sightings for delete
  to authenticated using (user_id = auth.uid());
