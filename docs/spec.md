# Software studio: the design

Assembled 2026-11-20 from the resolved tickets of the *Software studio setup* map. This document decides nothing: every statement comes from a planning ticket, and the ticket holds the reasons and the rejected alternatives. The planning tickets and their map stay in the unpublished planning repo, so they are named here in italics rather than linked. Where a ticket's dated comment is later than its answer, the comment wins.

- **Status.** Finished by the software-studio skill's test, and confirmed by the human on 2026-11-20. Nothing is built. Apart from the six baseline gates, which ran on a laptop, nothing here was tested on a live account.
- **Words.** Task, trigger, run, runner and the service names are defined in [the software-studio skill](../.claude/skills/software-studio/SKILL.md). Every other term in bold on first use is defined in [`GLOSSARY.md`](../GLOSSARY.md). "The human" is the one person the studio serves.
- **Who it is for.** One person, about half-time, building small **projects** for one or a few users each, on CAFE (Cloudflare, Alchemy, Foldkit, Effect). Every repo is public and no outside contributors are expected.
- **Handoff.** Building the studio follows the [Rollout](#rollout) section, step by step.

## Services

| Slot | Product | How it is used |
| --- | --- | --- |
| Ticket tracker | GitHub Issues | Each project's issues, plus the studio repo's own issues for the loose-ends issue and model-pin notices. Labels are the queues. |
| Ticket source | The human, and the model-change notice | See [Ticket sources](#ticket-sources). A feedback button is out of scope. |
| Git host | GitHub | A free organisation owns every repo. Repos are public with "Collaborators only" on issues and PRs. |
| Orchestrator | GitHub Actions | Each task's wiring is a workflow file in a repo. Nothing lives in a vendor's account. |
| Runner | GitHub-hosted standard runners | Free on public repos, for every task. |
| Observability platform | None, deliberately | Actions run pages show what happened inside a run. The loose-ends issue reads only labels, git and run outcomes. |

What fills the rest:

- **Harness and model.** Every task with a model runs Claude Code through the Claude Code GitHub Action in automation mode, on Opus 5.5 at medium effort, pinned in each **task definition**.
- **Billing.** Runs draw on the Claude Max subscription through a one-year `CLAUDE_CODE_OAUTH_TOKEN`. There is no billing fallback: a run that hits the subscription limit fails. Usage credits and the retry watchdog stay off.
- **Hosting.** Two Cloudflare accounts shared by every project: the **preview account** on Workers Free and the **production account** on Workers Paid. Alchemy v2 deploys a stage per PR (`pr-<n>`) and `prod` from `main`, with one state store per account.
- **Swap.** Nothing is prepared for one. A **swap** is done by the human, one task at a time, through a PR that rewrites the task definition and the step that calls the harness.

Detail: *Which products fill the orchestrator and runner slots?*, *Personal account or organisation, and which identity do runs act as?*, *How swappable must the model be?*.

## What every task shares

### Where things live

**The studio repo** is public, with "Collaborators only". It holds:

- the reusable workflows, referenced by every project at `@main`, so a merged studio PR changes every project's next run;
- the task definitions, read at run time at the workflow's own commit, so a task definition always matches its **wiring**;
- the **standards**, one rule per file in `standards/`, indexed by `standards/README.md`;
- the **project template** at `template/`;
- the setup script that creates a project;
- one small workflow file per **clock**, five in all, holding only `schedule` and dispatch by hand, and calling a reusable workflow;
- the `wake` script, the "back from a break" checklist and the project-retirement checklist.

Its own PRs get `actionlint`, the PR branch's checks workflow run against `template/`, and automated review from `main`'s review workflow. Nothing deploys from it.

**A project** is created by the setup script from the project template. Its parts:

| Part | Owner | How it changes |
| --- | --- | --- |
| Five caller workflows: `pr.yml`, `comment.yml`, `main.yml`, `issues.yml`, `review.yml` | Studio | Written by the studio's script, verified unchanged by the checks job, updated by the upgrade task's project leg |
| Baseline check configs | Studio | Written by the studio's script, verified unchanged, extended by adoption PRs |
| The **pinned set** | Follows the template | The upgrade task |
| Exception lists and exemptions | Project, under the ratchet rules | See [Baseline checks](#baseline-checks) |
| Alchemy stack, `AGENTS.md`, the "User report" issue form, the app | Project | By hand |
| Stamp file | Studio | Records the studio commit the project follows |

Callers hold only triggers, concurrency, permissions and named secrets. No project caller carries a `schedule`. Concurrency lives only in callers, and every concurrency group's name carries the repo name. Caller job names are a contract: a required check is named `<caller job> / <studio job>`, and the project's ruleset matches those strings.

### Identity and who can start a run

- **The studio app.** One private GitHub App owned by the organisation acts for every run. Each run mints a 1-hour token narrowed to its task's permissions.
- **The actor check.** Every task's wiring starts a run only when the event's actor is the human or the **studio app**. An outsider's comment never starts a run, and a run reads one only when the human brings it in.
- **Models don't post.** In every task a model-free posting step commits, pushes, opens PRs, posts comments and sets labels. The harness step never pushes or posts, so text in a diff or a ticket cannot make a model post. No token given to a model's work carries the Workflows permission, so no model can change CI.

| Task | Studio app token |
| --- | --- |
| Automated review | Contents read; Pull requests and Checks write |
| Rework | Contents and Pull requests write |
| Implementer | Contents, Pull requests and Issues write |
| Ratchet | Contents and Pull requests write |
| Explore | Contents read; Issues write |
| Sharpen | Issues and Pull requests read on every project; Contents and Pull requests write on the studio repo only |
| Adoption | Contents and Pull requests write on projects |
| Upgrade, studio leg | Contents and Pull requests write on the studio repo; Actions write on projects to dispatch the project leg |
| Upgrade, project leg | Posting step only: Contents, Pull requests and Workflows write on the project |
| Loose ends | Issues, Pull requests, Actions, Metadata, Contents and Dependabot alerts read on every project; organisation variables read; Issues write on the studio repo only |

### Secrets

- **Organisation secrets:** `CLAUDE_CODE_OAUTH_TOKEN`, the studio app's private key, and the preview account's Cloudflare token.
- **Per project:** a production Cloudflare token in the repo's `production` environment, which only `main` may deploy to. The app's own secrets have a test value in the `preview` environment and the real value only in `production`.
- **Passing.** Secrets pass to reusable workflows by name, never `secrets: inherit`. Review receives only the OAuth token and the studio app's key; preview the preview token; `prod` the production token; checks nothing.
- **No run with a model holds Cloudflare credentials**, not even preview ones. The preview job runs the PR branch's code with the preview token, so a run's change can reach the preview account and never production.

### Pausing and failing

- **`STUDIO_PAUSED`.** An organisation variable the human sets to take the subscription's limits back. Every task with a model checks it first and skips cleanly when it is set. Automated review and the loose-ends task are exempt. Baseline checks, preview, `prod`, adoption and the model-change notice have no model and never check it.
- **Failure.** A final step posts a studio app comment on the ticket or PR the run was working on, with the run link, the reason and a hidden `<!-- studio:failure -->` marker. There are no automatic retries: the human re-runs in Actions or re-applies the trigger label. A failed scheduled run has nowhere to comment and shows in the loose-ends issue.

## Tasks

| Task | Trigger | Model | `STUDIO_PAUSED` | Wired in |
| --- | --- | --- | --- | --- |
| [Baseline checks](#baseline-checks) | PR push | None | Always runs | Project `pr.yml`, `comment.yml` |
| [Preview](#preview-and-prod-deploys) | PR push; PR close | None | Always runs | Project `pr.yml` |
| [`prod` deploy](#preview-and-prod-deploys) | Push to `main` | None | Always runs | Project `main.yml` |
| [Automated review](#automated-review) | Baseline checks pass on a non-draft PR; `/review` | Yes | Exempt | Project `pr.yml`, `comment.yml` |
| [Rework](#rework) | Failed `automated review` on an **agent PR**; the human's "Request changes" on one | Yes | Respects | Project `pr.yml`, `review.yml` |
| [Sharpen](#sharpen) | Weekly clock; by hand | Yes, when there are inputs | Respects | Studio repo |
| [Adoption](#adoption) | By hand | None | By hand, no model | Studio repo |
| [Implementer](#implementer) | The human applies `ready-for-agent` | Yes | Respects | Project `issues.yml` |
| [Ratchet](#ratchet) | Daily clock in the studio repo; by hand | Yes, when a file is left | Respects | Project `issues.yml` |
| [Explore](#explore) | The human applies `needs-triage` | Yes | Respects | Project `issues.yml` |
| [Upgrade, studio leg](#upgrade) | Weekly clock; by hand | Only when the bump breaks something | Respects | Studio repo |
| [Upgrade, project leg](#upgrade) | A studio merge that changes the template's pinned set or callers | Only when the bump breaks something | Respects | Project `issues.yml` |
| [Loose ends](#loose-ends) | Daily clock; by hand | None | Exempt | Studio repo |

The three brakes are the baseline checks (automated checks), automated review, and the human reading and merging every PR by hand (human review). Rework and every clock-triggered or label-triggered task are accelerators.

### Baseline checks

The **baseline checks** are studio-owned, one rule or setting each. A project may add checks and never changes a baseline check.

1. **Trigger.** Every push to a PR (`opened`, `reopened`, `synchronize`, `ready_for_review`), through the `checks` job of `pr.yml`. A `/review` comment from the human reruns it first. Studio repo PRs run the same checks against `template/`.
2. **What it does.** One job runs `pnpm check`, which runs every gate, keeps going past a failure and exits non-zero if any failed:
   - a frozen install of the exact-pinned set (`pnpm install --frozen-lockfile`);
   - format (`oxfmt --check`);
   - plain `tsc --noEmit` on TypeScript 7 over `src/`, `test/` and `alchemy.run.ts`;
   - Oxlint with Foldkit's plugin, over every TypeScript file;
   - Effect diagnostics, through the Oxlint route only;
   - unit tests (`vitest run`), with V8 coverage written to the job summary and uploaded as an artifact, reported and never gated;
   - the Worker test on local workerd with `ALCHEMY_DEV=1`, needing no credentials.

   Warnings fail the job. Strictness starts at the scaffold's own settings, and stricter settings arrive later as new checks. The job also verifies the studio-owned files are unchanged and enforces the ratchet rules:
   1. A new or changed file must pass every check. A rename counts as a change.
   2. A PR that changes a file on an **exception list** must make it pass and remove it from the list.
   3. A listed file that already passes fails the job as stale.
   4. Removing entries is always allowed. Adding a file to an exception list, or adding an **exemption** with its written reason, fails unless the PR's author is the human or the PR is an adoption PR (an upgrade PR counts as one). Even on those, no commit a model wrote adds one: see [Rework](#rework) and [Upgrade](#upgrade).

   It reads the git host only, and writes one status check and the coverage artifact.
3. **What it triggers next.** On a pass, automated review, as a later job of the same run. It is one of the two required checks.
4. **Where the human re-enters.** Fixing their own red PR. Only the human grants an exemption, and only the human or a model-free step adds to an exception list.
5. **What stops duplicate work.** `pr.yml` and `comment.yml` share one concurrency group per PR with `cancel-in-progress`, so a new push replaces the run on the old commit.

Detail: *What baseline of automated checks must every project pass?*, *Run the candidate gates on a scaffolded CAFE app*, *Where do standards live, and how do they accumulate?*.

### Preview and `prod` deploys

Both are plain CI with no model.

**Preview**

1. **Trigger.** The same PR events as the baseline checks, as the `preview` job beside `checks`. Closing the PR, merged or not, triggers the `destroy` job.
2. **What it does.** Deploys stage `pr-<n>` to the preview account with the organisation's preview token, then runs the Worker test file against it (`ALCHEMY_DEV` unset). The **preview** is public on `workers.dev` and holds only test data. `destroy` tears the stage down whole. There is no `alchemy plan`, no scheduled sweep and no cap on open previews.
3. **What it triggers next.** Nothing. It is the second required check. Review does not wait for it.
4. **Where the human re-enters.** Re-running the check after a Cloudflare outage or an Alchemy bug, which block merging until then. Cleaning up after a failed destroy, which GitHub emails. When a preview fails on a Free limit: pausing the studio, closing PRs, or moving previews to Paid if it happens more than once.
5. **What stops duplicate work.** The per-PR concurrency group. `destroy` has its own group.

**`prod`**

1. **Trigger.** Every push to `main`, which only the human's merge makes, through `main.yml`.
2. **What it does.** Deploys stage `prod` to the production account, in the repo's `production` environment with that project's production token. Its last step is a read-only smoke check that fetches the production URL and expects HTTP 200. Stateful resources are marked `RemovalPolicy.retain()` in `prod` only, so a mistaken destroy cannot delete user data.
3. **What it triggers next.** Nothing.
4. **Where the human re-enters.** GitHub emails a failure. The human re-runs the job, merges a fix PR or merges a revert PR. Production is never deployed from the laptop, so production always equals `main`.
5. **What stops duplicate work.** One concurrency group per repo with no cancelling. GitHub keeps only the newest waiting run, which contains every earlier merge.

Detail: *How do deploys work, and on which Cloudflare plan?*.

### Automated review

1. **Trigger.** A non-draft PR is opened, reopened, marked ready or pushed to, and the baseline checks have passed on its head commit. This covers every PR, the human's included. A red commit gets no review, and a draft gets none, which is how the human controls how often reviews run. A `/review` comment from the human forces a fresh review of the current commit; it is the only comment command. Exempt from `STUDIO_PAUSED`.
2. **What it does.**
   - **Harness step.** Read-only. It reads the diff (without lockfiles, generated files or pure pin bumps), the ticket the PR closes, the project's `AGENTS.md`, the standards (index first) and the surrounding code. It does not read outsiders' comments, earlier review threads, coverage or the preview. A diff over about 1,500 changed lines gets a "too large to review well" note instead.
   - **Findings.** It writes **findings** to a file and never posts. Each has a severity (blocking, suggestion or lesson), why it matters, and a link to a standard, or else the upstream doc, or else a "no standard yet" mark. It never invents house rules. Each review covers the whole PR and says which earlier findings are fixed or still stand.
   - **Posting step.** Model-free, skipped if the run was cancelled. It posts one **review report** as the studio app, with coverage of the changed lines added from the baseline checks' artifact, and sets a check run named `automated review`: failed if any finding is blocking. That check is not required, because the human merges by hand and may overrule it.
   - **Nothing a model wrote.** Review ends before the model starts and passes `automated review` in two cases. An upgrade PR that holds only what model-free steps wrote gets a report saying "pins only, nothing to review". An adoption PR gets one saying "written by a model-free step, nothing to review".
   - **Services.** Reads the git host and the ticket tracker. Writes one review and one check run on the git host.
3. **What it triggers next.** On the human's PRs, nothing. On an agent PR, a failed `automated review` triggers rework. Posting the review report starts no run: `pr.yml` does not listen for PR reviews.
4. **Where the human re-enters.** Reading the review report and merging by hand. Replies disputing a finding trigger nothing; the sharpen task reads them later.
5. **What stops duplicate work.** The per-PR concurrency group cancels the review of an old commit, and a run whose head commit already has a review report exits.

Detail: *How does the automated review task work?*.

### Rework

Only agent PRs get rework.

1. **Trigger.** Two, and both respect `STUDIO_PAUSED`:
   - **A failed review.** A job in `pr.yml` after review, run only when `automated review` failed, the PR's author is the studio app and its branch starts with `studio/`.
   - **The human's "Request changes".** A fifth caller, `review.yml`, listens for a submitted PR review and starts rework only when the human requested changes on an agent PR. It is a separate file because the review report is itself a PR review posted by the studio app: if `pr.yml` listened for that event, the report would cancel the run that posted it.

   Rework never runs on an adoption PR, not even on the human's "Request changes", and it skips a PR labelled `ready-for-human`.
2. **What it does.** The harness reads the latest review report's blocking findings (or the human's review comments), the ticket, `AGENTS.md`, the standards and the code, and fixes only those. If `pnpm check` passes, a model-free step pushes one commit with the trailer `Studio-Rework: <n>`. If not, it pushes nothing, comments and labels the PR `ready-for-human`. It does the same with a commit that adds an exception-list line or an exemption, which no model may write. It reads and writes the git host.
3. **What it triggers next.** Its push re-runs the baseline checks, the preview and review, closing the loop.
4. **Where the human re-enters.** At the cap: 3 rework rounds, counted from the trailers, so a PR gets at most 4 reviews. Then the studio app comments the findings that still stand and labels the PR `ready-for-human`. Removing the label re-arms 3 more rounds. Rework on the human's "Request changes" is outside the cap. Once the human pushes to an agent PR, rework stops on it for good.
5. **What stops duplicate work.** The job in `pr.yml` rides the per-PR concurrency group, and `review.yml` has its own group per PR. The push step refuses if the PR's head moved since the run began.

Detail: *How do the implementer and rework tasks work?*, *What did writing the spec leave unsettled?*.

### Sharpen

Turns what review and the human catch into new standards, sharper review and new baseline checks.

1. **Trigger.** A weekly clock in the studio repo, or a dispatch by hand. Respects `STUDIO_PAUSED`.
2. **What it does.**
   - **Gathering.** A model-free step gathers, from every project since the "covered until" time in the last sharpen PR: findings marked "no standard yet", the human's replies disputing a finding, and the human's own PR review comments and requested changes. Inputs come from the human and the studio app only. With no inputs, the run ends before the model starts.
   - **Drafting.** It opens one PR in the studio repo with one commit per proposal: a new standard, a change to one or its retirement, an edit to the review task definition, or a new baseline check with its adoption dry run for each project. The body maps each input to its proposal and lists what it declined and why.
   - **Services.** Reads the ticket tracker and git host on every project. Writes the git host on the studio repo only.
3. **What it triggers next.** The PR gets the studio repo's checks and review. Merging it makes the standards live in the next review run. A merged baseline check waits for the human to dispatch adoption.
4. **Where the human re-enters.** Reading the PR, editing it, dropping commits, then merging or closing it.
5. **What stops duplicate work.** One concurrency group with no cancelling. A run skips the week while the previous sharpen PR is open. "Covered until" moves forward only when a sharpen PR opens, so no input is lost.

The standards start from a seed: one PR of community rules, each rewritten as one standard with its source, which the human keeps or cuts. The human's questions happen in local sessions the studio never sees, so sharpen feeds mostly on "no standard yet" findings and on what the human writes on PRs.

Detail: *Where do standards live, and how do they accumulate?*.

### Adoption

Brings a new baseline check to each existing project.

1. **Trigger.** The human dispatches the adoption workflow by hand, after a new baseline check merges in the studio repo.
2. **What it does.** Deterministic, with no model. For each project that is not exempt, it writes the check's config, runs the check, and opens one PR as the studio app on `studio/adopt-<check>`. The PR either accepts the check as-is or ratchets, with the failing files on an exception list. Whole-project checks (unit tests, the Worker test, the frozen install) are accepted as-is or exempted. It writes the git host on projects.
3. **What it triggers next.** The baseline checks and the preview on each adoption PR, then automated review, which passes it without the model. Rework never runs on it. It counts toward the open-agent-PR cap and is never blocked by it.
4. **Where the human re-enters.** Dispatching it, and merging each adoption PR by hand. Only the human grants an exemption. If an adoption PR is wrong, the human pushes to it, or closes it, deletes its branch and dispatches adoption again.
5. **What stops duplicate work.** A project that already has the branch is skipped. Adoption stays outside the per-project concurrency group that upgrade, implementer and ratchet share: it is by hand, model-free and seconds long. The cost is that an agent PR opened before an adoption PR merges may fail the new check on its next push, which the human sees at merge.

A new project gets every baseline check with empty exception lists. An upgrade PR counts as an adoption PR when a bumped tool flags files it did not change.

Detail: *Where do standards live, and how do they accumulate?*, *What did writing the spec leave unsettled?*.

### Implementer

1. **Trigger.** The human applies `ready-for-agent` to a project's issue. Respects `STUDIO_PAUSED`.
2. **What it does.**
   - **The label is the queue.** One implementer concurrency group per project, with no cancelling. A run takes the oldest issue labelled `ready-for-agent` and swaps the label for `agent-working`.
   - **Throttle.** A cap on open agent PRs per project, starting at 1. Every open agent PR counts, whichever task opened it, and the cap only ever stops the implementer and the ratchet. At the cap the run skips and tickets keep their labels. So with the cap at 1, an unmerged upgrade or adoption PR holds the implementer back until the human merges or closes it. That is intended: the cap measures how many agent PRs wait on the human.
   - **Harness step.** A 60-minute timeout. It reads the issue and only the human's and the studio app's comments, `AGENTS.md`, the standards and the code, and builds on `studio/<issue-number>-<slug>` until `pnpm check` passes.
   - **Posting step.** Model-free. It opens the PR as the studio app with "Closes #n", the model's summary and anything it was unsure about, and removes `agent-working` from the issue. If `pnpm check` passed, the PR opens ready. If not, it opens as a draft labelled `ready-for-human`, and review does not run.
   - **A ticket it can't build.** No PR. It posts its questions on the issue and swaps the label to `needs-info`.
   - **Failure.** The studio app comments on the issue and removes `agent-working`. The human re-applies `ready-for-agent`.
   - **Services.** Reads and writes the ticket tracker and the git host.
3. **What it triggers next.** A ready agent PR triggers the baseline checks, the preview and automated review, and a failed review triggers rework. Finishing dispatches the next implementer run while labelled issues remain, and so does merging or closing an agent PR.
4. **Where the human re-enters.** Answering `needs-info` questions and re-labelling. Reviewing and merging every agent PR by hand. Taking over a `ready-for-human` draft.
5. **What stops duplicate work.** One run per project at a time, the label swap as a claim that lasts only as long as the run, and skipping an issue that already has an open PR closing it.

Detail: *How do the implementer and rework tasks work?*.

### Ratchet

Works exception lists down, one file at a time.

1. **Trigger.** A daily clock in the studio repo, which dispatches `task: ratchet` on every project's `issues.yml`. The human can dispatch the same by hand at any time. Respects `STUDIO_PAUSED`.
2. **What it does.**
   - **Priority.** It joins the implementer's per-project concurrency group, in the order upgrade, implementer, ratchet. A run skips if any issue is labelled `ready-for-agent` or `agent-working`, if the project is at the open-agent-PR cap, or if a ratchet PR is already open. A run by hand still takes an open-agent-PR slot. `agent-working` is also explore's claim, so a live explore run can cost the ratchet that day's run, and a stale claim holds it until the human clears it.
   - **Picking the file.** A model-free step lists every file on any exception list, leaves out files with a `ratchet-skipped` PR, runs the checks, and picks the file with the fewest violations. With no files left, the run ends before the model starts.
   - **Harness step.** A 30-minute timeout. It fixes only what the listed checks flag in that file and changes no behaviour.
   - **Posting step.** Model-free. It removes the file from every list, runs `pnpm check`, pushes `studio/ratchet-<path-slug>` and opens a ready agent PR titled "Ratchet: `<path>`" with before and after counts. If the file can't be fixed, it opens a `ready-for-human` draft, which holds the project's one ratchet slot.
   - **Services.** Reads and writes the git host.
3. **What it triggers next.** The baseline checks, the preview, automated review and rework, as for any agent PR.
4. **Where the human re-enters.** Reviewing and merging each ratchet PR. Finishing, taking over or closing a draft. Closing a ratchet PR unmerged means "not this file for now": it is labelled `ratchet-skipped`, and removing the label makes the file eligible again.
5. **What stops duplicate work.** The shared concurrency group, at most one open ratchet PR per project, and the `ratchet-skipped` label.

Detail: *Should a ratchet task work exception lists down?*.

### Explore

Reads a **user report**, digs, and hands the result to the human.

1. **Trigger.** The human applies `needs-triage` to an issue, which the "User report" issue form does at creation. Never on an issue merely opening. Respects `STUDIO_PAUSED`.
2. **What it does.**
   - **Queue and claim.** One explore concurrency group per project, with no cancelling. A run takes the oldest issue labelled `needs-triage` and swaps the label for `agent-working`, the same claim label the implementer uses.
   - **Harness step.** A 30-minute timeout, read-only on code. It checks the report against the code, reproduces locally on the runner where it can (never against production or a preview), and searches open and recently closed issues for duplicates.
   - **Posting step.** Model-free. It posts one **explore report** as the studio app, with a category (easy call, needs a human, needs info from the user, not a bug, likely duplicate) and, for an easy call, a proposed ticket. It removes `agent-working` and leaves `needs-info` or `ready-for-human`. It never applies `ready-for-agent`, edits the issue body, pushes or closes an issue.
   - **Failure.** A studio app comment, `agent-working` removed. The human re-applies `needs-triage`.
   - **Services.** Reads the git host. Reads and writes the ticket tracker.
3. **What it triggers next.** Its own next run while issues labelled `needs-triage` remain. Nothing else.
4. **Where the human re-enters.** Every outcome: relaying `needs-info` questions to the user, adding the answer and re-applying `needs-triage`; or reading the report and labelling `ready-for-agent`, closing the issue or taking it on.
5. **What stops duplicate work.** One run per project at a time, the label swap as a claim, and skipping an issue whose latest explore report is newer than the human's last edit or comment.

Detail: *How do user reports reach the studio, and what does the explore task do?*.

### Upgrade

The pinned set is upgraded as one PR, majors included. The studio leads: the studio leg bumps the project template, and each project then follows it in the project leg. There is no separate security route: Dependabot alerts are on, Dependabot security updates are off, and a fix rides the normal upgrade.

**Studio leg**

1. **Trigger.** A weekly clock in the studio repo, or a dispatch by hand. Respects `STUDIO_PAUSED`. The weekly run skips while the previous studio upgrade PR is open.
2. **What it does.**
   - **Bump.** A model-free step runs `pnpm update --latest -r` in `template/` and takes the newest pnpm and Node LTS. The template's `minimumReleaseAge` of 3 days applies to everything.
   - **Checks.** It runs the checks against `template/`. If they pass, no model runs.
   - **Harness step, only on failure.** It reads the bumped packages' release notes and fixes the breakage without changing behaviour. It may edit a baseline check config where a bump forces it.
   - **Posting step.** Model-free. It pushes `studio/upgrade` and opens one PR with a from-to table, a `pnpm audit` summary and each hold. If the checks still fail, the PR is a draft labelled `ready-for-human`.
   - **Holds.** A package that can't be taken is held in the template for every project, with a written reason.
   - **Services.** Reads and writes the git host on the studio repo.
3. **What it triggers next.** The studio repo's checks and review, with no rework. Merging it starts the project leg in every project.
4. **Where the human re-enters.** Reading, editing, merging or closing the PR. Adding or removing a hold. For an urgent fix: unpausing and dispatching by hand, optionally naming one `package@version` to let through the release age.
5. **What stops duplicate work.** One branch and one concurrency group. A hand dispatch rebuilds the branch from `main` unless the human has pushed to it.

**Project leg**

1. **Trigger.** A merge to the studio repo's `main` that changes the template's pinned set or caller workflows: a studio workflow dispatches `task: upgrade` on every project's `issues.yml`. The weekly run also dispatches it for any project still behind with no open upgrade PR. Respects `STUDIO_PAUSED`.
2. **What it does.**
   - **Follow.** A model-free step writes the template's versions, takes the latest of the project's own extra dependencies, regenerates the lockfile, rewrites the caller workflows and writes the stamp.
   - **New findings in untouched files.** When a bumped tool makes format, lint or Effect diagnostics flag files the PR did not change, the step puts them on the exception list. Type errors and failing tests are never listed.
   - **Harness step, only on failure.** As in the studio leg, but it can't change a baseline check config.
   - **Posting step.** Model-free. It pushes `studio/upgrade` and opens one agent PR, or a `ready-for-human` draft. The body links the template's changes to the Alchemy stack and `AGENTS.md`. Only the follow step adds exception-list lines: the posting step refuses a commit from the harness step that adds one, or an exemption, and hands the PR over as `ready-for-human`.
   - **Services.** Reads and writes the git host on the project.
3. **What it triggers next.** The baseline checks, the preview, automated review (skipping the model when the PR is pins only) and rework.
4. **Where the human re-enters.** Reviewing and merging each upgrade PR. Taking over a draft. Applying template changes to the Alchemy stack and `AGENTS.md` by hand. Closing one unmerged means "not this set": it is labelled `upgrade-skipped` and the next template set tries again.
5. **What stops duplicate work.** One branch per project, rebuilt from `main` for a newer set unless the human has pushed to it. It runs first in the implementer's concurrency group. An upgrade PR counts toward the open-agent-PR cap and is never blocked by it.

Detail: *How does a project's pinned set get upgraded?*, *What did writing the spec leave unsettled?*.

### Loose ends

Shows the human every **loose end** in one place.

1. **Trigger.** A daily clock in the studio repo, or a dispatch by hand. Exempt from `STUDIO_PAUSED`.
2. **What it does.** With no model, it rewrites one pinned issue in the studio repo, labelled `studio-loose-ends`. The issue opens with its refresh date and the command that restarts the clocks. Its body is a table of projects against kinds, each count linking its search, and it ends with a collapsed JSON block for agents. It reads the ticket tracker, git host and orchestrator on every project and one organisation variable, and writes only that issue. The kinds:
   1. **Waiting on the human:** issues, drafts and PRs labelled `ready-for-human`.
   2. **Agent PRs awaiting review:** open, non-draft agent PRs, with the oldest one's age.
   3. **Questions:** issues labelled `needs-info`.
   4. **Stale claims:** issues labelled `agent-working` with no implementer or explore run in progress in that project.
   5. **Failures with no follow-up:** issues and PRs whose latest comment is a studio app failure comment.
   6. **Failed runs with nowhere to comment:** scheduled runs that failed in the last 7 days.
   7. **Sharpen held:** a sharpen PR open more than 7 days.
   8. **Ratchet skips:** closed PRs labelled `ratchet-skipped`.
   9. **Schedules switched off:** scheduled workflows GitHub disabled for inactivity.
   10. **Upgrade held:** the studio upgrade PR open more than 7 days.
   11. **Behind the template:** a project whose pinned set or callers differ from the template's, with days behind.
   12. **Security alerts:** open Dependabot alerts per project.
   13. **Renewals due:** `CLAUDE_CODE_OAUTH_TOKEN`, from 30 days before its expiry date, which an organisation variable holds. Domains are not counted.
3. **What it triggers next.** Nothing. On Monday it posts one comment with the totals and their change since last week, which notifies the human. No comment when every count is zero.
4. **Where the human re-enters.** Reading the issue or the Monday comment and acting on each item through its link.
5. **What stops duplicate work.** One concurrency group with `cancel-in-progress`. The issue is found by its label and created only if missing. The Monday comment is posted only if the studio app hasn't commented since Monday 00:00 UTC.

The issue carries no evidence for the dials.

Detail: *How does the human see the studio's loose ends?*.

## Ticket sources

**The human, filing user reports.** Users are non-developers with no GitHub account who already reach the human directly. The human files each report through the "User report" issue form in the project template, which applies `needs-triage`. Issues are public, so a user's name, email or private data never goes into a report, and the explore task definition forbids quoting any it finds. On the booking app only the calendar owner reports to the human, and a client's name, email or appointment never goes into a report.

- **What stops the same report being filed twice?** The human sees the open issues, and explore's duplicate search catches what the human misses.

**The model-change notice.** A weekly clock in the studio repo starts a model-free job that reads Claude Code's changelog for model names and "default". On a match the studio app opens a "Revisit the model pin" issue in the studio repo, quoting the lines. Its clock sits in its own small file like the other four, is switched on at wiring step 5 straight after the loose-ends clock, and is restarted by `wake`. It has no model, so it ignores `STUDIO_PAUSED`.

- **What stops it filing twice?** The issue records the changelog version it covered, the next check starts from there, and it adds to an open issue instead of opening a second.

Detail: *How do user reports reach the studio, and what does the explore task do?*, *How does the automated review task work?*.

## Monthly cost

Every recurring cost except the Claude subscription, at 2026-11-20 prices. The budget is about $100 a month, with an aim of about $50.

| Item | A month |
| --- | --- |
| Production account, Workers Paid | $5.00 |
| Preview account, Workers Free | $0 |
| One domain for the booking app (a `.com`, about $10.46 a year) | about $0.90 |
| Email sending (Cloudflare Email Sending, 3,000 a month included in Workers Paid) | $0 |
| Google Calendar API, Cloud project and test Google account | $0 |
| GitHub: free organisation, public repos, Actions, the studio app, Dependabot alerts | $0 |
| Model tokens beyond the subscription | $0 |
| **Total** | **about $6** |

- **Ceiling.** About $12: about $5 more if previews move to Paid, and about $0.90 more if the preview account needs its own sending domain, shared by every project's previews.
- **Each later project.** About $1 more if it sends email, because every email provider checked needs a domain the sender owns.
- **Headroom.** The rest of the $50 aim stays unspent. The likeliest claims on it are Resend Pro ($20 a month) if Cloudflare's email beta proves unfit, and a metered API key if a task is ever moved off the subscription by a deliberate PR.

Detail: *What does the studio cost a month, and in what order are its triggers switched on?*.

## Rollout

The rollout has two phases. The **wiring phase** proves the studio's wiring on the **scratch project**. The **evidence phase** proves the design on the booking app, the first real project and the only source of evidence for opening the throttle.

**The first trigger** switched on is a PR push starting the baseline checks. The first trigger that spends model usage is the same PR push starting automated review. The first accelerator is the human's `ready-for-agent` label. All three brakes are on before any accelerator.

### What switches a trigger on

- **PR-triggered tasks** (baseline checks, preview, automated review, rework) arrive with the project template. They are on from a project's first PR and never off.
- **Label-triggered tasks** (implementer, explore) are on the day the human first applies the label on the booking app. Nothing is configured.
- **Clocks.** There are five: loose ends (daily), the model-change notice (weekly), upgrade (weekly), sharpen (weekly) and ratchet (daily). Each has a workflow file in the studio repo with no `schedule` line until its turn. Switching one on is one studio PR adding the line, so the rollout can be read in the studio repo's history.
- **The upgrade's project leg** starts on a merge the human makes in the studio repo, so it is on once built.

### Wiring phase, on the scratch project

Each step is built, shown to stop a deliberate fault, and left on.

1. **By hand.** The organisation, the studio app, both Cloudflare accounts and the secrets. The "Collaborators only" check runs first, on an empty repo that is deleted straight after.
2. **Baseline checks.** The template and setup script create the repo `scratch`, then one faulty PR per gate.
3. **Preview, destroy on close, and `prod` with its smoke check.** The scratch project gets its own `production` environment, token and one production deploy.
4. **Automated review**, after the standards seed PR. A PR that breaks a seeded standard must fail `automated review`. This is the first run that spends model usage.
5. **Loose-ends task**, with its daily clock: the first clock switched on, before any task that can leave a loose end. The model-change notice's weekly clock is switched on straight after, so a failed notice run has somewhere to show.
6. **Implementer and rework.** One ticket through, and one agent PR through a rework round.
7. **Upgrade.** The studio leg by hand, merged, then the project leg on `scratch`. The deliberate fault is a model-written commit that adds an exception-list line, which the posting step must refuse.
8. **Adoption, then ratchet.** No exception list is edited by hand:
   - the human merges a file on `scratch` that breaks a stricter setting they want to keep;
   - the human adds that setting as a new baseline check in a studio PR, by hand;
   - the human dispatches adoption, and `scratch` gets an adoption PR with that file on its exception list;
   - the human merges it, and the ratchet opens one PR for that file.

   The check stays in the studio, so the booking app starts with it and an empty exception list. Which setting to use is left to the build: the human picks one they want to keep.
9. **Explore.** One invented user report through the issue form.
10. **Sharpen.** One dispatch by hand on a few review comments left on `scratch`, and the PR closed unmerged. Its weekly clock stays off, so nothing from the scratch project reaches the standards.

The wiring phase ends, and the booking app's repo is created, when every step has stopped its deliberate fault and every build-time check below has an answer or its fallback.

| Build-time check | Step | If it fails |
| --- | --- | --- |
| The studio app can open an issue and a PR under "Collaborators only" | 1 | Switch that restriction off, rely on the actor check, and close outsiders' issues and PRs by hand |
| The "All repositories" installation sees a new repo | 1 | Adding each new repo to the installation becomes a step in creating a project |
| A workflow execution protection limited to the human and the studio app can be saved on a free organisation | 1 | The actor check stands alone |
| Dependabot alerts see pnpm's two-document lockfile, tested by pinning one known-vulnerable version | 2 | The `pnpm audit` summary in the studio upgrade PR |
| The Alchemy test harness deploys the stack into a named stage by itself | 3 | A deploy step runs first |
| The minimal Cloudflare token permissions for a Foldkit, D1 and Durable Object app | 3 | A finding, not a pass or fail |
| The Cloudflare state store locks concurrent deploys | 3 | The `prod` concurrency group covers it either way |
| The PR stage name | 3 | Use `pr-<n>` |
| Whether the preview account needs its own sending domain to email verified addresses | On the booking app, before its first feature PR | A second domain in the preview account, shared by every project's previews, at about $0.90 a month |
| Concurrency groups do not cross repos, tested with a throwaway sleeping workflow under one group name in `scratch` and the studio repo | 6 | None needed: every group name carries the repo name from the start, so the check only confirms |
| `STUDIO_PAUSED` makes the implementer skip while review still runs | 6 | A fault to fix, not a fallback |
| Posting a review report cancels no run | 6 | A fault to fix, not a fallback |
| `pnpm update --latest` keeps exact pins exact | 7 | Add `--save-exact` to the update. If that fails too, a model-free step rewrites each range to the lockfile's version |
| The posting step refuses a model-written commit that adds an exception-list line or an exemption | 7 | A fault to fix, not a fallback |
| A label the issue form sets at creation fires a `labeled` event | 9 | `issues.yml` also listens for `opened`, and explore starts only if the human opened the issue and it already carries `needs-triage` |

### Evidence phase, on the booking app

The booking app is a small appointment-booking app: it reads one person's Google calendar and some constraint rules, lets clients book, writes to that calendar and sends reminder emails. The setup script creates it from the project template with empty exception lists. Its users are the calendar owner, who is not the human, and the owner's clients. **Launch** is the day the owner starts taking real bookings.

1. **From its first commit:** baseline checks, preview, `prod`, automated review and the daily loose-ends issue. Only the human opens PRs, from local sessions.
2. **Upgrade's weekly clock:** the day the booking app's repo is created.
3. **Test Google account and the email restriction:** by hand, before the first feature PR. The stack restricts the email binding to verified destination addresses in every stage but `prod`, and both Google OAuth clients are set "In production", unverified.
4. **Sharpen's weekly clock:** the day the scratch project is deleted, which is after the booking app's first PR has merged and deployed to production.
5. **Implementer and rework:** when the human first applies `ready-for-agent`, on the evidence under [Opening the throttle](#opening-the-throttle).
6. **Ratchet's daily clock:** switched on once the open-agent-PR cap is at 2 and an exception list holds a file, as the same section says. Until then the human can run the ratchet by hand.
7. **User reports and explore:** at launch, wherever launch falls in this order.

Because the booking app starts from the template, adoption PRs, exception lists and the ratchet get their first real use only when sharpen adds a baseline check or an upgrade PR lists new findings.

### The 60-day rule

GitHub disables scheduled workflows in a public repo after 60 days with no repository activity, and user reports say the whole workflow file stops. So no project carries a `schedule`, each of the five clocks sits in its own small file in the studio repo, and there is no keepalive: the studio repo stays active through the weekly upgrade and sharpen merges. After 60 days with none, the clocks stop until the human runs the `wake` script, which re-enables all five.

Detail: *What does the studio cost a month, and in what order are its triggers switched on?*, *Which project is the studio proven on first?*, *What did writing the spec leave unsettled?*.

## Opening the throttle

**Every threshold in this section is advice to the human.** Nothing in the studio reads, counts or enforces one, and nothing loosens a **dial** by itself. They are evidence, not gates. Only the booking app's PRs, review comments and tickets count; nothing on the scratch project does.

### Before the implementer is first used

All five, on the booking app:

| Evidence | Threshold | Counted with |
| --- | --- | --- |
| Volume | At least 10 PRs the human opened have merged, each with a review report. They come from local sessions, where an agent may have written the code while the human questioned it. | Search A |
| Review doesn't cry wolf | Across the last 10, the human disputed at most 2 blocking findings | Search B |
| The human can read cold | On the last 3, the diff and the review report held nothing the human had to take back to a session to have explained | The human's own judgement |
| The loop is closed | At least one sharpen PR has merged | Search C |
| Usage headroom | For two weeks, no run failed on the subscription limit and the human did not hit it in their own sessions | Search D, and the human's memory of their own sessions |

### Before the ratchet's clock is switched on

Both: the open-agent-PR cap has been raised to 2, and an exception list holds at least one file. The clock can be switched on the same day as the cap change. Before that the human can run the ratchet by hand.

### The dials

| Dial | Lives in | Starts at | Evidence for loosening | Counted with |
| --- | --- | --- | --- | --- |
| Who may apply `ready-for-agent` | Wiring: the implementer's actor check, and explore's posting step | The human only | About 9 in 10 of explore's easy calls are ones the human labelled the same way; then explore may apply it to easy calls | Search G |
| Open agent PRs per project | Wiring: the implementer's and ratchet's skip step | 1, with the human labelling one small ticket at a time | To 2: 5 implementer or ratchet PRs have merged and at most 1 needed commits from the human. Beyond 2: none until there is experience | Search E |
| Rework rounds before the human | Wiring: the rework job | 3 | Fewer than 1 in 5 agent PRs reach the cap | Search F |
| Draft on failure: a run that can't pass `pnpm check` hands a `ready-for-human` draft to the human | Wiring: the posting steps | The human takes every draft | None until there is experience | |
| `needs-info`: an unclear ticket's questions go to the human | Wiring: labels | The human answers every question | None until there is experience | |
| How often the ratchet runs | Wiring: the `schedule` line of the ratchet's clock file | Off, then daily | Ratchet PRs reliably merge with no rework rounds | Search H |
| Open ratchet PRs per project | Wiring: the ratchet's skip step | 1 | The same | Search H |
| How often the upgrade's studio leg runs | Wiring: the `schedule` line of the upgrade's clock file | Weekly | None until there is experience | |
| Release age | The project template's pnpm settings | 3 days | None until there is experience | |
| The project leg starts on a studio merge, with no dispatch by hand | Wiring: the studio's dispatch workflow | Starts by itself | None until there is experience | |
| Pins-only review skip | Wiring: the review workflow | Skips the model | None until there is experience | |
| A task clearing a kind of loose end itself | No such task exists; it would read the loose-ends issue's JSON block | Every loose end goes to the human | None until there is experience | |
| Auto-merge | Ruleset, and no task having a merge step | Shut | See below | Search I |

Only implementer and ratchet PRs count as evidence, here and for auto-merge. Upgrade and adoption PRs never do, even when the upgrade's harness step ran.

Effort is one line in a task definition, and no ticket lists it as a dial: the implementer runs at medium to start cheap, and the `Studio-Rework` trailers record the rework rate that would justify raising it.

### Rules for every dial

- **One at a time.** One dial is loosened, then at least two weeks pass before the next.
- **Switching a trigger on takes no turn.** The two-week rule covers dials only. The cap can go to 2 as soon as the fifth implementer or ratchet PR merges, however soon after the implementer's first use, and the ratchet's clock can be switched on the same day.
- **Counted by hand.** No task counts evidence, and the loose-ends issue stays free of it.
- **No evidence yet.** Where the table says "none until there is experience", the human writes the dial's evidence into this spec before loosening it, then waits to see that evidence.
- **Dials that start loose.** The weekly studio leg, the project leg starting by itself and the pins-only review skip are each tightened when one is the cause of a production break or of a week with two usage-limit hits.
- **What goes back.** When an agent PR the human merged breaks production, or runs push the human into the usage limit twice in one week, the human decides at the time what goes back. The default is the most recent change, whether that was a dial or one of the two switch-ons that wait on evidence: the implementer's first use and the ratchet's clock. If the human can see which change caused the trouble, that one goes back instead. Going back means a dial returns to its previous setting, the human stops labelling tickets `ready-for-agent`, or a studio PR removes the ratchet's `schedule` line.
- **Outside these rules.** The upgrade's clock, sharpen's clock and explore at launch, because a fixed event sets the day of each.

### Auto-merge

The last dial, shut. Whether some kind of agent PR may merge without the human is out of scope for this design, because deciding it needs evidence that exists only after the studio is built. The question reopens when every other dial is loosened, `automated review` has been made a required check, and 20 implementer or ratchet PRs in a row have merged with no change from the human. Upgrade and adoption PRs neither count toward the 20 nor break the run.

### Searches

GitHub issue searches. Replace `ORG` (the organisation), `BOOKING` (the booking app's repo), `STUDIO` (the studio repo), `HUMAN` (the human's login) and `APP` (the studio app's slug). Each search narrows; the human counts what it returns. None has been run, and the `app/` forms are the least certain.

- **A.** `repo:ORG/BOOKING is:pr is:merged author:HUMAN` gives the merged PRs the human opened. Open each to see its review report.
- **B.** `repo:ORG/BOOKING is:pr is:merged author:HUMAN commenter:HUMAN sort:updated-desc` gives those the human commented on. In the last 10 merged, count the replies that dispute a blocking finding.
- **C.** `repo:ORG/STUDIO is:pr is:merged author:app/APP` gives the studio app's merged PRs in the studio repo. At least one must be a sharpen PR; the rest are upgrade PRs.
- **D.** `org:ORG commenter:app/APP updated:>=YYYY-MM-DD`, with the date two weeks back, gives the threads the studio app commented on. Read its failure comments for the reason. Failed scheduled runs are in each repo's Actions tab.
- **E.** `repo:ORG/BOOKING is:pr is:merged author:app/APP -head:studio/upgrade` gives the merged agent PRs without the upgrade PRs. Skip the adoption PRs by eye: their branches start `studio/adopt-`. Open each remaining one's Commits tab for commits by the human.
- **F.** `repo:ORG/BOOKING is:pr author:app/APP` gives every agent PR. Count those where the studio app commented the findings that still stand after 3 rounds. Adding `label:ready-for-human` finds the ones still labelled.
- **G.** `repo:ORG/BOOKING is:issue commenter:app/APP in:comments "easy call"` gives the issues explore called easy. Compare each with what the human then did.
- **H.** `repo:ORG/BOOKING is:pr is:merged author:app/APP in:title "Ratchet:"` gives the merged ratchet PRs. Open each one's Commits tab for `Studio-Rework` trailers.
- **I.** Search E with `sort:updated-desc`. Skipping adoption PRs again, check the newest 20 for commits by the human.

Detail: *What does the studio cost a month, and in what order are its triggers switched on?*, *How do the implementer and rework tasks work?*, *What did writing the spec leave unsettled?*.

## By-hand work

### Once, at wiring step 1

- **GitHub.** Create the free organisation, with the human its only member. Register the studio app as a private GitHub App owned by the organisation, install it on all repositories, and store its private key as an organisation secret. Turn Dependabot alerts on and Dependabot security updates off. Publish the studio repo, which today is uncommitted and unpublished at `/Volumes/Roam/studio`.
- **Claude.** Run `claude setup-token` and store the result as the organisation secret `CLAUDE_CODE_OAUTH_TOKEN`. Set its expiry date as an organisation variable, whose name is left to the build. Leave usage credits off in claude.ai and the retry watchdog off.
- **Cloudflare.** Make two accounts under one login, the production account on Workers Paid. Run `alchemy state bootstrap` once in each. Make the preview token and store it as an organisation secret.
- **Standards.** Keep or cut each standard in the seed PR. The seeds include community rules and topstone's `CODING_STANDARDS.md`, Oxlint rule choices and ADRs.

### For each project

- **Create it.** Run the setup script. It creates the repo, pushes `template/`, and applies "Collaborators only", the ruleset with the exact required check names, the `preview` and `production` environments and the studio app's access. It also creates the seven labels the tasks use (`ready-for-agent`, `agent-working`, `needs-info`, `ready-for-human`, `needs-triage`, `ratchet-skipped`, `upgrade-skipped`) from a list kept in the project template, and `studio-loose-ends` in the studio repo. The issue form silently drops a label that does not exist, so they exist before the first issue. How a label added later reaches existing projects is left to the build. The script pauses for the production Cloudflare token, made by hand in the dashboard with permissions trimmed to what the app uses.
- **Domain.** Register one by hand in the production account if the project sends email, and check that auto-renew is on.
- **The app's own secrets.** A test value in `preview`, the real value in `production`.
- **The booking app.** A Google Cloud project, a test Google account with its own calendar, and both OAuth clients set "In production", unverified.
- **Template changes** to the Alchemy stack and `AGENTS.md`, applied by hand from the links in an upgrade PR.
- **Retire it.** From the checklist in the studio repo, written as the scratch project is deleted: delete the repo, destroy its stages in both Cloudflare accounts, remove its production token.

### Ongoing

- Read and merge every PR by hand.
- Read the loose-ends issue or its Monday comment and act on each item.
- Label tickets `ready-for-agent`, file user reports, and relay `needs-info` questions.
- Set and clear `STUDIO_PAUSED`.
- Re-run a failed run, or re-apply its trigger label.
- Merge or close the studio's upgrade and sharpen PRs. Add or remove holds.

### When the time comes

- **Adoption.** Dispatch it after a new baseline check merges, and merge each adoption PR.
- **Clocks.** Switch each on with a studio PR that adds its `schedule` line.
- **Dials.** Count the evidence by hand and loosen one dial at a time. On trouble, decide what goes back.
- **Model pin.** Answer a "Revisit the model pin" issue with a PR.
- **Urgent fix.** Unpause and dispatch the upgrade by hand.
- **Spam.** Lock a thread or set a temporary interaction limit.
- **Slow runs.** If Actions proves too slow in use, change one task's runner to an Actions-compatible vendor on its `runs-on:` line. Nothing is measured.

### Renewals

- **`CLAUDE_CODE_OAUTH_TOKEN`:** every year. The loose-ends issue counts it under "Renewals due" from 30 days before the expiry date in the organisation variable. Set that variable again when the new token is made.
- **Each domain:** left to the registrar's auto-renewal. Check that auto-renew is on when registering.

No other token has a renewal decided.

### Back from a break

A checklist in the studio repo. Its first line: run the `wake` script, which re-enables all five clocks after GitHub disabled them for 60 idle days. The loose-ends issue's stale refresh date is the sign that the clocks have stopped.

## Not confirmed

Facts the design rests on that no primary source or test has confirmed. Almost every ticket says "nothing was tested on a live account"; the rollout's build-time checks settle the first group.

**Settled by a build-time check** (see [Rollout](#rollout)): the studio app passing "Collaborators only"; the installation seeing a new repo; workflow execution protections on a free organisation; Dependabot alerts and pnpm's lockfile; the Alchemy test harness's deploy step; minimal Cloudflare token permissions; state-store locking; the preview account's sending domain; concurrency groups and repos; a review report cancelling no run; exact pins under `pnpm update --latest`; labels set at issue creation.

**GitHub**

- That a workflow with no `schedule` trigger is never disabled for inactivity. This is inferred from the docs' wording "scheduled workflows", and the whole 60-day design rests on it.
- Which events count as repository activity beyond a commit to the default branch, and whether the studio app's pushes count.
- Who receives GitHub's warning email before schedules are disabled.
- Whether public-repo artifact storage is free, which the coverage artifact uses.
- That the searches under [Opening the throttle](#searches) return what they say.
- Everything else about GitHub comes from its docs and changelog, read and not run: one pending run per concurrency group, the contexts that let a reusable workflow check out its own commit, and the names of required checks.

**Claude**

- The size of the subscription's five-hour and weekly limits. Anthropic publishes none, so how many runs fit before the human's own sessions suffer shows only in use.
- How the Claude Code GitHub Action exits when a limit is hit mid-run.
- Whether `/usage` works with a setup token. The design assumes a run cannot read remaining usage before it starts, which is why yielding is a switch the human sets.

**Cloudflare and the stack**

- Alchemy v2 is a beta, Cloudflare Email Sending is a public beta, and the Oxlint route for Effect diagnostics is labelled experimental.
- Whether an Effect 4 Worker fits Free's 10 ms CPU cap. Production avoids the question by being on Paid; previews run on Free.
- Whether coverage works for the Worker test inside workerd. It is reported only if it does.
- Timings of the baseline checks on a GitHub-hosted runner, and install time. Each gate took under 5 seconds on a laptop.
- The registrar's price, which comes from a third-party tracker.
- That Cloudflare's registrar renews a domain automatically by default.

**The booking app**

- That verifying a Google client for sensitive scopes is free, and the sensitivity label of each Calendar scope. The design stays unverified, under 100 users.
- Whether a Cloudflare email to several recipients counts once or per recipient.

## Sources

Every decision, in the order it was made:

1. *Can the Claude 5x subscription power unattended runs?*
2. *What automated checks can a CAFE project enforce?*
3. *How does a CAFE project deploy from CI, and what does Cloudflare cost?*
4. *What does GitHub give a solo studio on public repos?*
5. *Which agent harnesses let a run swap models?*
6. *Create the studio repo and move this map into it*
7. *How swappable must the model be?*
8. *Personal account or organisation, and which identity do runs act as?*
9. *What baseline of automated checks must every project pass?*
10. *Which products fill the orchestrator and runner slots?*
11. *How do deploys work, and on which Cloudflare plan?*
12. *How do shared task definitions reach each project?*
13. *How does the automated review task work?*
14. *Run the candidate gates on a scaffolded CAFE app*
15. *Where do standards live, and how do they accumulate?*
16. *How do the implementer and rework tasks work?*
17. *Should a ratchet task work exception lists down?*
18. *How does the human see the studio's loose ends?*
19. *How do user reports reach the studio, and what does the explore task do?*
20. *How does a project's pinned set get upgraded?*
21. *Which project is the studio proven on first?*
22. *What does the studio cost a month, and in what order are its triggers switched on?*
23. *What did writing the spec leave unsettled?*
