# frozen_string_literal: true

require_relative "rails_deploy_check/version"
require_relative "rails_deploy_check/checker"
require_relative "rails_deploy_check/result"

module RailsDeployCheck
  class Error < StandardError; end
  class ConfigurationError < Error; end

  class << self
    attr_accessor :configuration

    def configure
      self.configuration ||= Configuration.new
      yield(configuration)
    end

    def run
      checker = Checker.new(configuration)
      checker.run
    end
  end

  class Configuration
    attr_accessor :rails_root, :checks_to_run, :fail_on_warnings

    def initialize
      @rails_root = Dir.pwd
      @checks_to_run = [:migrations, :assets, :environment]
      @fail_on_warnings = false
    end
  end
end
