#!/usr/bin/env bash
#
# The baseline checks. Studio-owned: a project adds its own checks elsewhere
# and never changes this file.
#
# Runs every gate in order, keeps going past a failure, prints one PASS or
# FAIL line per gate, and exits non-zero if any gate failed.

set -uo pipefail

cd "$(dirname "$0")/.."

# name | command. Warnings fail every gate that can emit them.
gates=(
  "install|pnpm install --frozen-lockfile"
  "format|pnpm exec oxfmt --check"
  "types|pnpm exec tsc --noEmit"
  "lint|pnpm exec oxlint --deny-warnings ."
  "effect|pnpm exec effect-tsgo patch --no-typescript --oxlint && pnpm exec oxlint --config .oxlintrc.effect.json --deny-warnings ."
  "unit|pnpm exec vitest run --coverage"
  "worker|env -u CLOUDFLARE_API_TOKEN -u CLOUDFLARE_API_KEY -u CLOUDFLARE_EMAIL -u CLOUDFLARE_ACCOUNT_ID ALCHEMY_DEV=1 pnpm exec vitest run --config vitest.worker.config.ts"
)

summary=()
failed=0

for gate in "${gates[@]}"; do
  name="${gate%%|*}"
  command="${gate#*|}"
  echo
  echo "── $name: $command"
  if bash -c "$command"; then
    summary+=("PASS  $name")
  else
    summary+=("FAIL  $name")
    failed=1
  fi
done

echo
printf '%s\n' "${summary[@]}"
exit $failed
