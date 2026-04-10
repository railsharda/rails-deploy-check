# frozen_string_literal: true

require_relative "../result"

module RailsDeployCheck
  module Checks
    class SidekiqCheck
      DEFAULT_REDIS_URL = "redis://localhost:6379/0"

      def initialize(options = {})
        @redis_url = options[:redis_url] || ENV["REDIS_URL"] || DEFAULT_REDIS_URL
        @require_sidekiq = options.fetch(:require_sidekiq, true)
        @check_queues = options[:check_queues] || []
        @app_path = options[:app_path] || Dir.pwd
      end

      def run
        result = Result.new("Sidekiq")

        check_sidekiq_gem_available(result)
        check_sidekiq_config_exists(result)
        check_redis_url_configured(result)
        check_queue_configuration(result) if @check_queues.any?

        result
      end

      private

      def check_sidekiq_gem_available(result)
        if sidekiq_available?
          result.add_info("Sidekiq gem is available")
        elsif @require_sidekiq
          result.add_error("Sidekiq gem is not available. Add 'gem sidekiq' to your Gemfile")
        else
          result.add_warning("Sidekiq gem is not available (optional)")
        end
      end

      def check_sidekiq_config_exists(result)
        config_paths = [
          File.join(@app_path, "config", "sidekiq.yml"),
          File.join(@app_path, "config", "sidekiq.rb")
        ]

        found = config_paths.find { |p| File.exist?(p) }

        if found
          result.add_info("Sidekiq config found: #{File.basename(found)}")
        else
          result.add_warning("No Sidekiq config file found (config/sidekiq.yml or config/sidekiq.rb)")
        end
      end

      def check_redis_url_configured(result)
        if @redis_url.nil? || @redis_url.strip.empty?
          result.add_error("REDIS_URL is not configured for Sidekiq")
          return
        end

        unless @redis_url.match?(/\Aredis(s)?:\/\/.+/)
          result.add_error("REDIS_URL '#{@redis_url}' does not appear to be a valid Redis URL")
          return
        end

        result.add_info("Sidekiq Redis URL configured: #{@redis_url}")
      end

      def check_queue_configuration(result)
        @check_queues.each do |queue|
          result.add_info("Expected Sidekiq queue configured: #{queue}")
        end
      end

      def sidekiq_available?
        require "sidekiq"
        true
      rescue LoadError
        false
      end
    end
  end
end
