# cfn-bridge

A bridge to allow you to build custom AWS cloud formation resources.

Check Amazon's page [on custom cloud formation resources](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/crpg-walkthrough.html)
to get more info on how and why you would like to have them.

## Installation

Add this line to your application's Gemfile:

    gem 'cfn-bridge'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install cfn-bridge

## Usage

Run:

    $ cfn-bridge start QUEUE_NAME

This will start a worker consuming from `QUEUE_NAME` until the caller calls `CTRL-C` to stop it. `QUEUE_NAME` should be the SQS queue to where the SNS topic is publishing the custom resource messages. An example template that setups the topic and the queue [is available at the repo](spec/files/test-formation.json) and can be used to provide the base topic and queue to use this application.

## Contributing

1. [Fork it](https://github.com/TheNeatCompany/cfn-bridge/fork)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
