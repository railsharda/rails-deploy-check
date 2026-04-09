# RubyVersionCheck

The `RubyVersionCheck` validates that the Ruby version is consistently specified
across your project's version files before deployment.

## What It Checks

1. **`.ruby-version` file presence** — Warns if the `.ruby-version` file is
   missing from the application root. This file is used by version managers
   such as rbenv and rvm to automatically switch Ruby versions.

2. **Gemfile `ruby` directive** — Warns if the `Gemfile` does not include a
   `ruby` version declaration. Bundler uses this to enforce the correct runtime
   version.

3. **Version consistency** — Raises an error if the version declared in
   `.ruby-version` does not match the version in the `Gemfile`. Mismatches can
   cause unexpected behaviour between development, CI, and production
   environments.

## Configuration

No additional configuration is required. The check uses `app_path` (defaulting
to `Dir.pwd`) which is shared with the other checks.

## Example Output

```
[INFO]  .ruby-version file found: 3.2.2
[INFO]  Gemfile contains a ruby version directive
[INFO]  .ruby-version and Gemfile versions are consistent
```

## Fixing Issues

- Add a `.ruby-version` file: `echo '3.2.2' > .ruby-version`
- Add a ruby directive to your Gemfile: `ruby '3.2.2'`
- Ensure both files reference the same version string.
