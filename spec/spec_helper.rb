# frozen_string_literal: true

require "bundler/setup"
require "support/is_expected_block"
require "timecop"
require "sentry_smart_sampler"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include IsExpectedBlock

  config.around(:example, :freeze_time) do |example|
    freeze_time = example.metadata[:freeze_time]
    time_now = freeze_time == true ? Time.current.round : freeze_time
    Timecop.freeze(time_now) { example.run }
  end

  config.before do
    SentrySmartSampler.reset!
  end
end

RSpec::Matchers.define_negated_matcher :avoid_changing, :change
