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

Run `pnpm check` before you finish; `scripts/check.sh` lists the gates it runs. Warnings fail. The Worker gate runs with no Cloudflare credentials, from the environment or `~/.alchemy`, so a resource that needs the real cloud (one marked `Alchemy.remote()`) fails it.

The studio owns `scripts/check.sh` and the check configs, and changes them through upgrade and adoption PRs: make a failing check pass by changing the code.

### Alchemy

Alchemy v2 is a beta. https://alchemy.run/llms.txt indexes its docs; add `.md` to a page's URL to get it as Markdown. Where the docs and the pinned version disagree, `node_modules/alchemy/src` and `node_modules/@alchemy.run/*/src` are the truth.

### Dependencies

Every version is exact, and pnpm installs nothing published less than 3 days ago. Add a dependency with `pnpm add <package>@<version>`, which saves it without a range.
