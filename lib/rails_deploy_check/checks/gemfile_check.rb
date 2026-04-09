module RailsDeployCheck
  module Checks
    class GemfileCheck
      LOCK_FILE = "Gemfile.lock"
      GEMFILE    = "Gemfile"

      def initialize(options = {})
        @app_path     = options.fetch(:app_path, Dir.pwd)
        @warn_missing_groups = options.fetch(:warn_missing_groups, %w[production])
      end

      def run
        result = Result.new(name: "Gemfile")

        check_gemfile_exists(result)
        check_lockfile_exists(result)
        check_lockfile_up_to_date(result)
        check_required_groups(result)

        result
      end

      private

      def gemfile_path
        File.join(@app_path, GEMFILE)
      end

      def lockfile_path
        File.join(@app_path, LOCK_FILE)
      end

      def check_gemfile_exists(result)
        unless File.exist?(gemfile_path)
          result.add_error("Gemfile not found at #{gemfile_path}")
        end
      end

      def check_lockfile_exists(result)
        unless File.exist?(lockfile_path)
          result.add_error("Gemfile.lock not found — run `bundle install` before deploying")
        end
      end

      def check_lockfile_up_to_date(result)
        return unless File.exist?(gemfile_path) && File.exist?(lockfile_path)

        if File.mtime(gemfile_path) > File.mtime(lockfile_path)
          result.add_warning(
            "Gemfile is newer than Gemfile.lock — consider running `bundle install`"
          )
        end
      end

      def check_required_groups(result)
        return unless File.exist?(lockfile_path)

        lockfile_content = File.read(lockfile_path)

        @warn_missing_groups.each do |group|
          unless lockfile_content.include?(group)
            result.add_warning("Bundle group '#{group}' not found in Gemfile.lock")
          end
        end
      end
    end
  end
end
