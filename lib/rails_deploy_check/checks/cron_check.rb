module RailsDeployCheck
  module Checks
    class CronCheck
      attr_reader :result

      DEFAULT_SCHEDULE_PATHS = [
        "config/schedule.rb",
        "config/whenever.rb",
        "config/cron.rb"
      ].freeze

      KNOWN_CRON_GEMS = %w[whenever clockwork rufus-scheduler].freeze

      def initialize(app_path: Dir.pwd, schedule_paths: nil, check_gem: true)
        @app_path = app_path
        @schedule_paths = schedule_paths || DEFAULT_SCHEDULE_PATHS
        @check_gem = check_gem
        @result = Result.new("Cron / Scheduler")
      end

      def run
        check_schedule_file_exists
        check_cron_gem_in_lockfile if @check_gem
        check_schedule_syntax if schedule_file_path
        result
      end

      private

      def check_schedule_file_exists
        if schedule_file_path
          result.add_info("Schedule file found: #{schedule_file_path}")
        else
          result.add_warning("No schedule file found (checked: #{@schedule_paths.join(', ')})")
        end
      end

      def check_cron_gem_in_lockfile
        lockfile = File.join(@app_path, "Gemfile.lock")
        unless File.exist?(lockfile)
          result.add_warning("Gemfile.lock not found; cannot verify cron gem presence")
          return
        end

        content = File.read(lockfile)
        found = KNOWN_CRON_GEMS.select { |gem| content.match?(/^\s+#{Regexp.escape(gem)}\s+\(/) }

        if found.any?
          result.add_info("Cron/scheduler gem(s) detected in Gemfile.lock: #{found.join(', ')}")
        else
          result.add_info("No known cron gem detected in Gemfile.lock (#{KNOWN_CRON_GEMS.join(', ')})")
        end
      end

      def check_schedule_syntax
        content = File.read(schedule_file_path)
        if content.strip.empty?
          result.add_warning("Schedule file '#{schedule_file_path}' is empty")
        else
          result.add_info("Schedule file '#{schedule_file_path}' is non-empty (#{content.lines.count} lines)")
        end
      end

      def schedule_file_path
        @schedule_file_path ||= @schedule_paths
          .map { |p| File.join(@app_path, p) }
          .find { |p| File.exist?(p) }
      end
    end
  end
end
