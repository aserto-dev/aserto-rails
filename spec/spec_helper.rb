# frozen_string_literal: true

require "rubygems"
require "bundler/setup"
require "logger"

Bundler.require

require "rspec"
require "grpc_mock/rspec"
require "rack"

require "simplecov"
SimpleCov.start do
  enable_coverage :branch
  track_files "lib/**/*.rb"
end

GrpcMock.disable_net_connect!

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expose_dsl_globally = true

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

require "aserto/rails"
