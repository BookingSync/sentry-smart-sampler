# frozen_string_literal: true

require "spec_helper"

RSpec.describe SentrySmartSampler::SampleRatePerErrorRegistry do
  describe "#sample_rate_registration_for" do
    subject(:sample_rate_registration_for) { registry.sample_rate_registration_for(error) }

    let(:registry) { described_class.new(default_sample_rate) }
    let(:default_sample_rate) { 0.5 }

    before do
      registry.declare(error_class: RuntimeError, sample_rate: 0.1)
    end

    context "when the error has a sampling rate defined" do
      let(:error) { RuntimeError.new }

      it "returns the registration for the given error" do
        expect(sample_rate_registration_for.sample_rate).to eq 0.1
      end
    end

    context "when the error does not have a sampling rate defined" do
      let(:error) { StandardError.new }

      it "returns the registration for the given error" do
        expect(sample_rate_registration_for.sample_rate).to eq 0.5
      end
    end
  end
end
