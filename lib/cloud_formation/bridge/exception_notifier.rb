require 'cloud_formation/bridge/util'
require 'singleton'
require 'rollbar'

Rollbar.configure do |config|
  config.access_token = ENV['ROLLBAR_TOKEN']
  config.environment = ENV['CFN_ENVIRONMENT'] || 'development'
  config.enabled = config.environment != 'test'
end

module CloudFormation
  module Bridge

    class StdoutExceptionNotifier

      include Singleton

      def report_exception(exception, custom_data = {}, user_data = {})
        Util::LOGGER.error("#{exception.message} - #{custom_data.inspect} - #{user_data.inspect}\n#{exception.backtrace.join("\n")}")
      end

    end

    class RollbarExceptionNotifier

      include Singleton

      def report_exception(exception, custom_data = {}, user_data = {})
        Rollbar.report_exception(exception, custom_data, user_data)
      end

    end

    class ExceptionNotifier

      class << self

        def notifier
          @notifier ||= if ENV['ROLLBAR_TOKEN']
            RollbarExceptionNotifier.instance
          else
            StdoutExceptionNotifier.instance
          end
        end

        def notifier=(notifier)
          @notifier = notifier
        end

        def report_exception(exception, custom_data = {}, user_data = {})
          Rollbar.report_exception(exception, custom_data, user_data)
        end

      end

    end


  end
end