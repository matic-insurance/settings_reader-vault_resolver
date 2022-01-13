require 'vault'

module SettingsReader
  module VaultResolver
    class Resolver
      IDENTIFIER = 'vault://'.freeze
      DATABASE_MOUNT = 'database'.freeze

      def resolvable?(value, _path)
        return unless value.respond_to?(:start_with?)

        value.start_with?(IDENTIFIER)
      end

      # Expect value in format `vault://mount/path/to/secret?attribute_name`
      def resolve(value, _path)
        address = SettingsReader::VaultResolver::Address.new(value)
        secret = address.mount == DATABASE_MOUNT ? database_secret(address) : kv_secret(address)
        secret && secret.data[address.attribute.to_sym]
      end

      #Resolve KV secret
      def kv_secret(address)
        Vault.kv(address.mount).read(address.path)
      end

      def database_secret(address)
        Vault.logical.read(address.full_path)
      rescue Vault::HTTPClientError => e
        raise unless e.message.include?('* unknown role')

        nil
      end
    end
  end
end
