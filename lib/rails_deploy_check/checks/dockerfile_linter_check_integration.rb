# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    module DockerfileLinterCheckIntegration
      class << self
        def build(options = {})
          DockerfileLinterCheck.new(options)
        end

        def register(registry)
          return unless applicable?

          registry.register(:dockerfile_linter, build)
        end

        def applicable?
          dockerfile_present? || dockerignore_present?
        end

        def dockerfile_present?
          File.exist?(File.join(Dir.pwd, "Dockerfile"))
        end

        def dockerignore_present?
          File.exist?(File.join(Dir.pwd, ".dockerignore"))
        end
      end
    end
  end
end
