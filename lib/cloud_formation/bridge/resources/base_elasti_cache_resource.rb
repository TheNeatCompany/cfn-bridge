require 'cloud_formation/bridge/names'

module CloudFormation
  module Bridge
    module Resources
      module BaseElastiCacheResource

        include CloudFormation::Bridge::Names

        def replication_group_available?(replication_group_id)
          replication_group = client.describe_replication_groups(replication_group_id: replication_group_id)[:replication_groups][0]
          replication_group[:status] == ELASTI_CACHE::AVAILABLE
        end

        def find_cluster(cluster_id)
          client.describe_cache_clusters(
            cache_cluster_id: cluster_id,
            show_cache_node_info: true
          ).data[:cache_clusters][0]
        end

        def client
          @client ||= AWS::ElastiCache.new.client
        end

      end
    end
  end
end