module SettingsReader
  module VaultResolver
    module Engines
      # Adapter to retrieve / renew secret from database engine
      class Aws < Abstract
        MOUNT = 'aws'.freeze

        def retrieves?(address)
          address.mount == MOUNT
        end

        private

        def get_secret(address)
          debug { "Fetching new aws secret at: #{address}" }
          Vault.logical.read(address.full_path)
        rescue Vault::HTTPClientError => e
          return nil if e.message.match?('Role ".*" not found')

          raise e
        end

        def renew_lease(entry)
          Vault.sys.renew(entry.lease_id)
        end
      end
    end
  end
end
