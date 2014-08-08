require 'thor'
require 'cloud_formation/bridge/poller'

module CloudFormation
  module Bridge
    class Cli < Thor

      desc "start QUEUE_NAME", "Starts watching this specific SQS queue"
      def start(queue_name)
        poller = CloudFormation::Bridge::Poller.new(queue_name)
        poller.start
      end

    end
  end
end