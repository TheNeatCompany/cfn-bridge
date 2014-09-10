require 'timeout'
require 'cloud_formation/bridge/names'
require 'cloud_formation/bridge/util'

module CloudFormation
  module Bridge
    module Resources

      class Base
        include CloudFormation::Bridge::Names

        def require_fields(request, fields)
          empty_fields = fields.select do |field|
            request.resource_properties[field].nil? ||
              request.resource_properties[field].strip.empty?
          end

          unless empty_fields.empty?
            raise ArgumentError.new("The fields #{empty_fields.inspect} are required for this resource")
          end

        end

        def update(request)
          raise CloudFormation::Bridge::OperationNotImplementedError.new(
                  "The resource #{self.class.name} does not implement the update operation - #{request.inspect}")
        end

        def wait_until(description, seconds = 5, max_wait = 600, &block)
          Timeout.timeout(max_wait) do
            while !block.call
              Util.logger.info("Waiting for #{description}")
              sleep(seconds)
            end
          end
        end

      end

    end
  end
end