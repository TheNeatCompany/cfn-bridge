require 'cloud_formation/bridge/names'

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

      end

    end
  end
end