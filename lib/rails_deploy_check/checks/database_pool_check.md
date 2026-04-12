# DatabasePoolCheck

Validates the ActiveRecord database connection pool configuration in `config/database.yml`.

## What It Checks

- **database.yml exists**: Ensures `config/database.yml` is present in the app root.
- **Pool size configured**: Warns if no explicit `pool` setting is found (Rails defaults to 5).
- **Pool size reasonable**: Warns if the pool size is below the minimum (default: 2) or above the maximum (default: 100).
- **Adapter recognized**: Warns if the database adapter is not one of the known types (`postgresql`, `mysql2`, `sqlite3`, `trilogy`).

## Configuration

```ruby
RailsDeployCheck.configure do |config|
  config.checks[:database_pool] = {
    app_path: Rails.root.to_s,
    min_pool_size: 2,
    max_pool_size: 100
  }
end
```

## Why It Matters

An undersized connection pool causes `ActiveRecord::ConnectionTimeoutError` under load.
An oversized pool can exhaust database server connection limits, causing failures for all
connected applications.

## Applicability

This check runs automatically when `config/database.yml` is present or when `activerecord`
is detected in `Gemfile.lock`.
