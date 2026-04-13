# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    class ScheduledJobsCheck
      def initialize(options = {})
        @app_path = options[:app_path] || Dir.pwd
        @expected_jobs = options[:expected_jobs] || []
      end

      def run
        result = Result.new(name: "Scheduled Jobs")

        check_whenever_or_cron_configured(result)
        check_schedule_file_valid(result)
        check_expected_jobs_present(result)

        result
      end

      private

      def check_whenever_or_cron_configured(result)
        has_whenever = gem_in_lockfile?("whenever")
        has_cron = File.exist?(schedule_file_path)

        if !has_whenever && !has_cron
          result.add_warning("No scheduled job configuration found (whenever gem or schedule.rb missing)")
        elsif has_whenever
          result.add_info("whenever gem detected for cron job management")
        end
      end

      def check_schedule_file_valid(result)
        return unless File.exist?(schedule_file_path)

        content = File.read(schedule_file_path)

        if content.strip.empty?
          result.add_warning("config/schedule.rb exists but is empty")
          return
        end

        if content.match?(/every\s+[\d:]+.*do/m)
          result.add_info("config/schedule.rb contains job definitions")
        else
          result.add_warning("config/schedule.rb may not contain valid whenever job definitions")
        end
      end

      def check_expected_jobs_present(result)
        return if @expected_jobs.empty?
        return unless File.exist?(schedule_file_path)

        content = File.read(schedule_file_path)
        missing = @expected_jobs.reject { |job| content.include?(job) }

        if missing.any?
          result.add_error("Expected scheduled jobs not found in schedule.rb: #{missing.join(', ')}")
        else
          result.add_info("All expected scheduled jobs are present")
        end
      end

      def schedule_file_path
        File.join(@app_path, "config", "schedule.rb")
      end

      def lockfile_path
        File.join(@app_path, "Gemfile.lock")
      end

      def gem_in_lockfile?(gem_name)
        return false unless File.exist?(lockfile_path)

        File.read(lockfile_path).match?(/^\s+#{Regexp.escape(gem_name)}\s+\(/)
      end
    end
  end
end
