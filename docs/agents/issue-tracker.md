# Issue tracker: GitHub Issues

Issues for this repo live in GitHub Issues on `Reweavers/studio`. Use `gh` from the repo root; it targets this repo from the `origin` remote.

## Conventions

- One ticket per issue. The title is the ticket's name; the body holds what to build and its acceptance criteria as a task list.
- Triage state is a label, exactly one of the roles in `triage-labels.md`.
- Conversation and recorded results go in issue comments, each a dated line of findings.
- Refer to another ticket as `#N`.

## Blocking

GitHub's native "blocked by" relation is the source of truth; a `**Blocked by:** #N, #N` line in the body mirrors it for readers. A ticket is unblocked when every issue blocking it is closed.

`gh` has no command for the relation, so use the API. It takes the blocking issue's `id` (not its number):

```sh
gh api repos/Reweavers/studio/issues/<N>/dependencies/blocked_by --jq '[.[] | {number, state}]'   # list
id=$(gh api repos/Reweavers/studio/issues/<blocker> --jq .id)
gh api -X POST repos/Reweavers/studio/issues/<N>/dependencies/blocked_by -F issue_id="$id"       # add
```

## When a skill says "publish to the issue tracker"

`gh issue create --title "<name>" --body-file <file> --label <triage label>`, then add each blocking edge.

## When a skill says "fetch the relevant ticket"

`gh issue view <N> --comments`. The user will normally pass the issue number or URL.

## Wayfinding operations

Used by `/wayfinder`. The **map** is one issue; each **child** ticket is a sub-issue of it.

- **Map**: an issue whose body holds the Notes / Decisions-so-far / Fog sections.
- **Child ticket**: an issue with the question in the body and a `Type:` line (`research`/`prototype`/`grilling`/`task`), added to the map with `gh api -X POST repos/Reweavers/studio/issues/<map>/sub_issues -F sub_issue_id=<child id>`.
- **Blocking**: the native relation above.
- **Frontier**: the map's open sub-issues that are unblocked and unassigned; lowest number wins.
- **Claim**: `gh issue edit <N> --add-assignee @me` before any work.
- **Resolve**: comment the answer under an `## Answer` heading, close the issue, then append a context pointer (gist + `#N`) to the map's Decisions-so-far by editing the map's body.
