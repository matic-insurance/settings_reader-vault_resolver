module SettingsReader
  module VaultResolver
    # Secrets cache for seamless dynamic keys and renewal operations
    class Cache
      attr_accessor :raise_on_missing

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
        if !address.no_cache? && (existing_entry = retrieve(address))
          existing_entry
        else
          new_entry = block.call(address)
          secret_value = new_entry&.value_for(address.attribute)
          if secret_value.nil? || secret_value.empty?
            if raise_on_missing
              raise SettingsReader::VaultResolver::Error,
                    "Secret not found at #{address}. Secret data: #{new_entry&.secret&.to_h}"
            end
          elsif new_entry
            save(new_entry)
          end

          new_entry
        end
      end

      def entries(&block)
        @secrets.each_value(&block)
      end

      def active_entries(&block)
        @secrets.values.select(&:active?).each(&block)
      end

      def clear_all
        @secrets = {}
      end

      private

      def cache_key(address)
        address.full_path
      end
    end
  end
end
