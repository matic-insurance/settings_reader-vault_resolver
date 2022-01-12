module SettingsReader
  module VaultResolver
    class Cache
      def initialize
        @secrets = {}
      end

      def retrieve(address)
        return nil unless (entry = @secrets[address.to_s])
        return clear(entry) if entry.expired?

        entry
      end

      def save(entry)
        @secrets[entry.address.to_s] = entry
      end

      def clear(entry)
        @secrets.delete(entry.address.to_s)
        nil
      end

      def fetch(address, &block)
        return exiting_entry if (exiting_entry = retrieve(address))

        new_entry = block.call(address)
        save(new_entry)
        new_entry
      end

      protected

    end
  end
end