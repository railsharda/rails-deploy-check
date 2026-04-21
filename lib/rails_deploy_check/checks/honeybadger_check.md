# HoneybadgerCheck

Verifies that [Honeybadger](https://www.honeybadger.io/) error monitoring is properly configured for your Rails application before deployment.

## What it checks

- **API Key Present** — Ensures `HONEYBADGER_API_KEY` environment variable is set and non-empty.
- **API Key Format** — Validates the key looks like a valid hex string.
- **Gem in Gemfile.lock** — Confirms the `honeybadger` gem is included in `Gemfile.lock`.
- **Initializer Exists** — Checks for `config/initializers/honeybadger.rb`.

## When it runs

This check is automatically enabled when:
- `HONEYBADGER_API_KEY` is present in the environment, **or**
- `honeybadger` is found in `Gemfile.lock`

## Configuration

```ruby
RailsDeployCheck.configure do |config|
  config.checks[:honeybadger] = {
    api_key: ENV["HONEYBADGER_API_KEY"],
    app_path: Rails.root.to_s
  }
end
```

## Errors

| Severity | Message |
|----------|---------|
| Error    | `HONEYBADGER_API_KEY environment variable is not set` |
| Warning  | `honeybadger gem not found in Gemfile.lock` |
| Warning  | `Honeybadger initializer not found` |
| Warning  | `Honeybadger API key format looks unexpected` |
