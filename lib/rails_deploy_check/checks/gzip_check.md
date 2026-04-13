# GzipCheck

Validates that gzip compression is properly configured for your Rails application before deployment.

## What It Checks

1. **Nginx gzip configuration** — Looks for a local `config/nginx.conf` or `config/deploy/nginx.conf` and verifies that `gzip on` is present.
2. **Pre-compressed assets** — Checks that `public/assets/` contains `.gz` files generated during `assets:precompile`.
3. **Rack::Deflater middleware** — Verifies that `Rack::Deflater` is configured in `config/application.rb` or `config/environments/production.rb` as an application-level compression fallback.

## Configuration

```ruby
RailsDeployCheck.configure do |config|
  config.checks << RailsDeployCheck::Checks::GzipCheck.new(
    app_path:     Rails.root,
    check_nginx:  true,
    check_assets: true
  )
end
```

## Options

| Option          | Default      | Description                                        |
|-----------------|--------------|----------------------------------------------------|
| `app_path`      | `Dir.pwd`    | Root path of the Rails application                 |
| `check_nginx`   | auto-detect  | Whether to inspect nginx config files              |
| `check_assets`  | auto-detect  | Whether to check for pre-compressed asset files    |

## Remediation

- Enable `gzip on;` in your nginx server block.
- Run `RAILS_ENV=production bundle exec rake assets:precompile` to generate `.gz` files.
- Add `config.middleware.use Rack::Deflater` to `config/environments/production.rb`.
