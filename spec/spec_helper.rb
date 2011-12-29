$:.unshift "lib"
require "tasks"
require "rspec"

RSpec.configure do |config|
  config.expect_with :stdlib
  config.alias_example_to :test

  config.before(:all) do
  end
end
