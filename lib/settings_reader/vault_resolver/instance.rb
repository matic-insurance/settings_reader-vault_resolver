require 'vault'

module SettingsReader
  module VaultResolver
    # Resolver class for Settings Reader
    class Instance
      IDENTIFIER = 'vault://'.freeze
      DATABASE_MOUNT = 'database'.freeze

      def resolvable?(value, _path)
        return unless value.respond_to?(:start_with?)

        value.start_with?(IDENTIFIER)
      end

      # Expect value in format `vault://mount/path/to/secret?attribute_name`
      def resolve(value, _path)
        address = SettingsReader::VaultResolver::Address.new(value)
        entry = fetch_entry(address)
        entry&.value_for(address.attribute)
      end

      # Resolve KV secret
      def kv_secret(address)
        Vault.kv(address.mount).read(address.path)
      end

      def database_secret(address)
        Vault.logical.read(address.full_path)
      rescue Vault::HTTPClientError => e
        raise unless e.message.include?('* unknown role')

        nil
      end

      private

      def fetch_entry(address)
        cache.fetch(address) do
          if (secret = address.mount == DATABASE_MOUNT ? database_secret(address) : kv_secret(address))
            SettingsReader::VaultResolver::Entry.new(address, secret)
          end
        end
      end

      def cache
        SettingsReader::VaultResolver.cache
      end
    end
  end
end
