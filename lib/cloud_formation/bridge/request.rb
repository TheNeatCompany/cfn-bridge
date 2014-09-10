require 'securerandom'
require 'cloud_formation/bridge/http_bridge'
require 'cloud_formation/bridge/names'
require 'cloud_formation/bridge/util'

module CloudFormation
  module Bridge
    class Request

      include CloudFormation::Bridge::Names

      attr_reader :request, :logger

      def initialize(request, logger = Util::LOGGER)
        @request = request
        @logger = logger
      end

      def update?
        request_type == TYPES::UPDATE
      end

      def create?
        request_type == TYPES::CREATE
      end

      def delete?
        request_type == TYPES::DELETE
      end

      def request_type
        request[FIELDS::REQUEST_TYPE]
      end

      def request_url
        request[FIELDS::RESPONSE_URL]
      end

      def stack_id
        request[FIELDS::STACK_ID]
      end

      def request_id
        request[FIELDS::REQUEST_ID]
      end

      def resource_type
        request[FIELDS::RESOURCE_TYPE]
      end

      def logical_resource_id
        request[FIELDS::LOGICAL_RESOURCE_ID]
      end

      def physical_resource_id
        request[FIELDS::PHYSICAL_RESOURCE_ID]
      end

      def resource_properties
        request[FIELDS::RESOURCE_PROPERTIES]
      end

      def old_resource_properties
        request[FIELDS::OLD_RESOURCE_PROPERTIES]
      end

      def fail!(message)
        response = build_response(
          FIELDS::REASON => message,
          FIELDS::STATUS => RESULTS::FAILED,
        )

        HttpBridge.put(request_url, response)
      end

      def succeed!(response)
        actual_response = case response
          when Hash
            build_response(response)
          else
            build_response
        end

        HttpBridge.put(request_url, actual_response)
      end

      def build_response(response = {})
        {
          FIELDS::STATUS => RESULTS::SUCCESS,
          FIELDS::PHYSICAL_RESOURCE_ID => response[FIELDS::PHYSICAL_RESOURCE_ID] || physical_resource_id || generate_physical_id,
          FIELDS::STACK_ID => stack_id,
          FIELDS::REQUEST_ID => request_id,
          FIELDS::LOGICAL_RESOURCE_ID => logical_resource_id,
        }.merge(response)
      end

      def generate_physical_id
        "#{logical_resource_id}-#{SecureRandom.uuid}"
      end

    end
  end
end