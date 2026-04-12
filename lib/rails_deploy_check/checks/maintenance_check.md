# MaintenanceCheck

## Purpose

Verifies that the application is not currently in maintenance mode before deployment proceeds. Deploying while maintenance mode is active can cause confusion or leave the app in an inconsistent state.

## Checks Performed

### 1. Maintenance Lock File
Looks for a `tmp/maintenance.txt` file (or a custom path). If it exists, deployment is blocked with an error.

### 2. Public Maintenance Page
Checks whether `public/maintenance.html` exists. This is a best-practice for user-friendly downtime messaging. Missing file produces a warning.

### 3. MAINTENANCE_MODE Environment Variable
If the `MAINTENANCE_MODE` environment variable is set to `"true"`, deployment is blocked with an error.

## Configuration

```ruby
RailsDeployCheck.configure do |config|
  config.checks << RailsDeployCheck::Checks::MaintenanceCheck.new(
    app_path: Rails.root,
    maintenance_file: Rails.root.join("tmp", "maintenance.txt"),
    check_public_dir: true
  )
end
```

## Options

| Option | Default | Description |
|---|---|---|
| `app_path` | `Dir.pwd` | Root path of the Rails application |
| `maintenance_file` | `tmp/maintenance.txt` | Path to the maintenance lock file |
| `check_public_dir` | `true` | Whether to check for `public/maintenance.html` |

## Exit Conditions

- **Error**: `tmp/maintenance.txt` exists
- **Error**: `MAINTENANCE_MODE=true` in environment
- **Warning**: `public/maintenance.html` is missing
- **Info**: All clear
