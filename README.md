# BirdCherry 🍒

**Birdwatching, together.** Collect the birds you see, watch them land on a world map, and race your flock up the weekly leaderboard.

Flutter app for iOS and Android. Clean, warm-minimalist design (Fraunces + Inter, cherry-on-cream palette), haptics on every interaction, semantic labels throughout for screen readers.

**Brand:** the "cherry-bird" mark (a plump cherry-red bird that doubles as a cherry, with a leaf, stem and a second cherry) is an SVG in [`assets/logo/`](assets/logo/) — one source for the in-app logo (`lib/widgets/logo.dart`) and the launcher icon. Regenerate platform icons after editing the SVG with:
```bash
rsvg-convert -w 1024 -h 1024 assets/logo/birdcherry_icon.svg -o assets/icon/app_icon.png
dart run flutter_launcher_icons
```

## What's inside

A signed-out launch shows a 3-card **onboarding** carousel and a **sign-in** sheet
(email or Apple/Google — demo auth today, Supabase-ready). Once in:

| Tab | What it does |
| --- | --- |
| **Home** | Greeting + streak, **notifications bell** (friend activity + requests), weekly challenge, bird of the day, "seen near you lately", and species your friends have that you don't |
| **Map** | World map of every sighting (yours = cherry star pins, friends = their color). Filter by Everyone / Just me / Friends, and **down to a single friend**. **Tap anywhere on Earth** for the birds reported there |
| **＋ (center)** | Log a sighting: searchable species picker (all ~11,000) → location + field notes → celebration with points, lifer status, and any badges unlocked |
| **Birdpedia** | **Aviary** (default): your collected birds as a draggable forest scene. **Guide**: the full ~11,000-species database, searchable and filterable |
| **Flock** | Social feed + weekly leaderboard (tap anyone to view their profile) + a friends button to add/manage people |
| **Profile** | Level, stats, badge case, life list, a **Friends** manager (add / accept / remove), and **Settings** (data-source status + sign out). Opens for you or any friend |

### Gamification
- **Points by rarity**: Common 10 · Uncommon 25 · Rare 50 · Legendary 100
- **Levels** every 150 points, with names from *Fledgling* to *Living Legend*
- **Streaks** for consecutive days with a sighting
- **12 badges** computed live from your sightings (Early Bird, Globetrotter, Raptor Fan, Big Day…)
- **Weekly leaderboard** and **weekly challenge** (5 species per week)
- **Lifer** callouts when a species is new to your life list

## Data sources

BirdCherry pulls from open bird databases. Everything degrades gracefully: if a
source is unavailable (offline, or no key configured), the app falls back to its
curated demo data, so it always works.

| Content | Source | Key needed? |
| --- | --- | --- |
| Species list (~11,000) | **eBird** taxonomy (Cornell Lab) | No — open endpoint |
| "Birds near you" | **eBird** recent observations | Yes (free) |
| Bird photos | **Wikipedia** REST API, then **iNaturalist** (CC-licensed) | No |
| Bird songs & calls | **xeno-canto** v3 recordings | Yes (free) |
| Map tiles | **CARTO** light basemap on OpenStreetMap | No |

The 31 hand-written "featured" birds (rich descriptions, fun facts, call
mnemonics) are merged with the full eBird world checklist into one catalog: a
featured bird and its eBird twin are matched by scientific name, the curated
content wins, and every other eBird species is searchable and loggable with a
live photo (iNaturalist) and real audio (xeno-canto).

### API keys (both free, optional)

Without keys the app runs on curated data + open endpoints (species list, photos,
map all work). Add keys to unlock live "near you" and real audio:

```bash
flutter run \
  --dart-define=EBIRD_API_KEY=your_ebird_key \
  --dart-define=XENO_CANTO_API_KEY=your_xc_key
```

- **eBird** key → https://ebird.org/api/keygen (sign in to an eBird account)
- **xeno-canto** key → https://xeno-canto.org (account settings, after sign-up)

Keys are read in [`lib/config/app_config.dart`](lib/config/app_config.dart) and
never committed. Recordings show their recordist + Creative-Commons attribution.

## Architecture: built for the Supabase swap

Everything flows through four interfaces in [`lib/data/repositories.dart`](lib/data/repositories.dart):

```
AuthRepository      -> currentUser(), signIn(), signOut()
BirdRepository      -> getBirds()
SightingRepository  -> getSightings(), addSighting()
SocialRepository    -> getCurrentUser(), getFriends(), getFriendRequests(),
                       getSuggestions(), sendRequest(), acceptRequest(),
                       declineRequest(), removeFriend()
```

Screens only ever talk to `AppState` (`provider` ChangeNotifier), which reads through those interfaces. Demo content lives in `Demo*`/`Static*` implementations seeded from [`lib/data/seed.dart`](lib/data/seed.dart). Badges, points, streaks, leaderboards and the activity feed are pure functions of sightings + the social graph, so they keep working unchanged against real data.

### Connecting Supabase (the real backend)

This is the whole checklist to make accounts, friends and notifications real:

The Supabase implementations already exist ([`lib/data/supabase_repositories.dart`](lib/data/supabase_repositories.dart)) and `main.dart` auto-selects them when `SUPABASE_URL` + `SUPABASE_ANON_KEY` are defined. To connect a project:

1. **Create the project** at [supabase.com](https://supabase.com); set a database password.
2. **Fill in** `.env.local` (copy from [`.env.example`](.env.example)): project ref, DB password, and your free eBird / xeno-canto keys. The anon key is fetched for you if you leave it blank.
3. **Run one command:**
   ```bash
   ./scripts/dev.sh
   ```
   It links the project, applies the schema in [`supabase/migrations/`](supabase/migrations/), grabs the anon key, and launches the app on the live backend. (`./scripts/migrate.sh` applies migrations only.)

The schema (`profiles`, `friendships`, `sightings`, all with Row-Level Security) is versioned in `supabase/migrations/`. Email **one-time-code** auth is wired; the onboarding sign-in shows a code field automatically when a backend is configured.

> If a `supabase` command returns 403, the CLI is logged into a different account — run `supabase login` with the account that owns the project.

## Run it

```bash
flutter pub get
flutter run            # demo data, no backend needed
flutter test           # smoke tests + gamification math
./scripts/dev.sh       # live Supabase backend (after .env.local is filled)
```

## Roadmap
- GPS capture + photo upload on the log flow
- Sound ID and photo ID
- Real rarity from eBird abundance / IUCN status (currently derived for eBird-only species)
- (Optional) proxy + cache eBird through a Supabase Edge Function for scale
