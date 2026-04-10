# HealthcheckCheck

Validates that a healthcheck endpoint is defined and optionally reachable.

## What It Checks

1. **Route defined** — Scans `config/routes.rb` for common healthcheck paths
   (`/healthz`, `/health`, `/up`, `/ping`).
2. **Endpoint reachable** — When a `:host` is provided, performs an HTTP GET
   against each candidate path and reports the response code.

## Configuration

| Option       | Default                              | Description                                      |
|--------------|--------------------------------------|--------------------------------------------------|
| `app_root`   | `Dir.pwd`                            | Root of the Rails application                    |
| `host`       | `nil`                                | Hostname to probe (skipped when `nil`)           |
| `port`       | `3000`                               | Port to probe                                    |
| `paths`      | `['/healthz','/health','/up','/ping']` | Paths to look for / probe                      |
| `timeout`    | `5`                                  | HTTP connection/read timeout in seconds          |
| `require_ok` | `false`                              | Treat non-2xx/3xx responses as errors vs warnings|

## Example

```ruby
RailsDeployCheck.configure do |c|
  c.add_check :healthcheck,
    host: "staging.example.com",
    port: 443,
    require_ok: true
end
```

## Severity

- Missing route → **warning**
- Endpoint unreachable → **warning**
- HTTP 5xx (when `require_ok: true`) → **error**
