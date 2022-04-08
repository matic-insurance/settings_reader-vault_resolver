module SettingsReader
  module VaultResolver
    module Engines
      # Adapter to retrieve / renew secret from database engine
      class Database < Abstract
        MOUNT = 'database'.freeze

        def retrieves?(address)
          address.mount == MOUNT
        end

        private

        def get_secret(address)
          debug { "Fetching new database secret at: #{address}" }
          Vault.logical.read(address.full_path)
        rescue Vault::VaultError => e
          return nil if e.message.include?('* unknown role')

          raise e
        end

        def renew_lease(entry)
          Vault.sys.renew(entry.lease_id)
        end
      end
    end
  end
end
