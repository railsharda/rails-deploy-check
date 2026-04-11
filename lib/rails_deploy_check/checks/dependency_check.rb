module RailsDeployCheck
  module Checks
    class DependencyCheck
      attr_reader :config, :result

      def initialize(config = {})
        @config = config
        @result = Result.new("Dependency Check")
      end

      def run
        check_gemfile_exists
        check_bundler_available
        check_gems_installed
        check_native_extensions
        result
      end

      private

      def check_gemfile_exists
        gemfile = File.join(rails_root, "Gemfile")
        unless File.exist?(gemfile)
          result.add_error("Gemfile not found at #{gemfile}")
          return
        end
        result.add_info("Gemfile found")
      end

      def check_bundler_available
        output = `bundle --version 2>&1`
        if $?.success?
          result.add_info("Bundler available: #{output.strip}")
        else
          result.add_error("Bundler is not available. Run: gem install bundler")
        end
      rescue Errno::ENOENT
        result.add_error("Bundler command not found")
      end

      def check_gems_installed
        lockfile = File.join(rails_root, "Gemfile.lock")
        unless File.exist?(lockfile)
          result.add_warning("Gemfile.lock not found — run `bundle install` before deploying")
          return
        end

        output = `bundle check 2>&1`
        if $?.success?
          result.add_info("All gems are installed and up to date")
        else
          result.add_error("Bundle is not satisfied: #{output.strip}")
        end
      rescue Errno::ENOENT
        result.add_warning("Could not verify gem installation status")
      end

      def check_native_extensions
        lockfile_path = File.join(rails_root, "Gemfile.lock")
        return unless File.exist?(lockfile_path)

        lockfile_content = File.read(lockfile_path)
        gems_with_extensions = lockfile_content.scan(/^    (\S+) \(.*\)/).flatten.select do |gem|
          lockfile_content.include?("#{gem} (")
        end

        known_native = %w[nokogiri pg mysql2 sqlite3 bcrypt json ffi]
        found_native = known_native.select { |g| lockfile_content =~ /^    #{g} \(/ }

        if found_native.any?
          result.add_info("Native extension gems detected: #{found_native.join(", ")} — ensure build tools are available")
        end
      end

      def rails_root
        config[:rails_root] || Dir.pwd
      end
    end
  end
end
