#!/usr/bin/env bash
# One command to connect everything and run BirdCherry against your Supabase
# project: links the project, applies migrations, grabs the anon key, and
# launches the app with every key wired in.
#
#   1. Fill in .env.local  (copy from .env.example)
#   2. ./scripts/dev.sh
#
# Re-runnable: `supabase db push` only applies new migrations.
set -euo pipefail
cd "$(dirname "$0")/.."

# --- load local config ---
if [ -f .env.local ]; then
  set -a; # shellcheck disable=SC1091
  source .env.local; set +a
else
  echo "✗ No .env.local found. Copy .env.example → .env.local and fill it in."
  exit 1
fi

REF="${SUPABASE_PROJECT_REF:?set SUPABASE_PROJECT_REF in .env.local}"
URL="${SUPABASE_URL:-https://${REF}.supabase.co}"

# --- 1. make sure the CLI can see this project ---
if ! supabase projects api-keys --project-ref "$REF" >/dev/null 2>&1; then
  echo "✗ The Supabase CLI can't access project $REF (likely a 403)."
  echo "  You're probably logged into a different account. Run:"
  echo "      supabase login"
  echo "  using the account that owns this project, then re-run this script."
  exit 1
fi

# --- 2. link (only if not already linked to this ref) ---
LINKED="$(cat supabase/.temp/project-ref 2>/dev/null || true)"
if [ "$LINKED" != "$REF" ]; then
  echo "→ Linking Supabase project $REF…"
  if [ -n "${SUPABASE_DB_PASSWORD:-}" ]; then
    supabase link --project-ref "$REF" -p "$SUPABASE_DB_PASSWORD"
  else
    supabase link --project-ref "$REF"
  fi
fi

# --- 3. apply migrations ---
echo "→ Applying migrations (supabase db push)…"
if [ -n "${SUPABASE_DB_PASSWORD:-}" ]; then
  supabase db push -p "$SUPABASE_DB_PASSWORD"
else
  supabase db push
fi

# --- 4. anon key: use the one in .env.local, else fetch it ---
if [ -z "${SUPABASE_ANON_KEY:-}" ]; then
  echo "→ Fetching anon key…"
  SUPABASE_ANON_KEY="$(supabase projects api-keys --project-ref "$REF" -o json \
    | jq -r '[.[] | select(.name=="anon" or .name=="publishable")][0].api_key // .[0].api_key')"
fi
if [ -z "${SUPABASE_ANON_KEY:-}" ] || [ "$SUPABASE_ANON_KEY" = "null" ]; then
  echo "✗ Couldn't determine the anon key. Paste it into .env.local (SUPABASE_ANON_KEY)."
  exit 1
fi

# --- 5. run the app with everything wired ---
echo "→ Launching BirdCherry on the connected backend…"
flutter run \
  --dart-define=SUPABASE_URL="$URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=EBIRD_API_KEY="${EBIRD_API_KEY:-}" \
  --dart-define=XENO_CANTO_API_KEY="${XENO_CANTO_API_KEY:-}" \
  "$@"
