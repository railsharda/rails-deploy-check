# NewrelicCheck

Validates New Relic APM integration configuration for production deployments.

## What it checks

- **Gem presence**: Verifies `newrelic_rpm` is listed in `Gemfile.lock`
- **License key**: Ensures `NEW_RELIC_LICENSE_KEY` is set and has the expected length
- **App name**: Warns if `NEW_RELIC_APP_NAME` is not configured
- **Config file**: Checks for the presence of `config/newrelic.yml`

## Configuration

```ruby
RailsDeployCheck.configure do |config|
  config.checks[:newrelic] = {
    app_root: Rails.root,
    new_relic_license_key: ENV["NEW_RELIC_LICENSE_KEY"],
    new_relic_app_name: ENV["NEW_RELIC_APP_NAME"]
  }
end
```

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `NEW_RELIC_LICENSE_KEY` | Yes (if gem present) | New Relic account license key |
| `NEW_RELIC_APP_NAME` | Recommended | Application name shown in New Relic UI |

## Auto-detection

This check is automatically enabled when:
- `newrelic_rpm` is found in `Gemfile.lock`, **or**
- `NEW_RELIC_LICENSE_KEY` environment variable is set

## Notes

- If `newrelic_rpm` is not in the lockfile, all checks are skipped with an info message
- A license key shorter than 32 characters triggers a warning (standard keys are 40 chars)
- Missing `config/newrelic.yml` is a warning, not an error — New Relic can be configured entirely via environment variables
