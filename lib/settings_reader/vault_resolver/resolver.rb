require 'vault'

module SettingsReader
  module VaultResolver
    class Resolver
      IDENTIFIER = 'vault://'.freeze

      def resolvable?(value, _path)
        return unless value.respond_to?(:start_with?)

        value.start_with?(IDENTIFIER)
      end

      # Expect value in format `vault://mount/path/to/secret?attribute_name`
      def resolve(value, _path)
        value = value.delete_prefix(IDENTIFIER)
        mount, secret = value.split('/', 2)
        secret, attribute = secret.split('?')
        attribute ||= 'value'
        secret = ::Vault.kv(mount).read(secret)
        secret && secret.data[attribute.to_sym]
      end
    end
  end
end
