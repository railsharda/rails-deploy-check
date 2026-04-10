# TimezoneCheck Spec Notes

## Overview

The `timezone_check_spec.rb` covers the three sub-checks performed by `TimezoneCheck`:

1. `TZ` environment variable presence and value
2. `config/application.rb` `config.time_zone` directive
3. `config/database.yml` timezone variable block

## Test Strategy

- A temporary directory (`tmp_dir`) is created per example group and torn down with `FileUtils.remove_entry`.
- Environment variable state is preserved using `around` blocks that save and restore `ENV["TZ"]`.
- Config files are written on-demand using the `create_file` helper to isolate each scenario.

## Key Scenarios

| Scenario | Expected Outcome |
|---|---|
| `TZ=UTC` | Info message referencing UTC |
| `TZ` unset | Warning about missing TZ variable |
| `require_utc: true`, `TZ=America/New_York` | Error about UTC requirement |
| `application.rb` sets `time_zone` | Info with configured value |
| `application.rb` missing `time_zone` | Warning about unconfigured timezone |
| `require_utc: true`, `time_zone = "Tokyo"` | Error about UTC requirement |
| `database.yml` has `time_zone` variable | Info about database timezone |

## Notes

- The spec does **not** require a real Rails environment.
- File parsing is done via plain `File.read` and regex, keeping tests fast and dependency-free.
