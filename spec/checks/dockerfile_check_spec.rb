# frozen_string_literal: true

require "spec_helper"

RSpec.describe RailsDeployCheck::Checks::DockerfileCheck do
  def create_file(path, content = "")
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  def build_check(tmp_dir, options = {})
    described_class.new({ app_path: tmp_dir }.merge(options))
  end

  around do |example|
    Dir.mktmpdir do |tmp|
      @tmp = tmp
      example.run
    end
  end

  describe "#run" do
    context "when Dockerfile is missing" do
      it "adds an error" do
        result = build_check(@tmp).run
        expect(result.errors).to include(a_string_matching(/Dockerfile not found/))
      end
    end

    context "when Dockerfile exists with all required instructions" do
      before do
        content = <<~DOCKERFILE
          FROM ruby:3.2
          RUN bundle install
          EXPOSE 3000
          USER app
          CMD ["bundle", "exec", "rails", "server"]
        DOCKERFILE
        create_file(File.join(@tmp, "Dockerfile"), content)
      end

      it "adds no errors" do
        result = build_check(@tmp).run
        expect(result.errors).to be_empty
      end

      it "adds info for each required instruction" do
        result = build_check(@tmp).run
        expect(result.infos).to include(a_string_matching(/FROM/))
        expect(result.infos).to include(a_string_matching(/RUN/))
        expect(result.infos).to include(a_string_matching(/CMD/))
      end

      it "adds info for EXPOSE" do
        result = build_check(@tmp).run
        expect(result.infos).to include(a_string_matching(/EXPOSE/))
      end

      it "adds info for non-root USER" do
        result = build_check(@tmp).run
        expect(result.infos).to include(a_string_matching(/non-root USER/))
      end
    end

    context "when Dockerfile runs as root" do
      before do
        create_file(File.join(@tmp, "Dockerfile"), "FROM ruby:3.2\nUSER root\nRUN bundle install\nCMD [\"rails\", \"s\"]\n")
      end

      it "adds a warning about root user" do
        result = build_check(@tmp).run
        expect(result.warnings).to include(a_string_matching(/root user/))
      end
    end

    context "when Dockerfile has no USER instruction" do
      before do
        create_file(File.join(@tmp, "Dockerfile"), "FROM ruby:3.2\nRUN bundle install\nCMD [\"rails\", \"s\"]\n")
      end

      it "warns that it defaults to root" do
        result = build_check(@tmp).run
        expect(result.warnings).to include(a_string_matching(/defaults to root/))
      end
    end

    context "when Dockerfile is missing EXPOSE" do
      before do
        create_file(File.join(@tmp, "Dockerfile"), "FROM ruby:3.2\nRUN bundle install\nUSER app\nCMD [\"rails\", \"s\"]\n")
      end

      it "warns about missing EXPOSE" do
        result = build_check(@tmp).run
        expect(result.warnings).to include(a_string_matching(/EXPOSE/))
      end
    end
  end
end
