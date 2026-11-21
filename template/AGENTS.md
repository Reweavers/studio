# Agent Development Notes

This is a Foldkit app. Read [`FOLDKIT.md`](./FOLDKIT.md) before writing any code in this project. It covers the architecture, the APIs, and the conventions the project is built on.

Foldkit owns `FOLDKIT.md` and replaces it whole on upgrade. This file is yours. Anything you want an agent to know about this project goes below, where an upgrade won't touch it.

`FOLDKIT.md` reads the line below to decide whether it has already offered to vendor the Foldkit source. Leave it in place.

subtree_prompted: false

## Project Notes

Domain vocabulary, deployment steps, local conventions that differ from Foldkit's defaults: write them here.

### Layout

- `src/`: the Foldkit app. `src/worker.ts` is the Cloudflare Worker entry: it answers `/api/*` and hands every other request to the app's static assets.
- `alchemy.run.ts`: the Alchemy stack. It declares the Website, its bindings and the state store, which is on disk under `ALCHEMY_DEV=1` and in the Cloudflare account otherwise.
- `test/`: Worker tests. They deploy the stack and call it over HTTP.

### Checks

Run `pnpm check` before you finish. It runs every baseline gate in order, keeps going past a failure, and ends with one `PASS` or `FAIL` line per gate:

1. `install`: a frozen install of the exact-pinned set.
2. `format`: `oxfmt --check`. Run `pnpm format` to fix.
3. `types`: `tsc --noEmit` over `src/`, `test/` and `alchemy.run.ts`.
4. `lint`: Oxlint with Foldkit's plugin over every TypeScript file.
5. `effect`: Effect diagnostics, through Oxlint.
6. `unit`: `vitest run` with V8 coverage in `coverage/`. Coverage is reported, never gated.
7. `worker`: the Worker tests on local workerd with `ALCHEMY_DEV=1`. They need no Cloudflare account.

Warnings fail. The studio owns `scripts/check.sh` and the check configs; don't edit them to make a check pass.

### Dependencies

Every version is exact, and pnpm installs nothing published less than 3 days ago. Add a dependency with `pnpm add <package>@<version>`, which saves it without a range.
