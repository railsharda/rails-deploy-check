# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    class FilePermissionsCheck
      SENSITIVE_FILES = [
        "config/database.yml",
        "config/secrets.yml",
        "config/credentials.yml.enc",
        ".env",
        "config/master.key",
        "config/application.yml"
      ].freeze

      WRITABLE_DIRS = [
        "tmp",
        "log",
        "public/uploads"
      ].freeze

      def initialize(app_path: Dir.pwd, result: Result.new)
        @app_path = app_path
        @result = result
      end

      def run
        check_sensitive_files_not_world_readable
        check_writable_directories
        @result
      end

      private

      def check_sensitive_files_not_world_readable
        SENSITIVE_FILES.each do |relative_path|
          full_path = File.join(@app_path, relative_path)
          next unless File.exist?(full_path)

          mode = File.stat(full_path).mode
          world_readable = (mode & 0o004) != 0
          world_writable = (mode & 0o002) != 0

          if world_writable
            @result.add_error("#{relative_path} is world-writable (mode: #{format('%04o', mode & 0o7777)})")
          elsif world_readable
            @result.add_warning("#{relative_path} is world-readable (mode: #{format('%04o', mode & 0o7777)}); consider restricting to 0600 or 0640")
          else
            @result.add_info("#{relative_path} has safe permissions (mode: #{format('%04o', mode & 0o7777)})")
          end
        end
      end

      def check_writable_directories
        WRITABLE_DIRS.each do |relative_path|
          full_path = File.join(@app_path, relative_path)
          next unless File.exist?(full_path)

          unless File.writable?(full_path)
            @result.add_error("#{relative_path}/ is not writable by the current process")
          else
            @result.add_info("#{relative_path}/ is writable")
          end
        end
      end
    end
  end
end
