module RailsDeployCheck
  module Checks
    module SeedCheckIntegration
      def self.build(options = {})
        app_path = options[:app_path] || Dir.pwd

        SeedCheck.new(
          app_path: app_path,
          check_seed_file: options.fetch(:check_seed_file, true),
          check_seed_data: options.fetch(:check_seed_data, true),
          seed_file_path: options[:seed_file_path] || File.join(app_path, "db", "seeds.rb")
        )
      end

      def self.register(registry, options = {})
        return unless applicable?(options)

        registry << build(options)
      end

      def self.applicable?(options = {})
        app_path = options[:app_path] || Dir.pwd
        db_path = File.join(app_path, "db")

        # Applicable if a db/ directory exists (Rails app with ActiveRecord)
        return false unless Dir.exist?(db_path)

        # Also applicable if a seeds.rb file already exists
        seeds_file = File.join(db_path, "seeds.rb")
        schema_file = File.join(db_path, "schema.rb")
        structure_file = File.join(db_path, "structure.sql")

        File.exist?(seeds_file) || File.exist?(schema_file) || File.exist?(structure_file)
      end
    end
  end
end
