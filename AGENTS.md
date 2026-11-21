## Agent skills

### Issue tracker

Issues live in GitHub Issues on `Reweavers/studio`, worked with `gh`; blocking uses GitHub's native "blocked by" relation. See `docs/agents/issue-tracker.md`.

### Triage labels

Default vocabulary: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`, applied as GitHub labels. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: one `GLOSSARY.md` and `docs/adr/` at the repo root. See `docs/agents/domain.md`.

## The studio

- The design is `docs/spec.md`; each ticket links the sections it builds on.
- Changing `template/`: run `scripts/template-faults.sh`. A new or changed gate in `template/scripts/check.sh` gets a `fault_<gate>` there.

## Preferences

Don't use the "Co-Authored-By" line for commits
