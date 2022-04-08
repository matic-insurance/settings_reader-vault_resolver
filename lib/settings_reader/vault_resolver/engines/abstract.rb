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
          return unless (vault_secret = get_secret(address))

          wrap_secret(address, vault_secret)
        rescue Vault::VaultError => e
          raise SettingsReader::VaultResolver::Error, e.message
        end

        def renew(entry)
          return unless entry.leased?

          new_secret = renew_lease(entry)
          entry.update_renewed(new_secret)
          true
        rescue Vault::VaultError => e
          raise SettingsReader::VaultResolver::Error, e.message
        end

        protected

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
