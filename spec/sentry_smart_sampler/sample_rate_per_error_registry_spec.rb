# frozen_string_literal: true

require "spec_helper"

RSpec.describe SentrySmartSampler::SampleRatePerErrorRegistry do
  describe "#sample_rate_registration_for" do
    subject(:sample_rate_registration_for) { registry.sample_rate_registration_for(error) }

    let(:registry) { described_class.new(default_sample_rate) }
    let(:default_sample_rate) { 0.5 }

    before do
      registry.declare RuntimeError, sample_rate: 0.1
      registry.declare(%r{magic pattern}, sample_rate: 0.2)
      registry.declare "magic string", sample_rate: 0.3
    end

    context "when the error has a sampling rate defined" do
      let(:error) { error_class.new(error_message) }

      context "when matching by error class" do
        let(:error_class) { RuntimeError }
        let(:error_message) { "other message" }

        it "returns the registration for the given error" do
          expect(sample_rate_registration_for.sample_rate).to eq 0.1
        end
      end

      context "when matching by regexp" do
        let(:error_class) { StandardError }
        let(:error_message) { "this is the error containing a magic pattern." }

        it "returns the registration for the given error" do
          expect(sample_rate_registration_for.sample_rate).to eq 0.2
        end
      end

      context "when matching by string" do
        let(:error_class) { StandardError }
        let(:error_message) { "this is the error containing a magic string." }

        it "returns the registration for the given error" do
          expect(sample_rate_registration_for.sample_rate).to eq 0.3
        end
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
