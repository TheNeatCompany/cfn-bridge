require 'cloud_formation/bridge/resources/cloud_formation_outputs'
require 'cloud_formation/bridge/poller'

describe CloudFormation::Bridge::Resources::CloudFormationOutputs do

  include CloudFormationCreator

  it 'should correctly pull the outputs from the CFN', integration: true do

    with_main_formation do |stack, poller, outputs|
      params = {
        "Name" => stack.name,
        "EntryTopic" => outputs["Topic"],
        "EntryQueue" => outputs["Queue"],
      }

      with_cloud_formation('outputs-formation', params, false) do |outputs_stack|

        wait_until "messages available" do
          poller.visible_messages > 0
        end

        poller.poll

        wait_until_complete(outputs_stack)

        expected_outputs = stack_outputs(outputs_stack)

        expect(outputs["Topic"]).to eq(expected_outputs["Topic"])
        expect(outputs["Queue"]).to eq(expected_outputs["Queue"])
      end
    end

  end

end