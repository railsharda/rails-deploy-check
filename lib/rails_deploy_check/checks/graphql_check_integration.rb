# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    module GraphqlCheckIntegration
      class << self
        def build(options = {})
          GraphqlCheck.new(options)
        end

        def register(registry)
          return unless applicable?

          registry.register(:graphql, method(:build))
        end

        def applicable?
          graphql_in_lockfile? || graphql_controller_present?
        end

        def graphql_in_lockfile?
          lockfile = File.join(Dir.pwd, "Gemfile.lock")
          return false unless File.exist?(lockfile)

          File.read(lockfile).match?(/^\s+graphql\s+\(/)
        end

        def graphql_controller_present?
          File.exist?(File.join(Dir.pwd, "app", "controllers", "graphql_controller.rb"))
        end
      end
    end
  end
end
