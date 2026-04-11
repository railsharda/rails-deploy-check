# SmtpCheck

Validates SMTP server configuration and connectivity before deployment.

## What It Checks

- **Host configured**: Ensures `SMTP_HOST` environment variable or `:host` config is set
- **Port validity**: Warns if the configured port is not a commonly used SMTP port (25, 465, 587, 2525)
- **Reachability**: Attempts a TCP connection to the SMTP host/port within a configurable timeout
- **Auth credentials**: Warns if `SMTP_USERNAME` or `SMTP_PASSWORD` are missing (when `require_auth: true`)

## Configuration

```ruby
RailsDeployCheck.configure do |config|
  config.checks[:smtp] = {
    host: "smtp.example.com",
    port: 587,
    username: "user@example.com",
    timeout: 5,
    require_auth: true
  }
end
```

## Environment Variables

| Variable        | Description                        |
|-----------------|------------------------------------|
| `SMTP_HOST`     | SMTP server hostname               |
| `SMTP_PORT`     | SMTP server port (default: 587)    |
| `SMTP_USERNAME` | SMTP authentication username       |
| `SMTP_PASSWORD` | SMTP authentication password       |

## Result Levels

- **Error**: Host not configured, server unreachable
- **Warning**: Non-standard port, missing credentials
- **Info**: Successfully verified settings
