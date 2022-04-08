require_relative '../patches/authenticate'

module SettingsReader
  module VaultResolver
    module Helpers
      # Helps with Vault authentication using kubernetes login
      class K8sAuth
        def call(role, route: nil, service_token_path: nil)
          secret = Vault.auth.kubernetes(role, route: route, service_token_path: service_token_path)

          cache_token_for_renewal(secret)
          secret
        end

        private

        def cache_token_for_renewal(secret)
          address = SettingsReader::VaultResolver::Address.new('vault://v1/auth/token/lookup-self')
          entry = SettingsReader::VaultResolver::AuthEntry.new(address, secret)
          SettingsReader::VaultResolver.cache.save(entry)
          entry
        end
      end
    end

    # Helps with auth token lease renewal
    class AuthEntry < SettingsReader::VaultResolver::Entry
      def leased?
        true
      end

      def lease_duration
        @secret.auth.lease_duration
      end

      def renew
        Vault.client.auth_token.renew_self
        @lease_started = Time.now
        true
      end
    end
  end
end
