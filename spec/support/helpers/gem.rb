module Helpers
  module Gem
    def current_config
      SettingsReader::VaultResolver.configuration
    end

    def address_for(path)
      SettingsReader::VaultResolver::Address.new(path)
    end

    def build_entry_for(path, secret)
      SettingsReader::VaultResolver::Entry.new(address_for(path), secret)
    end

    def entry_double(options = {})
      instance_double(SettingsReader::VaultResolver::Entry, options)
    end

    def address_double(options = {})
      instance_double(SettingsReader::VaultResolver::Address, options)
    end
  end
end

RSpec.configure do |config|
  config.include(Helpers::Gem)

  config.before(:each) do
    SettingsReader::VaultResolver.configure do |conf|
      conf.logger = Logger.new($stdout, level: Logger::FATAL)
    end
  end
end
