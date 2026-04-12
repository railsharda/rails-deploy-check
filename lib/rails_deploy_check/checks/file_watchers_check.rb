# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    class FileWatchersCheck
      KNOWN_WATCHER_GEMS = %w[listen guard spring].freeze
      SPRING_PIDS_DIR = "tmp/spring"
      GUARD_TMP_DIR = "tmp/guard"

      def initialize(app_path: Dir.pwd, lockfile_path: nil)
        @app_path = app_path
        @lockfile_path = lockfile_path || File.join(app_path, "Gemfile.lock")
      end

      def run
        result = Result.new(name: "File Watchers")

        check_no_dev_watchers_in_production(result)
        check_spring_not_running(result)
        check_listen_not_in_production_group(result)

        result
      end

      private

      def check_no_dev_watchers_in_production(result)
        return unless File.exist?(@lockfile_path)

        lockfile_content = File.read(@lockfile_path)
        found = KNOWN_WATCHER_GEMS.select { |gem| lockfile_content.match?(/^    #{gem} \(/) }

        if found.any?
          result.add_warning(
            "Development file watcher gems found in Gemfile.lock: #{found.join(', ')}. " \
            "Ensure these are scoped to :development/:test groups only."
          )
        else
          result.add_info("No unexpected file watcher gems detected in lockfile.")
        end
      end

      def check_spring_not_running(result)
        spring_pid_dir = File.join(@app_path, SPRING_PIDS_DIR)

        if Dir.exist?(spring_pid_dir) && Dir.glob(File.join(spring_pid_dir, "*.pid")).any?
          result.add_warning(
            "Spring PID files found in #{SPRING_PIDS_DIR}. " \
            "Spring may be running — stop it before deploying with `spring stop`."
          )
        else
          result.add_info("No Spring PID files detected.")
        end
      end

      def check_listen_not_in_production_group(result)
        gemfile_path = File.join(@app_path, "Gemfile")
        return unless File.exist?(gemfile_path)

        content = File.read(gemfile_path)

        # Detect if 'listen' gem appears outside of a group :development or :test block
        in_dev_test_group = false
        listen_outside_group = false

        content.each_line do |line|
          if line.match?(/^\s*group\s+.*:(development|test)/)
            in_dev_test_group = true
          elsif line.match?(/^\s*end\s*$/) && in_dev_test_group
            in_dev_test_group = false
          elsif !in_dev_test_group && line.match?(/^\s*gem\s+['"]listen['"]/) && !line.match?(/#/)
            listen_outside_group = true
          end
        end

        if listen_outside_group
          result.add_error(
            "The 'listen' gem appears to be required outside of a :development/:test group. " \
            "This may cause issues in production."
          )
        end
      end
    end
  end
end
