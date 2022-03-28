module SettingsReader
  module VaultResolver
    # Vault Lease refresher task
    class Refresher
      include Logging

      DEFAULT_RENEW_DELAY = 200
      REFRESH_INTERVAL = 60

      def initialize(cache)
        @cache = cache
      end

      def refresh
        @cache.entries.each do |entry|
          debug { "Checking lease for #{entry}. Leased?: #{entry.leased?}. Expires in: #{entry.expires_in}s" }
          next unless entry.leased?
          next unless entry.expires_in < DEFAULT_RENEW_DELAY

          info { "Refreshing lease for #{entry}. Expires in: #{entry.expires_in}" }
          entry.renew
          info { "Lease renewed for #{entry}. Expires in: #{entry.expires_in}" }
        rescue SettingsReader::VaultResolver::Error => e
          error { "Error refreshing lease for #{entry}: #{e.message}" }
          # Continue renewal.
        end
      end

      def self.refresh_task(cache)
        refresher = self
        Concurrent::TimerTask.new(execution_interval: refresher::REFRESH_INTERVAL) do
          info { 'Refreshing Vault leases' }
          refresher.new(cache).refresh
        end
      end
    end
  end
end
