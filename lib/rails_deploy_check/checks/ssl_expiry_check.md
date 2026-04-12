# SSL Expiry Check

The `SslExpiryCheck` verifies that SSL certificates for a given host are valid and not expiring soon.

## What It Checks

- **Certificate Expiry**: Fetches the SSL certificate for the configured host and checks the expiry date.
- **Warning Threshold**: Warns if the certificate expires within `warning_days` (default: 30 days).
- **Critical Threshold**: Raises an error if the certificate expires within `critical_days` (default: 7 days).

## Configuration

```ruby
RailsDeployCheck.configure do |config|
  config.checks << RailsDeployCheck::Checks::SslExpiryCheck.new(
    host: "example.com",
    warning_days: 30,
    critical_days: 7
  )
end
```

## Environment Variables

| Variable          | Description                            |
|-------------------|----------------------------------------|
| `SSL_EXPIRY_HOST` | Host to check SSL certificate for      |
| `APP_HOST`        | Fallback host if SSL_EXPIRY_HOST unset |

## Auto-Detection

The check is automatically registered when:
- `SSL_EXPIRY_HOST` or `APP_HOST` environment variable is set
- `RAILS_ENV` or `RACK_ENV` is `production`

## Result Levels

| Condition                          | Level   |
|------------------------------------|----------|
| Certificate valid, not expiring    | Info    |
| Expiring within `warning_days`     | Warning |
| Expiring within `critical_days`    | Error   |
| Could not fetch certificate        | Warning |
