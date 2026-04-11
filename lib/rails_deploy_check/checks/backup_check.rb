module RailsDeployCheck
  module Checks
    class BackupCheck
      attr_reader :result

      DEFAULT_BACKUP_PATHS = [
        "tmp/backups",
        "backups",
        "db/backups"
      ].freeze

      BACKUP_CONFIG_FILES = [
        "config/backup.rb",
        "config/initializers/backup.rb",
        ".backuprc"
      ].freeze

      def initialize(app_path: Dir.pwd, backup_paths: nil, require_config: true)
        @app_path = app_path
        @backup_paths = backup_paths || DEFAULT_BACKUP_PATHS
        @require_config = require_config
        @result = Result.new("Backup")
      end

      def run
        check_backup_config_exists
        check_backup_directory_exists
        check_backup_directory_writable
        result
      end

      private

      def check_backup_config_exists
        if @require_config
          found = BACKUP_CONFIG_FILES.any? do |config|
            File.exist?(File.join(@app_path, config))
          end

          if found
            result.add_info("Backup configuration file found")
          else
            result.add_warning(
              "No backup configuration file found. " \
              "Expected one of: #{BACKUP_CONFIG_FILES.join(', ')}"
            )
          end
        else
          result.add_info("Backup config check skipped (require_config: false)")
        end
      end

      def check_backup_directory_exists
        found_path = @backup_paths.find do |path|
          File.directory?(File.join(@app_path, path))
        end

        if found_path
          @backup_dir = File.join(@app_path, found_path)
          result.add_info("Backup directory found: #{found_path}")
        else
          result.add_warning(
            "No backup directory found. " \
            "Checked: #{@backup_paths.join(', ')}"
          )
        end
      end

      def check_backup_directory_writable
        return unless @backup_dir

        if File.writable?(@backup_dir)
          result.add_info("Backup directory is writable")
        else
          result.add_error("Backup directory is not writable: #{@backup_dir}")
        end
      end
    end
  end
end
