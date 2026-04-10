# GitCheck

Verifies the Git repository state before deployment to help catch common issues like deploying uncommitted changes or deploying from the wrong branch.

## What It Checks

- **Git repository presence** — Warns if the app directory is not a Git repository.
- **Uncommitted changes** — Warns if there are staged or unstaged changes that haven't been committed.
- **Unpushed commits** — Warns if local commits exist that haven't been pushed to the remote tracking branch.
- **Branch validation** — Optionally verifies the current branch matches an expected deployment branch.

## Configuration

```ruby
RailsDeployCheck.configure do |config|
  config.checks[:git] = {
    expected_branch: "main"  # optional: warn if not on this branch
  }
end
```

### Options

| Option            | Type   | Default  | Description                                      |
|-------------------|--------|----------|--------------------------------------------------|
| `expected_branch` | String | `nil`    | If set, warns when current branch doesn't match  |
| `app_path`        | String | `Dir.pwd`| Path to the root of the Rails application        |

## Result Levels

| Condition                        | Level     |
|----------------------------------|-----------|
| Git not installed                | `:info`   |
| Not a git repository             | `:warning`|
| Uncommitted changes present      | `:warning`|
| Unpushed commits exist           | `:warning`|
| Branch mismatch                  | `:warning`|
| All checks pass                  | `:info`   |

## Notes

- Git must be available in the system `PATH` for this check to run.
- The check will skip gracefully if Git is not installed.
- Unpushed commit detection requires a configured remote tracking branch.
