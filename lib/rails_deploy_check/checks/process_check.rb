module RailsDeployCheck
  module Checks
    class ProcessCheck
      REQUIRED_PROCESSES = %w[web worker].freeze

      def initialize(options = {})
        @app_root = options.fetch(:app_root, Dir.pwd)
        @required_processes = options.fetch(:required_processes, REQUIRED_PROCESSES)
        @procfile_path = options.fetch(:procfile_path, File.join(@app_root, "Procfile"))
      end

      def run
        result = Result.new(name: "Process Check")

        check_procfile_exists(result)
        check_required_process_types(result)
        check_no_duplicate_process_types(result)

        result
      end

      private

      def check_procfile_exists(result)
        if File.exist?(@procfile_path)
          result.add_info("Procfile found at #{@procfile_path}")
        else
          result.add_error("Procfile not found at #{@procfile_path}")
        end
      end

      def check_required_process_types(result)
        return unless File.exist?(@procfile_path)

        defined_types = parse_procfile.keys

        @required_processes.each do |process_type|
          if defined_types.include?(process_type)
            result.add_info("Process type '#{process_type}' is defined in Procfile")
          else
            result.add_warning("Process type '#{process_type}' is not defined in Procfile")
          end
        end
      end

      def check_no_duplicate_process_types(result)
        return unless File.exist?(@procfile_path)

        lines = File.readlines(@procfile_path).map(&:strip).reject { |l| l.empty? || l.start_with?("#") }
        type_names = lines.map { |l| l.split(":").first.strip }
        duplicates = type_names.select { |t| type_names.count(t) > 1 }.uniq

        if duplicates.empty?
          result.add_info("No duplicate process types found in Procfile")
        else
          duplicates.each do |dup|
            result.add_error("Duplicate process type '#{dup}' found in Procfile")
          end
        end
      end

      def parse_procfile
        File.readlines(@procfile_path).each_with_object({}) do |line, hash|
          line = line.strip
          next if line.empty? || line.start_with?("#")

          type, command = line.split(":", 2)
          hash[type.strip] = command&.strip
        end
      end
    end
  end
end
