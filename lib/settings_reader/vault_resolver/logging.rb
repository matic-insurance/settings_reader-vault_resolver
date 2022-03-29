module SettingsReader
  module VaultResolver
    # Methods for centralized logging
    module Logging
      def debug(&block)
        log_message(Logger::DEBUG, &block)
      end

      def info(&block)
        log_message(Logger::INFO, &block)
      end

      def warn(&block)
        log_message(Logger::WARN, &block)
      end

      def error(&block)
        log_message(Logger::ERROR, &block)
      end

      private

      def log_message(severity, &block)
        logger&.log(severity) do
          "[VaultResolver] #{block.call}"
        rescue StandardError => _e
          # Ignoring errors in log message
        end
        nil
      end

      def logger
        config.logger
      end
    end
  end
end
