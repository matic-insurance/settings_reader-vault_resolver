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
          return unless (vault_secret = get_secret_with_retries(address))

          wrap_secret(address, vault_secret)
        rescue Vault::VaultError => e
          raise SettingsReader::VaultResolver::Error, e.message
        end

        def renew(entry)
          return unless entry.leased?

          new_secret = renew_lease_with_retries(entry)
          entry.update_renewed(new_secret)
          true
        rescue Vault::VaultError => e
          raise SettingsReader::VaultResolver::Error, e.message
        end

        protected

        def get_secret_with_retries(address)
          Vault.with_retries(Vault::HTTPConnectionError, attempts: config.retrieval_retries) do
            get_secret(address)
          end
        end

        def renew_lease_with_retries(address)
          Vault.with_retries(Vault::HTTPConnectionError, attempts: config.lease_renew_retries) do
            renew_lease(address)
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
      end
    end
  end
end
