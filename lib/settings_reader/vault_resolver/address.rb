module SettingsReader
  module VaultResolver
    class Address
      def initialize(uri)
        @uri = URI.parse(uri)
      end

      def mount
        @uri.host
      end

      def path
        @uri.path
      end

      def full_path
        "#{mount}#{path}"
      end

      def attribute
        @uri.fragment
      end

      def options
        URI::decode_www_form(@uri.query || '').to_h
      end

      def to_s
        @uri.to_s
      end
    end
  end
end
