#!/bin/bash
# Script to set up branch protection for the main branch
# This ensures PRs are properly checked before merging

set -e

REPO="lucasilverentand/lumo-server"
BRANCH="main"

echo "Setting up branch protection for ${REPO}:${BRANCH}..."

# Branch protection configuration as JSON
# Reference: https://docs.github.com/en/rest/branches/branch-protection
gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "/repos/${REPO}/branches/${BRANCH}/protection" \
  --input - <<'EOF'
{
  "required_status_checks": {
    "strict": true,
    "checks": [
      {
        "context": "build"
      },
      {
        "context": "test"
      }
    ]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": false,
    "required_approving_review_count": 1,
    "require_last_push_approval": false
  },
  "restrictions": null,
  "required_linear_history": false,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "block_creations": false,
  "required_conversation_resolution": true,
  "lock_branch": false,
  "allow_fork_syncing": true
}
EOF

echo ""
echo "✓ Branch protection configured successfully!"
echo ""
echo "Protection rules applied:"
echo "  • Required status checks:"
echo "    - build (must pass)"
echo "    - test (must pass)"
echo "  • Require branches to be up to date before merging"
echo "  • Require 1 approving review"
echo "  • Dismiss stale reviews when new commits are pushed"
echo "  • Require conversation resolution before merging"
echo "  • Prevent force pushes"
echo "  • Prevent branch deletion"
echo ""
echo "You can view/modify these settings at:"
echo "https://github.com/${REPO}/settings/branches"
