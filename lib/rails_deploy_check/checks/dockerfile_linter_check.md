# DockerfileLinterCheck

Lints the project's `Dockerfile` for common security and best-practice issues.

## What it checks

- **No `latest` tag**: Using `FROM image:latest` makes builds non-reproducible.
  A specific version tag (e.g., `ruby:3.3.0-slim`) is recommended.
- **HEALTHCHECK instruction**: Ensures Docker knows how to test that the container is healthy.
- **USER instruction**: Ensures the container does not run as root.
- **No hardcoded secrets**: Detects `ENV` or `ARG` directives whose names suggest
  they hold secrets (e.g., `SECRET_KEY`, `DB_PASSWORD`).
- **Non-root USER**: Warns if `USER root` is explicitly set.

## Configuration

```ruby
RailsDeployCheck.configure do |config|
  config.check_options[:dockerfile_linter] = {
    app_path: Rails.root.to_s,
    dockerfile_path: Rails.root.join("Dockerfile").to_s
  }
end
```

## Severity guide

| Finding | Severity |
|---|---|
| Hardcoded secret in ENV/ARG | Error |
| Missing HEALTHCHECK or USER | Warning |
| `latest` or untagged base image | Warning |
| `USER root` directive | Warning |
