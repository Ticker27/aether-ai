#!/bin/sh
# Push to trigger GitHub Actions CI build.
# Debug APK on push to main/develop; Release APK on tag v*.
# Auth comes from the cloned remote URL (token embedded) - never echo it.
set -e
BRANCH="$(git rev-parse --abbrev-ref HEAD)"
echo "Pushing branch '$BRANCH' to origin (triggers CI build)..."
git push origin "$BRANCH"
echo "Done. Watch the Actions tab for the build + artifact."
