module SettingsReader
  module VaultResolver
    module Engines
      # Adapter to retrieve / renew auth tokens
      class Auth < Abstract
        MOUNT = 'auth'.freeze
        AUTH_BACKEND = ENV['VAULT_AUTH_BACKEND'] || 'kubernetes'
        K8S_AUTH = "#{AUTH_BACKEND}/login".freeze

        def retrieves?(address)
          address.mount == MOUNT
        end

        protected

        # Auth backend should not retry auth errors as it causing infinite recursion
        def get_and_retry_auth(address)
          get_and_retry_connection(address)
        end

        # Auth backend should not retry auth errors as it causing infinite recursion
        def renew_and_retry_auth(address)
          renew_and_retry_connection(address)
        end

        def get_secret(address)
          return k8s_auth(address) if address.path == K8S_AUTH

          raise SettingsReader::VaultResolver::Error, "Unsupported auth backed for #{address}"
        end

        def renew_lease(_entry)
          secret = Vault.client.auth_token.renew_self
          secret&.auth
        end

        private

        def k8s_auth(address)
          options = { route: address.options['route'], service_token_path: address.options['service_token_path'] }
          secret = Vault.auth.kubernetes(address.options['role'], **options)
          secret&.auth
        end
      end
    end
  end
end
