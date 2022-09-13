module SettingsReader
  module VaultResolver
    # Parsing of vault address
    class Address
      def initialize(uri)
        @uri = URI.parse(uri)
      end

      def mount
        @uri.host
      end

      def path
        @uri.path.delete_prefix('/')
      end

      def full_path
        "#{mount}#{@uri.path}"
      end

      def attribute
        @uri.fragment
      end

      def options
        URI.decode_www_form(@uri.query || '').to_h
      end

      def no_cache?
        options['no_cache'] == 'true'
      end

      def to_s
        @uri.to_s
      end
    end
  end
end
