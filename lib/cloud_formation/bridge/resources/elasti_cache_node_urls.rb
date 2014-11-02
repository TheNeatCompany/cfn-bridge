require 'cloud_formation/bridge/resources/base'
require 'cloud_formation/bridge/resources/base_elasti_cache_resource'

module CloudFormation
  module Bridge
    module Resources

      class ElastiCacheNodeUrls < Base

        include BaseElastiCacheResource

        def create(request)
          require_fields(request, ELASTI_CACHE::CLUSTER_ID)

          cluster_id = request.resource_properties[ELASTI_CACHE::CLUSTER_ID]

          wait_until_cluster_is_available(cluster_id)

          data = {
            ELASTI_CACHE::REPLICA_CLUSTER_ID => cluster_id,
            ELASTI_CACHE::NODE_URLS => node_urls(cluster_id),

          }

          if config = config_endpoint(cluster_id)
            data[ELASTI_CACHE::CONFIG_ENDPOINT] = config
          end

          {
            FIELDS::DATA => data,
            FIELDS::PHYSICAL_RESOURCE_ID => cluster_id,
          }
        end

        def delete(request)
        end

      end

    end
  end
end
