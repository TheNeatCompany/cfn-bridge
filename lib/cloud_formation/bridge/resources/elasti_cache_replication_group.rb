require 'aws/elasticache'
require 'cloud_formation/bridge/util'
require 'cloud_formation/bridge/resources/base'
require 'cloud_formation/bridge/resources/base_elasti_cache_resource'

module CloudFormation
  module Bridge
    module Resources

      class ElastiCacheReplicationGroup < Base

        include BaseElastiCacheResource

        REQUIRED_FIELDS = [
          ELASTI_CACHE::CLUSTER_ID,
          ELASTI_CACHE::REPLICATION_GROUP_ID,
          ELASTI_CACHE::DESCRIPTION,
        ]

        def create(request)
          require_fields(request, REQUIRED_FIELDS)

          replication_id = request.resource_properties[ELASTI_CACHE::REPLICATION_GROUP_ID]

          client.create_replication_group(
            replication_group_id: replication_id,
            primary_cluster_id: request.resource_properties[ELASTI_CACHE::CLUSTER_ID],
            replication_group_description: request.resource_properties[ELASTI_CACHE::DESCRIPTION],
          )

          wait_until("replication group #{replication_id} to be available") do
            replication_group_available?(replication_id)
          end

          {
            FIELDS::DATA => {
              ELASTI_CACHE::REPLICATION_GROUP_ID => replication_id
            },
            FIELDS::PHYSICAL_RESOURCE_ID => replication_id,
          }
        end

        def delete(request)
          require_fields(request, ELASTI_CACHE::REPLICATION_GROUP_ID)

          begin
            replication_id = request.resource_properties[ELASTI_CACHE::REPLICATION_GROUP_ID]

            wait_until("replication group #{replication_id} to be available") do
              replication_group_available?(replication_id)
            end

            client.delete_replication_group(
              replication_group_id: replication_id,
              retain_primary_cluster: true,
            )
          rescue AWS::ElastiCache::Errors::ReplicationGroupNotFoundFault
            # main cluster does not exist, ignore
            Util.logger.info("Replication group #{replication_id} does not exist, ignoring")
          end
        end

      end

    end
  end
end