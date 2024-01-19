require 'concurrent/promise'

module SettingsReader
  module VaultResolver
    # Vault Lease refresher task
    class Refresher
      include Logging

      DEFAULT_RENEW_DELAY = 200
      REFRESH_INTERVAL = 60

      attr_reader :cache, :config

      def initialize(cache, config)
        @cache = cache
        @config = config
      end

      def refresh
        info { 'Performing Vault leases refresh' }
        promises = cache.active_entries.map do |entry|
          debug { "Checking lease for #{entry}. Renewable?: #{entry.renewable?}. Expires in: #{entry.expires_in}s" }
          refresh_entry(entry)
        end.compact
        promises.each(&:wait)
        promises
      end

      def refresh_entry(entry)
        return unless entry.expires_in < config.lease_renew_delay

        Concurrent::Promise.execute do
          debug { "Refreshing lease for #{entry}. Expires in: #{entry.expires_in}" }
          config.vault_engine_for(entry.address).renew(entry)
          info { "Lease renewed for #{entry}. Expires in: #{entry.expires_in}" }
          entry
        rescue StandardError => e
          handle_refresh_error(e, entry)
        end
      end

      private

      def handle_refresh_error(error, entry)
        handle_lease_not_found(entry) if lease_not_found_error?(error)

        error { "Error refreshing lease for #{entry}: #{error.message}" }
        raise SettingsReader::VaultResolver::Error, error.message
      end

      def lease_not_found_error?(error)
        error.is_a?(Vault::HTTPClientError) && error.code == 400 && error.message =~ /lease not found/
      end

      def handle_lease_not_found(entry)
        cache.clear(entry)
        config.lease_not_found_handler.call(entry)
      end
    end
  end
end
