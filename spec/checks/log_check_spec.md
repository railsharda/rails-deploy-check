# LogCheck Spec Notes

## Test Coverage

The spec covers the following scenarios for `RailsDeployCheck::Checks::LogCheck`:

### Directory Checks
- **Missing log directory** — expects a warning (not an error), since Rails creates it automatically
- **Existing log directory** — expects an informational message confirming presence

### Log File Size
- **Acceptable size** — info message when file is below warning threshold
- **Warning threshold exceeded** — uses `size_warning_mb: 0` to force a warning on any file
- **Error threshold exceeded** — uses `size_error_mb: 0` to force an error on any file

### Writability
- **Non-writable directory** — chmod 0555 before the test, restored after; expects an error

### Default Options
- Confirms `RAILS_ENV` environment variable is respected
- Confirms fallback to `"production"` when `RAILS_ENV` is absent

## Notes

- All tests use a `Dir.mktmpdir` temporary directory cleaned up in `after` hooks.
- Size threshold tests rely on injecting custom `size_warning_mb` / `size_error_mb` values
  rather than writing gigabytes of data to disk.
