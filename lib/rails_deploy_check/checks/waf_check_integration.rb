module RailsDeployCheck
  module Checks
    module WafCheckIntegration
      class << self
        def build(options = {})
          WafCheck.new(
            app_path: options.fetch(:app_path, Dir.pwd),
            waf_provider: options[:waf_provider] || ENV["WAF_PROVIDER"],
            waf_url: options[:waf_url] || ENV["WAF_URL"]
          )
        end

        def register(registry)
          return unless applicable?

          registry.register(:waf, -> (opts) { build(opts) })
        end

        def applicable?
          rails_app? || waf_provider_present? || rack_attack_in_lockfile?
        end

        def rails_app?
          File.exist?(File.join(Dir.pwd, "config", "application.rb"))
        end

        def waf_provider_present?
          !ENV["WAF_PROVIDER"].to_s.strip.empty? || !ENV["WAF_URL"].to_s.strip.empty?
        end

        def rack_attack_in_lockfile?
          lockfile = File.join(Dir.pwd, "Gemfile.lock")
          return false unless File.exist?(lockfile)

          File.read(lockfile).match?(/^\s+rack-attack\s/)
        end
      end
    end
  end
end
