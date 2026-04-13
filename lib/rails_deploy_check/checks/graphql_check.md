# GraphQL Check

Validates GraphQL configuration for production readiness.

## What it checks

- **graphql gem present**: Verifies `graphql` is listed in `Gemfile.lock`
- **Schema file exists**: Looks for a schema definition under `app/graphql/`
- **GraphQL controller**: Checks for `app/controllers/graphql_controller.rb`
- **Introspection disabled**: Warns if introspection is not explicitly disabled, which can expose your API schema to attackers

## Configuration

```ruby
RailsDeployCheck.configure do |config|
  config.checks[:graphql] = {
    app_path: Rails.root.to_s
  }
end
```

## Disabling introspection

In your schema class:

```ruby
class AppSchema < GraphQL::Schema
  # Disable introspection in production
  disable_introspection_entry_points if Rails.env.production?
end
```

## Auto-detection

This check is automatically enabled when:
- `graphql` gem is found in `Gemfile.lock`, or
- `app/controllers/graphql_controller.rb` exists
