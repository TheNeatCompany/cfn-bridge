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
          automatic_failover = (request.resource_properties[ELASTI_CACHE::AUTOMATIC_FAILOVER] || "").downcase == "true"
          ncc_int = request.resource_properties[ELASTI_CACHE::NUM_CACHE_CLUSTERS].to_i
          num_cache_clusters = ncc_int > 0 ? ncc_int : nil

          response = client.create_replication_group(
            replication_group_id: replication_id,
            primary_cluster_id: request.resource_properties[ELASTI_CACHE::CLUSTER_ID],
            replication_group_description: request.resource_properties[ELASTI_CACHE::DESCRIPTION],
            automatic_failover_enabled: automatic_failover,
            num_cache_clusters: num_cache_clusters || ( automatic_failover ? 2 : 1 )
          )

          wait_until("replication group #{replication_id} to be available") do
            replication_group_available?(replication_id)
          end

          groups = client.describe_replication_groups(
            replication_group_id: replication_id
          )

          primary_endpoint = groups[:replication_groups][0][:node_groups][0][:primary_endpoint]

          {
            FIELDS::DATA => {
              ELASTI_CACHE::REPLICATION_GROUP_ID => replication_id,
              ELASTI_CACHE::PE_ADDRESS => primary_endpoint[:address],
              ELASTI_CACHE::PE_PORT => primary_endpoint[:port],
            },
            FIELDS::PHYSICAL_RESOURCE_ID => replication_id,
          }
        end

        def delete(request)
          require_fields(request, ELASTI_CACHE::REPLICATION_GROUP_ID)

          begin
            replication_id = request.resource_properties[ELASTI_CACHE::REPLICATION_GROUP_ID]
            automatic_failover = (request.resource_properties[ELASTI_CACHE::AUTOMATIC_FAILOVER] || "").downcase == "true"

            wait_until("replication group #{replication_id} to be available") do
              replication_group_available?(replication_id)
            end

            client.delete_replication_group(
              replication_group_id: replication_id,
              retain_primary_cluster: automatic_failover ? false : true,
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
