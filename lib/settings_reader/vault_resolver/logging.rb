module SettingsReader
  module VaultResolver
    # Methods for centralized logging
    module Logging
      def debug(&block)
        logger.debug do
          "[VaultResolver] #{block.call}"
        end
        nil
      end

      def info(&block)
        logger.info do
          "[VaultResolver] #{block.call}"
        end
        nil
      end

      def warn(&block)
        logger.warn do
          "[VaultResolver] #{block.call}"
        end
        nil
      end

      def error(&block)
        logger.error do
          "[VaultResolver] #{block.call}"
        end
        nil
      end

      private

      def logger
        SettingsReader::VaultResolver.logger
      end
    end
  end
end
