# frozen_string_literal: true

require "spec_helper"
require "rails_deploy_check/checks/feature_flags_check"
require "rails_deploy_check/checks/feature_flags_check_integration"

RSpec.describe RailsDeployCheck::Checks::FeatureFlagsCheck do
  include_context "with_tmp_rails_app"

  def create_file(relative_path, content = "")
    full_path = File.join(tmp_path, relative_path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
  end

  def build_check(options = {})
    described_class.new({ app_path: tmp_path }.merge(options))
  end

  describe "#run" do
    context "when Gemfile.lock does not exist" do
      it "adds an info message and does not error" do
        result = build_check.run
        expect(result.infos).to include(a_string_matching(/Gemfile.lock not found/))
        expect(result.errors).to be_empty
      end
    end

    context "when Flipper gem is in Gemfile.lock" do
      before do
        create_file("Gemfile.lock", "GEM\n  specs:\n    flipper (0.28.0)\n    flipper-active_record (0.28.0)\n")
      end

      it "reports Flipper gem detected" do
        result = build_check.run
        expect(result.infos).to include(a_string_matching(/Flipper gem detected/))
      end

      context "and initializer is missing" do
        it "adds a warning about missing initializer" do
          result = build_check.run
          expect(result.warnings).to include(a_string_matching(/no initializer or config file found/))
        end
      end

      context "and initializer exists" do
        before do
          create_file("config/initializers/flipper.rb", "Flipper.enable(:my_feature)\n")
        end

        it "reports initializer found" do
          result = build_check.run
          expect(result.infos).to include(a_string_matching(/Flipper initializer found/))
        end
      end
    end

    context "when required_flags are specified" do
      before do
        create_file("Gemfile.lock", "GEM\n  specs:\n    flipper (0.28.0)\n")
        create_file("config/initializers/flipper.rb",
          "Flipper.enable(:dark_mode)\nFlipper.enable(:new_dashboard)\n")
      end

      it "passes when all required flags are present" do
        result = build_check(required_flags: [:dark_mode, :new_dashboard]).run
        expect(result.warnings).to be_empty
        expect(result.infos).to include(a_string_matching(/All required feature flags/))
      end

      it "warns when a required flag is missing" do
        result = build_check(required_flags: [:dark_mode, :beta_checkout]).run
        expect(result.warnings).to include(a_string_matching(/beta_checkout.*not found/))
      end
    end
  end

  describe RailsDeployCheck::Checks::FeatureFlagsCheckIntegration do
    context ".applicable?" do
      it "returns false when no Flipper files are present" do
        expect(described_class.applicable?(app_path: tmp_path)).to be false
      end

      it "returns true when flipper is in Gemfile.lock" do
        create_file("Gemfile.lock", "  flipper (0.28.0)\n")
        expect(described_class.applicable?(app_path: tmp_path)).to be true
      end

      it "returns true when flipper initializer exists" do
        create_file("config/initializers/flipper.rb", "")
        expect(described_class.applicable?(app_path: tmp_path)).to be true
      end
    end
  end
end
