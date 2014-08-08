require 'securerandom'
require 'aws/cloud_formation'
require 'aws/sns'

module CloudFormationCreator

  COMPLETE_STATUSES = %w(
    CREATE_FAILED
    CREATE_COMPLETE
    ROLLBACK_FAILED
    ROLLBACK_COMPLETE
    DELETE_FAILED
    DELETE_COMPLETE
    UPDATE_COMPLETE_CLEANUP_IN_PROGRESS
    UPDATE_COMPLETE
    UPDATE_ROLLBACK_FAILED
    UPDATE_ROLLBACK_COMPLETE
  )

  def with_cloud_formation(file, params = {}, wait = true)
    path = File.join(File.dirname(__FILE__), '..', 'files', "#{file}.json")
    stack = cloud_formation.stacks.create(
      "test-custom-#{SecureRandom.uuid}",
      IO.read(path),
      parameters: params)

    wait_until_complete(stack) if wait

    if block_given?
      yield(stack)
      stack.delete
    end

    stack
  end

  def cloud_formation
    @cloud_formation ||= AWS::CloudFormation.new
  end

  def topics
    @topics ||= sns.topics
  end

  def sns
    @sns ||= AWS::SNS.new
  end

  def subscriptions
    sns.subscriptions
  end

  def queues
    @queues ||= AWS::SQS.new.queues
  end

  def wait_until(label, max_waits = 60)
    waits = 0
    while !yield
      print '*'
      waits += 1

      if waits >= max_waits
        raise "Waited for #{waits * 3} #{label} and it didn't finish, giving up"
      end

      sleep(3)
    end
  end

  def wait_until_complete(stack, max_waits = 60)
    waits = 0
    while !COMPLETE_STATUSES.include?(stack.status)
      print '*'
      waits += 1

      if waits >= max_waits
        raise "Waited for #{waits * 3} and #{stack.name} status is still #{stack.status}, giving up"
      end

      sleep(3)
    end
  end

  def stack_outputs(stack)
    stack.outputs.inject({}) do |acc, output|
      acc[output.key] = output.value
      acc
    end
  end

  def with_main_formation(&block)
    with_cloud_formation 'test-formation' do |stack|
      outputs = stack_outputs(stack)

      poller = CloudFormation::Bridge::Poller.new(outputs["Queue"])

      block.call(stack, poller, outputs)

      poller.poll
    end
  end

end