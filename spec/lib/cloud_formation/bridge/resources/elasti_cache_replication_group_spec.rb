require 'cloud_formation/bridge/request'
require 'cloud_formation/bridge/names'
require 'cloud_formation/bridge/resources/elasti_cache_replication_group'

describe CloudFormation::Bridge::Resources::ElastiCacheReplicationGroup do

  include FileSupport

  FIELDS = CloudFormation::Bridge::Names::FIELDS
  ELASTI_CACHE = CloudFormation::Bridge::Names::ELASTI_CACHE

  let(:replication_group_id) { "dev-redis-rep" }

  def stub_describe_replication_group
    expect(subject.client).to receive(:describe_replication_groups).
                                with(replication_group_id: replication_group_id).
                                and_return(parse_json("describe-replication-group-primary-only"))
  end

  context "#create" do

    let(:request) { CloudFormation::Bridge::Request.new(parse_json("create-replication-group-message", false)) }

    it 'creates the replication group' do
      expect(subject.client).to receive(:create_replication_group).with(
                                  replication_group_id: replication_group_id,
                                  primary_cluster_id: "cluster-id-here",
                                  replication_group_description: "Sample replication group for the redis instances",
                                )

      stub_describe_replication_group

      outputs = subject.create(request)

      expect(outputs).to eq(
                           FIELDS::DATA => {
                             ELASTI_CACHE::REPLICATION_GROUP_ID => replication_group_id,
                           },
                           FIELDS::PHYSICAL_RESOURCE_ID => replication_group_id,
                         )
    end

  end

  context "#delete" do

    let(:request) { CloudFormation::Bridge::Request.new(parse_json("delete-replication-group-message", false)) }

    it 'should delete the group' do
      stub_describe_replication_group
      expect(subject.client).to receive(:delete_replication_group).with(
                                  replication_group_id: replication_group_id,
                                  retain_primary_cluster: true,
                                )
      subject.delete(request)
    end

    it 'should ignore if the replication group does not exist' do
      expect(subject).to receive(:replication_group_available?).and_raise(AWS::ElastiCache::Errors::ReplicationGroupNotFoundFault)
      expect { subject.delete(request) }.not_to raise_error
    end

  end

end