# CronCheck

Validates the presence and basic integrity of cron/scheduler configuration in a Rails application.

## What It Checks

- **Schedule file presence** — Looks for `config/schedule.rb`, `config/whenever.rb`, or `config/cron.rb`.
- **Cron gem in Gemfile.lock** — Detects known scheduler gems (`whenever`, `clockwork`, `rufus-scheduler`).
- **Schedule file non-empty** — Warns if a schedule file exists but contains no content.

## Configuration Options

| Option | Type | Default | Description |
|---|---|---|---|
| `app_path` | String | `Dir.pwd` | Root path of the Rails application |
| `schedule_paths` | Array | `DEFAULT_SCHEDULE_PATHS` | Paths to check for schedule files |
| `check_gem` | Boolean | `true` | Whether to check Gemfile.lock for cron gems |

## Example

```ruby
RailsDeployCheck.configure do |config|
  config.checks[:cron] = {
    app_path: Rails.root.to_s,
    schedule_paths: ["config/schedule.rb"],
    check_gem: true
  }
end
```

## Result Levels

- **info** — Schedule file found, gem detected, or file has content.
- **warning** — No schedule file found, Gemfile.lock missing, or schedule file is empty.
- **error** — (none currently; cron config is optional)
