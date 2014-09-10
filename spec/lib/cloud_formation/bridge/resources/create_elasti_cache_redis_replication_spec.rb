require 'cloud_formation/bridge/resources/create_elasti_cache_redis_replication'

describe CloudFormation::Bridge::Resources::CreateElastiCacheRedisReplication do

  include FileSupport

  context 'static methods' do

    it 'produces a unique id with the string given if it is bigger than 12' do
      id = CloudFormation::Bridge::Resources::CreateElastiCacheRedisReplication.produce_id_from("sample-items-here")
      expect(id.size).to eq(20)
      expect(id).to start_with("sample-item")
    end

    it 'produces a unique id with the string given if it is smaller than 12' do
      id = CloudFormation::Bridge::Resources::CreateElastiCacheRedisReplication.produce_id_from("sample-item")
      expect(id.size).to eq(20)
      expect(id).to start_with("sample-item")
    end

    it 'correctly finds the replicas' do
      replication_data = parse_json("describe-replication-group-primary-and-replica")[:replication_groups][0]
      replicas = CloudFormation::Bridge::Resources::CreateElastiCacheRedisReplication.filter_replicas(replication_data)

      expect(replicas.size).to eq(1)
      expect(replicas.first[:read_endpoint]).to eq(
                                                  port: 6379,
                                                  address: "rn-redisclu-a7392cba.mzufvw.0001.use1.cache.amazonaws.com",
                                                )
    end

    it 'does not find any replicas if only the primary exists' do
      replication_data = parse_json("describe-replication-group-primary-only")[:replication_groups][0]
      replicas = CloudFormation::Bridge::Resources::CreateElastiCacheRedisReplication.filter_replicas(replication_data)

      expect(replicas).to be_empty
    end

  end

end