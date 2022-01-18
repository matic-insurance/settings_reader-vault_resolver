if ENV["COVERAGE"]
  require 'simplecov'
  require 'codecov'
  SimpleCov.start do
    enable_coverage :branch
    primary_coverage :branch
    formatter SimpleCov::Formatter::Codecov
  end
end