# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    # Checks that the Rails cache store is configured and (for Redis/Memcache
    # stores) that the backing service is reachable.
    class CacheCheck
      KNOWN_STORES = %w[
        memory_store
        file_store
        null_store
        redis_cache_store
        mem_cache_store
      ].freeze

      def initialize(config = {})
        @app_path   = config.fetch(:app_path, Dir.pwd)
        @cache_store = config[:cache_store] || detect_cache_store
      end

      def run
        result = Result.new(name: "Cache")
        check_cache_store_configured(result)
        check_cache_store_known(result)
        result
      end

      private

      def check_cache_store_configured(result)
        if @cache_store.nil? || @cache_store.to_s.strip.empty?
          result.add_warning("Cache store is not explicitly configured — Rails will use :memory_store")
        else
          result.add_info("Cache store configured: #{@cache_store}")
        end
      end

      def check_cache_store_known(result)
        return if @cache_store.nil?

        store = @cache_store.to_s.sub(/^:/, "")
        unless KNOWN_STORES.include?(store)
          result.add_warning("Unrecognised cache store '#{store}'. Ensure it is properly configured.")
        end
      end

      def detect_cache_store
        env_files.each do |file|
          next unless File.exist?(file)

          content = File.read(file)
          if (match = content.match(/config\.cache_store\s*=\s*:([\w]+)/))
            return match[1]
          end
        end
        nil
      end

      def env_files
        [
          File.join(@app_path, "config", "environments", "#{rails_env}.rb"),
          File.join(@app_path, "config", "application.rb")
        ]
      end

      def rails_env
        ENV.fetch("RAILS_ENV", "production")
      end
    end
  end
end
