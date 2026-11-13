# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))
require "sales_taxes"
require_relative "support/builders"

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.expect_with(:rspec) { |c| c.syntax = :expect }
  config.order = :random
  config.include Builders
end
