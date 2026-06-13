#!/usr/bin/env bash
# Apply the database schema/migrations to your linked Supabase project
# (without launching the app). Reads .env.local for the project ref + password.
set -euo pipefail
cd "$(dirname "$0")/.."

if [ -f .env.local ]; then set -a; source .env.local; set +a; fi
REF="${SUPABASE_PROJECT_REF:?set SUPABASE_PROJECT_REF in .env.local}"

LINKED="$(cat supabase/.temp/project-ref 2>/dev/null || true)"
if [ "$LINKED" != "$REF" ]; then
  if [ -n "${SUPABASE_DB_PASSWORD:-}" ]; then
    supabase link --project-ref "$REF" -p "$SUPABASE_DB_PASSWORD"
  else
    supabase link --project-ref "$REF"
  fi
fi

if [ -n "${SUPABASE_DB_PASSWORD:-}" ]; then
  supabase db push -p "$SUPABASE_DB_PASSWORD"
else
  supabase db push
fi
echo "✓ Migrations applied to $REF."
