require 'cloud_formation/bridge/resources/subscribe_queue_to_topic'
require 'cloud_formation/bridge/names'
require 'cloud_formation/bridge/poller'
require 'cloud_formation/bridge/request'

describe CloudFormation::Bridge::Resources::SubscribeQueueToTopic do

  include CloudFormationCreator

  context 'in isolation', integration: true do

    let(:uuid) { SecureRandom.uuid }
    let(:topic) { topics.create("cfn-test-topic-#{uuid}") }
    let(:queue_name) { "cfn-test-queue-#{uuid}" }
    let(:queue) { queues.create(queue_name) }

    before do
      @items = [topic, queue]
    end

    after do
      @items.map(&:delete)
    end

    it 'should subscribe the the queue to the topic' do
      request = CloudFormation::Bridge::Request.new(
        CloudFormation::Bridge::Names::FIELDS::RESOURCE_PROPERTIES => {
          CloudFormation::Bridge::Resources::SubscribeQueueToTopic::QUEUE_NAME => queue_name,
          CloudFormation::Bridge::Resources::SubscribeQueueToTopic::TOPIC_ARN => topic.arn,
        },
      )

      response = subject.create(request)
      data = response[CloudFormation::Bridge::Names::FIELDS::DATA]

      subscription = subscriptions[data[CloudFormation::Bridge::Resources::SubscribeQueueToTopic::ARN]]

      payload = "this is the payload"

      topic.publish( payload )

      sleep(1)

      message = queue.receive_message
      body = JSON.parse(message.body)

      expect(body["Message"]).to eq(payload)
      expect(subscription.exists?).to eq(true)
    end

  end

  context 'when creating the cloud formation' do

    it "should accept a request and subscribe a queue to an SNS topic", integration: true do

      with_main_formation do |_, poller, outputs|
        params = {
          "EntryTopic" => outputs["Topic"],
        }

        with_cloud_formation('subscribe-to-sns-formation', params, false) do |topics_stack|

          wait_until "messages available" do
            poller.visible_messages > 0
          end

          poller.poll

          wait_until_complete(topics_stack)

          message_body = "sample message"

          topic = topics[topics_stack["FirstTopic"]]
          topic.publish(message_body)

          queue = queues.named(topics_stack["FirstQueue"])
          message = queue.receive_message
          message.delete

          received_message = JSON.parse(message.body)["Message"]

          expected_outputs = stack_outputs(topics_stack)

          expect(received_message).to eq(message_body)
          expect(expected_outputs["SubscriptionProtocol"]).to eq('sqs')
          expect(expected_outputs["FirstQueueArn"]).to eq(expected_outputs["SubscriptionEndpoint"])
        end
      end

    end

  end

end