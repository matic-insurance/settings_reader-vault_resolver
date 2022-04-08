module SettingsReader
  module VaultResolver
    # Wrapper around vault secret object
    class Entry
      attr_reader :address, :secret

      MONTH = 30 * 60 * 60

      def initialize(address, secret)
        @address = address
        @secret = secret
        @lease_started = Time.now
      end

      def leased?
        lease_id && lease_duration.positive?
      end

      def expired?
        return false unless leased?

        Time.now > @lease_started + lease_duration
      end

      def expires_in
        return MONTH unless leased?

        @lease_started + lease_duration - Time.now
      end

      def lease_id
        @secret.lease_id
      end

      def update_renewed(new_secret)
        @secret = new_secret
        @lease_started = Time.now
      end

      def renew
        return unless leased?

        @secret = Vault.sys.renew(@secret.lease_id)
        @lease_started = Time.now
        true
      rescue Vault::HTTPClientError => e
        raise SettingsReader::VaultResolver::Error, e.message
      end

      def value_for(attribute)
        secret.data[attribute.to_sym]
      end

      def to_s
        address.to_s
      end

      private

      def lease_duration
        @secret.lease_duration.to_i
      end
    end
  end
end
