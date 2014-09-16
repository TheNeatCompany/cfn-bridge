<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**

- [cfn-bridge](#cfn-bridge)
	- [Installation](#installation)
	- [Usage](#usage)
	- [Building a custom resource](#building-a-custom-resource)
		- [Implementing the `create` operation](#implementing-the-create-operation)
		- [Implementing `update` is usually not a requirement](#implementing-update-is-usually-not-a-requirement)
		- [Implementing the `delete` operation](#implementing-the-delete-operation)
		- [Registering and using it](#registering-and-using-it)
	- [Current custom resources](#current-custom-resources)
		- [Custom::SubscribeSQSQueueToSNSTopic](#customsubscribesqsqueuetosnstopic)
		- [Custom::CloudFormationOutputs](#customcloudformationoutputs)
		- [Custom::Custom::ElastiCacheReplicationGroup](#customcustomelasticachereplicationgroup)
		- [Custom::ElastiCacheReplicaCluster](#customelasticachereplicacluster)
		- [Custom::ElastiCacheNodeURLs](#customelasticachenodeurls)
	- [Contributing](#contributing)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# cfn-bridge

[This project is sponsored by Neat](http://www.neat.com/)

A bridge to allow you to build custom AWS cloud formation resources in Ruby.

Check Amazon's page [on custom cloud formation resources](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/crpg-walkthrough.html)
to get more info on how and why you would like to have them.

If you're into Python more than Ruby, there's an [AWS project for this as well](http://blogs.aws.amazon.com/application-management/post/Tx2FNAPE4YGYSRV/Customers-CloudFormation-and-Custom-Resources).

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

This will start a worker consuming from `QUEUE_NAME` until the caller calls `CTRL-C` to stop it. `QUEUE_NAME` should be the SQS queue to where the SNS topic is publishing the custom resource messages. An example template that setups the topic and the queue [is available at the repo](spec/files/test-formation.json) and can be used to provide the base topic and queue to use this gem.

Since this gem uses the `aws-sdk` gem you have to setup your AWS keys as environment variables (or as an IAM profile if you're running on EC2) to make sure the gem has the right credentials to perform the operations. As usual, we recommend that you provide keys with access only to the operations you're going to perform, do not provide all access keys for this.

## Building a custom resource

Building a custom resource is simple, all it requires is a class with two methods, `create` and `delete` (you can also have an `update` one if it makes sense for your resource to be updateable) that will take the message parameter. Your custom resource should also inherit from `CloudFormation::Bridge::Resources::Base` to simplify your job, it provides a default `update` method that always fails and includes a couple constants you will have to use at your responses.

All three operations take a [Request](lib/cloud_formation/bridge/request.rb) method as a parameter and you should check it to see the method the fields that are available there for you to use.

Let's look at our `SubscribeQueueToTopic` to get a sense of how custom resources could be implemented, starting with the constants:

```ruby
ARN = 'Arn'

TOPIC_ARN = 'TopicArn'
QUEUE_NAME = 'QueueName'
RAW_MESSAGE_DELIVERY = 'RawMessageDelivery'

REQUIRED_FIELDS = [
  TOPIC_ARN,
  QUEUE_NAME,
]
```

This list of constants are first the outputs produced by the resource (`ARN`) and then the inputs that are used to create it, `TOPIC_ARN`, `QUEUE_NAME` and `RAW_MESSAGE_DELIVERY`. The inputs are the fields we use to create the resource, since this resource is meant to subscribe an SQS queue to an SNS topic, we accept the topic ARN, the queue name and an optional `raw message delivery` field that instructs the subscription to send the raw message only and not the message with the other SNS fields.

### Implementing the `create` operation

Now let's look at the first operation, the `create` method:

```ruby
def create(request)
  require_fields(request, REQUIRED_FIELDS)

  queue = queues.named(request.resource_properties[QUEUE_NAME])
  topic = topics[request.resource_properties[TOPIC_ARN]]

  subscription = topic.subscribe(queue)

  if request.resource_properties[RAW_MESSAGE_DELIVERY]
    subscription.raw_message_delivery = true
  end

  {
    FIELDS::PHYSICAL_RESOURCE_ID => subscription.arn,
    FIELDS::DATA => {
      ARN => subscription.arn,
    },
  }
end
```

First, we validate that we have all the fields required to create the resource (topic ARN and queue name), if any one of these fields is empty, we raise an exception with the field that was empty. The code at the gem that does the messaging and executes your resources will catch any exception that inherits from `StandardError` and will forward it's message as a failure to the Cloud Formation service, this errors will be visible at the cloud formation events so make sure you raise exceptions with useful error messages whenever you have to.

From that on, we just implement the operation, grab the queue, grab the topic, subscribe one to the other, set the raw message delivery field if it was set and then, here's the important part, return the response.

Let's look at an example return response in raw JSON:

```javascript
{
   "Status" : "SUCCESS",
   "PhysicalResourceId" : "Tester1",
   "StackId" : "arn:aws:cloudformation:us-east-1:EXAMPLE:stack/stack-name/guid",
   "RequestId" : "unique id for this create request",
   "LogicalResourceId" : "MySeleniumTester",
   "Data" : {
      "resultsPage" : "http://www.myexampledomain/test-results/guid",
      "lastUpdate" : "2012-11-14T03:30Z",
   }
}
```

And let's look at the one we're returning at the current `create` method:

```ruby
{
  FIELDS::PHYSICAL_RESOURCE_ID => subscription.arn,
  FIELDS::DATA => {
    ARN => subscription.arn,
  },
}
```

The fields `Status`, `StackId`, `LogicalResourceId` and `RequestId` are not present here because the code that executes your resource already knows how to fill them, so you only have to care about `PhysicalResourceId` and `Data`.

The physical resource id should be a unique value that you can use to find this resource later when you receive `update` and `delete` operations. When dealing with AWS resources your best bet is to always use the `ARN` for the resource you're creating, this guarantees it is unique for your cloud formation and that you can easily find it later on other requests.

The `Data` field should contain fields that might be useful for the cloud formation where the resource is included, you don't actually have to provide one, but all fields returned here are available to `Fn::GetAtt` operations at your cloud formation template, so make sure you send back some useful data back if possible.

### Implementing `update` is usually not a requirement

Since it wouldn't make much sense to update a subscription (you're either subscribed to something or you're not) we don't have an `update` method here, but if it makes sense for your resource, the update method follows the same pattern as `create`, just make sure you're *not changing the physical resource id* as it will be ignored. It's usually much simpler not to implement updates and always require the resource to be deleted and created again.

### Implementing the `delete` operation

The `delete` method is much simpler than `create`:

```ruby
def delete(request)
  subscription = subscriptions[request.physical_resource_id]
  subscription.unsubscribe if subscription && subscription.exists?
end
```

Here we find the subscription using it's physical resource id (we used the subscription's `ARN` for this) and, if it exists, it is destroyed. Checking for the existence here is important because if your resource fails to be created the cloud formation service will still issue a `delete` operation for it (in case it was created even after failing) so make sure your code ignores delete operations for resources that do not exist.

### Registering and using it

Once you resource is implemented, you must either register it at the [Executor::DEFAULT_REGISTRY hash](lib/cloud_formation/bridge/executor.rb) or manually create an executor providing it at the hash. Make sure the name you use starts with `Custom::` and that it doesn't clash with other resources already registered there.

Once you have it registered, you can just declare your resource at any cloud formation template:

```javascript
"Resources": {
    "FirstQueue": {
        "Type": "AWS::SQS::Queue",
        "Properties": {
            "ReceiveMessageWaitTimeSeconds": 20,
            "VisibilityTimeout": 60
        }
    },
    "FirstTopic": {
        "Type": "AWS::SNS::Topic"
    },
    "SubscribeResource": {
        "Type": "Custom::SubscribeSQSQueueToSNSTopic",
        "Properties": {
            "ServiceToken": {
                "Ref": "EntryTopic"
            },
            "TopicArn": {
                "Ref": "FirstTopic"
            },
            "QueueName": {
                "Fn::GetAtt": ["FirstQueue", "QueueName"]
            }
        }
    }
}
```

It is declared just like any other custom resource with the name you have registered at the executor (`Custom::SubscribeSQSQueueToSNSTopic` in this case) and then you can include your properties as needed. The `ServiceToken` property must always be there and should point to the SNS topic that is being watched for custom resource messages, the other properties are the ones your resource will use to implement it's actions.

And with this you should be able to start creating your own custom cloud formation resources.

Gotchas you should be aware:

* Do not return `nil` on `Data` fields, your resource will not be created and you will not get any error message about this;
* Make sure all messages are logged somewhere (I'd recommend an email) so even if the service fails to create resources for some reason you can still work with the cloud formation manually;
* Direct your logs somewhere where you can easily look at, the command line interface will print everything to `STDOUT`, make sure you send this data to a file so you can look at what's going on;

## Current custom resources

### Custom::SubscribeSQSQueueToSNSTopic

Subscribes an SQS queue to an SNS topic.

Parameters:

* `TopicArn` - the SNS topic that will be subscribed to - *required*;
* `QueueName` - the SQS queue that will receive the messages from the topic - *required*;
* `RawMessageDelivery` - if set, the SNS message will not include the JSON envelope, it will send the raw message to the queue;

### Custom::CloudFormationOutputs

Makes all outputs from another cloud formation available to `Fn::GetAtt` calls.

Parameters:

* `Name` - the name of the cloud formation you want to get the outputs from - *required*;


### Custom::Custom::ElastiCacheReplicationGroup

Creates an `ElastiCache` replication group from an already available cache cluster (that will be configured as the primary).

Parameters:

* `ClusterId` - the name of the primary ElastiCache cluster for this replication group;
* `ReplicationGroupId` - the name of this replication group - this field follows the same `ElastiCache` naming requirements, 20 alphanumeric characters or `-`;
* `Description` - the group description;

Produced `Fn::GetAtt` values:

* `ReplicationGroupId` - the replication group id;

### Custom::ElastiCacheReplicaCluster

Creates an `ElastiCache` replica cluster for an already existing replication group.

Parameters:

* `ReplicationGroupId` - the id of the replication group where this replica cluster will register itself;
* `ReplicaClusterId` - the id for this replication group;

Produced `Fn::GetAtt` values:

* `ReplicaClusterId` - the id of this replica cluster;
* `NodeURLs` - list of `host:port` values (separated by `,`) for the nodes in the cluster if it is a redis cluster or the configuration URL for a memcached cluster;

### Custom::ElastiCacheNodeURLs

Produces pairs of `host:port` separated by `,` for all nodes in the cluster if it's a Redis cluster or the configuration `host:port` if it is a Memcached cluster.

Parameters:

* `ClusterId` - the name of the primary ElastiCache cluster for this replication group;

Produced `Fn::GetAtt` values:

* `NodeURLs` - list of `host:port` values (separated by `,`) for the nodes in the cluster if it is a Redis cluster or the configuration `host:port` for a Memcached cluster;

## Contributing

1. [Fork it](https://github.com/TheNeatCompany/cfn-bridge/fork)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
