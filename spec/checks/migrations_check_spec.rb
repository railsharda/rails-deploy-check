# frozen_string_literal: true

require "spec_helper"
require "rails_deploy_check/checks/migrations_check"
require "rails_deploy_check/result"

RSpec.describe RailsDeployCheck::Checks::MigrationsCheck do
  let(:app_path) { Dir.mktmpdir("rails_app") }
  let(:result) { RailsDeployCheck::Result.new }
  let(:check) { described_class.new(app_path: app_path) }

  after { FileUtils.rm_rf(app_path) }

  def create_file(relative_path, content = "")
    full_path = File.join(app_path, relative_path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
    full_path
  end

  describe "#run" do
    context "when no db directory exists" do
      it "adds a warning about missing schema file" do
        check.run(result)
        expect(result.warnings.map(&:message)).to include(
          a_string_matching(/No schema file found/)
        )
      end
    end

    context "when schema.rb exists and is up to date" do
      before do
        create_file("db/schema.rb", "ActiveRecord::Schema.define(version: 20231001120000) do\nend\n")
        mig = create_file("db/migrate/20231001120000_create_users.rb", "")
        past_time = Time.now - 3600
        File.utime(past_time, past_time, mig)
      end

      it "reports no pending migrations" do
        check.run(result)
        expect(result.infos.map(&:message)).to include(a_string_matching(/No pending migrations/))
      end

      it "reports schema file found" do
        check.run(result)
        expect(result.infos.map(&:message)).to include(a_string_matching(/Schema file found/))
      end

      it "has no errors" do
        check.run(result)
        expect(result.errors).to be_empty
      end
    end

    context "when there are pending migrations" do
      before do
        create_file("db/schema.rb", "ActiveRecord::Schema.define(version: 20231001120000) do\nend\n")
        create_file("db/migrate/20231001120000_create_users.rb", "")
        create_file("db/migrate/20231010090000_add_email_to_users.rb", "")
      end

      it "adds an error listing pending migrations" do
        check.run(result)
        expect(result.errors.map(&:message)).to include(
          a_string_matching(/1 pending migration/)
        )
      end
    end

    context "when schema.rb is older than a migration file" do
      before do
        schema = create_file("db/schema.rb", "ActiveRecord::Schema.define(version: 20231001120000) do\nend\n")
        mig = create_file("db/migrate/20231001120000_create_users.rb", "")
        past_time = Time.now - 7200
        File.utime(past_time, past_time, schema)
        File.utime(Time.now, Time.now, mig)
      end

      it "warns that schema may be out of date" do
        check.run(result)
        expect(result.warnings.map(&:message)).to include(
          a_string_matching(/newer than schema\.rb/)
        )
      end
    end
  end
end
