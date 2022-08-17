# SentrySmartSampler

Smart sampler for `sentry-ruby` with rate limiting/throttling and sampling specific errors.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sentry-smart-sampler'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install sentry-smart-sampler

## Usage

Inside Sentry initializer:

``` rb
Rails.application.config.to_prepare do
  SentrySmartSampler.configure do |config|
    config.cache_storage = Rails.cache # ideally a Rails cache backed by Redis. But could be anything responding to the same interface
    config.logger = Rails.logger
    config.default_sample_rate = 0.5 # defaults to 1
    config.declare_sampling_rate_per_error do
      declare Faraday::ClientError, sample_rate: 0.1
      declare ActiveRecord::RecordInvalid, sample_rate: 0.2
      declare /message pattern as regexp/, sample_rate: 0.3
      declare "message pattern as string", sample_rate: 0.4
    end
    
    config.default_throttling_errors_number_threshold = 100 # do not set it if you don't want errors to be throttled
    config.default_throttling_time_unit = :minute  # do not set it if you don't want errors to be throttled, other options: [:second, :minute, :hour, :day]
    # this config means that at most 100 errors of the same type can be sent withing a minute
    
    config.declare_throttling_per_error do
      declare ActiveRecord::StatementInvalid, time_unit: :hour, threshold: 50
      declare /message pattern as regexp/, time_unit: :hour, threshold: 100
      declare "message pattern as string", time_unit: :hour, threshold: 200
    end
    
    config.after_throttling_threshold_reached = lambda do |event, hint|
      # do something when the threshold is reached, e.g. send a Slack notification. This callback will be fired at most once, when the threshold is reached. Not required
      # when not provided, the error will be logged using logger
    end
  end
end

Sentry.init do |config| 
  config.dsn = ENV["SENTRY_DSN"]
  
  config.before_send = lambda do |event, hint|
    SentrySmartSampler.call(event, hint) # returns event or nil if the event should be dropped
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/sentry-smart-sampler.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
