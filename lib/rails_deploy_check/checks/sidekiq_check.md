# SidekiqCheck

Validates that Sidekiq background job processing is properly configured for deployment.

## What It Checks

- **Sidekiq gem availability** — Confirms the `sidekiq` gem is present in the bundle
- **Sidekiq config file** — Looks for `config/sidekiq.yml` or `config/sidekiq.rb`
- **Redis URL** — Validates that `REDIS_URL` is set and has a valid Redis URI format
- **Queue configuration** — Optionally verifies expected queue names are configured

## Options

| Option | Type | Default | Description |
|---|---|---|---|
| `redis_url` | String | `ENV['REDIS_URL']` | Redis connection URL |
| `require_sidekiq` | Boolean | `true` | Treat missing gem as error vs warning |
| `check_queues` | Array | `[]` | List of expected queue names |
| `app_path` | String | `Dir.pwd` | Path to the Rails application root |

## Example

```ruby
RailsDeployCheck.configure do |config|
  config.checks << RailsDeployCheck::Checks::SidekiqCheck.new(
    redis_url: ENV["REDIS_URL"],
    require_sidekiq: true,
    check_queues: ["default", "mailers", "critical"]
  )
end
```

## Notes

- If `require_sidekiq` is `false`, a missing gem produces a warning instead of an error
- Redis URL validation checks format only; it does not attempt a live connection (see `RedisCheck` for that)
- A missing config file produces a warning, not an error, since Sidekiq can run without one
