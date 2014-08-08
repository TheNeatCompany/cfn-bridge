require 'cloud_formation/bridge/resources/base'
require 'aws/sns'
require 'aws/sqs'

module CloudFormation
  module Bridge
    module Resources

      class SubscribeQueueToTopic < Base

        ARN = 'Arn'
        ENDPOINT = 'Endpoint'
        PROTOCOL = 'Protocol'

        TOPIC_ARN = 'TopicArn'
        QUEUE_NAME = 'QueueName'
        RAW_MESSAGE_DELIVERY = 'RawMessageDelivery'

        REQUIRED_FIELDS = [
          TOPIC_ARN,
          QUEUE_NAME,
        ]

        def create(request)
          require_fields(request, REQUIRED_FIELDS)

          queue = queues.named(request.resource_properties[QUEUE_NAME])
          topic = topics[request.resource_properties[TOPIC_ARN]]

          subscription = topic.subscribe(queue)

          if request.resource_properties[RAW_MESSAGE_DELIVERY]
            subscription.raw_message_delivery = true
          end

          {
            FIELDS::PHYSICAL_RESOURCE_ID => subscription.arn,
            FIELDS::DATA => {
              ARN => subscription.arn,
              ENDPOINT => subscription.endpoint,
              PROTOCOL => subscription.protocol,
            },
          }
        end

        def delete(request)
          subscription = subscriptions[request.physical_resource_id]
          subscription.unsubscribe if subscription && subscription.exists?
        end

        def topics
          @topics ||= sns.topics
        end

        def subscriptions
          @subscriptions ||= sns.subscriptions
        end

        def sns
          @sns ||= AWS::SNS.new
        end

        def queues
          @queues ||= AWS::SQS.new.queues
        end

      end

    end
  end
end