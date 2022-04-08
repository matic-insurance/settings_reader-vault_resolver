module SettingsReader
  module VaultResolver
    module Engines
      # Adapter to retrieve / renew secret from kv2 engine
      class KV2 < Abstract
        MOUNT = 'secret'.freeze

        def retrieves?(address)
          address.mount == MOUNT
        end

        def renew(_entry)
          # KV secrets are static. Nothing to do
        end

        private

        def get_secret(address)
          debug { "Fetching new kv secret at: #{address}" }
          Vault.kv(address.mount).read(address.path)
        end
      end
    end
  end
end
