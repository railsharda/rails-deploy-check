# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    class StorageCheck
      KNOWN_SERVICES = %w[local test amazon google mirror disk].freeze

      def initialize(options = {})
        @app_path = options.fetch(:app_path, Dir.pwd)
        @rails_env = options.fetch(:rails_env, ENV["RAILS_ENV"] || "production")
      end

      def run
        result = Result.new(name: "Storage")

        check_storage_config_exists(result)
        check_service_configured(result)
        check_active_storage_installed(result)

        result
      end

      private

      def check_storage_config_exists(result)
        path = File.join(@app_path, "config", "storage.yml")
        if File.exist?(path)
          result.add_info("config/storage.yml found")
        else
          result.add_warning("config/storage.yml not found — Active Storage may not be configured")
        end
      end

      def check_service_configured(result)
        path = File.join(@app_path, "config", "storage.yml")
        return unless File.exist?(path)

        content = File.read(path)
        env_config_path = File.join(@app_path, "config", "environments", "#{@rails_env}.rb")

        if File.exist?(env_config_path)
          env_content = File.read(env_config_path)
          if env_content.match?(/config\.active_storage\.service\s*=/)
            service = env_content[/config\.active_storage\.service\s*=\s*:(\w+)/, 1]
            if service
              if content.match?(/^#{service}:/)
                result.add_info("Active Storage service ':#{service}' is defined in storage.yml")
              else
                result.add_error("Active Storage service ':#{service}' is not defined in config/storage.yml")
              end
            end
          else
            result.add_warning("config.active_storage.service not set in config/environments/#{@rails_env}.rb")
          end
        end
      end

      def check_active_storage_installed(result)
        migrations_path = File.join(@app_path, "db", "migrate")
        return unless File.exist?(migrations_path)

        has_migration = Dir.glob(File.join(migrations_path, "*active_storage*")).any?
        if has_migration
          result.add_info("Active Storage migrations are present")
        else
          lockfile = File.join(@app_path, "Gemfile.lock")
          if File.exist?(lockfile) && File.read(lockfile).include?("activestorage")
            result.add_warning("Active Storage is in Gemfile.lock but migrations not found — run rails active_storage:install")
          end
        end
      end
    end
  end
end
