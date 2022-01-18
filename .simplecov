if ENV["COVERAGE"]
  require 'simplecov'
  require 'codecov'
  SimpleCov.start
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end