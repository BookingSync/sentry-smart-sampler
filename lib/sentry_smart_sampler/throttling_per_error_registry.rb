# frozen_string_literal: true

class SentrySmartSampler::ThrottlingPerErrorRegistry
  attr_reader :default_throttling_errors_number_threshold, :default_throttling_time_unit, :registry
  private     :default_throttling_errors_number_threshold, :default_throttling_time_unit, :registry

  def initialize(default_throttling_errors_number_threshold, default_throttling_time_unit)
    @default_throttling_errors_number_threshold = default_throttling_errors_number_threshold
    @default_throttling_time_unit = default_throttling_time_unit
    @registry = []
  end

  def declare(error_class:, time_unit:, threshold:)
    registry << Registration.new(error_class: error_class, time_unit: time_unit, threshold: threshold)
  end

  def throttling_registration_for(error)
    registry.find(-> { default_registration }) { |registration| error.is_a?(registration.error_class) }
  end

  private

  def default_registration
    Registration.new(error_class: nil, time_unit: default_throttling_time_unit,
      threshold: default_throttling_errors_number_threshold)
  end

  class Registration
    attr_reader :error_class, :threshold, :time_unit

    def initialize(error_class:, threshold:, time_unit:)
      @error_class = error_class
      @threshold = threshold
      @time_unit = time_unit
    end
  end
end
