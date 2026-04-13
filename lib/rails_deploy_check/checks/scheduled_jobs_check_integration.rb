# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    module ScheduledJobsCheckIntegration
      class << self
        def build(options = {})
          ScheduledJobsCheck.new(options)
        end

        def register(registry)
          return unless applicable?

          registry.register(:scheduled_jobs, build)
        end

        def applicable?
          schedule_file_present? || whenever_in_lockfile?
        end

        def schedule_file_present?
          File.exist?(File.join(Dir.pwd, "config", "schedule.rb"))
        end

        def whenever_in_lockfile?
          lockfile = File.join(Dir.pwd, "Gemfile.lock")
          return false unless File.exist?(lockfile)

          File.read(lockfile).match?(/^\s+whenever\s+\(/)
        end
      end
    end
  end
end
