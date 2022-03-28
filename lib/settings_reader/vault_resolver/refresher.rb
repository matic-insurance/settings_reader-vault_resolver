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
        info { 'Starting Vault lease refreshing' }
        @cache.entries.each do |entry|
          refresh_entry(entry)
        end
        info { 'Finished Vault lease refreshing' }
      end

      def refresh_entry(entry)
        debug { "Checking lease for #{entry}. Leased?: #{entry.leased?}. Expires in: #{entry.expires_in}s" }
        return unless entry.leased?
        return unless entry.expires_in < DEFAULT_RENEW_DELAY

        info { "Refreshing lease for #{entry}. Expires in: #{entry.expires_in}" }
        entry.renew
        info { "Lease renewed for #{entry}. Expires in: #{entry.expires_in}" }
      rescue SettingsReader::VaultResolver::Error => e
        error { "Error refreshing lease for #{entry}: #{e.message}" }
        # Continue renewal.
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
