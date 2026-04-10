# DockerCheck

Validates Docker-related configuration files to ensure the application is ready for container-based deployments.

## What It Checks

- **Dockerfile presence** — Warns if no `Dockerfile` exists in the project root.
- **Docker Compose file** — Detects `docker-compose.yml`, `docker-compose.yaml`, `compose.yml`, or `compose.yaml`.
- **Production Compose override** — Warns if no `docker-compose.production.yml` or `docker-compose.prod.yml` is present alongside a Compose file.
- **Required services** — When `required_services` is configured, verifies each service is defined in the Compose file.
- **`.dockerignore` / `.env` exclusion** — Warns if `.env` files are not excluded from the Docker build context, which could leak secrets into the image.

## Configuration

```ruby
RailsDeployCheck.configure do |config|
  config.checks[:docker] = {
    app_path: Rails.root,
    required_services: ["web", "redis", "sidekiq"]
  }
end
```

| Option              | Default    | Description                                          |
|---------------------|------------|------------------------------------------------------|
| `app_path`          | `Dir.pwd`  | Root directory of the Rails application              |
| `required_services` | `[]`       | Service names that must appear in the Compose file   |

## Result Levels

| Level   | Condition                                                         |
|---------|-------------------------------------------------------------------|
| `info`  | Dockerfile found, Compose file found, services verified           |
| `warn`  | Missing Dockerfile, no production override, .env not in ignore    |
| `error` | A required service is not defined in the Compose file             |
