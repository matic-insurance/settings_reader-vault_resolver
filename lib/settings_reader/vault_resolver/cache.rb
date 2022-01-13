module SettingsReader
  module VaultResolver
    class Cache
      def initialize
        @secrets = {}
      end

      def retrieve(address)
        return nil unless (entry = @secrets[cache_key(address)])
        return clear(entry) if entry.expired?

        entry
      end

      def save(entry)
        @secrets[cache_key(entry.address)] = entry
      end

      def clear(entry)
        @secrets.delete(cache_key(entry.address))
        nil
      end

      def fetch(address, &block)
        if (exiting_entry = retrieve(address))
          exiting_entry
        else
          new_entry = block.call(address)
          save(new_entry) if new_entry
          new_entry
        end
      end

      def entries(&block)
        @secrets.each_value(&block)
      end

      private

      def cache_key(address)
        address.full_path
      end
    end
  end
end