# frozen_string_literal: true

class SentrySmartSampler::SampleRatePerErrorRegistry
  attr_reader :default_sample_rate, :registry
  private     :default_sample_rate, :registry

  def initialize(default_sample_rate)
    @default_sample_rate = default_sample_rate
    @registry = []
  end

  def declare(error_class:, sample_rate:)
    registry << Registration.new(error_class: error_class, sample_rate: sample_rate)
  end

  def sample_rate_registration_for(error)
    registry.find(-> { default_registration }) { |registration| error.is_a?(registration.error_class) }
  end

  private

  def default_registration
    Registration.new(error_class: nil, sample_rate: default_sample_rate)
  end

  class Registration
    attr_reader :error_class, :sample_rate

    def initialize(error_class:, sample_rate:)
      @error_class = error_class
      @sample_rate = sample_rate
    end
  end
end
