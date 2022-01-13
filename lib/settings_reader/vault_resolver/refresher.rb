module SettingsReader
  module VaultResolver
    class Refresher
      DEFAULT_RENEW_DELAY = 120

      def initialize(cache)
        @cache = cache
      end

      def call
        @cache.entries.each do |entry|
          next unless entry.leased?
          next unless entry.expires_in < DEFAULT_RENEW_DELAY

          entry.renew
        end
      end
    end
  end
end