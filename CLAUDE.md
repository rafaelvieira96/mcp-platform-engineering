# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repository is

This is a hands-on lab (in Portuguese, documented entirely in `README.md`) for studying how AI agents interact with DevOps/Infrastructure-as-Code tooling — specifically the difference between an agent calling AWS directly via MCP versus an agent going through Terraform (as an IaC layer) via MCP. It is **not** an application: there is no source code, build system, package manifest, or test suite. The repository currently contains only `README.md` and `pictures/` (screenshots referenced from the README).

Progress is tracked as a series of numbered "Checkpoints" inside `README.md`, grouped into three scenarios:

- **Cenário 1 — AWS MCP direto**: `Claude Code → AWS MCP Server → AWS APIs → AWS`. Completed: connecting the AWS MCP server, read-only queries (e.g. listing VPCs), and a write operation (creating an S3 bucket).
- **Cenário 2 — Terraform MCP**: `Claude Code → Terraform MCP Server → Terraform → AWS Provider → AWS`. In progress. `main.tf`/`vars.tf` now exist and have been applied at least once (an `aws_s3_bucket` with a public-access block and a 10-day expiration lifecycle rule).
- **Cenário 3 — Pipeline** (starting): a `github` MCP server (HTTP, `https://api.githubcopilot.com/mcp/`, auth via `GITHUB_PAT`) is registered at user scope. Next steps involve pushing this repo to GitHub and wiring up GitHub Actions.

Before doing any work here, read `README.md` in full (it's short) to see which checkpoint the lab is currently on — **do not jump ahead** (e.g. do not generate or apply Terraform code while the roadmap still shows Checkpoint 2.4/2.5 unchecked), per the lab's own stated principles below.

## Environment / tooling used in this lab

No build/lint/test commands apply (no code). The tools involved are external CLIs and MCP servers, validated with:

```bash
claude --version      # Claude Code
aws --version          # AWS CLI
terraform version      # Terraform CLI
docker --version       # Docker
aws sts get-caller-identity   # confirms AWS auth
```

- **AWS MCP server**: provides direct AWS API access (`aws-mcp` in `claude mcp list`). Configured via the AWS Agent Toolkit (`aws configure agent-toolkit`), which also installs AWS Agent Skills globally under `~/.claude/skills/` (not part of this repo).
- **Terraform MCP server**: the official HashiCorp Terraform MCP Server, run locally via Docker, registered globally with:
  ```bash
  claude mcp add terraform -s user -t stdio -- docker run -i --rm hashicorp/terraform-mcp-server
  ```
  Its tools are **registry-only and read-only** (search/get for providers, modules, and policies on the Terraform Registry) — it is not a wrapper around `terraform plan/apply/validate`. Actual Terraform execution is a separate concern (the local Terraform CLI against the AWS provider), conceptually split as:
  ```
                     Claude
                       │
              ┌────────┴────────┐
              │                 │
       Terraform MCP       Terraform CLI
              │                 │
              ▼                 ▼
       Terraform Registry   AWS Provider
                                │
                                ▼
                               AWS
  ```
- If `aws-mcp` shows as disconnected, it's typically a config issue fixable by re-running/repairing the agent-toolkit setup (previously diagnosed by Claude Code itself).
- If Docker commands fail with a permission error on `/var/run/docker.sock` despite the user being in the `docker` group, the running shell session likely predates the group membership — a full logout/login (not just a new shell) is required to pick it up.
- **gitleaks pre-push hook**: `.githooks/pre-push` runs `gitleaks detect` and blocks the push if it finds secrets. It's not active by default on a fresh clone — run `git config core.hooksPath .githooks` once per clone to enable it. Requires the `gitleaks` binary on `PATH` (`sudo apt install gitleaks`).

## Working principles for this lab (from README.md)

1. Don't skip steps — advance checkpoint by checkpoint.
2. Understand the concept before automating it.
3. Prefer read-only operations whenever possible.
4. Keep Agent, MCP, tools, and infrastructure conceptually separate — don't conflate MCP with Terraform or with the AWS API directly.
5. Destructive changes require explicit human supervision.
6. Document discoveries and problems encountered as the lab progresses (i.e. update `README.md`'s checkpoint/roadmap sections when completing steps, matching its existing style).

Real AWS account IDs/ARNs must not be stored in `README.md` (existing entries are redacted with `X`s) — keep this convention if adding new examples.

## GitHub / version control guard-rails

This repo creates real AWS resources and has a `github` MCP server configured with a `GITHUB_PAT`. Before any commit or push:

- Never commit `*.tfstate`, `*.tfstate.*`, `.terraform/`, lock files, or `*.tfvars` — all already covered by `.gitignore`. If you add a new file type that can hold generated/secret values (e.g. a new `.tfvars` variant, a state backup, provider credentials), add it to `.gitignore` before it's ever staged, not after.
- Never hardcode `GITHUB_PAT`, AWS credentials, or any other secret in `.tf`, `.tfvars`, scripts, or docs. Secrets live only in the shell environment or in user-scope MCP config (`claude mcp add-json ... --scope user`) — never in-repo.
- Real AWS account IDs/ARNs must never appear in any committed file, not just `README.md` (same redaction convention as above, applies repo-wide).
- Run `git status` and `git diff --staged` before every commit — check nothing above slipped in, especially since this lab actively creates billable AWS resources.

### Branch naming convention

Use `<type>/<short-description>`:

- `feat/` — new capability or checkpoint (e.g. `feat/terraform-s3-bucket`)
- `fix/` — correcting a mistake in existing config or docs
- `chore/` — tooling/config housekeeping (e.g. `chore/gitignore-tfstate`)
- `docs/` — README/CLAUDE.md-only changes

Lowercase, hyphen-separated description, no checkpoint numbers in the branch name (checkpoint numbers belong in `README.md`, not git history).