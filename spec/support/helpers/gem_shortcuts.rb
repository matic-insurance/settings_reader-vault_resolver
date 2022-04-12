module Helpers
  module GemShortcuts
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
  end
end

RSpec.configure do |config|
  config.include(Helpers::GemShortcuts)
end