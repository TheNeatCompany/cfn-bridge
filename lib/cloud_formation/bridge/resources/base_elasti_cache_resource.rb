require 'aws/elasticache'
require 'cloud_formation/bridge/names'

module CloudFormation
  module Bridge
    module Resources
      module BaseElastiCacheResource

        UnknownCacheEngineError = Class.new(StandardError)

        include CloudFormation::Bridge::Names

        def replication_group_available?(replication_group_id)
          replication_group = client.describe_replication_groups(replication_group_id: replication_group_id)[:replication_groups][0]
          replication_group[:status] == ELASTI_CACHE::AVAILABLE
        end

        def find_cluster(cluster_id)
          client.describe_cache_clusters(
            cache_cluster_id: cluster_id,
            show_cache_node_info: true
          )[:cache_clusters][0]
        end

        def node_urls(cluster_id)
          cluster = find_cluster(cluster_id)

          cluster[:cache_nodes].map do |node|
            "#{node[:endpoint][:address]}:#{node[:endpoint][:port]}"
          end.join(",")
        end

        def config_endpoint(cluster_id)
          cluster = find_cluster(cluster_id)
          "#{cluster[:configuration_endpoint][:address]}:#{cluster[:configuration_endpoint][:port]}" if cluster[:engine] == 'memcached'
        end

        def wait_until_cluster_is_available(cluster_id)
          wait_until("replica #{cluster_id} to be available") do
            cluster = find_cluster(cluster_id)
            Util.logger.info("Cluster info is #{cluster.inspect}")
            cluster[:cache_cluster_status] == ELASTI_CACHE::AVAILABLE
          end
        end

        def client
          @client ||= AWS::ElastiCache.new.client
        end

      end
    end
  end
end
