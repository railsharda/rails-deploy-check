# SecretsCheck

Validates that secrets and credentials are properly configured before deployment.

## What It Checks

### Master Key
- Verifies `RAILS_MASTER_KEY` environment variable is set, OR
- Verifies `config/master.key` file is present on disk
- Reports an error if neither is found (required to decrypt credentials)

### Encrypted Credentials
- Looks for environment-specific credentials: `config/credentials/<env>.yml.enc`
- Falls back to checking `config/credentials.yml.enc`
- Reports a warning if no credentials file is found

### SECRET_KEY_BASE
- Checks for `SECRET_KEY_BASE` environment variable
- Validates it meets a minimum length of 30 characters
- Reports a warning if not set via env (may still be available through credentials)

### .env File Safety
- If a `.env` file exists, verifies it is listed in `.gitignore`
- Warns if `.env` could accidentally be committed to version control

## Options

| Option | Default | Description |
|---|---|---|
| `app_path` | `Dir.pwd` | Root path of the Rails application |
| `rails_env` | `ENV["RAILS_ENV"] \|\| "production"` | Target Rails environment |
| `check_master_key` | `true` | Whether to verify master key presence |

## Example

```ruby
check = RailsDeployCheck::Checks::SecretsCheck.new(
  app_path: "/var/www/myapp",
  rails_env: "production"
)
result = check.run
puts result.summary
```
