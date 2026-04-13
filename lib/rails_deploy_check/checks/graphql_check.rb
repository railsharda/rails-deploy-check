# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    class GraphqlCheck
      attr_reader :result

      def initialize(options = {})
        @app_path = options.fetch(:app_path, Dir.pwd)
        @result = Result.new("GraphQL")
      end

      def run
        check_graphql_gem_available
        check_schema_file_exists
        check_graphql_controller_exists
        check_introspection_disabled_in_production
        result
      end

      private

      def check_graphql_gem_available
        lockfile = File.join(@app_path, "Gemfile.lock")
        unless File.exist?(lockfile)
          result.add_warning("Gemfile.lock not found; cannot verify graphql gem")
          return
        end
        content = File.read(lockfile)
        if content.match?(/^\s+graphql\s+\(/)
          result.add_info("graphql gem found in Gemfile.lock")
        else
          result.add_info("graphql gem not detected; skipping GraphQL checks")
        end
      end

      def check_schema_file_exists
        schema_paths = [
          File.join(@app_path, "app", "graphql", "schema.rb"),
          File.join(@app_path, "app", "graphql", "*_schema.rb")
        ]
        found = schema_paths.any? do |pattern|
          Dir.glob(pattern).any?
        end
        if found
          result.add_info("GraphQL schema file found")
        else
          result.add_warning("No GraphQL schema file found in app/graphql/")
        end
      end

      def check_graphql_controller_exists
        controller_path = File.join(@app_path, "app", "controllers", "graphql_controller.rb")
        if File.exist?(controller_path)
          result.add_info("GraphQL controller found")
        else
          result.add_warning("graphql_controller.rb not found in app/controllers/")
        end
      end

      def check_introspection_disabled_in_production
        schema_files = Dir.glob(File.join(@app_path, "app", "graphql", "**", "*.rb"))
        return if schema_files.empty?

        content = schema_files.map { |f| File.read(f) }.join("\n")
        if content.match?(/disable_introspection_entry_points/) ||
           content.match?(/introspection.*false/i)
          result.add_info("GraphQL introspection appears to be restricted")
        else
          result.add_warning(
            "GraphQL introspection may be enabled in production; " \
            "consider disabling with `disable_introspection_entry_points` in your schema"
          )
        end
      end
    end
  end
end
