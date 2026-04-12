# RackTimeoutCheck

Validates that rack-timeout is properly configured to prevent hung requests in production.

## What it checks

- **Gem presence**: Verifies `rack-timeout` is listed in `Gemfile.lock`
- **Initializer**: Looks for a timeout initializer in `config/initializers/`
- **Timeout values**: Validates `RACK_TIMEOUT_SERVICE_TIMEOUT` and `RACK_TIMEOUT_WAIT_TIMEOUT` environment variables

## Configuration

```ruby
RailsDeployCheck.configure do |config|
  config.checks << RailsDeployCheck::Checks::RackTimeoutCheck.new(
    app_path: Rails.root,
    warn_timeout: 5,
    service_timeout: 15
  )
end
```

## Options

| Option | Default | Description |
|--------|---------|-------------|
| `app_path` | `Dir.pwd` | Path to the Rails application root |
| `warn_timeout` | `5` | Minimum acceptable service timeout in seconds |
| `service_timeout` | `15` | Expected maximum service timeout in seconds |

## Environment Variables

- `RACK_TIMEOUT_SERVICE_TIMEOUT` — Maximum time (seconds) a request can be processed
- `RACK_TIMEOUT_WAIT_TIMEOUT` — Maximum time (seconds) a request can wait in the queue

## Severity

- **Error**: Invalid timeout value (zero or negative)
- **Warning**: Missing gem, missing initializer, or misconfigured timeout relationship
- **Info**: All settings look correct
