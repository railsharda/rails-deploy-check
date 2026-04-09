# BundlerAuditCheck

Checks your application's gem dependencies for known security vulnerabilities using the `bundler-audit` gem.

## What It Checks

- Whether `bundler-audit` is installed on the system
- Whether `Gemfile.lock` exists (required for auditing)
- Whether any gems have known CVE advisories or unpatched vulnerabilities

## Options

| Option | Type | Default | Description |
|---|---|---|---|
| `app_path` | String | `Dir.pwd` | Root path of the Rails application |
| `fail_on_warnings` | Boolean | `false` | Treat vulnerability warnings as hard errors |

## Usage

```ruby
RailsDeployCheck.configure do |config|
  config.checks << RailsDeployCheck::Checks::BundlerAuditCheck.new(
    app_path: Rails.root,
    fail_on_warnings: true
  )
end
```

## Requirements

The `bundler-audit` gem must be installed:

```bash
gem install bundler-audit
```

Or add it to your Gemfile (development/test group is sufficient for CI):

```ruby
gem 'bundler-audit', require: false
```

## Behavior

- If `bundler-audit` is **not installed**, a **warning** is added and the check is skipped gracefully.
- If `Gemfile.lock` is **missing**, an **error** is added.
- If vulnerabilities are found and `fail_on_warnings` is `false` (default), a **warning** is added.
- If vulnerabilities are found and `fail_on_warnings` is `true`, an **error** is added.
- The advisory database is updated automatically before each scan (`--update` flag).
