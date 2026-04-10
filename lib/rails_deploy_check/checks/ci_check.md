# CiCheck

Validates that the deployment is being performed within a proper CI/CD environment and that CI configuration files are present.

## What it checks

- **CI environment detection**: Looks for common CI environment variables (`CI`, `GITHUB_ACTIONS`, `CIRCLECI`, `TRAVIS`, `GITLAB_CI`, `BUILDKITE`, `JENKINS_URL`).
- **CI config file presence**: Scans for known CI configuration files such as `.github/workflows/`, `.circleci/config.yml`, `.travis.yml`, `.gitlab-ci.yml`, and `.buildkite/pipeline.yml`.
- **CI job status** *(optional)*: When `require_ci_passing: true` is set, attempts to read the current job status from environment variables.

## Configuration

```ruby
RailsDeployCheck.configure do |config|
  config.checks[:ci] = {
    app_path: Rails.root,        # Path to the Rails application root
    require_ci: true,            # Fail if not running inside a CI environment
    require_ci_passing: false    # Warn if CI job status cannot be determined
  }
end
```

## Severity levels

| Condition | Severity |
|---|---|
| CI environment detected | Info |
| CI config file found | Info |
| No CI environment (require_ci: false) | Warning |
| No CI config file found | Warning |
| No CI environment (require_ci: true) | Error |
