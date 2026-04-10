# rails-deploy-check

Pre-deployment validation tool for Rails applications that checks migrations, assets, and environment configurations before deploying to production.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rails-deploy-check', group: :development
```

Then execute:

```bash
bundle install
```

## Usage

Run the deployment check before deploying:

```bash
rails deploy:check
```

This will validate:

- **Pending Migrations**: Ensures no unapplied migrations exist
- **Asset Compilation**: Verifies assets can be precompiled without errors
- **Environment Variables**: Checks required ENV vars are set
- **Database Connectivity**: Tests database connection
- **Dependencies**: Validates gem dependencies are met

To run only specific checks, use the `--only` flag:

```bash
rails deploy:check --only migrations,env_vars
```

### Configuration

Create a `.deploy-check.yml` in your Rails root:

```yaml
required_env_vars:
  - DATABASE_URL
  - SECRET_KEY_BASE
  - REDIS_URL

skip_checks:
  - assets  # Skip asset compilation check
```

### CI Integration

Add to your CI pipeline:

```yaml
- name: Pre-deployment validation
  run: bundle exec rails deploy:check
```

## License

This project is licensed under the MIT License.
