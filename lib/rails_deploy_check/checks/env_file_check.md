# EnvFileCheck

Verifies that `.env` files are handled safely and that environment variable documentation is present.

## What It Checks

1. **`.env` not committed** — Detects if a `.env` file exists on disk and verifies it is listed in `.gitignore`. Raises an error if it is missing from `.gitignore`.
2. **Example file present** — Looks for `.env.example`, `.env.sample`, or `.env.template` to ensure developers have a reference for required variables.
3. **Required keys documented** — If `required_keys` are configured, verifies each key appears in the example file.

## Configuration

```ruby
RailsDeployCheck.configure do |config|
  config.checks << RailsDeployCheck::Checks::EnvFileCheck.new(
    app_path: Rails.root.to_s,
    required_keys: %w[DATABASE_URL SECRET_KEY_BASE REDIS_URL],
    warn_if_dotenv_present: true
  )
end
```

## Options

| Option | Default | Description |
|---|---|---|
| `app_path` | `Dir.pwd` | Root path of the Rails application |
| `required_keys` | `[]` | List of env keys that must be in the example file |
| `warn_if_dotenv_present` | `true` | Emit a warning when `.env` exists on disk |

## Severity Levels

- **Error** — `.env` exists but is not in `.gitignore`
- **Warning** — `.env` present on disk; no example file found; required keys missing from example
- **Info** — `.env` absent; example file found; all required keys documented
