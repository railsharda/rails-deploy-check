# GemfileCheck

Validates the presence and consistency of `Gemfile` and `Gemfile.lock` before deployment.

## What It Checks

| Check | Severity | Description |
|-------|----------|-------------|
| Gemfile exists | Error | The `Gemfile` must be present in the application root. |
| Gemfile.lock exists | Error | `Gemfile.lock` must exist; its absence means `bundle install` has never been run. |
| Lock file up to date | Warning | If `Gemfile` is newer than `Gemfile.lock`, the lock file may be stale. |
| Required bundle groups | Warning | Ensures specified bundle groups (default: `production`) appear in `Gemfile.lock`. |

## Usage

```ruby
RailsDeployCheck.configure do |config|
  config.checks = [
    RailsDeployCheck::Checks::GemfileCheck.new(
      app_path: Rails.root,
      warn_missing_groups: %w[production]
    )
  ]
end
```

## Options

| Option | Default | Description |
|--------|---------|-------------|
| `app_path` | `Dir.pwd` | Root directory of the Rails application. |
| `warn_missing_groups` | `["production"]` | Bundle groups that must appear in `Gemfile.lock`. |

## Example Output

```
[GemfileCheck] ERROR   Gemfile.lock not found — run `bundle install` before deploying
[GemfileCheck] WARNING Gemfile is newer than Gemfile.lock — consider running `bundle install`
[GemfileCheck] WARNING Bundle group 'production' not found in Gemfile.lock
```
