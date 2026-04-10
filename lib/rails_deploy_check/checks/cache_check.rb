module RailsDeployCheck
  module Checks
    class CacheCheck
      KNOWN_CACHE_STORES = %w[
        memory_store
        file_store
        mem_cache_store
        redis_cache_store
        null_store
      ].freeze

      def initialize(options = {})
        @app_path = options.fetch(:app_path, Dir.pwd)
        @rails_env = options.fetch(:rails_env, ENV["RAILS_ENV"] || "production")
      end

      def run
        result = Result.new("Cache")

        check_cache_store_configured(result)
        check_cache_store_known(result)
        check_cache_store_reachable(result)

        result
      end

      private

      def check_cache_store_configured(result)
        config_path = File.join(@app_path, "config", "environments", "#{@rails_env}.rb")

        unless File.exist?(config_path)
          result.add_warning("Environment config not found at #{config_path}; cannot verify cache store")
          return
        end

        content = File.read(config_path)
        if content.match?(/config\.cache_store/)
          result.add_info("Cache store is configured in #{@rails_env} environment")
        else
          result.add_warning("No explicit cache_store configuration found in #{config_path}")
        end
      end

      def check_cache_store_known(result)
        config_path = File.join(@app_path, "config", "environments", "#{@rails_env}.rb")
        return unless File.exist?(config_path)

        content = File.read(config_path)
        match = content.match(/config\.cache_store\s*=\s*:([\w]+)/)
        return unless match

        store = match[1]
        if KNOWN_CACHE_STORES.include?(store)
          result.add_info("Cache store '#{store}' is a recognised Rails cache backend")
        else
          result.add_warning("Cache store '#{store}' is not a standard Rails cache backend")
        end
      end

      def check_cache_store_reachable(result)
        config_path = File.join(@app_path, "config", "environments", "#{@rails_env}.rb")
        return unless File.exist?(config_path)

        content = File.read(config_path)
        match = content.match(/config\.cache_store\s*=\s*:([\w]+)/)
        return unless match

        store = match[1]

        case store
        when "mem_cache_store"
          check_memcache_reachable(result)
        when "redis_cache_store"
          check_redis_url_present(result)
        end
      end

      def check_memcache_reachable(result)
        if ENV["MEMCACHE_SERVERS"] || ENV["MEMCACHIER_SERVERS"]
          result.add_info("Memcache server environment variable is set")
        else
          result.add_warning("mem_cache_store configured but MEMCACHE_SERVERS / MEMCACHIER_SERVERS is not set")
        end
      end

      def check_redis_url_present(result)
        if ENV["REDIS_URL"] || ENV["REDIS_CACHE_URL"]
          result.add_info("Redis URL environment variable is set for redis_cache_store")
        else
          result.add_warning("redis_cache_store configured but REDIS_URL / REDIS_CACHE_URL is not set")
        end
      end
    end
  end
end
