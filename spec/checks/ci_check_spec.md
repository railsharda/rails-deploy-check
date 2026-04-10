# CiCheck Spec Notes

## Overview

Tests for `RailsDeployCheck::Checks::CiCheck` cover three main areas:

1. **CI environment variable detection** — verifies that known CI vars like `GITHUB_ACTIONS`, `CIRCLECI`, etc. are detected and reported as info messages.
2. **CI config file presence** — checks that files like `.travis.yml`, `.github/workflows/`, `.circleci/config.yml` are detected in the app path.
3. **Severity escalation** — ensures that missing CI environments produce warnings by default and errors when `require_ci: true`.

## Helpers

- `with_env(vars)` — temporarily sets environment variables for a block.
- `with_clean_env` — strips all known CI env vars for the duration of a block to simulate a non-CI environment.
- `create_file(base, relative, content)` — creates a file at the given path inside the tmp Rails app.

## Notes

- Tests use the `with_tmp_rails_app` helper from `spec_helper.rb` to isolate file system operations.
- Environment variable manipulation is always restored after each test via `ensure` blocks.
