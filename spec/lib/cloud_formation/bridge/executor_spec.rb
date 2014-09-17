require 'cloud_formation/bridge/executor'
require 'cloud_formation/bridge/request'
require 'cloud_formation/bridge/names'

describe CloudFormation::Bridge::Executor do

  FIELDS = CloudFormation::Bridge::Names::FIELDS
  TYPES = CloudFormation::Bridge::Names::TYPES

  let(:custom_resource) { double("custom-resource") }
  let(:url) { "http://example.com/request-id" }
  let(:custom_resource_name) { "sample-custom-resource" }
  let(:registry) { { custom_resource_name => custom_resource } }
  let(:unknown_resource) { "unknown-resource" }
  let(:response) { { FIELDS::LOGICAL_RESOURCE_ID => "sample-resource" } }

  context 'when processing resources that are available' do

    TYPES::ALL.each do |type|
      it "should #{type.downcase} the resource if it is a #{type} request" do
        request = CloudFormation::Bridge::Request.new(
          FIELDS::REQUEST_TYPE => type,
          FIELDS::RESOURCE_TYPE => custom_resource_name,
        )

        expect(custom_resource).to receive(type.downcase).with(request).and_return(response)

        expect(request).to receive(:succeed!).with(response)

        executor = CloudFormation::Bridge::Executor.new(registry)
        executor.execute(request)
      end
    end

    it 'should fail the request if the resource type is unknown' do
      request = CloudFormation::Bridge::Request.new(
        FIELDS::REQUEST_TYPE => TYPES::CREATE,
        FIELDS::RESOURCE_TYPE => custom_resource_name,
      )

      expect(request).to receive(:fail!) do |message|
        expect(message).to match(/#{custom_resource_name}/)
      end

      executor = CloudFormation::Bridge::Executor.new
      executor.execute(request)
    end

    it 'should fail the request if the resource raised an exception' do
      request = CloudFormation::Bridge::Request.new(
        FIELDS::REQUEST_TYPE => TYPES::CREATE,
        FIELDS::RESOURCE_TYPE => custom_resource_name,
      )

      message = "This should not have been called"
      expect(custom_resource).to receive(:create).and_raise(ArgumentError.new(message))

      expect(request).to receive(:fail!).with("ArgumentError - #{message}")

      executor = CloudFormation::Bridge::Executor.new(registry)
      executor.execute(request)
    end


    it 'deletes the resource even if there is no resource there' do
      request = CloudFormation::Bridge::Request.new(
        FIELDS::REQUEST_TYPE => TYPES::DELETE,
        FIELDS::RESOURCE_TYPE => unknown_resource,
        FIELDS::RESPONSE_URL => "http://localhost:3000/example",
      )

      expect(CloudFormation::Bridge::HttpBridge).to receive(:put) do |url,response|
        expect(url).to eq("http://localhost:3000/example")
      end

      executor = CloudFormation::Bridge::Executor.new(registry)
      executor.execute(request)
    end

  end


end