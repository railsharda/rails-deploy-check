# TwoFactorCheck

Validates that two-factor authentication (2FA) or one-time password (OTP) configuration is properly set up for production deployment.

## What It Checks

1. **2FA Gem Present** — Looks for `devise-two-factor` or `rotp` in `Gemfile.lock`.
2. **OTP Secret Key** — Verifies that one of `OTP_SECRET_KEY`, `ROTP_SECRET`, or `TWO_FACTOR_SECRET` environment variables is set.
3. **OTP Initializer** — Checks for a 2FA-related initializer file under `config/initializers/`.

## Configuration

```ruby
RailsDeployCheck.configure do |config|
  config.checks << RailsDeployCheck::Checks::TwoFactorCheck.new(
    app_path: Rails.root.to_s,
    env: ENV
  )
end
```

## Auto-Registration

The check is automatically registered when any of the following conditions are met:

- `devise-two-factor` or `rotp` is present in `Gemfile.lock`
- An OTP secret environment variable is set
- A 2FA initializer file exists

## Results

| Condition | Severity |
|---|---|
| Gemfile.lock missing | Warning |
| No 2FA gem detected | Info |
| No OTP secret env var | Warning |
| No 2FA initializer found | Warning |
| All checks pass | Info |
