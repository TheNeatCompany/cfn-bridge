require 'cloud_formation/bridge/resources/create_elasti_cache_replication'

describe CloudFormation::Bridge::Resources::CreateElastiCacheReplication do

  context 'static methods' do

    it 'produces a unique id with the string given if it is bigger than 12' do
      id = CloudFormation::Bridge::Resources::CreateElastiCacheReplication.produce_id_from("sample-items-here")
      expect(id.size).to eq(20)
      expect(id).to start_with("sample-item")
    end

    it 'produces a unique id with the string given if it is smaller than 12' do
      id = CloudFormation::Bridge::Resources::CreateElastiCacheReplication.produce_id_from("sample-item")
      expect(id.size).to eq(20)
      expect(id).to start_with("sample-item")
    end

  end

end