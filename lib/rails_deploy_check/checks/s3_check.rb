# frozen_string_literal: true

require "uri"

module RailsDeployCheck
  module Checks
    class S3Check
      attr_reader :result, :options

      def initialize(options = {})
        @options = options
        @result = Result.new("S3 / Object Storage")
      end

      def run
        check_access_key_id_present
        check_secret_access_key_present
        check_region_configured
        check_bucket_name_configured
        check_endpoint_format
        result
      end

      private

      def check_access_key_id_present
        key = env_or_option(:access_key_id, "AWS_ACCESS_KEY_ID")
        if key.nil? || key.strip.empty?
          result.add_error("AWS_ACCESS_KEY_ID is not set")
        else
          result.add_info("AWS_ACCESS_KEY_ID is configured")
        end
      end

      def check_secret_access_key_present
        secret = env_or_option(:secret_access_key, "AWS_SECRET_ACCESS_KEY")
        if secret.nil? || secret.strip.empty?
          result.add_error("AWS_SECRET_ACCESS_KEY is not set")
        else
          result.add_info("AWS_SECRET_ACCESS_KEY is configured")
        end
      end

      def check_region_configured
        region = env_or_option(:region, "AWS_REGION") ||
                 env_or_option(:region, "AWS_DEFAULT_REGION")
        if region.nil? || region.strip.empty?
          result.add_warning("AWS_REGION / AWS_DEFAULT_REGION is not set; SDK will use its default region")
        else
          result.add_info("AWS region: #{region}")
        end
      end

      def check_bucket_name_configured
        bucket = env_or_option(:bucket, "AWS_S3_BUCKET") ||
                 env_or_option(:bucket, "S3_BUCKET")
        if bucket.nil? || bucket.strip.empty?
          result.add_warning("S3 bucket name is not set (AWS_S3_BUCKET / S3_BUCKET)")
        else
          result.add_info("S3 bucket: #{bucket}")
        end
      end

      def check_endpoint_format
        endpoint = env_or_option(:endpoint, "AWS_S3_ENDPOINT") ||
                   env_or_option(:endpoint, "S3_ENDPOINT")
        return unless endpoint && !endpoint.strip.empty?

        uri = URI.parse(endpoint)
        unless %w[http https].include?(uri.scheme)
          result.add_error("S3 endpoint '#{endpoint}' must use http or https scheme")
          return
        end
        result.add_info("Custom S3 endpoint: #{endpoint}")
      rescue URI::InvalidURIError
        result.add_error("S3 endpoint '#{endpoint}' is not a valid URI")
      end

      def env_or_option(key, env_var)
        options[key] || ENV[env_var]
      end
    end
  end
end
