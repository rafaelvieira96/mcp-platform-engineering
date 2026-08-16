---
name: grant-ci-iam-permission
description: >-
  Grants the gh-actions-terraform-plan CI role the minimum IAM permissions
  needed to plan/refresh (and optionally manage) a given AWS resource type
  (e.g. "give the CI role DynamoDB permissions", "extend the plan role for
  SQS", "the workflow needs Lambda read access"). Encodes this repo's
  least-privilege IAM workflow: research the exact AWS provider API calls,
  scope-check with the user, edit github_actions_oidc.tf, plan/apply locally,
  verify independently, then commit on a fresh branch without auto-pushing.
version: 1
---

# Grant CI Role IAM Permission

This repo's CI role, `gh-actions-terraform-plan`, is intentionally least-privilege
and is assumed via GitHub Actions OIDC on `pull_request` in a **public** repo that
accepts PRs from forks (see README Checkpoint 3.4). Every permission it has today
(S3, IAM self-read, SQS) was arrived at the hard way this session — several rounds
of `AccessDenied` because `terraform plan` refreshes *every* resource in state and
each resource's AWS provider `Read()` aborts at the *first* missing permission,
revealing only one gap per CI run. This skill exists so future grants are done in
one pass instead of repeating that whack-a-mole across several round trips.

Follow these steps in order. Do not skip the research step and do not skip the
scope question, even if the request sounds unambiguous.

## 1. Identify the resource

Map the user's request to a specific Terraform AWS provider resource type (e.g.
"DynamoDB" → `aws_dynamodb_table`, "Lambda" → `aws_lambda_function`). If there's
more than one plausible resource type or the user named a service rather than a
specific resource, ask which one.

## 2. Research the exact API calls — do not guess from memory

Use WebSearch (or the terraform MCP server's provider tools) to find the actual
AWS API calls that resource type's `Read()` function makes in the AWS provider,
and the corresponding IAM actions. Prior rounds in this repo got this wrong by
assuming a short "obvious" list (e.g. `GetBucketLocation` alone for S3) and only
discovering the full set — `GetBucketAcl`, `GetBucketCORS`, `GetBucketVersioning`,
etc. — one `AccessDenied` at a time. Search for something like:
`terraform-provider-aws aws_<resource> Read function IAM permissions required`,
and separately confirm the write/CRUD action names if write access is in scope
(step 3). Cite what you find back to the user briefly, the way prior grants in
this repo did.

If the resource has a parent/self-referential dependency (e.g. a role reading its
own attached policies), remember `terraform plan` refreshes that resource too —
check whether the CI role already has the permissions to read *itself* and any
adjacent resources the new one might pull in.

## 3. Always ask read-only vs. write scope — never assume

Ask explicitly, every time, via AskUserQuestion, offering at least:
- **Read-only** — only the actions `Read()`/`plan`/`refresh` need.
- **Read + full CRUD** — read-only plus the create/update/delete actions
  `terraform apply` would need to manage the resource's full lifecycle.
- **Broader/custom** — let the user specify exactly which additional actions.

Do this even if the user's phrasing implies write access, and especially if a
later instruction in the conversation contradicts an earlier explicit constraint
(e.g. "must stay read-only" followed later by "add write permissions") — flag the
contradiction and confirm before proceeding, don't silently comply. This role's
blast radius (fork-PR-assumable, public repo) makes silent scope creep worse here
than in a typical private-repo CI role.

Never include destructive-adjacent write actions (`Purge*`, `Force*`, `*All`) or
service-wide wildcards (`<service>:*`) unless the user explicitly asks for them
by name.

## 4. Scope the Resource ARN — never bare `*`

Default to `arn:aws:<service>:${var.aws_region}:${data.aws_caller_identity.current.account_id}:<name-pattern>`,
using the `mcp-platform-engineering-*` naming prefix this repo's other resources
already use (the state bucket, etc.) — `var.aws_region` and
`data.aws_caller_identity.current` are already defined in the root module
(`vars.tf`, `state_backend.tf`), reference them rather than hardcoding the region
or account ID.

If the actual resource doesn't exist in Terraform yet (this skill is commonly
used to stage IAM ahead of writing the resource, as with SQS), confirm the naming
prefix with the user rather than assuming — and remind them the resource they
eventually write must match the prefix or they'll hit `AccessDenied` again.

## 5. Edit `github_actions_oidc.tf`

Add a new `aws_iam_role_policy` resource on `aws_iam_role.gh_actions_terraform_plan`,
following the file's existing conventions:
- Separate statements (and Sids) for read vs. write, e.g. `Terraform<Resource>ReadOnly`
  / `Terraform<Resource>ReadWrite`.
- A one-line comment above each statement explaining *why* that specific action
  list was chosen (matches the existing `s3_bucket_metadata_read_actions` /
  `terraform_plan_iam_self_read_only` comments in the file).
- If a large action list is likely to be reused (as with the S3 metadata list),
  consider a `locals` entry — otherwise inline is fine.

Run `terraform fmt <file>` and `terraform validate` after editing.

## 6. Plan, confirm, apply, verify — do not skip any of these

1. `terraform plan` — show the user the exact diff (resource count added/changed,
   the literal action list) before doing anything further.
2. Get explicit confirmation before `terraform apply`, unless the user has already
   pre-authorized the apply step in the same message (e.g. gave a numbered
   instruction set that included "apply using local admin credentials").
3. `terraform apply` using local AWS credentials.
4. Verify independently of Terraform state: `aws iam get-role-policy --role-name
   gh-actions-terraform-plan --policy-name <name>` and
   `aws iam list-role-policies --role-name gh-actions-terraform-plan`.

## 7. Git workflow — check branch staleness first

This repo's PRs merge immediately on approval (observed repeatedly this session —
there is effectively no "push, wait for CI, then merge" window). Before
committing:

1. `git fetch origin main` and check whether the current local branch is already
   merged (`git log --oneline origin/main | grep <branch-name>`, or check the PR
   state via the github MCP server). If merged/stale, branch fresh off
   `origin/main` — do not commit onto an already-merged branch.
2. Follow the branch naming convention from `CLAUDE.md` (`feat/`, `fix/`,
   `chore/`, `docs/`, lowercase-hyphenated, no checkpoint numbers).
3. Commit message should note the change was already applied directly to AWS
   (since apply happens locally, ahead of any PR) and what was verified.
4. **Do not push or open a PR automatically.** Ask first, as two separate
   confirmable actions ("commit locally" vs. "push" vs. "open PR") — mirror
   however granularly the user phrases the request; don't bundle steps they
   didn't ask for.

## Out of scope for this skill

- Never create the actual AWS resource (e.g. don't create a DynamoDB table)
  unless explicitly asked — this skill grants IAM ahead of the real resource.
- Never write the corresponding `.tf` resource for the new AWS resource type
  unless explicitly asked — IAM and the resource config are separate requests.
- Never modify `.github/workflows/terraform.yml` unless explicitly asked.
- Never touch account IDs/ARNs in anything that gets committed — reference
  `data.aws_caller_identity.current.account_id`, never a literal value, per
  `CLAUDE.md`'s redaction convention.
