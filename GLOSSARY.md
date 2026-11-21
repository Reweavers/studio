# Software studio

The design of one person's software studio and the projects it serves. The studio's own vocabulary (task, trigger, run, runner, ticket tracker, ticket source, git host, orchestrator, observability platform) is defined in `.claude/skills/software-studio/SKILL.md`; this glossary holds only the terms that skill does not define.

## Language

**Project**:
One app built for one set of users, living in one repo on the git host. One studio serves many projects.
_Avoid_: product, app (as the name for the unit of work), client

**Harness**:
The agent program a run executes to carry out a task, driving one model: Claude Code, Codex, opencode.
_Avoid_: agent (as the name of the program), CLI, tool, runner (the runner is the machine)

**Swap**:
Moving one task to a model from a different vendor, which changes the task's harness. A change of billing route or of model tier within one vendor is not a swap.
_Avoid_: migration, switch, fallback

**Task definition**:
The instructions that say what a task does, written once and read by the harness on every run. It excludes the wiring.
_Avoid_: prompt (the prompt is only the line that starts a run), workflow, agent config

**Wiring**:
The part of a task that connects its task definition to the services: its trigger, its runner, its secrets and the call to the harness.
_Avoid_: workflow, pipeline, config

**Studio repo**:
The repo where the studio is set up: its shared task definitions and its standards. Separate from every project's repo, and from the repo where the studio is planned.
_Avoid_: home, meta repo, config repo

**Project template**:
The folder in the studio repo a new project is created from, carrying the baseline checks and the thin wiring that calls the studio's tasks. A project owns its copy from then on, except the baseline checks and that wiring, which stay the studio's.
_Avoid_: template repo, starter, boilerplate, scaffold

**Scratch project**:
A project made from the unmodified project template, with no users, that exists only to prove the studio's wiring. Nothing that happens on it counts as evidence for opening the throttle, and it is deleted once a real project is running.
_Avoid_: tracer bullet, throwaway app, test project, canary, sandbox

**Launch**:
The day a project's users start using its production. Before it, nobody but the human has seen the project run.
_Avoid_: go-live, release, ship date

**Dial**:
One setting that keeps the human in the loop or limits what runs may do. The throttle is opened by loosening one dial at a time, on evidence from a real project.
_Avoid_: gate (a gate is a check that blocks), knob, setting, limit

**Clock**:
A trigger that fires on a schedule. Every clock starts switched off, and the human switches it on when its task's turn in the rollout comes.
_Avoid_: cron, timer, schedule (as the name for the trigger)

**Pinned set**:
Every version a project pins exactly: all its dependencies, its lockfile, pnpm and Node. It is upgraded as a whole, never one package at a time. The project template's pinned set leads and each project follows it.
_Avoid_: dependencies (as the name for the set), deps, CAFE set (only the part every project shares), versions

**Baseline checks**:
The automated checks every project must pass on every PR, owned by the studio repo: a project never changes one. A project may add its own checks, and may opt out of a baseline check only through an exemption.
_Avoid_: baseline (alone), gates (as the name for the set), CI, quality bar

**Exception list**:
For one baseline check in one project, the files the check is not yet enforced on. It only ever shrinks: a file leaves it when a change makes the file pass.
_Avoid_: exemptions file, allowlist, ignore list, baseline file

**Exemption**:
A project opting out of one baseline check entirely, with the reason recorded in its repo. Only the human grants one.
_Avoid_: exception (for a whole project), waiver, override

**Studio app**:
The single identity every run acts as on the git host and ticket tracker, distinct from the human, so that a run's changes are attributable and can trigger further runs.
_Avoid_: bot, machine user, service account

**Agent PR**:
A PR the studio app opened for a task, as opposed to one the human opened. Only agent PRs get rework.
_Avoid_: bot PR, studio PR (a PR in the studio repo)

**Loose end**:
Something that waits on the human with nothing to remind them: a draft or PR awaiting the human, a question on an issue, a claim or failure a run left behind, a scheduled run that failed or was switched off, a file the ratchet task skips, a project that has fallen behind the project template, a security alert nobody has acted on, or a renewal coming due.
_Avoid_: orphan, orphan PR

**User report**:
A ticket the human files on a user's behalf, describing what the user saw, without the user's personal details.
_Avoid_: bug report, feedback, complaint

**Explore report**:
The one comment an explore run posts on a ticket: what it found, how it reproduced it if it could, where in the code the cause likely lies, a category, and for an easy call a proposed ticket.
_Avoid_: findings, triage note, analysis

**Preview**:
One PR's own running copy of a project, deployed to the preview account and torn down when the PR closes.
_Avoid_: staging, preview environment, test deploy

**Preview account**:
The one Cloudflare account that holds every project's previews. Nothing in it is production, so a run's change can reach it.
_Avoid_: test account, staging account, dev account

**Production account**:
The one Cloudflare account that holds every project's production, deployed only from main.
_Avoid_: prod (alone), live account

**Finding**:
One point an automated review raises about a PR, with a severity (blocking, suggestion or lesson), why it matters, and a link to the standard or upstream doc behind it, or marked "no standard yet".
_Avoid_: comment, issue, nit, review comment

**Review report**:
The one formal PR review an automated review run posts as the studio app: its findings on the changed lines, and a summary with coverage of the changed lines and which earlier findings are fixed or still standing.
_Avoid_: review (alone), review comment, summary

**Standard**:
One rule for how code in every project is written, kept in the studio repo, with why it matters. A finding links the standard that covers it.
_Avoid_: guideline, convention, best practice, house rule, coding standards (as the name for the set)
