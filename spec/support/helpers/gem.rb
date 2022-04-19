module Helpers
  module Gem
    def current_config
      SettingsReader::VaultResolver.configuration
    end

    def address_for(path)
      SettingsReader::VaultResolver::Address.new(path)
    end

    def build_entry_for(path, secret)
      address = path.is_a?(String) ? address_for(path) : path
      SettingsReader::VaultResolver::Entry.new(address, secret)
    end

    def entry_double(options = {})
      instance_double(SettingsReader::VaultResolver::Entry, options)
    end

    def address_double(options = {})
      instance_double(SettingsReader::VaultResolver::Address, options)
    end

    def vault_secret_double(options = {})
      defaults = { data: {} }
      instance_double(Vault::Secret, defaults.merge(options))
    end

    def vault_auth_double(options = {})
      instance_double(Vault::SecretAuth, options)
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

  config.after(:each) do
    SettingsReader::VaultResolver.cache.clear_all
  end
end
