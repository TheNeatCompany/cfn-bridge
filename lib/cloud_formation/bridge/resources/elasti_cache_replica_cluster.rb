require 'aws/elasticache'
require 'cloud_formation/bridge/util'
require 'cloud_formation/bridge/resources/base'
require 'cloud_formation/bridge/resources/base_elasti_cache_resource'

module CloudFormation
  module Bridge
    module Resources

      class ElastiCacheReplicaCluster < Base
        include BaseElastiCacheResource

        REQUIRED_FIELDS = [
          ELASTI_CACHE::REPLICATION_GROUP_ID,
          ELASTI_CACHE::REPLICA_CLUSTER_ID,
        ]

        def create(request)
          require_fields(request, REQUIRED_FIELDS)

          cluster_id = request.resource_properties[ELASTI_CACHE::REPLICA_CLUSTER_ID]
          replication_id = request.resource_properties[ELASTI_CACHE::REPLICATION_GROUP_ID]

          client.create_cache_cluster(cache_cluster_id: cluster_id, replication_group_id: replication_id)

          wait_until_cluster_is_available(cluster_id)

          node_urls = find_cluster(cluster_id)[:cache_nodes].map do |node|
            "#{node[:endpoint][:address]}:#{node[:endpoint][:port]}"
          end

          {
            FIELDS::DATA => {
              ELASTI_CACHE::REPLICA_CLUSTER_ID => cluster_id,
              ELASTI_CACHE::NODE_URLS => node_urls.join(","),
            },
            FIELDS::PHYSICAL_RESOURCE_ID => cluster_id,
          }
        end

        def delete(request)
          require_fields(request, ELASTI_CACHE::REPLICA_CLUSTER_ID)

          cluster_id = request.resource_properties[ELASTI_CACHE::REPLICA_CLUSTER_ID]

          begin
            wait_until_cluster_is_available(cluster_id)

            client.delete_cache_cluster(cache_cluster_id: cluster_id)

            wait_until("cluster #{cluster_id} to be gone") do
              begin
                find_cluster(cluster_id)
                false
              rescue AWS::ElastiCache::Errors::CacheClusterNotFound
                true
              end
            end

          rescue AWS::ElastiCache::Errors::CacheClusterNotFound
            # no cache cluster? ignore
            Util.logger.info("Could not find cache cluster for #{cluster_id}, ignoring")
          end
        end

        def wait_until_cluster_is_available(cluster_id)
          wait_until("replica #{cluster_id} to be available") do
            cluster = find_cluster(cluster_id)
            Util.logger.info("Cluster info is #{cluster.inspect}")
            cluster[:cache_cluster_status] == ELASTI_CACHE::AVAILABLE
          end
        end

      end

    end
  end
end