# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    class CloudwatchCheck
      def initialize(options = {})
        @app_path = options[:app_path] || Dir.pwd
        @region = options[:region] || ENV["AWS_REGION"] || ENV["AWS_DEFAULT_REGION"]
        @access_key_id = options[:access_key_id] || ENV["AWS_ACCESS_KEY_ID"]
        @secret_access_key = options[:secret_access_key] || ENV["AWS_SECRET_ACCESS_KEY"]
        @log_group = options[:log_group] || ENV["CLOUDWATCH_LOG_GROUP"]
      end

      def run
        result = Result.new("CloudWatch")

        check_aws_credentials(result)
        check_region_configured(result)
        check_log_group_configured(result)
        check_aws_sdk_available(result)

        result
      end

      private

      def check_aws_credentials(result)
        if @access_key_id.nil? || @access_key_id.empty?
          result.add_warning("AWS_ACCESS_KEY_ID is not set; CloudWatch logging may not work")
        else
          result.add_info("AWS_ACCESS_KEY_ID is configured")
        end

        if @secret_access_key.nil? || @secret_access_key.empty?
          result.add_warning("AWS_SECRET_ACCESS_KEY is not set; CloudWatch logging may not work")
        else
          result.add_info("AWS_SECRET_ACCESS_KEY is configured")
        end
      end

      def check_region_configured(result)
        if @region.nil? || @region.empty?
          result.add_error("AWS region is not configured (AWS_REGION or AWS_DEFAULT_REGION)")
        else
          result.add_info("AWS region configured: #{@region}")
        end
      end

      def check_log_group_configured(result)
        if @log_group.nil? || @log_group.empty?
          result.add_warning("CLOUDWATCH_LOG_GROUP is not set; logs may not be routed to CloudWatch")
        else
          result.add_info("CloudWatch log group configured: #{@log_group}")
        end
      end

      def check_aws_sdk_available(result)
        lockfile = File.join(@app_path, "Gemfile.lock")
        if File.exist?(lockfile)
          content = File.read(lockfile)
          if content.include?("aws-sdk-cloudwatchlogs") || content.include?("aws-sdk-core")
            result.add_info("AWS SDK gem found in Gemfile.lock")
          else
            result.add_warning("aws-sdk-cloudwatchlogs not found in Gemfile.lock; CloudWatch integration may be missing")
          end
        else
          result.add_warning("Gemfile.lock not found; cannot verify AWS SDK gem")
        end
      end

      def blank?(value)
        value.nil? || value.strip.empty?
      end
    end
  end
end
