# RedisCheck Spec Notes

## Test Strategy

Because `RedisCheck` performs a live network call, all Redis interactions are
stubbed using `instance_double` and `stub_const` to keep the suite fast and
hermetic.

## Stubs Used

- `Redis` class is stubbed via `stub_const` so the spec works even if the
  `redis` gem is not installed in the test environment.
- `Redis::CannotConnectError` and `Redis::ConnectionError` are also stubbed
  as plain `StandardError` subclasses for the same reason.
- `LoadError` is raised by stubbing `require` to simulate a missing gem.

## Coverage

| Scenario                              | Expected outcome        |
|---------------------------------------|-------------------------|
| Gem missing, `required: false`        | Warning                 |
| Gem missing, `required: true`         | Error                   |
| Connection OK                         | Info (ping success)     |
| Connection refused, `required: false` | Warning                 |
| Connection refused, `required: true`  | Error                   |
| URL scheme not redis/rediss           | Error                   |
| Malformed URL                         | Error                   |
| `REDIS_URL` env var present           | Used as URL             |
| No env var                            | Falls back to localhost |
