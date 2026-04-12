# Rate Limit Check

Validates that rate limiting is configured for your Rails application before deployment.

## What It Checks

- **Rate limiting gem**: Detects presence of `rack-attack`, `rack-throttle`, or `rack-shield`
- **Throttle initializer**: Verifies a rate limiting initializer exists in `config/initializers/`
- **Redis backend**: Warns if `rack-attack` is present but no `REDIS_URL` is configured

## Why It Matters

Without rate limiting, your application is vulnerable to:
- Brute force login attacks
- Credential stuffing
- API abuse and scraping
- Denial-of-service via excessive requests

## Configuration

```ruby
RailsDeployCheck.configure do |config|
  config.checks[:rate_limit] = {
    app_path: Rails.root.to_s,
    check_throttle_config: true
  }
end
```

## Fixing Warnings

### No rate limiting gem
Add `gem 'rack-attack'` to your Gemfile and run `bundle install`.

### Missing initializer
Create `config/initializers/rack_attack.rb`:

```ruby
Rack::Attack.throttle('requests by ip', limit: 300, period: 5.minutes) do |req|
  req.ip
end
```

### No Redis backend
Set the `REDIS_URL` environment variable to share throttle state across processes:

```
REDIS_URL=redis://localhost:6379/0
```
