# SSL Check

Validates the SSL/TLS certificate for a configured host before deployment.

## What It Checks

- **Host configured** — Ensures an SSL host is provided in the configuration.
- **Certificate retrieval** — Attempts to connect and fetch the peer certificate.
- **Certificate expiry** — Warns or errors depending on how soon the certificate expires.
- **Hostname identity** — Verifies the certificate is valid for the configured host.

## Configuration

```ruby
RailsDeployCheck.configure do |config|
  config.ssl_host             = "example.com"  # required
  config.ssl_port             = 443             # default: 443
  config.ssl_timeout          = 5               # seconds, default: 5
  config.ssl_warn_expiry_days = 30              # default: 30
  config.ssl_critical_expiry_days = 7          # default: 7
end
```

## Result Levels

| Condition                              | Level   |
|----------------------------------------|---------|
| No host configured                     | error   |
| Connection refused or timed out        | error   |
| Certificate expired                    | error   |
| Expires within critical threshold      | error   |
| Expires within warning threshold       | warning |
| Hostname mismatch                      | error   |
| Certificate valid and not expiring     | info    |

## Notes

- Uses Ruby's built-in `openssl` and `socket` standard libraries — no extra gems required.
- The check respects the system's default CA certificate store for peer verification.
- Recommended to run this check as part of pre-deployment validation in staging and production environments.
