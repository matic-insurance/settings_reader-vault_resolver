require_relative '../patches/authenticate'

module SettingsReader
  module VaultResolver
    module Helpers
      # Helps with authentication using different schemes
      class VaultAuthentication
        FAKE_RESOLVER_PATH = 'vault/authentication'.freeze

        def authenticate_via_k8s(role, route: nil, service_token_path: nil)
          params = URI.encode_www_form({ role: role, route: route, service_token_path: service_token_path }.compact)
          resolver.resolve("vault://auth/kubernetes/login?#{params}#client_token", FAKE_RESOLVER_PATH)
        end

        private

        def resolver
          @resolver = SettingsReader::VaultResolver.resolver
        end
      end
    end
  end
end
