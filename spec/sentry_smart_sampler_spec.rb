# frozen_string_literal: true

require "spec_helper"

RSpec.describe SentrySmartSampler do
  describe ".configuration/.configure" do
    subject(:default_sample_rate) { described_class.configuration.default_sample_rate }

    before do
      described_class.configure do |config|
        config.default_sample_rate = 0.5
      end
    end

    it { is_expected.to eq 0.5 }
  end

  describe ".sample_rate_registration_for" do
    subject(:sample_rate_registration_for) { described_class.sample_rate_registration_for(error) }

    before do
      described_class.configure do |config|
        config.default_sample_rate = 0.5
        config.declare_sampling_rate_per_error do
          declare RuntimeError, sample_rate: 0.1
        end
      end
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

  describe ".throttling_registration_for" do
    subject(:throttling_registration_for) { described_class.throttling_registration_for(error) }

    before do
      described_class.configure do |config|
        config.default_throttling_errors_number_threshold = 100
        config.default_throttling_time_unit = :minute

        config.declare_throttling_per_error do
          declare RuntimeError, time_unit: :hour, threshold: 50
        end
      end
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

  describe ".call" do
    subject(:call) { described_class.call(event, hint) }

    let(:event) { double }
    let(:hint) { { exception: error } }
    let(:error) { RuntimeError.new }

    before do
      described_class.configure do |config|
        config.default_sample_rate = 1

        config.declare_sampling_rate_per_error do
          declare RuntimeError, sample_rate: 0.1
        end
      end
    end

    context "when the error is allowed based on the sampling rate" do
      before do
        allow(Random).to receive(:rand).and_return(0.05)
      end

      it { is_expected.to eq event }
    end

    context "when the error is sampled out" do
      before do
        allow(Random).to receive(:rand).and_return(0.11)
      end

      it { is_expected.to be_nil }
    end
  end

  describe ".reset!" do
    subject(:reset!) { described_class.reset! }

    before do
      described_class.configuration
    end

    it { is_expected_block.to change { described_class.instance_variable_get(:@configuration) }.to(nil) }
  end
end
