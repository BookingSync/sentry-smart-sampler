# frozen_string_literal: true

require "spec_helper"

RSpec.describe SentrySmartSampler::ThrottlingPerErrorRegistry do
  describe "#throttling_registration_for" do
    subject(:throttling_registration_for) { registry.throttling_registration_for(error) }

    let(:registry) { described_class.new(default_throttling_errors_number_threshold, default_throttling_time_unit) }
    let(:default_throttling_errors_number_threshold) { 100 }
    let(:default_throttling_time_unit) { :minute }

    before do
      registry.declare(error_class: RuntimeError, time_unit: :hour, threshold: 50)
    end

    context "when the error has a throttling config defined" do
      let(:error) { RuntimeError.new }

      it "returns the registration for the given error" do
        expect(throttling_registration_for.threshold).to eq 50
        expect(throttling_registration_for.time_unit).to eq :hour
      end
    end

    context "when the error does not have a throttling config defined" do
      let(:error) { StandardError.new }

      it "returns the registration for the given error" do
        expect(throttling_registration_for.threshold).to eq 100
        expect(throttling_registration_for.time_unit).to eq :minute
      end
    end
  end
end
