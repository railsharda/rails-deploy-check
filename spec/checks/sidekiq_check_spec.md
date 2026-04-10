# SidekiqCheck Spec Notes

## Test Coverage

The spec covers the following scenarios:

### Gem Availability
- Sidekiq gem present → info message
- Sidekiq gem missing + `require_sidekiq: true` → error
- Sidekiq gem missing + `require_sidekiq: false` → warning

### Config File Detection
- `config/sidekiq.yml` found → info message
- `config/sidekiq.rb` found → info message
- Neither file found → warning

### Redis URL Validation
- Valid `redis://` URL → info message
- Valid `rediss://` (TLS) URL → info message
- Malformed URL → error
- Empty/nil URL → error

### Queue Configuration
- `check_queues` populated → info per queue name
- `check_queues` empty → no queue-related messages

## Mocking Strategy

`sidekiq_available?` is stubbed via `allow(check).to receive(...)` to avoid
requiring the actual gem in the test environment.
