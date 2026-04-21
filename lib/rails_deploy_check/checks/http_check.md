# HttpCheck

Verifies that the application is reachable over HTTP/HTTPS before or after deployment.

## What It Checks

- That a configured `app_url` is reachable.
- That each specified endpoint returns an HTTP success status (2xx or 3xx).
- Handles timeouts and DNS resolution failures gracefully.

## Configuration

```ruby
RailsDeployCheck.configure do |config|
  config.checks[:http] = {
    app_url:   ENV["APP_URL"],      # Base URL of the application
    timeout:   10,                  # Seconds before a request times out (default: 10)
    endpoints: ["/", "/health"]     # Paths to probe (default: ["/"])
  }
end
```

## Result Levels

| Level   | Condition |
|---------|-----------|
| info    | Endpoint responded with 2xx or 3xx |
| warning | `app_url` not configured |
| error   | Non-success HTTP status, timeout, or DNS failure |

## Notes

- Uses Ruby's built-in `net/http` — no external dependencies required.
- SSL certificate verification follows Ruby's default behaviour; pair with
  `SslCheck` for deeper certificate validation.
- Redirects are treated as success (3xx codes are included in the success range).
- Each endpoint is checked independently; a failure on one does not prevent
  the remaining endpoints from being probed.
