# RedisCheck

Verifies that Redis is reachable and properly configured before deployment.

## What It Checks

1. **Redis gem availability** — Ensures the `redis` gem is present in the bundle.
2. **URL format** — Validates that `REDIS_URL` (or the configured URL) uses a valid `redis://` or `rediss://` scheme.
3. **Connection** — Attempts a live `PING` to the Redis server within a 2-second timeout.

## Configuration

```ruby
RailsDeployCheck.configure do |config|
  config.checks << RailsDeployCheck::Checks::RedisCheck.new(
    url:      ENV["REDIS_URL"],  # default: redis://localhost:6379
    required: true               # default: false
  )
end
```

### Options

| Option     | Type    | Default                     | Description                                      |
|------------|---------|-----------------------------|--------------------------------------------------|
| `url`      | String  | `ENV["REDIS_URL"]` or `redis://localhost:6379` | Redis connection URL |
| `required` | Boolean | `false`                     | Treat connection failures as errors instead of warnings |

## Severity

- **Error** — Invalid URL format, or connection failure when `required: true`, or Redis gem missing when `required: true`.
- **Warning** — Connection failure when `required: false`, or Redis gem missing when `required: false`.
- **Info** — Gem available and connection succeeded.

## Notes

- Supports both `redis://` (plain) and `rediss://` (TLS) URL schemes.
- The connection attempt uses a 2-second timeout to avoid blocking deploys.
