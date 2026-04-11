# QueueCheck

Validates Active Job queue adapter configuration for production readiness.

## What It Checks

- **Adapter configured**: Detects the queue adapter from environment variables or `config/application.rb`.
- **Adapter known**: Warns if an unrecognised adapter name is used.
- **Production suitability**: Warns when `async` or `inline` adapters are used, as they are unsuitable for most production workloads.

## Options

| Option | Default | Description |
|---|---|---|
| `app_path` | `Dir.pwd` | Root path of the Rails application |
| `warn_on_async` | `true` | Emit a warning when the `async` adapter is detected |
| `warn_on_inline` | `true` | Emit a warning when the `inline` adapter is detected |

## Detection Sources

1. `QUEUE_ADAPTER` environment variable
2. `ACTIVE_JOB_QUEUE_ADAPTER` environment variable
3. `config.active_job.queue_adapter` in `config/application.rb`

## Example

```ruby
RailsDeployCheck.configure do |config|
  config.checks[:queue] = {
    warn_on_async: true,
    warn_on_inline: true
  }
end
```

## Applicability

This check is automatically registered when:
- `ActiveJob` is defined (i.e. a Rails app with Active Job loaded), **or**
- A known queue gem (`sidekiq`, `resque`, `delayed_job`, `good_job`, `que`) is present in `Gemfile.lock`, **or**
- A queue adapter environment variable is set.
