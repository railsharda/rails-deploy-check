# NginxCheck

Verifies that nginx is properly installed and configured for deployment.

## What It Checks

- **nginx installed**: Confirms the `nginx` binary is available in `PATH`.
- **Config file exists**: Looks for nginx configuration in standard system paths
  (`/etc/nginx/nginx.conf`, `/etc/nginx/sites-enabled`, `/usr/local/etc/nginx/nginx.conf`).
- **nginx running**: Optionally checks whether an nginx process is currently active using `pgrep`.
- **App-level config**: Looks for an optional `config/nginx.conf` in the Rails app root.

## Configuration

```ruby
RailsDeployCheck.configure do |config|
  config.checks[:nginx] = {
    config_paths: ["/etc/nginx/nginx.conf", "/etc/nginx/sites-enabled"],
    check_running: true,
    app_root: Rails.root.to_s
  }
end
```

## Options

| Option | Default | Description |
|---|---|---|
| `config_paths` | System defaults | Paths to search for nginx config |
| `check_running` | `true` | Whether to verify nginx process is active |
| `app_root` | `Dir.pwd` | Root of the Rails application |

## Severity

All findings from this check are reported as **warnings** or **info** — nginx
not being present is not necessarily a hard failure (some deployments use
alternative reverse proxies).
