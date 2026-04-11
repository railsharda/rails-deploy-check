# PumaCheck

Validates that Puma (the Rails web server) is correctly configured for deployment.

## What It Checks

- **Config file exists** — Looks for `config/puma.rb` or `config/puma/production.rb`
- **Workers configured** — Warns if `workers` directive is missing (single-process mode may not be suitable for production)
- **Threads configured** — Warns if `threads` is not explicitly set
- **Bind/port configured** — Warns if neither `bind` nor `port` is set

## Options

| Option | Default | Description |
|---|---|---|
| `app_path` | `Dir.pwd` | Path to the Rails application root |
| `min_threads` | `1` | Minimum expected thread count (informational) |
| `min_workers` | `1` | Minimum expected worker count (informational) |

## Example

```ruby
RailsDeployCheck.configure do |config|
  config.checks << RailsDeployCheck::Checks::PumaCheck.new(
    app_path: "/var/www/myapp",
    min_workers: 2
  )
end
```

## Auto-registration

`PumaCheckIntegration.register` will automatically include this check if:
- `puma` is present in `Gemfile.lock`, or
- A Puma config file exists at one of the default paths
