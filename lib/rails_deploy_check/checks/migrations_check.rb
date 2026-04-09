# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    class MigrationsCheck
      SCHEMA_FILE_PATHS = [
        "db/schema.rb",
        "db/structure.sql"
      ].freeze

      def initialize(app_path: Dir.pwd)
        @app_path = app_path
      end

      def run(result)
        check_pending_migrations(result)
        check_schema_file_exists(result)
        check_schema_up_to_date(result)
        result
      end

      private

      def check_pending_migrations(result)
        pending = pending_migrations
        if pending.empty?
          result.add_info("migrations", "No pending migrations found")
        else
          result.add_error(
            "migrations",
            "#{pending.size} pending migration(s) detected: #{pending.join(', ')}"
          )
        end
      rescue => e
        result.add_warning("migrations", "Could not check pending migrations: #{e.message}")
      end

      def check_schema_file_exists(result)
        schema_file = SCHEMA_FILE_PATHS.find { |f| File.exist?(File.join(@app_path, f)) }
        if schema_file
          result.add_info("migrations", "Schema file found: #{schema_file}")
        else
          result.add_warning("migrations", "No schema file found (expected db/schema.rb or db/structure.sql)")
        end
      end

      def check_schema_up_to_date(result)
        schema_path = File.join(@app_path, "db", "schema.rb")
        return unless File.exist?(schema_path)

        schema_mtime = File.mtime(schema_path)
        stale_migrations = migration_files.select { |f| File.mtime(f) > schema_mtime }

        if stale_migrations.any?
          result.add_warning(
            "migrations",
            "#{stale_migrations.size} migration file(s) newer than schema.rb — schema may be out of date"
          )
        end
      end

      def pending_migrations
        migrations_dir = File.join(@app_path, "db", "migrate")
        return [] unless File.directory?(migrations_dir)

        schema_path = File.join(@app_path, "db", "schema.rb")
        return [] unless File.exist?(schema_path)

        schema_content = File.read(schema_path)
        schema_version = schema_content.match(/version:\s*(\d+)/i)&.captures&.first&.to_i
        return [] unless schema_version

        migration_files.select do |f|
          version = File.basename(f).split("_").first.to_i
          version > schema_version
        end.map { |f| File.basename(f) }
      end

      def migration_files
        migrations_dir = File.join(@app_path, "db", "migrate")
        return [] unless File.directory?(migrations_dir)

        Dir.glob(File.join(migrations_dir, "*.rb")).sort
      end
    end
  end
end
