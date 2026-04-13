# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    module DockerfileCheckIntegration
      class << self
        def build(options = {})
          DockerfileCheck.new(
            app_path: options.fetch(:app_path, Dir.pwd),
            required_instructions: options.fetch(:required_instructions, %w[FROM RUN CMD])
          )
        end

        def register(registry)
          return unless applicable?

          registry.register(:dockerfile, -> (opts = {}) { build(opts) })
        end

        def applicable?
          dockerfile_present? || dockercompose_present?
        end

        def dockerfile_present?
          File.exist?(File.join(Dir.pwd, "Dockerfile"))
        end

        def dockercompose_present?
          %w[docker-compose.yml docker-compose.yaml].any? do |f|
            File.exist?(File.join(Dir.pwd, f))
          end
        end
      end
    end
  end
end
