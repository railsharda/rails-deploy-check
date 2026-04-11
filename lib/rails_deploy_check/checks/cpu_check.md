# CPU Check

The `CpuCheck` validates that the server's CPU usage is within acceptable limits before deployment.

## What It Checks

- **CPU Load**: Measures current CPU usage percentage and compares it against configurable thresholds.
- **CPU Count**: Reports the number of available CPU cores and warns if fewer than 2 cores are available.

## Configuration Options

| Option | Default | Description |
|--------|---------|-------------|
| `warning_threshold` | `80.0` | CPU usage % that triggers a warning |
| `critical_threshold` | `95.0` | CPU usage % that triggers an error |
| `app_path` | `Dir.pwd` | Path to the application root |

## Example Usage

```ruby
RailsDeployCheck.configure do |config|
  config.checks[:cpu] = {
    warning_threshold: 75.0,
    critical_threshold: 90.0
  }
end
```

## Platform Support

- **Linux**: Uses `top -bn1` to read CPU idle time.
- **macOS**: Uses `top -l1 -n0` to read CPU idle time.
- **Other**: Emits a warning that CPU usage could not be determined.

## Result Messages

- **Error**: CPU usage is critically high (>= critical threshold)
- **Warning**: CPU usage is elevated (>= warning threshold), or only 1 CPU core detected
- **Info**: CPU usage and core count when within normal range
