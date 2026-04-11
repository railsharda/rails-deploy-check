# StorageCheck

Validates that Active Storage is properly configured for deployment.

## What It Checks

1. **config/storage.yml exists** — Confirms the storage configuration file is present.
2. **Service configured for environment** — Verifies that the environment config sets `config.active_storage.service` and that the referenced service is defined in `storage.yml`.
3. **Migrations installed** — Checks that Active Storage migrations have been generated if `activestorage` is in `Gemfile.lock`.

## Options

| Option | Default | Description |
|--------|---------|-------------|
| `app_path` | `Dir.pwd` | Root path of the Rails application |
| `rails_env` | `ENV["RAILS_ENV"] \|\| "production"` | Target Rails environment |

## Example

```ruby
RailsDeployCheck.configure do |config|
  config.checks << RailsDeployCheck::Checks::StorageCheck.new(
    app_path: "/var/www/myapp",
    rails_env: "production"
  )
end
```

## Severity

- **Error** — Referenced storage service is missing from `storage.yml`.
- **Warning** — `config/storage.yml` not found, service not configured in env file, or migrations missing.
- **Info** — Storage config and service definitions look correct.

## Notes

- If your app does not use Active Storage, this check can be safely skipped by omitting it from your configuration.
- When using a cloud storage service (e.g. S3, GCS, Azure), ensure that the required credentials and environment variables are set separately — this check only validates the structural configuration, not runtime credentials.
