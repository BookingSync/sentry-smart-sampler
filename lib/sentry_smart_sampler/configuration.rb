# frozen_string_literal: true

class SentrySmartSampler::Configuration
  attr_accessor :cache_storage, :logger, :default_throttling_errors_number_threshold
  attr_reader :default_throttling_time_unit
  attr_writer :default_sample_rate, :after_throttling_threshold_reached

  TIME_UNITS = %i[second minute hour day].freeze
  private_constant :TIME_UNITS

  def default_sample_rate
    @default_sample_rate || 1
  end

  def after_throttling_threshold_reached
    @after_throttling_threshold_reached || default_after_throttling_threshold_reached_callback
  end

  def default_throttling_time_unit=(time_unit)
    time_unit = time_unit.to_sym
    validate_time_unit(time_unit)
    @default_throttling_time_unit = time_unit
  end

  def declare_sampling_rate_per_error(&block)
    sampling_rate_per_error_registry.instance_exec(&block)
  end

  def sampling_rate_per_error_registry
    @sampling_rate_per_error_registry ||= SampleRatePerErrorRegistry.new(default_sample_rate)
  end

  def declare_throttling_per_error(&block)
    throttling_per_error_registry.instance_exec(&block)
  end

  def throttling_per_error_registry
    @throttling_per_error_registry ||= ThrottlingPerErrorRegistry.new(default_throttling_errors_number_threshold,
      default_throttling_time_unit)
  end

  private

  def validate_time_unit(time_unit)
    TIME_UNITS.include?(time_unit) or raise_invalid_time_unit_error(time_unit)
  end

  def raise_invalid_time_unit_error(time_unit)
    raise(ArgumentError.new("Invalid time unit: :#{time_unit}, allowed_values: #{TIME_UNITS}"))
  end

  def default_after_throttling_threshold_reached_callback
    lambda do |_event, hint|
      error = hint[:exception]
      logger.info "[SentrySmartSampler] Throttling threshold reached for #{error.class}: #{error.message}"
    end
  end
end
