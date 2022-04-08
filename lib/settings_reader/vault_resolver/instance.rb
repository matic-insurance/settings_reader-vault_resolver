require 'vault'

module SettingsReader
  module VaultResolver
    # Resolver class for Settings Reader
    class Instance
      include Logging

      IDENTIFIER = 'vault://'.freeze
      DATABASE_MOUNT = 'database'.freeze

      attr_reader :config

      def initialize(config)
        @config = config
        @engines = config.vault_engines
      end

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

      private

      def fetch_entry(address)
        cache.fetch(address) do
          info { "Retrieving new secret at: #{address}" }
          config.vault_engine_for(address).get(address)
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
