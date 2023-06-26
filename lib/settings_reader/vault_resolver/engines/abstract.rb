module SettingsReader
  module VaultResolver
    module Engines
      # Abstract interface for Vault Backends
      class Abstract
        include Logging

        attr_reader :config

        def initialize(config)
          @config = config
        end

        def retrieves?(_address)
          raise NotImplementedError
        end

        def get(address)
          return unless (vault_secret = get_and_retry_auth(address))

          wrap_secret(address, vault_secret)
        rescue Vault::VaultError => e
          raise SettingsReader::VaultResolver::Error, e.message
        end

        def renew(entry)
          return unless entry.leased?

          new_secret = renew_and_retry_auth(entry)
          entry.update_renewed(new_secret)
          true
        end

        protected

        def get_and_retry_auth(address)
          get_and_retry_connection(address)
        rescue Vault::HTTPError => e # if not authenticated, let's reauthenticate and try once more
          raise unless auth_error?(e)

          config.vault_initializer.call
          get_and_retry_connection(address)
        end

        def get_and_retry_connection(address)
          Vault.with_retries(*config.retriable_errors, attempts: config.retrieval_retries) do
            get_secret(address)
          end
        end

        def renew_and_retry_auth(entry)
          renew_and_retry_connection(entry)
        rescue Vault::HTTPError => e # if not authenticated, let's reauthenticate and try once more
          raise unless auth_error?(e)

          config.vault_initializer.call
          renew_and_retry_connection(entry)
        end

        def renew_and_retry_connection(entry)
          Vault.with_retries(*config.retriable_errors, attempts: config.lease_renew_retries) do
            renew_lease(entry)
          end
        end

        def get_secret(address)
          raise NotImplementedError
        end

        def renew_lease(entry)
          raise NotImplementedError
        end

        def wrap_secret(address, secret)
          SettingsReader::VaultResolver::Entry.new(address, secret)
        end

        def auth_error?(error)
          error.code == 403 || error.message =~ /token mac for token_version.*is incorrect/
        end
      end
    end
  end
end
