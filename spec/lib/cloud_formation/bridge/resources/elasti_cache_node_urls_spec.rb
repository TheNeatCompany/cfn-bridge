require 'cloud_formation/bridge/names'
require 'cloud_formation/bridge/request'
require 'cloud_formation/bridge/resources/elasti_cache_node_urls'

describe CloudFormation::Bridge::Resources::ElastiCacheNodeUrls do

  FIELDS = CloudFormation::Bridge::Names::FIELDS
  ELASTI_CACHE = CloudFormation::Bridge::Names::ELASTI_CACHE

  include FileSupport

  context '#create' do

    it 'produces the node URLs for a memcached cluster' do
      cluster_id = "samplecache"

      expect(subject.client).to receive(:describe_cache_clusters).
                                  with(cache_cluster_id: cluster_id,
                                       show_cache_node_info: true).twice.and_return(parse_json("describe-memcached-cluster"))

      request = CloudFormation::Bridge::Request.new(parse_json("create-cache-node-urls-message", false))

      outputs = subject.create(request)

      expect(outputs).to eq(
                           {
                             FIELDS::DATA => {
                               ELASTI_CACHE::REPLICA_CLUSTER_ID => cluster_id,
                               ELASTI_CACHE::NODE_URLS => "somecache.tgbhomz.cfg.use1.cache.amazonaws.com:11211",
                             },
                             FIELDS::PHYSICAL_RESOURCE_ID => cluster_id,
                           }
                         )

    end

    it 'produces the node URLs for a redis cluster' do
      cluster_id = "dev-redis-replica"
      expect(subject.client).to receive(:describe_cache_clusters).
                                  with(cache_cluster_id: cluster_id,
                                       show_cache_node_info: true).twice.and_return(parse_json("describe-cache-cluster-replica-done"))

      request = CloudFormation::Bridge::Request.new(parse_json("create-redis-cache-node-urls-message", false))

      outputs = subject.create(request)

      expect(outputs).to eq(
                           {
                             FIELDS::DATA => {
                               ELASTI_CACHE::REPLICA_CLUSTER_ID => cluster_id,
                               ELASTI_CACHE::NODE_URLS => "dev-redis-replica.mzufvw.0001.use1.cache.amazonaws.com:6379,dev-redis-replica.mzufvw.0002.use1.cache.amazonaws.com:6379",
                             },
                             FIELDS::PHYSICAL_RESOURCE_ID => cluster_id,
                           }
                         )

    end

  end

end
