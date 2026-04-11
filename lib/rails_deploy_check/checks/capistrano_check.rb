# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    class CapistranoCheck
      CHECK_NAME = "Capistrano"

      CAPISTRANO_GEMS = %w[capistrano capistrano-rails capistrano-bundler].freeze
      DEPLOY_RB_PATHS = %w[config/deploy.rb Capfile].freeze
      STAGE_DIR = "config/deploy"

      def initialize(config = {})
        @root = config.fetch(:root, Dir.pwd)
        @required_stages = config.fetch(:required_stages, [])
      end

      def run
        result = Result.new(CHECK_NAME)

        check_capfile_exists(result)
        check_deploy_rb_exists(result)
        check_capistrano_in_lockfile(result)
        check_stages_defined(result)

        result
      end

      private

      def check_capfile_exists(result)
        capfile = File.join(@root, "Capfile")
        if File.exist?(capfile)
          result.add_info("Capfile found")
        else
          result.add_warning("Capfile not found — Capistrano may not be configured")
        end
      end

      def check_deploy_rb_exists(result)
        deploy_rb = File.join(@root, "config", "deploy.rb")
        if File.exist?(deploy_rb)
          result.add_info("config/deploy.rb found")
        else
          result.add_warning("config/deploy.rb not found — deployment configuration missing")
        end
      end

      def check_capistrano_in_lockfile(result)
        lockfile = File.join(@root, "Gemfile.lock")
        return result.add_warning("Gemfile.lock not found, cannot verify Capistrano gems") unless File.exist?(lockfile)

        content = File.read(lockfile)
        found = CAPISTRANO_GEMS.select { |gem| content.match?(/^\s+#{Regexp.escape(gem)}\s+\(/) }

        if found.any?
          result.add_info("Capistrano gems found in Gemfile.lock: #{found.join(', ')}")
        else
          result.add_warning("No Capistrano gems found in Gemfile.lock")
        end
      end

      def check_stages_defined(result)
        stage_dir = File.join(@root, STAGE_DIR)
        return unless File.directory?(stage_dir)

        stages = Dir.glob(File.join(stage_dir, "*.rb")).map { |f| File.basename(f, ".rb") }

        if stages.empty?
          result.add_warning("No deployment stages found in #{STAGE_DIR}/")
          return
        end

        result.add_info("Deployment stages defined: #{stages.join(', ')}")

        @required_stages.each do |stage|
          unless stages.include?(stage.to_s)
            result.add_error("Required deployment stage '#{stage}' not found in #{STAGE_DIR}/")
          end
        end
      end
    end
  end
end
