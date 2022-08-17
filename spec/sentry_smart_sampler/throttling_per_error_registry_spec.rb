# frozen_string_literal: true

require "spec_helper"

RSpec.describe SentrySmartSampler::ThrottlingPerErrorRegistry do
  describe "#throttling_registration_for" do
    subject(:throttling_registration_for) { registry.throttling_registration_for(error) }

    let(:registry) { described_class.new(default_throttling_errors_number_threshold, default_throttling_time_unit) }
    let(:default_throttling_errors_number_threshold) { 100 }
    let(:default_throttling_time_unit) { :minute }

    before do
      registry.declare(RuntimeError, time_unit: :hour, threshold: 50)
      registry.declare(%r{magic pattern}, time_unit: :hour, threshold: 100)
      registry.declare("magic string", time_unit: :hour, threshold: 200)
    end

    context "when the error has a throttling config defined" do
      let(:error) { error_class.new(error_message) }

      context "when matching by error class" do
        let(:error_class) { RuntimeError }
        let(:error_message) { "other message" }

        it "returns the registration for the given error" do
          expect(throttling_registration_for.threshold).to eq 50
          expect(throttling_registration_for.time_unit).to eq :hour
        end
      end

      context "when matching by regexp" do
        let(:error_class) { StandardError }
        let(:error_message) { "this is the error containing a magic pattern." }

        it "returns the registration for the given error" do
          expect(throttling_registration_for.threshold).to eq 100
          expect(throttling_registration_for.time_unit).to eq :hour
        end
      end

      context "when matching by string" do
        let(:error_class) { StandardError }
        let(:error_message) { "this is the error containing a magic string." }

        it "returns the registration for the given error" do
          expect(throttling_registration_for.threshold).to eq 200
          expect(throttling_registration_for.time_unit).to eq :hour
        end
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
