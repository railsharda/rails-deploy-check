module RailsDeployCheck
  module Checks
    class WafCheck
      def initialize(options = {})
        @app_path = options.fetch(:app_path, Dir.pwd)
        @waf_provider = options[:waf_provider]
        @waf_url = options[:waf_url] || ENV["WAF_URL"]
      end

      def run
        result = Result.new("WAF Check")

        check_waf_provider_configured(result)
        check_waf_gem_available(result)
        check_waf_initializer_exists(result)
        check_blocked_ips_configured(result)

        result
      end

      private

      def check_waf_provider_configured(result)
        provider = @waf_provider || ENV["WAF_PROVIDER"]

        if provider.nil? || provider.strip.empty?
          result.add_warning("No WAF provider configured (WAF_PROVIDER env var not set)")
        else
          known_providers = %w[cloudflare aws_waf fastly sucuri]
          unless known_providers.include?(provider.downcase)
            result.add_warning("Unknown WAF provider '#{provider}'. Known: #{known_providers.join(", ")}")
          end
          result.add_info("WAF provider configured: #{provider}")
        end
      end

      def check_waf_gem_available(result)
        lockfile = File.join(@app_path, "Gemfile.lock")
        return unless File.exist?(lockfile)

        content = File.read(lockfile)
        waf_gems = %w[rack-attack waf-protection]
        found = waf_gems.select { |gem| content.match?(/^\s+#{Regexp.escape(gem)}\s/) }

        if found.empty?
          result.add_warning("No WAF-related gem found in Gemfile.lock (e.g. rack-attack)")
        else
          result.add_info("WAF gem(s) present: #{found.join(", ")}")
        end
      end

      def check_waf_initializer_exists(result)
        initializers_dir = File.join(@app_path, "config", "initializers")
        return unless File.directory?(initializers_dir)

        waf_files = Dir.glob(File.join(initializers_dir, "{waf,rack_attack,rack-attack}*.rb"))

        if waf_files.empty?
          result.add_warning("No WAF initializer found in config/initializers/")
        else
          result.add_info("WAF initializer found: #{waf_files.map { |f| File.basename(f) }.join(", ")}")
        end
      end

      def check_blocked_ips_configured(result)
        blocklist_env = ENV["WAF_BLOCKED_IPS"] || ENV["BLOCKED_IPS"]

        if blocklist_env.nil? || blocklist_env.strip.empty?
          result.add_info("No IP blocklist configured via environment variables (optional)")
        else
          count = blocklist_env.split(",").length
          result.add_info("IP blocklist configured with #{count} entr#{count == 1 ? 'y' : 'ies'}")
        end
      end
    end
  end
end
