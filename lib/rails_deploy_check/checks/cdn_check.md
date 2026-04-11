# CDN Check

## Purpose

Validates that a CDN (Content Delivery Network) is properly configured for
serving static assets in production deployments.

## What It Checks

1. **CDN URL configured** — Looks for `CDN_URL` or `ASSET_HOST` environment
   variables. Warns if neither is set, since assets will be served directly
   from the app server.

2. **CDN URL format** — Ensures the URL starts with `http://` or `https://`
   and does not have a trailing slash that could produce malformed asset paths.

3. **asset_host in Rails config** — Scans
   `config/environments/production.rb` and `config/application.rb` for an
   `asset_host` setting to confirm Rails is wired to use the CDN.

## Configuration

```ruby
RailsDeployCheck.configure do |config|
  config.checks[:cdn] = {
    cdn_url: "https://cdn.example.com"
  }
end
```

## Severity Guide

| Finding | Severity |
|---|---|
| CDN URL missing | Warning |
| CDN URL has invalid format | Error |
| CDN URL has trailing slash | Warning |
| asset_host not in config | Warning |
