# Branch Protection Setup

This document explains the branch protection rules configured for the `main` branch to ensure code quality and stability.

## Overview

The `main` branch is protected to ensure that all changes go through proper review and automated testing before being merged. This prevents breaking changes from being introduced into production.

## Protection Rules

### Required Status Checks

All pull requests must pass the following checks before merging:

1. **build** - Docker image must build successfully
2. **test** - All automated tests must pass, including:
   - Image structure verification
   - Server startup test
   - RCON connectivity
   - Plugin loading verification (17+ plugins)
   - Server health checks
   - Economy, NPC, and shop plugin tests
   - BlueMap and Multiverse tests
   - Script syntax validation

### Pull Request Requirements

- **Require 1 approving review** - At least one maintainer must approve the PR
- **Dismiss stale reviews** - Approvals are dismissed when new commits are pushed
- **Require conversation resolution** - All review comments must be resolved
- **Require branch up-to-date** - PRs must be rebased on latest main before merging

### Branch Restrictions

- **No force pushes** - Prevents rewriting git history on main
- **No deletions** - Main branch cannot be deleted
- **No direct commits** - All changes must go through pull requests

## Setup Instructions

### Automated Setup (Recommended)

Run the setup script with repository admin access:

```bash
.github/scripts/setup-branch-protection.sh
```

This script uses the GitHub API via `gh` CLI to configure all protection rules automatically.

### Manual Setup

If you prefer to configure protection rules manually:

1. Go to https://github.com/lucasilverentand/lumo-server/settings/branches
2. Click "Add branch protection rule"
3. Enter `main` as the branch name pattern
4. Enable the following options:

   **Status checks:**
   - ✅ Require status checks to pass before merging
   - ✅ Require branches to be up to date before merging
   - Select: `build` and `test`

   **Pull request reviews:**
   - ✅ Require a pull request before merging
   - ✅ Require approvals: 1
   - ✅ Dismiss stale pull request approvals when new commits are pushed

   **Other rules:**
   - ✅ Require conversation resolution before merging
   - ✅ Do not allow bypassing the above settings
   - ❌ Allow force pushes (disabled)
   - ❌ Allow deletions (disabled)

5. Click "Create" or "Save changes"

## Workflow Integration

### Existing Workflows

The repository has the following CI/CD workflows:

#### 1. Build, Test and Push (`build.yml`)
- **Triggers:** Push to main, PRs to main, manual dispatch
- **Jobs:**
  - `build`: Builds Docker image, saves as artifact
  - `test`: Loads image, starts server, validates plugins and functionality
  - `push`: Pushes image to ghcr.io (only on main, not PRs)
- **Required for merge:** Yes (both build and test jobs must pass)

#### 2. Claude Code Review (`claude-code-review.yml`)
- **Triggers:** PR opened or updated
- **Purpose:** Automated code review using Claude
- **Required for merge:** Optional (but recommended to review feedback)

#### 3. Claude Code Assistant (`claude.yml`)
- **Triggers:** Comments mentioning @claude
- **Purpose:** On-demand assistance with issues and PRs
- **Required for merge:** No (helper workflow)

### Pull Request Process

When creating a pull request:

1. **Create feature branch**
   ```bash
   git checkout -b feature/my-feature
   ```

2. **Make changes and commit**
   ```bash
   git add .
   git commit -m "feat: add new feature"
   ```

3. **Push to GitHub**
   ```bash
   git push -u origin feature/my-feature
   ```

4. **Create PR**
   ```bash
   gh pr create --title "Add new feature" --body "Description of changes"
   ```

5. **Wait for checks**
   - Build job must complete successfully
   - Test job must complete successfully
   - Claude Code Review will provide automated feedback

6. **Request review**
   - Tag a maintainer for review
   - Address any feedback from automated or human reviews
   - Resolve all conversations

7. **Merge**
   - Once approved and all checks pass, merge the PR
   - The push workflow will automatically build and publish the new image

## Troubleshooting

### Checks not running

If status checks aren't appearing on your PR:

1. Verify workflows are enabled in repo settings
2. Check that `.github/workflows/build.yml` exists
3. Ensure PR is targeting the `main` branch

### Build or test failures

1. Review the workflow logs in the Actions tab
2. Run tests locally using Docker:
   ```bash
   docker build -t lumo-server:test .
   docker run -e EULA=TRUE -e MEMORY=2G lumo-server:test
   ```
3. Fix issues and push new commits

### Branch protection bypass

Repository administrators can bypass branch protection if absolutely necessary:

1. Go to PR page
2. Use "Merge without waiting for requirements" option
3. **Use sparingly** - only for critical hotfixes or infrastructure issues

## Verifying Protection Status

Check current protection status:

```bash
gh api repos/lucasilverentand/lumo-server/branches/main/protection | jq
```

## References

- [GitHub Branch Protection Documentation](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)
- [GitHub Actions Status Checks](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/collaborating-on-repositories-with-code-quality-features/about-status-checks)
