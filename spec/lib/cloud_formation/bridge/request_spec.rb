require 'cloud_formation/bridge/names'
require 'cloud_formation/bridge/request'
require 'cloud_formation/bridge/http_bridge'

describe CloudFormation::Bridge::Request do

  FIELDS = CloudFormation::Bridge::Names::FIELDS
  TYPES = CloudFormation::Bridge::Names::TYPES
  RESULTS = CloudFormation::Bridge::Names::RESULTS

  let(:properties) do
    {
      "seleniumTester" => "SeleniumTest()",
      "endpoints" => ["http://mysite.com", "http://myecommercesite.com/", "http://search.mysite.com"],
      "frequencyOfTestsPerHour" => ["3", "2", "4"]
    }
  end

  let(:request_hash) do
    {
      "RequestType" => "Create",
      "ResponseURL" => "http://pre-signed-S3-url-for-response",
      "StackId" => "arn:aws:cloudformation:us-east-1:EXAMPLE/stack-name/guid",
      "RequestId" => "unique id for this create request",
      "ResourceType" => "Custom::SeleniumTester",
      "LogicalResourceId" => "MySeleniumTester",
      "ResourceProperties" => properties,
    }
  end

  let(:request) { CloudFormation::Bridge::Request.new(request_hash) }
  let(:physical_id) { "sample-physical-id" }

  context 'matching fields' do

    it 'should correctly fill the values' do
      expect(request).to be_create
      expect(request.request_url).to eq("http://pre-signed-S3-url-for-response")
      expect(request.stack_id).to eq("arn:aws:cloudformation:us-east-1:EXAMPLE/stack-name/guid")
      expect(request.request_id).to eq("unique id for this create request")
      expect(request.logical_resource_id).to eq("MySeleniumTester")
      expect(request.resource_type).to eq("Custom::SeleniumTester")
      expect(request.resource_properties).to eq(properties)
    end

    it 'should correctly detect an update request' do
      request_hash["RequestType"] = 'Update'

      expect(request).to be_update
    end

    it 'should correctly detect a delete request' do
      request_hash["RequestType"] = 'Delete'

      expect(request).to be_delete
    end

  end

  context 'when building responses' do

    it 'should correctly fill in the expected fields' do
      response = request.build_response

      expect(response).to include(
        FIELDS::STATUS => RESULTS::SUCCESS,
        FIELDS::STACK_ID => request.stack_id,
        FIELDS::REQUEST_ID => request.request_id,
        FIELDS::LOGICAL_RESOURCE_ID => request.logical_resource_id,
      )

      expect(response[FIELDS::PHYSICAL_RESOURCE_ID]).not_to be_empty
    end

    it 'should use the base response physical id if it was provided' do
      base = {
        FIELDS::PHYSICAL_RESOURCE_ID => physical_id,
      }

      response = request.build_response(base)

      expect(response[FIELDS::PHYSICAL_RESOURCE_ID]).to eq(physical_id)
    end

    it 'should use the request physical id if the base response was not provided but request has it' do
      request_hash[FIELDS::PHYSICAL_RESOURCE_ID] = physical_id
      response = request.build_response
      expect(response[FIELDS::PHYSICAL_RESOURCE_ID]).to eq(physical_id)
    end

  end

  context 'when succeeding' do

    it "should push the response with its own values" do
      base = {
        FIELDS::PHYSICAL_RESOURCE_ID => physical_id,
      }

      expect(CloudFormation::Bridge::HttpBridge).to receive(:put).with(request.request_url, request.build_response(base))

      request.succeed!(base)
    end

  end

  context 'when failing' do

    it "should push the failure message with the known values" do
      message = "failed to create resource"

      expect(CloudFormation::Bridge::HttpBridge).to receive(:put) do |url, options|
        expect(url).to eq(request.request_url)

        response = request.build_response(
          FIELDS::REASON => message,
          FIELDS::STATUS => RESULTS::FAILED
        )

        response.delete(FIELDS::PHYSICAL_RESOURCE_ID)

        expect(options).to include(response)
      end

      request.fail!(message)
    end

  end

end