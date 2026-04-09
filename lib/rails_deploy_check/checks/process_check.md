# ProcessCheck

Validates the presence and correctness of a `Procfile` before deployment.

## What It Checks

- **Procfile exists** — Ensures a `Procfile` is present at the application root.
- **Required process types** — Verifies that expected process types (e.g., `web`, `worker`) are defined.
- **No duplicate process types** — Detects duplicate entries that could cause ambiguous process startup.

## Configuration Options

| Option | Default | Description |
|---|---|---|
| `app_root` | `Dir.pwd` | Root directory of the Rails application |
| `required_processes` | `["web", "worker"]` | List of process type names that must be present |
| `procfile_path` | `<app_root>/Procfile` | Explicit path to the Procfile |

## Example Usage

```ruby
RailsDeployCheck.configure do |config|
  config.checks = [
    RailsDeployCheck::Checks::ProcessCheck.new(
      app_root: Rails.root,
      required_processes: %w[web worker clock]
    )
  ]
end
```

## Severity Levels

- **Error** — Procfile missing, or duplicate process types detected.
- **Warning** — A required process type is not defined in the Procfile.
- **Info** — Procfile found; each required process type confirmed present.
