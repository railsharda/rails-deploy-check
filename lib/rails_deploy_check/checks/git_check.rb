module RailsDeployCheck
  module Checks
    class GitCheck
      attr_reader :options

      def initialize(options = {})
        @options = options
      end

      def run
        result = Result.new("Git")

        check_git_repository(result)
        check_uncommitted_changes(result)
        check_unpushed_commits(result)
        check_branch(result)

        result
      end

      private

      def check_git_repository(result)
        unless git_available?
          result.add_info("Git not available, skipping git checks")
          return
        end

        unless File.directory?(File.join(app_path, ".git"))
          result.add_warning("Not a git repository — cannot verify deployment state")
        else
          result.add_info("Git repository detected")
        end
      end

      def check_uncommitted_changes(result)
        return unless git_available? && git_repo?

        output = `git -C #{app_path} status --porcelain 2>/dev/null`.strip
        if output.empty?
          result.add_info("No uncommitted changes")
        else
          result.add_warning("Uncommitted changes detected — deploy may not reflect latest code")
        end
      end

      def check_unpushed_commits(result)
        return unless git_available? && git_repo?

        output = `git -C #{app_path} log @{u}.. --oneline 2>/dev/null`.strip
        if $?.success? && !output.empty?
          count = output.lines.count
          result.add_warning("#{count} unpushed commit(s) on current branch")
        elsif $?.success?
          result.add_info("All commits pushed to remote")
        end
      end

      def check_branch(result)
        return unless git_available? && git_repo?

        branch = `git -C #{app_path} rev-parse --abbrev-ref HEAD 2>/dev/null`.strip
        return unless $?.success?

        expected = options[:expected_branch]
        if expected && branch != expected
          result.add_warning("Current branch '#{branch}' does not match expected '#{expected}'")
        else
          result.add_info("Deploying from branch: #{branch}")
        end
      end

      def git_available?
        @git_available ||= system("git --version > /dev/null 2>&1")
      end

      def git_repo?
        File.directory?(File.join(app_path, ".git"))
      end

      def app_path
        options[:app_path] || Dir.pwd
      end
    end
  end
end
