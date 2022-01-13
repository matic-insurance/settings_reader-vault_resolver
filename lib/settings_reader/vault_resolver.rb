require "settings_reader/vault_resolver/version"
require "settings_reader/vault_resolver/resolver"
require "settings_reader/vault_resolver/address"
require "settings_reader/vault_resolver/entry"
require "settings_reader/vault_resolver/cache"
require "settings_reader/vault_resolver/refresher"

module SettingsReader
  module VaultResolver
    class Error < StandardError; end

    class << self
      attr_accessor :cache, :resolver
    end

    self.cache ||= SettingsReader::VaultResolver::Cache.new
  end
end
