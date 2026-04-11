require "spec_helper"
require "rails_deploy_check/checks/dependency_check"

RSpec.describe RailsDeployCheck::Checks::DependencyCheck do
  def create_file(dir, name, content = "")
    path = File.join(dir, name)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
    path
  end

  def build_check(dir, opts = {})
    described_class.new({ rails_root: dir }.merge(opts))
  end

  describe "#run" do
    context "when Gemfile is missing" do
      it "adds an error" do
        with_tmp_rails_app do |dir|
          FileUtils.rm_f(File.join(dir, "Gemfile"))
          result = build_check(dir).run
          expect(result.errors).to include(a_string_matching(/Gemfile not found/))
        end
      end
    end

    context "when Gemfile exists" do
      it "adds an info message" do
        with_tmp_rails_app do |dir|
          create_file(dir, "Gemfile", "source 'https://rubygems.org'")
          result = build_check(dir).run
          expect(result.infos).to include(a_string_matching(/Gemfile found/))
        end
      end
    end

    context "when Gemfile.lock is missing" do
      it "adds a warning" do
        with_tmp_rails_app do |dir|
          create_file(dir, "Gemfile", "source 'https://rubygems.org'")
          FileUtils.rm_f(File.join(dir, "Gemfile.lock"))
          allow_any_instance_of(described_class).to receive(:`).
            with("bundle --version 2>&1").and_return("Bundler version 2.4.0")
          allow($?).to receive(:success?).and_return(true)
          result = build_check(dir).run
          expect(result.warnings).to include(a_string_matching(/Gemfile.lock not found/))
        end
      end
    end

    context "when bundler is not available" do
      it "adds an error" do
        with_tmp_rails_app do |dir|
          create_file(dir, "Gemfile", "source 'https://rubygems.org'")
          check = build_check(dir)
          allow(check).to receive(:`) do |cmd|
            raise Errno::ENOENT if cmd.include?("bundle --version")
            ""
          end
          result = check.run
          expect(result.errors).to include(a_string_matching(/Bundler command not found/))
        end
      end
    end

    context "when bundle check succeeds" do
      it "adds an info message about gems" do
        with_tmp_rails_app do |dir|
          create_file(dir, "Gemfile", "source 'https://rubygems.org'")
          create_file(dir, "Gemfile.lock", "GEM\n  remote: https://rubygems.org/\n  specs:\n")
          check = build_check(dir)
          allow(check).to receive(:`).and_return("")
          allow($?).to receive(:success?).and_return(true)
          result = check.run
          expect(result.infos).to include(a_string_matching(/All gems are installed/))
        end
      end
    end

    context "when native extension gems are present" do
      it "adds an info message about native extensions" do
        with_tmp_rails_app do |dir|
          create_file(dir, "Gemfile", "source 'https://rubygems.org'\ngem 'nokogiri'")
          lockfile_content = "GEM\n  remote: https://rubygems.org/\n  specs:\n    nokogiri (1.15.0)\n"
          create_file(dir, "Gemfile.lock", lockfile_content)
          check = build_check(dir)
          allow(check).to receive(:`).and_return("")
          allow($?).to receive(:success?).and_return(true)
          result = check.run
          expect(result.infos).to include(a_string_matching(/nokogiri/))
        end
      end
    end
  end
end
