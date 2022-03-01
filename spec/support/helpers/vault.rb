module Helpers
  module VaultHelpers
    attr_accessor :vault_keys

    def set_vault_value(path, data)
      self.vault_keys ||= []
      self.vault_keys << path
      Vault.kv('secret').write(path, data)
    end

    def clear_vault_values
      return unless self.vault_keys

      self.vault_keys.each do |path|
        Vault.kv('secret').delete(path)
      end
      self.vault_keys = []
    end
  end
end

RSpec.configure do |config|
  config.include(Helpers::VaultHelpers, :vault)

  config.before(:each, :vault) do
    Vault.address = 'http://127.0.0.1:8200'
    Vault.token = 'vault_root_token'

    # Use token with custom policy to access the vault
    secret = Vault.auth_token.create(policies: %(app))
    Vault.token = secret.auth.client_token
  end

  config.after(:each, :vault) do
    clear_vault_values
  end
end
