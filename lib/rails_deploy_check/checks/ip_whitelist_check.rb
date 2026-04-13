# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    class IpWhitelistCheck
      CHECK_NAME = "IP Whitelist"

      KNOWN_WHITELIST_ENV_VARS = %w[
        IP_WHITELIST
        ALLOWED_IPS
        TRUSTED_IPS
        ADMIN_IP_WHITELIST
      ].freeze

      KNOWN_INITIALIZER_PATHS = %w[
        config/initializers/ip_whitelist.rb
        config/initializers/allowed_ips.rb
        config/initializers/trusted_ips.rb
      ].freeze

      def initialize(options = {})
        @root = options.fetch(:root, Dir.pwd)
        @env = options.fetch(:env, ENV)
        @result = Result.new(CHECK_NAME)
      end

      def run
        check_whitelist_env_var_present
        check_initializer_exists
        check_whitelist_format
        @result
      end

      private

      def check_whitelist_env_var_present
        found = KNOWN_WHITELIST_ENV_VARS.find { |var| @env[var] && !@env[var].strip.empty? }

        if found
          @result.add_info("IP whitelist configured via #{found}")
        else
          @result.add_warning("No IP whitelist environment variable found (checked: #{KNOWN_WHITELIST_ENV_VARS.join(', ')})")
        end
      end

      def check_initializer_exists
        found = KNOWN_INITIALIZER_PATHS.find { |path| File.exist?(File.join(@root, path)) }

        if found
          @result.add_info("IP whitelist initializer found at #{found}")
        else
          @result.add_info("No IP whitelist initializer found (optional)")
        end
      end

      def check_whitelist_format
        whitelist_var = KNOWN_WHITELIST_ENV_VARS.find { |var| @env[var] && !@env[var].strip.empty? }
        return unless whitelist_var

        value = @env[whitelist_var]
        ips = value.split(/[,\s]+/).map(&:strip).reject(&:empty?)

        if ips.empty?
          @result.add_warning("#{whitelist_var} is set but contains no valid IP entries")
          return
        end

        invalid = ips.reject { |ip| valid_ip_or_cidr?(ip) }

        if invalid.any?
          @result.add_warning("#{whitelist_var} contains potentially invalid entries: #{invalid.join(', ')}")
        else
          @result.add_info("#{whitelist_var} contains #{ips.size} valid IP/CIDR entr#{ips.size == 1 ? 'y' : 'ies'}")
        end
      end

      def valid_ip_or_cidr?(entry)
        # Basic IPv4, IPv6, or CIDR notation check
        entry.match?(/\A(\d{1,3}\.){3}\d{1,3}(\/\d{1,2})?\z/) ||
          entry.match?(/\A[0-9a-fA-F:]+(\/\d{1,3})?\z/) ||
          entry == "localhost"
      end
    end
  end
end
