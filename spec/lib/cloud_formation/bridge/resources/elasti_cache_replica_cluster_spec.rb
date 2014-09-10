require 'cloud_formation/bridge/names'
require 'cloud_formation/bridge/resources/elasti_cache_replica_cluster'

describe CloudFormation::Bridge::Resources::ElastiCacheReplicaCluster do

  FIELDS = CloudFormation::Bridge::Names::FIELDS
  ELASTI_CACHE = CloudFormation::Bridge::Names::ELASTI_CACHE

  include FileSupport

  let(:creating) { parse_json("describe-cache-cluster-replica") }
  let(:available) { parse_json("describe-cache-cluster-replica-done") }
  let(:replication_group_id) { "dev-redis-rep-group" }
  let(:replica_cluster_id) { "dev-redis-replica" }

  context '#create' do

    let(:request) { CloudFormation::Bridge::Request.new(parse_json("create-replica-cluster-message", false)) }

    it 'creates the cluster' do
      expect(subject.client).to receive(:create_cache_cluster).
                                  with(cache_cluster_id: replica_cluster_id, replication_group_id: replication_group_id)
      expect(subject.client).to receive(:describe_cache_clusters).
                                  with(cache_cluster_id: replica_cluster_id,
                                       show_cache_node_info: true).twice.and_return(available)

      outputs = subject.create(request)

      expect(outputs).to eq(
                           {
                             FIELDS::DATA => {
                               ELASTI_CACHE::REPLICA_CLUSTER_ID => replica_cluster_id,
                               ELASTI_CACHE::NODE_URLS => "dev-redis-replica.mzufvw.0001.use1.cache.amazonaws.com:6379",
                             },
                             FIELDS::PHYSICAL_RESOURCE_ID => replica_cluster_id,
                           }
                         )
    end

  end

  context '#delete' do

    let(:request) { CloudFormation::Bridge::Request.new(parse_json("delete-replica-cluster-message", false)) }

    it 'deletes the cluster' do
      expect(subject.client).to receive(:delete_cache_cluster).with(cache_cluster_id: replica_cluster_id)

      count = 0

      expect(subject.client).to receive(:describe_cache_clusters).
                                  with(cache_cluster_id: replica_cluster_id,
                                       show_cache_node_info: true).at_least(:once) do
        if count == 0
          count += 1
          available
        else
          raise AWS::ElastiCache::Errors::CacheClusterNotFound
        end
      end

      subject.delete(request)
    end

  end

end