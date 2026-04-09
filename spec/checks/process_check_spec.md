# ProcessCheck Spec Notes

## Overview

Tests for `RailsDeployCheck::Checks::ProcessCheck` cover the following scenarios:

## Test Cases

### Procfile Missing
- Expects an **error** when no Procfile exists in the app root.

### Valid Procfile
- Expects an **info** message confirming Procfile was found.
- Expects **info** messages for each required process type that is present.
- Expects **no errors** or warnings when all required types are defined.

### Missing Required Process Type
- Expects a **warning** for each required process type absent from the Procfile.

### Duplicate Process Types
- Expects an **error** for each process type that appears more than once.

### Custom Required Processes
- Supports overriding the default `["web", "worker"]` list via options.
- Only the specified types are checked for presence.

## Helpers

- `create_file(path, content)` — Writes a file to the temp directory for the test.
- `build_check(options = {})` — Instantiates the check with `app_root` set to the temp dir.
