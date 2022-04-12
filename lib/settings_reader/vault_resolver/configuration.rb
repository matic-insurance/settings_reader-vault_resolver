module SettingsReader
  module VaultResolver
    # Configurations for vault resolver
    class Configuration
      # Logger for gem
      # Default: Logger.new(STDOUT, level: Logger::ERROR)
      attr_accessor :logger

      # How often do we check if secret lease is about to expire
      # Default: 60seconds
      attr_accessor :lease_refresh_interval

      # Time before expiration when we try to renew the lease
      # Default: 300seconds
      attr_accessor :lease_renew_delay

      # Block to be executed when lease is refreshed
      # Default: empty proc
      attr_accessor :lease_renew_success_listener

      # Block to be executed when lease is not refreshed
      # Default: empty proc
      attr_accessor :lease_renew_error_listener

      def initialize
        @logger = Logger.new($stdout, level: Logger::ERROR)
        @lease_refresh_interval = 60
        @lease_renew_delay = 300
        @lease_renew_error_listener = proc {}
        @lease_renew_success_listener = proc {}
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
