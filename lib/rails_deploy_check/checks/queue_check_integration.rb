# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    module QueueCheckIntegration
      def self.build(options = {})
        QueueCheck.new(options)
      end

      def self.register(runner)
        return unless applicable?

        runner.register(:queue, build)
      end

      def self.applicable?
        active_job_present? || queue_adapter_env_present? || known_queue_gem_in_lockfile?
      end

      def self.active_job_present?
        defined?(ActiveJob)
      end

      def self.queue_adapter_env_present?
        ENV["QUEUE_ADAPTER"] || ENV["ACTIVE_JOB_QUEUE_ADAPTER"]
      end

      def self.known_queue_gem_in_lockfile?
        lockfile = File.join(Dir.pwd, "Gemfile.lock")
        return false unless File.exist?(lockfile)

        content = File.read(lockfile)
        %w[sidekiq resque delayed_job good_job que].any? { |gem| content.match?(/^    #{gem} /) }
      end
    end
  end
end
