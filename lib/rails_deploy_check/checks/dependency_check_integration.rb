module RailsDeployCheck
  module Checks
    module DependencyCheckIntegration
      def self.build(config = {})
        DependencyCheck.new(config)
      end

      def self.register(registry, config = {})
        registry[:dependency] = build(config)
      end

      def self.bundler_available?
        system("bundle --version > /dev/null 2>&1")
      end

      def self.gemfile_present?(rails_root = Dir.pwd)
        File.exist?(File.join(rails_root, "Gemfile"))
      end

      def self.applicable?(rails_root = Dir.pwd)
        gemfile_present?(rails_root)
      end
    end
  end
end
