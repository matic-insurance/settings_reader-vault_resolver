require 'logger'
require 'concurrent/timer_task'

require 'settings_reader'
require 'settings_reader/vault_resolver/version'
require 'settings_reader/vault_resolver/logging'
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
      attr_accessor :refresher_timer_task
    end

    def self.logger
      return @logger if @logger
      return @logger = Rails.logger if (defined? Rails) && Rails.logger

      @logger = Logger.new($stdout, level: Logger::INFO)
    end

    def self.logger=(logger)
      @logger = logger
    end

    def self.cache
      @cache ||= SettingsReader::VaultResolver::Cache.new
    end

    def self.resolver
      SettingsReader::VaultResolver::Instance.new
    end

    def self.setup_lease_refresher
      return @refresher_timer_task if @refresher_timer_task

      refresher = SettingsReader::VaultResolver::Refresher
      @refresher_timer_task = Concurrent::TimerTask.new(execution_interval: refresher::REFRESH_INTERVAL) do
        SettingsReader::VaultResolver::Refresher.new(cache).refresh
      end
      @refresher_timer_task.execute
    end

    setup_lease_refresher
  end
end
