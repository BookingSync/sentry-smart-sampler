# frozen_string_literal: true

require_relative "lib/sentry/smart/sampler/version"

Gem::Specification.new do |spec|
  spec.name          = "sentry-smart-sampler"
  spec.version       = Sentry::Smart::Sampler::VERSION
  spec.authors       = ["Karol Galanciak"]
  spec.email         = ["karol.galanciak@gmail.com"]

  spec.summary       = "Smart sampler for sentry-ruby with rate limiting/throttling and sampling specific errors"
  spec.description   = "Smart sampler for sentry-ruby with rate limiting/throttling and sampling specific errors"
  spec.homepage      = "https://github.com/BookingSync/sentry-smart-sampler"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.7.0")

  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/BookingSync/sentry-smart-sampler"
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    %x(git ls-files -z).split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  spec.add_dependency "activesupport", ">= 5"
  spec.add_dependency "sentry-ruby", "~> 5"
  spec.add_dependency "zeitwerk"

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
  spec.metadata["rubygems_mfa_required"] = "true"
end
