require 'concurrent/timer_task'
require 'settings_reader'
require 'settings_reader/vault_resolver/version'
require 'settings_reader/vault_resolver/address'
require 'settings_reader/vault_resolver/entry'
require 'settings_reader/vault_resolver/cache'
require 'settings_reader/vault_resolver/refresher'
require 'settings_reader/vault_resolver/instance'

module SettingsReader
  # Singleton for lease renewals and secrets cache
  module VaultResolver
    class Error < StandardError; end

    class << self
      attr_accessor :cache, :refresher_timer_task
    end

    def self.setup_cache
      self.cache ||= SettingsReader::VaultResolver::Cache.new
    end

    def self.setup_lease_refresher
      self.refresher_timer_task ||= SettingsReader::VaultResolver::Refresher.refresh_task(self.cache)
      self.refresher_timer_task.execute
    end

    def self.resolver
      SettingsReader::VaultResolver::Instance.new
    end

    setup_cache
    setup_lease_refresher
  end
end
