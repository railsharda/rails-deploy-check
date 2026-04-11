# frozen_string_literal: true

require_relative "elasticsearch_check"

module RailsDeployCheck
  module Checks
    module ElasticsearchCheckIntegration
      def self.build(config = {})
        ElasticsearchCheck.new(config)
      end

      def self.register(registry, config = {})
        return unless applicable?

        registry << build(config)
      end

      def self.applicable?
        elasticsearch_url_present? || elasticsearch_gem_in_lockfile?
      end

      def self.elasticsearch_url_present?
        %w[ELASTICSEARCH_URL BONSAI_URL SEARCHBOX_URL].any? { |var| ENV[var] && !ENV[var].empty? }
      end

      def self.elasticsearch_gem_in_lockfile?
        lockfile = File.join(Dir.pwd, "Gemfile.lock")
        return false unless File.exist?(lockfile)

        content = File.read(lockfile)
        content.match?(/^\s+(elasticsearch|searchkick|chewy)\s+\(\d/)
      end
    end
  end
end
