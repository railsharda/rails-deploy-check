# frozen_string_literal: true

require "spec_helper"

RSpec.describe RailsDeployCheck::Checks::GraphqlCheck do
  def create_file(path, content = "")
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  def build_check(tmp_path)
    described_class.new(app_path: tmp_path)
  end

  describe "#run" do
    context "when Gemfile.lock is missing" do
      it "adds a warning about missing lockfile" do
        with_tmp_rails_app do |app_path|
          result = build_check(app_path).run
          expect(result.warnings.first).to match(/Gemfile.lock not found/)
        end
      end
    end

    context "when graphql gem is in Gemfile.lock" do
      it "adds info confirming gem found" do
        with_tmp_rails_app do |app_path|
          create_file("#{app_path}/Gemfile.lock", "    graphql (2.1.4)\n")
          result = build_check(app_path).run
          expect(result.infos.join).to match(/graphql gem found/)
        end
      end
    end

    context "when graphql gem is not in Gemfile.lock" do
      it "adds info that graphql is not detected" do
        with_tmp_rails_app do |app_path|
          create_file("#{app_path}/Gemfile.lock", "    rails (7.0.0)\n")
          result = build_check(app_path).run
          expect(result.infos.join).to match(/not detected/)
        end
      end
    end

    context "when schema file exists" do
      it "adds info confirming schema found" do
        with_tmp_rails_app do |app_path|
          create_file("#{app_path}/Gemfile.lock", "    graphql (2.1.4)\n")
          create_file("#{app_path}/app/graphql/schema.rb", "class AppSchema < GraphQL::Schema; end")
          result = build_check(app_path).run
          expect(result.infos.join).to match(/schema file found/)
        end
      end
    end

    context "when schema file is missing" do
      it "adds a warning" do
        with_tmp_rails_app do |app_path|
          create_file("#{app_path}/Gemfile.lock", "    graphql (2.1.4)\n")
          result = build_check(app_path).run
          expect(result.warnings.join).to match(/No GraphQL schema file found/)
        end
      end
    end

    context "when graphql_controller.rb exists" do
      it "adds info confirming controller found" do
        with_tmp_rails_app do |app_path|
          create_file("#{app_path}/Gemfile.lock", "    graphql (2.1.4)\n")
          create_file("#{app_path}/app/controllers/graphql_controller.rb", "class GraphqlController < ApplicationController; end")
          result = build_check(app_path).run
          expect(result.infos.join).to match(/GraphQL controller found/)
        end
      end
    end

    context "when introspection is disabled in schema" do
      it "adds info confirming introspection is restricted" do
        with_tmp_rails_app do |app_path|
          create_file("#{app_path}/Gemfile.lock", "    graphql (2.1.4)\n")
          create_file(
            "#{app_path}/app/graphql/schema.rb",
            "class AppSchema < GraphQL::Schema\n  disable_introspection_entry_points\nend"
          )
          result = build_check(app_path).run
          expect(result.infos.join).to match(/introspection appears to be restricted/)
        end
      end
    end

    context "when introspection is not disabled" do
      it "adds a warning about introspection" do
        with_tmp_rails_app do |app_path|
          create_file("#{app_path}/Gemfile.lock", "    graphql (2.1.4)\n")
          create_file("#{app_path}/app/graphql/schema.rb", "class AppSchema < GraphQL::Schema; end")
          result = build_check(app_path).run
          expect(result.warnings.join).to match(/introspection may be enabled/)
        end
      end
    end
  end
end
