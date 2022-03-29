module SettingsReader
  module VaultResolver
    # Check lease refresh result and report problems if needed
    class RefresherObserver
      attr_reader :config

      def initialize(config)
        @config = config
      end

      def update(_time, result, error)
        if result
          result.map do |promise|
            promise.on_success(&method(:notify_success)).on_error(&method(:notify_error))
          end.each(&:wait)
        else
          notify_error(error)
        end
      end

      def notify_success(result)
        config.lease_renew_success_listener.call(result)
      end

      def notify_error(result)
        config.lease_renew_error_listener.call(result)
      end
    end
  end
end
