module SettingsReader
  module VaultResolver
    # Configurations for vault resolver
    class Configuration
      # How often do we check if secret lease is about to expire
      # Default: 60seconds
      attr_accessor :lease_refresh_interval

      # Time before expiration when we try to renew the lease
      # Default: 300seconds
      attr_accessor :lease_renew_delay

      def initialize
        @lease_refresh_interval = 60
        @lease_renew_delay = 300
      end

      def setup_lease_refresher(previous_task = nil)
        previous_task&.shutdown

        timer_task = Concurrent::TimerTask.new(execution_interval: lease_refresh_interval) do
          SettingsReader::VaultResolver::Refresher.new(cache).refresh
        end
        timer_task.execute
        timer_task
      end
    end
  end
end
