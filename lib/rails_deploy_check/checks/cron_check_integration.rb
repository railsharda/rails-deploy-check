require_relative "cron_check"

module RailsDeployCheck
  module Checks
    module CronCheckIntegration
      SCHEDULE_FILES = %w[
        config/schedule.rb
        config/whenever.rb
        config/cron.rb
      ].freeze

      CRON_GEMS = %w[whenever clockwork rufus-scheduler].freeze

      def self.build(config = {})
        CronCheck.new(
          app_path: config.fetch(:app_path, Dir.pwd),
          schedule_paths: config.fetch(:schedule_paths, nil),
          check_gem: config.fetch(:check_gem, true)
        )
      end

      def self.register(registry)
        registry.register(:cron, method(:build)) if applicable?
      end

      def self.applicable?
        schedule_file_present? || cron_gem_in_lockfile?
      end

      def self.schedule_file_present?
        SCHEDULE_FILES.any? { |f| File.exist?(File.join(Dir.pwd, f)) }
      end

      def self.cron_gem_in_lockfile?
        lockfile = File.join(Dir.pwd, "Gemfile.lock")
        return false unless File.exist?(lockfile)

        content = File.read(lockfile)
        CRON_GEMS.any? { |gem| content.match?(/^\s+#{Regexp.escape(gem)}\s+\(/) }
      end
    end
  end
end
