module RailsDeployCheck
  module Checks
    module CdnCheckIntegration
      def self.build(options = {})
        CdnCheck.new(options)
      end

      def self.register(runner)
        return unless applicable?

        runner.register(:cdn, build(app_path: runner.app_path))
      end

      def self.applicable?
        cdn_url_present? || asset_host_in_production_config?
      end

      def self.cdn_url_present?
        url = ENV["CDN_URL"] || ENV["ASSET_HOST"]
        !url.nil? && !url.strip.empty?
      end

      def self.asset_host_in_production_config?(app_path = Dir.pwd)
        prod_config = File.join(app_path, "config", "environments", "production.rb")
        return false unless File.exist?(prod_config)

        File.read(prod_config).include?("asset_host")
      end
    end
  end
end
