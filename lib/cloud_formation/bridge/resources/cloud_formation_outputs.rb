require 'aws/cloud_formation'
require 'cloud_formation/bridge/resources/base'

module CloudFormation
  module Bridge
    module Resources

      class CloudFormationOutputs < Base

        NAME = 'Name'

        def create(request)
          require_fields(request, [NAME])

          stack_name = request.resource_properties[NAME]

          stack = stacks[stack_name]

          outputs = stack.outputs.inject({}) do |acc,output|
            acc[output.key] = output.value
            acc
          end

          {
            FIELDS::DATA => outputs,
            FIELDS::PHYSICAL_RESOURCE_ID => stack.stack_id,
          }
        end

        alias_method :update, :create

        def delete(request)
          # no need to do anything here
        end

        def stacks
          @stacks ||= AWS::CloudFormation.new.stacks
        end

      end

    end
  end
end