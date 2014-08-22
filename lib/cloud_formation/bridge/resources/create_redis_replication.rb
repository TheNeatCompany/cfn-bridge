require 'aws/cloud_formation'
require 'aws/elasticache'
require 'cloud_formation/bridge/resources/base'

module CloudFormation
  module Bridge
    module Resources

      class CreateRedisReplication < Base

        CLUSTER_ID = 'ClusterId'
        REPLICAS_COUNT = 'ReplicasCount'
        DESCRIPTION = 'Description'

        REQUIRED_FIELDS = [
          CLUSTER_ID,
          REPLICAS_COUNT,
          DESCRIPTION,
        ]

        def create(request)
          require_fields(request, REQUIRED_FIELDS)

          cluster_id = request.resource_properties[CLUSTER_ID]

          master_data = client.describe_cache_clusters(
            cache_cluster_id: cluster_id,
            show_cache_node_info: true
          ).data[:cache_clusters][0]

          replication_data = client.create_replication_group(
            replication_group_id: "#{cluster_id[0,15]}r",
            primary_cluster_id: cluster_id,
            replication_group_description: request.resource_properties[DESCRIPTION]
          ).data

          request.resource_properties[REPLICAS_COUNT].times do |i|
            client.create_cache_cluster(
              cache_cluster_id: "#{cluster_id[0,15]}#{i}",
              replication_group_id: replication_data[:replication_group_id],
              cache_node_type: master_data[:master_data],
              engine: 'redis',
              cache_security_group_names: master_data[:cache_security_groups].map { |e| e[:cache_security_group_name] },
              preferred_availability_zone: master_data[:preferred_availability_zone]
            )
          end

          {
            FIELDS::DATA => {
              'Host' => master_data[:cache_nodes][0][:endpoint][:address],
              'Port' => master_data[:cache_nodes][0][:endpoint][:port],
            },
            FIELDS::PHYSICAL_RESOURCE_ID => cluster_id,
          }
        end

        def delete(request)
          require_fields(request, [CLUSTER_ID])

          master_data = client.describe_cache_clusters(
            cache_cluster_id: request.resource_properties[CLUSTER_ID],
            show_cache_node_info: true
          ).data[:cache_clusters][0]

          if master_data[:replication_group_id].present?
            client.delete_replication_group(replication_group_id: master_data[:replication_group_id])
          end
        end

        def client
          @client ||= AWS::ElastiCache.new.client
        end
      end

    end
  end
end