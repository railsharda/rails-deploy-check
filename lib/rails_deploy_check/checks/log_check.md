# LogCheck

Validates the Rails application log directory and log files before deployment.

## What It Checks

### Log Directory Existence
Verifies that the `log/` directory exists. If missing, a warning is issued since
Rails will create it automatically, but it may indicate a misconfigured deployment.

### Log File Size
Checks the size of the environment-specific log file (e.g., `log/production.log`):

- **Warning** if the log file exceeds 500 MB
- **Error** if the log file exceeds 1000 MB

Oversized log files can slow down deployment and indicate the log rotation is not configured.

### Log Directory Writability
Ensures the log directory (or its parent if it doesn't exist yet) is writable by
the current process. Without write access, the application will fail to start.

## Configuration Options

| Option | Default | Description |
|---|---|---|
| `app_path` | `Dir.pwd` | Root path of the Rails application |
| `log_dir` | `<app_path>/log` | Path to the log directory |
| `rails_env` | `RAILS_ENV` or `production` | Environment name used to find log file |
| `size_warning_mb` | `500` | MB threshold for warning |
| `size_error_mb` | `1000` | MB threshold for error |

## Example

```ruby
check = RailsDeployCheck::Checks::LogCheck.new(
  app_path: "/var/www/myapp",
  size_warning_mb: 200
)
result = check.run
```
