require 'cloud_formation/bridge/poller'
require 'cloud_formation/bridge/executor'

describe CloudFormation::Bridge::Poller do

  include CloudFormationCreator
  include FileSupport

  shared_context 'pulls messages from queue' do

    it "should correctly poll the queue and execute the message" do
      message = read_file("sample-create-message.json")
      queue.send_message(message)

      expect(executor).to receive(:execute) do |request|
        expect(request).to be_create
        expect(request.logical_resource_id).to eq('OutputsResource')
        expect(request.resource_type).to eq('Custom::CloudFormationOutputs')
      end

      expect(poller.visible_messages).to eq(1)

      thread_poller = poller

      thread = Thread.new do
        thread_poller.start
      end

      while poller.visible_messages != 0
        sleep(1)
      end

      poller.stop

      thread.join
    end

  end

  context 'in integration', integration: true do

    let(:queue_name) { "test-cfn-queue-#{SecureRandom.uuid}" }
    let(:queue) { queues.create(queue_name) }
    let(:executor) { instance_double(CloudFormation::Bridge::Executor) }
    let(:poller) { CloudFormation::Bridge::Poller.new(queue_name, executor) }

    after do
      queue.delete
    end

    include_context 'pulls messages from queue'

  end

  context 'in isolation' do

    let(:queue_name) { "test-cfn-queue-#{SecureRandom.uuid}" }
    let(:executor) { instance_double(CloudFormation::Bridge::Executor) }
    let(:queue_items) { [] }
    let(:queue) { instance_double(AWS::SQS::Queue) }
    let(:poller) { CloudFormation::Bridge::Poller.new(queue_name, executor) }

    before do
      allow(queue).to receive(:send_message) do |message|
        queue_items << message
        nil
      end
      allow(queue).to receive(:visible_messages) { queue_items.size }
      allow(queue).to receive(:receive_message) do
        if queue_items.empty?
          sleep(20)
          nil
        else
          message = queue_items.shift
          message_double = instance_double(AWS::SQS::ReceivedMessage, id: "some-id", body: message, handle: 'some-handle')
          expect(message_double).to receive(:delete)
          message_double
        end
      end

      allow(poller).to receive(:queue).and_return(queue)
    end

    include_context 'pulls messages from queue'

  end

end