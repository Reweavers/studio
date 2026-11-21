#!/usr/bin/env bash
#
# Proves that `pnpm check` in template/ catches what each gate is for.
#
# Copies template/ to a scratch directory, runs `pnpm check` on the clean copy
# (which must pass), then makes deliberate faulty changes, at least one per
# gate, and checks that `pnpm check` exits non-zero with that gate, and only
# that gate, marked FAIL in its summary. A fault named `<gate>_<what>` is a
# further fault for that gate.
#
# Usage: scripts/template-faults.sh [fault ...]   (default: every fault)

set -euo pipefail

studio_root="$(cd "$(dirname "$0")/.." && pwd)"
work="$(mktemp -d "${TMPDIR:-/tmp}/template-faults.XXXXXX")"
trap 'rm -rf "$work"' EXIT

faults=(install format types lint effect unit worker worker_remote)

rsync -a --exclude node_modules --exclude .alchemy --exclude coverage \
  "$studio_root/template/" "$work/"
cd "$work"
git init -q
git add -A
git -c user.name=faults -c user.email=faults@localhost commit -qm clean
pnpm install --frozen-lockfile >/dev/null

# Each fault is one small edit that only its own gate should notice.
fault_install() {
  # package.json asks for a version the lockfile doesn't hold.
  sed -i.bak 's/"vite": "[^"]*"/"vite": "8.3.7"/' package.json
}
fault_format() {
  # Double quotes where the formatter wants single ones.
  sed -i.bak "s/from 'effect'/from \"effect\"/" src/main.ts
}
fault_types() {
  # A type error in the Alchemy stack, which tsc must cover.
  printf "\nexport const notANumber: number = 'x'\n" >>alchemy.run.ts
}
fault_lint() {
  # A type assertion, which the scaffold's Oxlint settings forbid.
  printf "\nexport const asserted = 1 as number\n" >>src/worker.ts
}
fault_effect() {
  # A floating Effect: built and never run.
  cat >>alchemy.run.ts <<'EOF'

export const lost = Effect.gen(function* () {
  Effect.log('never logged')
})
EOF
}
fault_unit() {
  # The counter adds two.
  sed -i.bak 's/count => count + 1/count => count + 2/' src/main.ts
}
fault_worker() {
  # The Worker's visit counter adds two.
  sed -i.bak "s/Number(stored ?? '0') + 1/Number(stored ?? '0') + 2/" src/worker.ts
}
fault_worker_remote() {
  # The KV namespace uses the real cloud even in dev, which needs credentials
  # the Worker gate must not have, even with a login saved in ~/.alchemy.
  sed -i.bak "s/Cloudflare.KV.Namespace('Visits')$/&.pipe(Alchemy.remote())/" \
    alchemy.run.ts
}
# Text the log must contain, for faults whose gate could fail for other reasons.
expected_text_worker_remote='CredentialsRequired'

reset() {
  git checkout -q -- .
  git clean -qfd
}

# Runs `pnpm check`, then checks its exit code, that the FAIL lines in its
# summary are exactly the expected gate (or none), and that its output holds
# the expected text, if any.
expect_check() {
  local label="$1" expected="$2" text="${3:-}" log="$work/.check-$1.log" status=0
  pnpm check >"$log" 2>&1 || status=$?
  local failed
  failed="$(sed -n 's/^FAIL  //p' "$log" | tr '\n' ' ' | sed 's/ $//')"
  if [[ -n "$text" ]] && ! grep -q "$text" "$log"; then
    echo "WRONG $label: the output doesn't contain '$text'"
  elif [[ -z "$expected" && $status -eq 0 && -z "$failed" ]] ||
    [[ -n "$expected" && $status -ne 0 && "$failed" == "$expected" ]]; then
    echo "ok    $label"
    return 0
  fi
  echo "WRONG $label: exit $status, failed gates: [${failed}], expected: [${expected}]"
  sed 's/^/      /' "$log" | tail -40
  return 1
}

selected=("$@")
[[ ${#selected[@]} -eq 0 ]] && selected=("${faults[@]}")

result=0
expect_check clean "" || result=1
for fault in "${selected[@]}"; do
  reset
  "fault_$fault"
  if git diff --quiet; then
    echo "WRONG $fault: the fault changed nothing"
    result=1
    continue
  fi
  text_var="expected_text_$fault"
  expect_check "$fault" "${fault%%_*}" "${!text_var:-}" || result=1
done
reset

exit $result
