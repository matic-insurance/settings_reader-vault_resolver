require 'logger'
require 'concurrent/timer_task'

require 'settings_reader'
require_relative 'vault_resolver/version'
require_relative 'vault_resolver/logging'
require_relative 'vault_resolver/configuration'
require_relative 'vault_resolver/address'
require_relative 'vault_resolver/entry'
require_relative 'vault_resolver/engines/abstract'
require_relative 'vault_resolver/engines/auth'
require_relative 'vault_resolver/engines/kv2'
require_relative 'vault_resolver/engines/database'
require_relative 'vault_resolver/cache'
require_relative 'vault_resolver/refresher'
require_relative 'vault_resolver/refresher_observer'
require_relative 'vault_resolver/instance'

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
      @configuration.vault_initializer.call
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
