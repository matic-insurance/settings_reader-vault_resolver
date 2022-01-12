module SettingsReader
  module VaultResolver
    class Entry
      attr_reader :address, :secret

      def initialize(address, secret)
        @address = address
        @secret = secret
        @lease_started = Time.now
      end

      def expired?
        return false unless secret.lease_duration.to_i > 0

        Time.now > @lease_started + secret.lease_duration
      end
    end
  end
end
