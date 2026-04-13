# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    module FileSizeCheckIntegration
      class << self
        def build(config = {})
          root = config.fetch(:root, Dir.pwd)
          paths = config.fetch(:paths, nil)

          options = { root: root }
          options[:paths] = paths if paths

          FileSizeCheck.new(options)
        end

        def register(registry)
          return unless applicable?

          registry.register(:file_size, -> (config = {}) { build(config) })
        end

        def applicable?
          rails_app?
        end

        def rails_app?
          File.exist?(File.join(Dir.pwd, "config", "application.rb"))
        end

        def large_log_files_present?
          log_dir = File.join(Dir.pwd, "log")
          return false unless File.directory?(log_dir)

          Dir.glob(File.join(log_dir, "*.log")).any? do |f|
            File.size(f) > 100 * 1_048_576
          end
        end
      end
    end
  end
end
