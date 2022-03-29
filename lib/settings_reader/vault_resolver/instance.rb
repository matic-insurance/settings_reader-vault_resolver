require 'vault'

module SettingsReader
  module VaultResolver
    # Resolver class for Settings Reader
    class Instance
      include Logging

      IDENTIFIER = 'vault://'.freeze
      DATABASE_MOUNT = 'database'.freeze

      def resolvable?(value, _path)
        return unless value.respond_to?(:start_with?)

        value.start_with?(IDENTIFIER)
      end

      # Expect value in format `vault://mount/path/to/secret?attribute_name`
      def resolve(value, _path)
        debug { "Resolving Vault secret at #{value}" }
        address = SettingsReader::VaultResolver::Address.new(value)
        entry = fetch_entry(address)
        entry&.value_for(address.attribute)
      end

      # Resolve KV secret
      def kv_secret(address)
        debug { "Fetching new kv secret at: #{address}" }
        Vault.kv(address.mount).read(address.path)
      rescue Vault::HTTPClientError => e
        raise SettingsReader::VaultResolver::Error, e.message
      end

      def database_secret(address)
        debug { "Fetching new database secret at: #{address}" }
        Vault.logical.read(address.full_path)
      rescue Vault::HTTPClientError => e
        return nil if e.message.include?('* unknown role')

        raise SettingsReader::VaultResolver::Error, e.message
      end

      private

      def fetch_entry(address)
        cache.fetch(address) do
          info { "Retrieving new secret at: #{address}" }
          if (secret = address.mount == DATABASE_MOUNT ? database_secret(address) : kv_secret(address))
            debug { "Retrieved secret at: #{address}" }
            SettingsReader::VaultResolver::Entry.new(address, secret)
          end
        end
      rescue StandardError => e
        error { "Error retrieving secret: #{address}: #{e.message}" }
        raise e
      end

      def cache
        SettingsReader::VaultResolver.cache
      end
    end
  end
end
