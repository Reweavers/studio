# Organisation secrets and variables

Every secret and variable the studio keeps at the organisation level, all with visibility "All repositories". Set at wiring step 1 by `scripts/wiring-step-1.sh`. Pass secrets to reusable workflows by name, never `secrets: inherit`.

## Secrets

| Name | Holds | Used by |
| --- | --- | --- |
| `STUDIO_APP_PRIVATE_KEY` | The studio app's private key (PEM) | Every task that mints a studio app token |
| `CLAUDE_CODE_OAUTH_TOKEN` | The one-year token from `claude setup-token` | Every task with a model |
| `CLOUDFLARE_PREVIEW_API_TOKEN` | The preview account's account-owned API token | Preview deploys and destroys only |

## Variables

| Name | Holds | Used by |
| --- | --- | --- |
| `STUDIO_APP_CLIENT_ID` | The studio app's Client ID (`client-id` input of `actions/create-github-app-token`) | Every task that mints a studio app token |
| `CLAUDE_CODE_OAUTH_TOKEN_EXPIRES` | Expiry date of `CLAUDE_CODE_OAUTH_TOKEN`, as `YYYY-MM-DD` | The loose-ends task's "Renewals due" count, from 30 days before this date |
| `CLOUDFLARE_PREVIEW_ACCOUNT_ID` | The preview account's ID, passed to Alchemy as `CLOUDFLARE_ACCOUNT_ID` | Preview deploys and destroys |

## Renewing the Claude token

Each year: run `claude setup-token`, set the secret `CLAUDE_CODE_OAUTH_TOKEN` again, then set `CLAUDE_CODE_OAUTH_TOKEN_EXPIRES` to one year from that day.

```sh
gh secret set CLAUDE_CODE_OAUTH_TOKEN --org <org> --visibility all
gh variable set CLAUDE_CODE_OAUTH_TOKEN_EXPIRES --org <org> --visibility all --body YYYY-MM-DD
```

Production Cloudflare tokens are not here: each project keeps its own in its `production` environment.
