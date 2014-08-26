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
          replication_id = "#{cluster_id[0,14]}replic"

          primary_data = client.describe_cache_clusters(
            cache_cluster_id: cluster_id,
            show_cache_node_info: true
          ).data[:cache_clusters][0]

          client.create_replication_group(
            replication_group_id: replication_id,
            primary_cluster_id: cluster_id,
            replication_group_description: request.resource_properties[DESCRIPTION]
          )

          replicas_count = request.resource_properties[REPLICAS_COUNT]
          1.upto(replicas_count) do |i|
            client.create_cache_cluster(
              cache_cluster_id: "#{cluster_id[0,14]}#{i}",
              replication_group_id: replication_id,
              cache_node_type: primary_data[:cache_node_type],
              engine: 'redis',
              cache_security_group_names: primary_data[:cache_security_groups].map { |e| e[:cache_security_group_name] },
              preferred_availability_zone: primary_data[:preferred_availability_zone]
            )
          end

          {
            FIELDS::DATA => {
              'Host' => primary_data[:cache_nodes][0][:endpoint][:address],
              'Port' => primary_data[:cache_nodes][0][:endpoint][:port],
            },
            FIELDS::PHYSICAL_RESOURCE_ID => cluster_id,
          }
        end

        def update(request)
          require_fields(request, REQUIRED_FIELDS)

          cluster_id = request.resource_properties[CLUSTER_ID]

          primary_data = client.describe_cache_clusters(
            cache_cluster_id: cluster_id,
            show_cache_node_info: true
          ).data[:cache_clusters][0]

          replication_data = client.describe_replication_groups(
            replication_group_id: primary_data[:replication_group_id]
          ).data[:replication_groups][0]

          real_count = replication_data[:member_clusters].count
          new_count = request.resource_properties[REPLICAS_COUNT]
          if real_count < new_count
            (real_count + 1).upto(new_count) do |i|
              client.create_cache_cluster(
                cache_cluster_id: "#{cluster_id[0,14]}#{i}",
                replication_group_id: replication_data[:replication_group_id],
                cache_node_type: primary_data[:cache_node_type],
                engine: 'redis',
                cache_security_group_names: primary_data[:cache_security_groups].map { |e| e[:cache_security_group_name] },
                preferred_availability_zone: primary_data[:preferred_availability_zone]
              )
            end
          elsif real_count > new_count
            (new_count + 1).upto(real_count) do |i|
              client.delete_cache_cluster(cache_cluster_id: "#{cluster_id[0,14]}#{i}")
            end
          end

          {
            FIELDS::DATA => {
              'Host' => primary_data[:cache_nodes][0][:endpoint][:address],
              'Port' => primary_data[:cache_nodes][0][:endpoint][:port],
            },
            FIELDS::PHYSICAL_RESOURCE_ID => cluster_id,
          }
        end

        def delete(request)
          require_fields(request, [CLUSTER_ID])

          primary_data = client.describe_cache_clusters(
            cache_cluster_id: request.resource_properties[CLUSTER_ID],
            show_cache_node_info: true
          ).data[:cache_clusters][0]

          if primary_data[:replication_group_id].present?
            client.delete_replication_group(replication_group_id: primary_data[:replication_group_id])
          end
        end

        def client
          @client ||= AWS::ElastiCache.new.client
        end
      end

    end
  end
end
