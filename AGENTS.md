# Project workflow

- Read `docs/ARCHITECTURE.md`, `docs/DESIGN_SYSTEM.md`, and `docs/PROJECT_CONTEXT.md` before making changes.
- Implement the requested task, update relevant documentation, and provide a short report.
- Commit code changes.
- After every addon update, automatically deploy the current runtime files with `tools/deploy.ps1` to `C:\Users\Public\Documents\Elder Scrolls Online\live\AddOns\OneCrosshair`. The user has authorized this ongoing deployment; do not ask again.
- Verify deployment using the script's file-hash checks. Do not copy development tooling or change other addons or SavedVariables.
- For every release, push the release commits to the configured Git remote. The user has authorized this ongoing release push; do not ask again. If no remote is configured or the push fails, report the blocker explicitly.
- Release changelogs must be brief and written in English.
