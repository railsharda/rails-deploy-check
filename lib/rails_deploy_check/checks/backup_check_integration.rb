module RailsDeployCheck
  module Checks
    module BackupCheckIntegration
      def self.build(app_path: Dir.pwd, **options)
        BackupCheck.new(app_path: app_path, **options)
      end

      def self.register(config)
        return unless applicable?(config.app_path)

        config.add_check(
          build(
            app_path: config.app_path,
            require_config: require_config?(config.app_path)
          )
        )
      end

      def self.applicable?(app_path = Dir.pwd)
        backup_gem_in_lockfile?(app_path) || backup_dir_present?(app_path)
      end

      def self.backup_gem_in_lockfile?(app_path = Dir.pwd)
        lockfile = File.join(app_path, "Gemfile.lock")
        return false unless File.exist?(lockfile)

        content = File.read(lockfile)
        content.match?(/^\s+(backup|whenever|clockwork)\s+\(/)  
      end

      def self.backup_dir_present?(app_path = Dir.pwd)
        BackupCheck::DEFAULT_BACKUP_PATHS.any? do |path|
          File.directory?(File.join(app_path, path))
        end
      end

      def self.require_config?(app_path = Dir.pwd)
        backup_gem_in_lockfile?(app_path)
      end
    end
  end
end
