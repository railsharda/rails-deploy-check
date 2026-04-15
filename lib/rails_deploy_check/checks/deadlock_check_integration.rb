# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    module DeadlockCheckIntegration
      class << self
        def build(options = {})
          DeadlockCheck.new(options)
        end

        def register(registry)
          return unless applicable?

          registry.register(:deadlock, build)
        end

        def applicable?
          database_yml_present? || active_record_present?
        end

        def database_yml_present?
          File.exist?(File.join(Dir.pwd, "config", "database.yml"))
        end

        def active_record_present?
          return false unless File.exist?(File.join(Dir.pwd, "Gemfile.lock"))

          File.read(File.join(Dir.pwd, "Gemfile.lock")).include?("activerecord")
        end
      end
    end
  end
end
