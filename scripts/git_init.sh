#!/usr/bin/env bash
# scripts/git_init.sh
# Run this ONCE after cloning/unzipping to initialise the git repo
# and push to GitHub.
#
# Usage:
#   chmod +x scripts/git_init.sh
#   ./scripts/git_init.sh https://github.com/YOUR_USERNAME/tenderpro_ai.git

set -e

REMOTE_URL="${1:-}"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " TenderPro AI — Git Initialisation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 1. Init repo
if [ ! -d ".git" ]; then
  git init
  echo "✔ git repo initialised"
else
  echo "ℹ  git repo already exists — skipping init"
fi

# 2. Set default branch name
git checkout -b main 2>/dev/null || git checkout main

# 3. Stage everything
git add .
git status --short

# 4. Initial commit
git commit -m "feat: initial TenderPro AI project

- Flutter 3.22 app with Provider state management
- AI-powered BOQ extraction via Claude (claude-sonnet-4)
- Screens: Dashboard, Upload Tender, BOQ Editor, Quotation, Projects
- PDF export and sharing
- Android + iOS + Web platform support
- GitHub Actions CI/CD (lint, test, build all platforms)"

echo "✔ initial commit created"

# 5. Add remote and push (only if URL provided)
if [ -n "$REMOTE_URL" ]; then
  git remote add origin "$REMOTE_URL"
  git push -u origin main
  echo "✔ pushed to $REMOTE_URL"
  echo ""
  echo "Next steps:"
  echo "  1. Go to GitHub → Settings → Secrets → Actions"
  echo "  2. Add secret: ANTHROPIC_API_KEY = sk-ant-..."
  echo "  3. GitHub Actions will build APK, iOS & Web automatically"
else
  echo ""
  echo "⚠️  No remote URL provided. To push later:"
  echo "   git remote add origin https://github.com/YOUR_USERNAME/tenderpro_ai.git"
  echo "   git push -u origin main"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Done!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
