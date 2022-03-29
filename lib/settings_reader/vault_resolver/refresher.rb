require 'concurrent/promise'

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
        info { 'Performing Vault leases refresh' }
        promises = @cache.entries.map do |entry|
          debug { "Checking lease for #{entry}. Leased?: #{entry.leased?}. Expires in: #{entry.expires_in}s" }
          refresh_entry(entry)
        end.compact
        promises.each(&:wait)
        promises
      end

      def refresh_entry(entry)
        return unless entry.leased?
        return unless entry.expires_in < DEFAULT_RENEW_DELAY

        Concurrent::Promise.execute do
          debug { "Refreshing lease for #{entry}. Expires in: #{entry.expires_in}" }
          entry.renew
          info { "Lease renewed for #{entry}. Expires in: #{entry.expires_in}" }
        rescue StandardError => e
          error { "Error refreshing lease for #{entry}: #{e.message}" }
          raise SettingsReader::VaultResolver::Error, e.message
        end
      end
    end
  end
end
