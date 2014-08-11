require 'thor'
require 'cloud_formation/bridge/poller'
require 'cloud_formation/bridge/util'

module CloudFormation
  module Bridge
    class Cli < Thor

      desc "start QUEUE_NAME", "Starts watching this specific SQS queue"
      def start(queue_name)
        STDOUT.sync = true
        poller = CloudFormation::Bridge::Poller.new(queue_name, Util::LOGGER)
        poller.start
      end

    end
  end
end