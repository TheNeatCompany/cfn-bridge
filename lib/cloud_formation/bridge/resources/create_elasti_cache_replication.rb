require 'securerandom'
require 'aws/elasticache'
require 'cloud_formation/bridge/resources/base'
require 'cloud_formation/bridge/util'

module CloudFormation
  module Bridge
    module Resources

      class CreateElastiCacheReplication < Base

        CLUSTER_ID = 'ClusterId'
        REPLICAS_COUNT = 'ReplicasCount'
        DESCRIPTION = 'Description'

        REPLICA = 'replica'
        AVAILABLE = 'available'

        BASE_ATTRIBUTES = [
        ]

        REQUIRED_FIELDS = [
          CLUSTER_ID,
          REPLICAS_COUNT,
          DESCRIPTION,
        ]

        def create(request)
          require_fields(request, REQUIRED_FIELDS)

          cluster_id = request.resource_properties[CLUSTER_ID]
          replication_id = CreateElastiCacheReplication.produce_id_from("rg-#{request.logical_resource_id}")

          client.create_replication_group(
            replication_group_id: replication_id,
            primary_cluster_id: cluster_id,
            replication_group_description: request.resource_properties[DESCRIPTION],
          )

          wait_until("replication group #{replication_id} to be available") do
            replication_group_available?(replication_id)
          end

          replicas_count = request.resource_properties[REPLICAS_COUNT].to_i

          replicas = create_cluster(replication_id, replicas_count, "rn-#{request.logical_resource_id}")

          Util.logger.info("replicated cluster data is #{replicas.inspect}")

          node_urls = replicas.map do |replica|
            "#{replica[:configuration_endpoint][:address]}:#{replica[:configuration_endpoint][:port]}"
          end.join(",")

          {
            FIELDS::DATA => {
              'NodeURLs' => node_urls,
            },
            FIELDS::PHYSICAL_RESOURCE_ID => replication_id,
          }
        end

        def update(request)
          require_fields(request, REQUIRED_FIELDS)

          cluster_id = request.resource_properties[CLUSTER_ID]
          primary_data = find_cluster(request.resource_properties[CLUSTER_ID])
          replicas = find_replicas(primary_data[:replication_group_id])

          real_count = replicas.size
          new_count = request.resource_properties[REPLICAS_COUNT]

          difference = new_count - real_count

          if difference > 0
            create_cluster(primary_data[:replication_group_id], difference, "rn-#{request.logical_resource_id}")
          elsif difference < 0
            (difference...0).each do |index|
              client.delete_cache_cluster(cache_cluster_id: replicas[index][:cache_cluster_id])
            end
          end

          replicas = find_replicas(primary_data[:replication_group_id])

          node_urls = replicas.mao do |replica|
            "#{replica[:read_endpoint][:address]}:#{replica[:read_endpoint][:port]}"
          end.join(",")

          {
            FIELDS::DATA => {
              'NodeURLs' => node_urls,
            },
            FIELDS::PHYSICAL_RESOURCE_ID => cluster_id,
          }
        end

        def delete(request)
          require_fields(request, [CLUSTER_ID])

          begin
            primary_data = find_cluster(request.resource_properties[CLUSTER_ID])
            replication_id = primary_data[:replication_group_id]

            if replication_id

              wait_until("replication group #{replication_id} to be available") do
                replication_group_available?(replication_id)
              end

              client.delete_replication_group(
                replication_group_id: replication_id,
                retain_primary_cluster: true,
              )
            end
          rescue AWS::ElastiCache::Errors::CacheClusterNotFound
            # main cluster does not exist, ignore
          end
        end

        def client
          @client ||= AWS::ElastiCache.new.client
        end

        def create_cluster(replication_id, replicas_count, base_name)
          replica_ids = (1..replicas_count).map do
            replica_cluster_id = CreateElastiCacheReplication.produce_id_from(base_name)
            client.create_cache_cluster(cache_cluster_id: replica_cluster_id, replication_group_id: replication_id)
            replica_cluster_id
          end

          wait_until("replicas #{replica_ids.inspect} to be available") do
            replica_ids.all? do |cluster_id|
              cluster = find_cluster(cluster_id)
              Util.logger.info("Cluster info is #{cluster.inspect}")
              cluster[:cache_cluster_status] == AVAILABLE
            end
          end

          replica_ids.map do |cluster_id|
            find_cluster(cluster_id)
          end
        end

        def find_cluster(cluster_id)
          client.describe_cache_clusters(
            cache_cluster_id: cluster_id,
            show_cache_node_info: true
          ).data[:cache_clusters][0]
        end

        def find_replicas(replication_group_id)
          replication_data = client.describe_replication_groups(
            replication_group_id: replication_group_id
          ).data[:replication_groups][0]

          CreateElastiCacheReplication.filter_replicas(replication_data)
        end

        def replication_group_available?(replication_group_id)
          replication_group = client.describe_replication_groups(replication_group_id: replication_group_id)[:replication_groups][0]
          replication_group[:status] == AVAILABLE
        end

        class << self

          def filter_replicas(replication_data)
            replication_data[:node_groups].inject([]) do |acc, node_group|
              if node = node_group[:node_group_members].find { |member| member[:current_role] == REPLICA }
                acc << node
              end
              acc
            end
          end

          def produce_id_from(base, base_size = 12)
            base_id = "#{base[0, base_size - 1]}-"
            "#{base_id}#{SecureRandom.hex((20 - base_id.size)/2)}"
          end

        end

      end

    end
  end
end
