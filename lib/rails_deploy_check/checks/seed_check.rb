module RailsDeployCheck
  module Checks
    class SeedCheck
      def initialize(options = {})
        @app_path = options[:app_path] || Dir.pwd
        @check_seed_file = options.fetch(:check_seed_file, true)
        @check_seed_data = options.fetch(:check_seed_data, false)
        @seed_file_path = options[:seed_file_path] || File.join(@app_path, "db", "seeds.rb")
      end

      def run
        result = Result.new("Seed Check")

        check_seed_file_exists(result) if @check_seed_file
        check_seed_file_not_empty(result) if @check_seed_file
        check_no_destructive_operations(result) if @check_seed_data

        result
      end

      private

      def check_seed_file_exists(result)
        if File.exist?(@seed_file_path)
          result.add_info("Seed file exists at db/seeds.rb")
        else
          result.add_warning("No db/seeds.rb file found — seed data may not be initialized")
        end
      end

      def check_seed_file_not_empty(result)
        return unless File.exist?(@seed_file_path)

        content = File.read(@seed_file_path).strip
        if content.empty?
          result.add_warning("db/seeds.rb is empty — no seed data defined")
        else
          non_comment_lines = content.lines.reject { |l| l.strip.start_with?("#") || l.strip.empty? }
          if non_comment_lines.empty?
            result.add_warning("db/seeds.rb contains only comments — no seed logic found")
          else
            result.add_info("db/seeds.rb contains seed logic (#{non_comment_lines.size} non-comment lines)")
          end
        end
      end

      def check_no_destructive_operations(result)
        return unless File.exist?(@seed_file_path)

        content = File.read(@seed_file_path)
        destructive_patterns = [
          { pattern: /\.delete_all/, label: "delete_all" },
          { pattern: /\.destroy_all/, label: "destroy_all" },
          { pattern: /ActiveRecord::Base\.connection\.execute.*DROP/i, label: "DROP statement" },
          { pattern: /ActiveRecord::Base\.connection\.execute.*TRUNCATE/i, label: "TRUNCATE statement" }
        ]

        destructive_patterns.each do |entry|
          if content.match?(entry[:pattern])
            result.add_warning("db/seeds.rb contains potentially destructive operation: #{entry[:label]}")
          end
        end
      end
    end
  end
end
