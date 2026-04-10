# TimezoneCheck

Validates timezone configuration consistency across the Rails application, environment variables, and database settings.

## What It Checks

1. **TZ Environment Variable** — Verifies the `TZ` environment variable is set and optionally enforces UTC.
2. **Rails `config.time_zone`** — Reads `config/application.rb` to confirm an explicit timezone is configured.
3. **Database Timezone** — Inspects `config/database.yml` for any database-level timezone variable settings.

## Options

| Option | Type | Default | Description |
|---|---|---|---|
| `app_path` | String | `Dir.pwd` | Root path of the Rails application |
| `require_utc` | Boolean | `false` | When `true`, errors if timezone is not UTC |

## Usage

```ruby
RailsDeployCheck.configure do |config|
  config.checks = [
    RailsDeployCheck::Checks::TimezoneCheck.new(
      app_path: Rails.root,
      require_utc: true
    )
  ]
end
```

## Result Levels

- **Error** — `require_utc: true` and a non-UTC timezone is detected.
- **Warning** — `TZ` variable is unset, or `config.time_zone` is not explicitly configured.
- **Info** — Timezone values found and reported for visibility.

## Why It Matters

Timezone mismatches between the OS, Rails, and the database can cause subtle bugs with timestamps, scheduled jobs, and log correlation — especially in multi-region deployments or when migrating between environments.
