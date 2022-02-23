module SettingsReader
  module VaultResolver
    # Vault Lease refresher task
    class Refresher
      DEFAULT_RENEW_DELAY = 120
      REFRESH_INTERVAL = 60

      def initialize(cache)
        @cache = cache
      end

      def refresh
        @cache.entries.each do |entry|
          next unless entry.leased?
          next unless entry.expires_in < DEFAULT_RENEW_DELAY

          entry.renew
        end
      end

      def self.refresh_task(cache)
        refresher = self
        Concurrent::TimerTask.new(execution_interval: refresher::REFRESH_INTERVAL) do
          refresher.new(cache).refresh
        end
      end
    end
  end
end
