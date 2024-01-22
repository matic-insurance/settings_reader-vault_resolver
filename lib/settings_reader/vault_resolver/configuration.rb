module SettingsReader
  module VaultResolver
    # Configurations for vault resolver
    class Configuration
      # Logger for gem
      # Default: Logger.new(STDOUT, level: Logger::ERROR)
      attr_accessor :logger

      # What errors should be retried when connecting to vault
      # Default: `Vault::HTTPConnectionError` and `OpenSSL::SSL::SSLError`
      attr_accessor :retriable_errors

      # How many times to retry retrieval of the secret
      # Default: 2
      attr_accessor :retrieval_retries

      # How often do we check if secret lease is about to expire
      # Default: 60seconds
      attr_accessor :lease_refresh_interval

      # Time before expiration when we try to renew the lease
      # Default: 300seconds
      attr_accessor :lease_renew_delay

      # How many times to retry renew of the secret
      # Default: 4
      attr_accessor :lease_renew_retries

      # Block to be executed when lease is refreshed
      # Default: empty proc
      attr_accessor :lease_renew_success_listener

      # Block to be executed when lease is not refreshed
      # Default: empty proc
      attr_accessor :lease_renew_error_listener

      # Block to be executed for initialization and authorization
      # Default: empty proc
      attr_accessor :vault_initializer

      # Block to be executed when "lease not found" error is raised
      # Default: empty proc
      attr_accessor :lease_not_found_handler

      def initialize
        @logger = Logger.new($stdout, level: Logger::ERROR)
        @retriable_errors = [OpenSSL::SSL::SSLError, Vault::HTTPConnectionError]
        @retrieval_retries = 2
        @lease_refresh_interval = 60
        @lease_renew_delay = 300
        @lease_renew_retries = 4
        @lease_renew_error_listener = ->(_result) {}
        @lease_renew_success_listener = ->(_result) {}
        @vault_initializer = -> {}
        @lease_not_found_handler = ->(_entry) {}
      end

      def setup_lease_refresher(cache, previous_task = nil)
        previous_task&.shutdown

        timer_task = Concurrent::TimerTask.new(execution_interval: lease_refresh_interval) do
          SettingsReader::VaultResolver::Refresher.new(cache, self).refresh
        end
        timer_task.add_observer(SettingsReader::VaultResolver::RefresherObserver.new(self))
        timer_task.execute
        timer_task
      end

      def vault_engines
        @vault_engines ||= [
          SettingsReader::VaultResolver::Engines::KV2.new(self),
          SettingsReader::VaultResolver::Engines::Database.new(self),
          SettingsReader::VaultResolver::Engines::Aws.new(self),
          SettingsReader::VaultResolver::Engines::Auth.new(self)
        ]
      end

      def vault_engine_for(address)
        unless (engine = vault_engines.detect { |e| e.retrieves?(address) })
          raise SettingsReader::VaultResolver::Error, "Unknown engine for #{address}"
        end

        engine
      end
    end
  end
end
