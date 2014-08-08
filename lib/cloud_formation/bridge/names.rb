module CloudFormation
  module Bridge
    module Names

      module TYPES
        UPDATE = 'Update'
        CREATE = 'Create'
        DELETE = 'Delete'
        ALL = [UPDATE, CREATE, DELETE]
      end

      module RESULTS
        SUCCESS = 'SUCCESS'
        FAILED = 'FAILED'
      end

      module FIELDS
        REQUEST_TYPE = 'RequestType'
        RESPONSE_URL = 'ResponseURL'
        STACK_ID = 'StackId'
        REQUEST_ID = 'RequestId'
        RESOURCE_TYPE = 'ResourceType'
        LOGICAL_RESOURCE_ID = 'LogicalResourceId'
        PHYSICAL_RESOURCE_ID = 'PhysicalResourceId'
        RESOURCE_PROPERTIES = 'ResourceProperties'
        OLD_RESOURCE_PROPERTIES = 'OldResourceProperties'
        STATUS = 'Status'
        REASON = 'Reason'
        DATA = 'Data'
      end

    end
  end
end