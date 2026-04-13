# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    module CloudwatchCheckIntegration
      class << self
        def build(options = {})
          CloudwatchCheck.new(options)
        end

        def register(registry)
          return unless applicable?

          registry.register(:cloudwatch, build)
        end

        def applicable?
          aws_credentials_present? || cloudwatch_log_group_present? || aws_sdk_in_lockfile?
        end

        def aws_credentials_present?
          (ENV["AWS_ACCESS_KEY_ID"] && !ENV["AWS_ACCESS_KEY_ID"].empty?) ||
            (ENV["AWS_SECRET_ACCESS_KEY"] && !ENV["AWS_SECRET_ACCESS_KEY"].empty?)
        end

        def cloudwatch_log_group_present?
          ENV["CLOUDWATCH_LOG_GROUP"] && !ENV["CLOUDWATCH_LOG_GROUP"].empty?
        end

        def aws_sdk_in_lockfile?
          lockfile = File.join(Dir.pwd, "Gemfile.lock")
          return false unless File.exist?(lockfile)

          content = File.read(lockfile)
          content.include?("aws-sdk-cloudwatchlogs") || content.include?("aws-sdk-core")
        end
      end
    end
  end
end
