# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    class YarnCheck
      attr_reader :result

      def initialize(app_path: Dir.pwd)
        @app_path = app_path
        @result = Result.new("Yarn")
      end

      def run
        check_yarn_lock_exists
        check_package_json_exists
        check_yarn_installed
        check_yarn_lock_in_sync
        result
      end

      private

      def check_yarn_lock_exists
        if File.exist?(yarn_lock_path)
          result.add_info("yarn.lock found")
        else
          result.add_warning("yarn.lock not found — run `yarn install` to generate it")
        end
      end

      def check_package_json_exists
        unless File.exist?(package_json_path)
          result.add_info("package.json not found — skipping Yarn checks")
          return
        end
        result.add_info("package.json found")
      end

      def check_yarn_installed
        output = `yarn --version 2>&1`
        if $?.success?
          result.add_info("Yarn #{output.strip} is installed")
        else
          result.add_warning("Yarn is not installed or not in PATH")
        end
      rescue Errno::ENOENT
        result.add_warning("Yarn executable not found")
      end

      def check_yarn_lock_in_sync
        return unless File.exist?(yarn_lock_path) && File.exist?(package_json_path)

        package_mtime = File.mtime(package_json_path)
        lock_mtime = File.mtime(yarn_lock_path)

        if package_mtime > lock_mtime
          result.add_warning("package.json is newer than yarn.lock — dependencies may be out of sync")
        else
          result.add_info("yarn.lock appears up to date with package.json")
        end
      end

      def yarn_lock_path
        File.join(@app_path, "yarn.lock")
      end

      def package_json_path
        File.join(@app_path, "package.json")
      end
    end
  end
end
