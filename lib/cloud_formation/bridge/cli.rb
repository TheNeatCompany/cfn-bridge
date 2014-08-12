require 'thor'
require 'cloud_formation/bridge/poller'
require 'cloud_formation/bridge/util'
require 'cloud_formation/bridge/version'

module CloudFormation
  module Bridge
    class Cli < Thor

      desc "start QUEUE_NAME", "Starts watching this specific SQS queue"
      def start(queue_name)
        STDOUT.sync = true

        Util::LOGGER.info("Starting cfn-bridge with queue #{queue_name} - version #{CloudFormation::Bridge::VERSION}")

        poller = CloudFormation::Bridge::Poller.new(queue_name)
        poller.start
      end

    end
  end
end