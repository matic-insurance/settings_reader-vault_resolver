require 'logger'
require 'concurrent/timer_task'

require 'settings_reader'
require 'settings_reader/vault_resolver/version'
require 'settings_reader/vault_resolver/logging'
require 'settings_reader/vault_resolver/configuration'
require 'settings_reader/vault_resolver/address'
require 'settings_reader/vault_resolver/entry'
require 'settings_reader/vault_resolver/engines/abstract'
require 'settings_reader/vault_resolver/engines/kv2'
require 'settings_reader/vault_resolver/engines/database'
require 'settings_reader/vault_resolver/cache'
require 'settings_reader/vault_resolver/refresher'
require 'settings_reader/vault_resolver/refresher_observer'
require 'settings_reader/vault_resolver/instance'

module SettingsReader
  # Singleton for lease renewals and secrets cache
  module VaultResolver
    class Error < StandardError; end

    class << self
      attr_reader :configuration, :refresher_timer_task
    end

    def self.configure(&block)
      @configuration = SettingsReader::VaultResolver::Configuration.new
      block&.call(@configuration)
      @refresher_timer_task = @configuration.setup_lease_refresher(cache, refresher_timer_task)
    end

    def self.cache
      @cache ||= SettingsReader::VaultResolver::Cache.new
    end

    def self.resolver
      raise Error, 'Gem not configured. Call configure before getting resolver' unless configuration

      SettingsReader::VaultResolver::Instance.new(configuration)
    end
  end
end
