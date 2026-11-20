# Volunteer onboarding

Use this guide to prepare a local checkout and make a first contribution. You can
complete the local checks below without an AWS account or AWS credentials.

## 1. Complete the team introduction

Follow the [DevSecOps wiki's getting-started instructions](https://github.com/saayam-for-all/devsecops/wiki)
for the current reading order, onboarding tracking, and team coordination. The wiki
links to the project overview, architecture, and access request process. Follow its
instructions for the shared onboarding issue; do not close it for other volunteers.

Use the [DevSecOps Dashboard](https://github.com/saayam-for-all/devsecops/wiki/DevSecOps-Dashboard)
to find repository support assignments. The wiki remains the source for team
processes; this guide covers the local contribution steps.

## 2. Prepare your tools

| Tool | When you need it | Verification |
| --- | --- | --- |
| Git | Cloning, branches, and reviewing changes | `git --version` |
| GitHub account and a text editor | Reviewing issues, editing files, and opening a PR | Sign in to GitHub and open a Markdown file in your editor |
| Python 3 | Optional syntax check for Python scripts below | `python3 --version` |
| GitHub CLI | Optional alternative to the GitHub website | `gh --version`, then `gh auth status` |

Install missing tools using the official [Git](https://git-scm.com/downloads),
[Python](https://www.python.org/downloads/), or [GitHub CLI](https://cli.github.com/)
instructions. These are verification commands, not installation commands.

The shell examples use Bash on Linux, macOS, or Windows Subsystem for Linux (WSL).
Other shells may need different syntax. If your Python 3 command is `python`, use
that command in place of `python3` after checking `python --version`.

Node.js, browser packages, AWS tools, and cloud credentials are task-specific.
They are not prerequisites for this documentation contribution.

## 3. Choose a contribution with a clear finish

Check the prioritized work linked from the wiki, read the entire issue discussion,
and look for related open PRs before starting. An open issue can contain work that
is already implemented or waiting for review.

For an assigned issue, coordinate a specific remaining contribution with its owners.
Describe the files or behavior you intend to change and how you will verify it.
Examples of work that can be verified locally include:

- Correcting documentation against the current repository contents.
- Improving setup instructions and recording the commands you actually checked.
- Adding regression tests to an existing script when the tests use mocked service
  responses and do not call live AWS APIs.

Check whether the issue also requires deployment, cloud integration, or validation
in a shared environment. Agree who will perform those steps before claiming that
the whole issue is complete. For an umbrella issue such as
[#58](https://github.com/saayam-for-all/devsecops/issues/58), describe the specific
part your PR addresses rather than closing the entire initiative.

## 4. Create a working branch

Follow the fork-based process in [CONTRIBUTING.md](../CONTRIBUTING.md). Fork the
repository on GitHub, then replace `YOUR_GITHUB_USERNAME` in these commands with
your actual username. Run them from the parent folder where you want the checkout.

```bash
git clone https://github.com/YOUR_GITHUB_USERNAME/devsecops.git
cd devsecops
git remote add upstream https://github.com/saayam-for-all/devsecops.git
git fetch upstream
git switch -c docs/YOUR_GITHUB_USERNAME-onboarding upstream/main
```

If you already have a checkout, inspect `git status` and `git remote -v` first.
Keep existing work on its own branch. Add the `upstream` remote only if it does not
already exist, and use a new branch name if that name is already taken.

## 5. Make and verify a small change

For a documentation contribution, edit the agreed Markdown files, preview them in
your editor or on GitHub, and check that local links point to existing files.
Verify external reference links while signed in if they require membership.

Review your changes from the repository root:

```bash
git status --short
git diff --check
git diff --stat
git diff
```

`git diff --check` reports whitespace errors and conflict markers in the diff; it
does not validate commands, Markdown links, or application behavior. Read the diff
and verify the commands relevant to your change separately.

For a Python syntax-only check, the following example parses the existing S3
script without importing it, executing it, or contacting AWS:

```bash
python3 - <<'PY'
import ast
from pathlib import Path

path = Path("s3securitycompliance.py")
ast.parse(path.read_text(encoding="utf-8"), filename=str(path))
print(f"Syntax OK: {path}")
PY
```

This check proves only that the file parses. It does not prove imports, credentials,
API permissions, or compliance behavior work. Some service scripts make AWS calls
at import or startup, so running them with a dry-run flag still requires access.
Use mocked tests for offline behavior checks when the contribution includes them.

Only run commands that are relevant to the change. Documentation changes do not
require installing every dependency in the repository or running scripts against
shared services.

## 6. Open a focused pull request

Stage only the files you reviewed. For example, after editing this guide:

```bash
git add docs/ONBOARDING.md
git diff --cached --check
git diff --cached
git commit -m "docs: improve local onboarding instructions"
git push -u origin HEAD
```

Open a PR from your fork to the branch agreed with the issue owners, normally
`saayam-for-all/devsecops:main` for this guide. Include:

- The onboarding problem and the concrete change.
- A reference such as `Related to #58` for the umbrella initiative.
- The commands and manual checks you performed, with their outcomes.
- Any cloud or integration verification that remains for an authorized teammate.

Do not count a PR as merged or deployed until those steps have actually occurred.

## 7. Request cloud access when the task needs it

Use the access request process linked from the [team wiki](https://github.com/saayam-for-all/devsecops/wiki).
Include the issue URL, service, account/environment, region, resource identifiers
when known, the operations you need, and why you need them. Request the scope
required by the task and confirm the approved authentication method with the team.

Keep credentials out of commits, issue comments, screenshots, and example output.
When blocked, record the missing permission or configuration and the specific
validation it prevents, rather than marking the whole task complete.

## Troubleshooting

| Problem | Next step |
| --- | --- |
| `git` is not found | Install Git, reopen the terminal, and rerun `git --version`. |
| `python3` is not found | Check whether `python` is Python 3, or install Python 3 if your task needs it. Markdown editing does not require Python. |
| `gh` is not found | Use the GitHub website, or install the optional GitHub CLI. |
| `upstream` already exists | Inspect `git remote -v`; reuse it if it points to the organization repository. |
| A branch already exists | Use another descriptive branch name and preserve the existing branch's work. |
| Push or PR creation is denied | Check that you are pushing to your fork and signed in with the intended account. Ask the team about required repository or organization membership. |
| A script reports missing AWS credentials or `AccessDenied` | Use local checks that do not execute AWS calls, then follow the access request process for the task's cloud validation. |
| An issue looks complete but remains open | Read its comments and linked PRs, then confirm the remaining scope with its owners. |

## First-contribution checklist

- [ ] Follow the wiki introduction and identify the relevant issue owners.
- [ ] Agree a small contribution and its verification method.
- [ ] Create a separate branch and make the change.
- [ ] Review the diff, relevant links, and documented commands.
- [ ] Open a PR with the issue reference and actual verification results.
- [ ] Record any remaining access or integration dependency explicitly.
