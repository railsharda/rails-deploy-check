# frozen_string_literal: true

module RailsDeployCheck
  class Result
    attr_reader :errors, :warnings, :info_messages

    def initialize
      @errors = []
      @warnings = []
      @info_messages = []
    end

    def add_error(message, context: nil)
      @errors << { message: message, context: context }
    end

    def add_warning(message, context: nil)
      @warnings << { message: message, context: context }
    end

    def add_info(message, context: nil)
      @info_messages << { message: message, context: context }
    end

    def success?
      @errors.empty?
    end

    def has_warnings?
      @warnings.any?
    end

    def failure?
      !success?
    end

    def summary
      {
        total_errors: @errors.count,
        total_warnings: @warnings.count,
        total_info: @info_messages.count,
        success: success?
      }
    end

    # Merges another Result's errors, warnings, and info messages into this one.
    def merge!(other)
      @errors.concat(other.errors)
      @warnings.concat(other.warnings)
      @info_messages.concat(other.info_messages)
      self
    end

    def to_s
      output = []
      
      if @errors.any?
        output << "\n❌ ERRORS (#{@errors.count}):"
        @errors.each { |e| output << "  - #{e[:message]}" }
      end

      if @warnings.any?
        output << "\n⚠️  WARNINGS (#{@warnings.count}):"
        @warnings.each { |w| output << "  - #{w[:message]}" }
      end

      if @info_messages.any?
        output << "\nℹ️  INFO (#{@info_messages.count}):"
        @info_messages.each { |i| output << "  - #{i[:message]}" }
      end

      if success? && !has_warnings?
        output << "\n✅ All checks passed!"
      elsif success? && has_warnings?
        output << "\n✅ All checks passed (with warnings)"
      else
        output << "\n❌ Deployment validation failed!"
      end

      output.join("\n")
    end
  end
end
