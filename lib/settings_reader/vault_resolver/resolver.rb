require 'vault'

module SettingsReader
  module VaultResolver
    class Resolver
      IDENTIFIER = 'vault://'.freeze
      DATABASE_PREFIX = 'database/'.freeze

      def resolvable?(value, _path)
        return unless value.respond_to?(:start_with?)

        value.start_with?(IDENTIFIER)
      end

      # Expect value in format `vault://mount/path/to/secret?attribute_name`
      def resolve(value, _path)
        path = value.delete_prefix(IDENTIFIER)
        path, attribute = path.split('?')
        secret = path.start_with?(DATABASE_PREFIX) ? database_secret(path) : kv_secret(path)
        secret && secret.data[attribute.to_sym]
      end

      #Resolve KV secret
      def kv_secret(path)
        mount, path = path.split('/', 2)
        Vault.kv(mount).read(path)
      end

      def database_secret(path)
        Vault.logical.read(path)
      rescue Vault::HTTPClientError => e
        raise unless e.message.include?('* unknown role')
        nil
      end
    end
  end
end
