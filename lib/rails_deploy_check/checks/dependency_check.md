# DependencyCheck

Verifies that application dependencies are properly installed and available before deployment.

## What It Checks

- **Gemfile exists** — Ensures a `Gemfile` is present in the Rails root
- **Bundler available** — Confirms the `bundler` gem is installed and executable
- **Gems installed** — Runs `bundle check` to verify all gems are satisfied
- **Native extensions** — Warns if gems with native extensions are present, reminding you to ensure build tools are available

## Configuration

```ruby
RailsDeployCheck.configure do |config|
  config.checks[:dependency] = {
    rails_root: "/path/to/app"  # defaults to Dir.pwd
  }
end
```

## Severity Levels

| Condition | Severity |
|---|---|
| Gemfile missing | Error |
| Bundler not found | Error |
| Gems not installed | Error |
| Gemfile.lock missing | Warning |
| Native extensions present | Info |

## Notes

- Requires `bundle check` to be runnable in the deployment environment
- Native extension detection is heuristic-based using a known list of common gems
