module Helpers
  module VaultHelpers
    attr_accessor :vault_keys

    def set_vault_value(path, value)
      mount, secret = path.split('/', 2)
      secret, attribute = secret.split('?')
      self.vault_keys ||= []
      self.vault_keys << [mount, secret]
      serialized_value = value.is_a?(String) ? value : value.to_json
      Vault.kv(mount).write(secret, attribute => serialized_value)
    end

    def clear_vault_values
      return unless self.vault_keys

      self.vault_keys.each do |mount, secret|
        Vault.kv(mount).delete(secret)
      end
      self.vault_keys = []
    end
  end
end

RSpec.configure do |config|
  config.include(Helpers::VaultHelpers, :vault)

  config.before(:each, :vault) do
    Vault.address = 'http://127.0.0.1:8200'
    Vault.token = 'vault_resolver_token'
  end

  config.after(:each, :vault) do
    clear_vault_values
  end
end
