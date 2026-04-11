module RailsDeployCheck
  module Checks
    class PermissionsCheck
      WRITABLE_DIRS = %w[tmp log public/assets].freeze
      READABLE_FILES = %w[config/database.yml config/application.rb].freeze

      def initialize(options = {})
        @app_path = options.fetch(:app_path, Dir.pwd)
        @writable_dirs = options.fetch(:writable_dirs, WRITABLE_DIRS)
        @readable_files = options.fetch(:readable_files, READABLE_FILES)
      end

      def run
        result = Result.new(name: "Permissions")

        check_writable_directories(result)
        check_readable_files(result)
        check_executable_binstubs(result)

        result
      end

      private

      def check_writable_directories(result)
        @writable_dirs.each do |dir|
          full_path = File.join(@app_path, dir)
          next unless File.exist?(full_path)

          if File.writable?(full_path)
            result.add_info("Directory is writable: #{dir}")
          else
            result.add_error("Directory is not writable: #{dir} — app may fail to write logs or assets")
          end
        end
      end

      def check_readable_files(result)
        @readable_files.each do |file|
          full_path = File.join(@app_path, file)
          next unless File.exist?(full_path)

          if File.readable?(full_path)
            result.add_info("File is readable: #{file}")
          else
            result.add_error("File is not readable: #{file} — Rails may fail to boot")
          end
        end
      end

      def check_executable_binstubs(result)
        bin_path = File.join(@app_path, "bin")
        return result.add_warning("bin/ directory not found — binstubs may be missing") unless File.directory?(bin_path)

        non_executable = Dir[File.join(bin_path, "*")].reject { |f| File.executable?(f) }

        if non_executable.empty?
          result.add_info("All binstubs in bin/ are executable")
        else
          non_executable.each do |f|
            result.add_warning("Binstub is not executable: bin/#{File.basename(f)} — run chmod +x")
          end
        end
      end
    end
  end
end
