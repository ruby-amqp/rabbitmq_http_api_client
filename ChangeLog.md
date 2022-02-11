## Changes Between 2.1.0 and 2.2.0 (in development)

No changes yet.


## Changes Between 2.0.0 and 2.1.0 (February 12, 2022)

### Handle Responses that Do Not Contain a Body

GitHub issue: [#52](https://github.com/ruby-amqp/rabbitmq_http_api_client/issues/52)

### Support for Management of Topic Permissions

Contributed by @bagedevimo.

GitHub issue: [#57](https://github.com/ruby-amqp/rabbitmq_http_api_client/issues/57)

### Upgraded Faraday Middleware

Faraday (a dependency) has been upgraded to `1.2.x` to eliminate some deprecation warnings.


## Changes Between 1.15.0 and 2.0.0 (May 21, 2021)

### Health Check Endpoint Changes

`RabbitMQ::HTTP::Client#aliveness_test` has been removed. The endpoint has been deprecated
in favor of [more focussed health check endpoints](https://www.rabbitmq.com/monitoring.html#health-checks):

``` ruby
c = RabbitMQ::HTTP::Client.new("http://username:s3kRe7@localhost:15672")

# Returns a pair of [success, details]. Details will be nil
# if the check succeeds.
#
# Checks for any alarms across the cluster
passed, details = c.health.check_alarms

# alarms on the given node
passed, details = c.health.check_local_alarms

# is this node essential for an online quorum of any quorum queues?
passed, details = c.health.check_if_node_is_quorum_critical

# do any certificates used by this node's TLS listeners expire within
# three months?
passed, details = c.health.check_certificate_expiration(3, "months")
```

See the list of methods in `RabbitMQ::HTTP::HealthChecks` to find out what other
health checks are available.

### User Tags Type Change

User tags returned by the `RabbitMQ::HTTP::Client#list_users` and `RabbitMQ::HTTP::Client#user_info`
methods are now arrays of strings instead of comma-separated strings.

Internally the method encodes both command-separated strings and JSON arrays in API responses
to support response types from RabbitMQ 3.9 and earlier versions.

See [rabbitmq/rabbitmq-server#2676](https://github.com/rabbitmq/rabbitmq-server/pull/2676) for details.

## Changes Between 1.14.0 and 1.15.0 (February 16th, 2021)
### Content Length Detection Changes

When deserialising response bodies, the client now uses actual body length instead of
the value of the `content-length` header.

Contributed by Ryan @rquant Quant.

GitHub issue: [#49](https://github.com/ruby-amqp/rabbitmq_http_api_client/pull/49)


## Changes Between 1.13.0 and 1.14.0 (July 8th, 2020)

### URI.escape is No Longer Used

Deprecated `URI.escape` has been replaced with `Addressable::URI.escape_component`.
This introduces `addressable` as a new dependency.

### Dependency Bump

Note: Faraday will now raise a `Faraday::ResourceNotFound` instead of `Faraday::Error::ResourceNotFound`.

GitHub issue: [#45](https://github.com/ruby-amqp/rabbitmq_http_api_client/pull/45)

Contributed by Niels Jansen.

## Changes Between 1.12.0 and 1.13.0 (March 5th, 2020)

### Pagination Support

GitHub issue: [#43](https://github.com/ruby-amqp/rabbitmq_http_api_client/pull/43)

Contributed by Rustam Sharshenov.

### Dependency Updates

GitHub issue: [#42](https://github.com/ruby-amqp/rabbitmq_http_api_client/pull/42)

Contributed by @hatch-carl.


## Changes Between 1.11.0 and 1.12.0 (March 12th, 2019)

### Dependency Updates

GitHub issue: [#38](https://github.com/ruby-amqp/rabbitmq_http_api_client/pull/38)

Contributed by Jon Homan.


## Changes Between 1.10.0 and 1.11.0 (Dec 25th, 2018)

### effin_utf8 Dependency Dropped

This library no longer supports Ruby 1.8 and thus
doesn't need to depend on the `effin_utf8` gem.

Contributed by Luciano Sousa.


## Changes Between 1.9.0 and 1.10.0 (Nov 27th, 2018)

### Improved Resource Deserialisation

Bodies of responses with content length of 0 will no longer
be deserialised.

This improves compatibility with future versions of RabbitMQ
that will use Cowboy 2.7.0 or later, which doesn't include
the content-type header for blank responses (e.g. PUTs).


## Changes Between 1.9.0 and 1.9.1 (Oct 19th, 2017)

Spec files and development/CI scripts are no longer included into the gem.


## Changes Between 1.8.0 and 1.9.0 (July 30th, 2017)

### Make it Possible to Pass Faraday Adapter as Option

GitHub issue: [#30](https://github.com/ruby-amqp/rabbitmq_http_api_client/issues/30)

Contributed by Mrinmoy Das.



## Changes Between 1.7.0 and 1.8.0 (Feb 1st, 2017)

### Correct URI Path Segment Encoding

URI path segment encoding (e.g. vhosts, queue names, etc)
in this client now correctly encodes spaces.

GitHub issue: [#28](https://github.com/ruby-amqp/rabbitmq_http_api_client/issues/28).



## Changes Between 1.6.0 and 1.7.0

### Blank Tags by Default

The `:tags` attribute is no longer required by `Client#update_user`. If not provided,
a blank list of tags will be used.


## Changes Between 1.5.0 and 1.6.0

### Definition Upload Support

The client now can upload definitions (of queues, exchanges, etc):

``` ruby
defs = {
        :queues => [{
          :name => 'my-definition-queue',
          :vhost => '/',
          :durable => true,
          :auto_delete =>  false,
          :arguments => {
             "x-dead-letter-exchange" => 'dead'
          }
        }]
      }.to_json

c.upload_definitions(defs)
```

Contributed by Pol Miro.



## Changes Between 1.4.0 and 1.5.0

### Support for URIs containing a path

If provided endpoint contains a path, it will be used instead of `/api`.

Contributed by Pol Miro.

## Changes Between 1.3.0 and 1.4.0

### Protocol Ports for Non-Administrators

`Client#protocol_ports` no longer fails with a nil pointer exception
for non-administrators.

### Hashie Upgrade

The library now depends on `hashie ~> 3.2`.

Contributed by Damon Morgan.

### MultiJSON Upgrade

The library now depends on `multi_json ~> 1.9`.

Contributed by Damon Morgan.


## Changes Between 1.2.0 and 1.3.0

### Faraday Upgrade

The project now depends on Faraday `0.9.x`.

Contributed by John Murphy.

### Exchange Deletion

`RabbitMQ::HTTP::Client#delete_exchange` is a new function that deletes exchanges:

``` ruby
c.delete_exchange("/", "an.exchange")
```

Contributed by Matt Bostock.


## Changes Between 1.1.0 and 1.2.0

### Ruby 1.8 Compatibility Restored

The library no longer uses 1.9-specific hash syntax.



## Changes Between 1.0.0 and 1.1.0

### declare_exchange

It is now possible to declare an exchange over HTTP API using `RabbitMQ::HTTP::Client#declare_exchange`:

``` ruby
c.declare_exchange("/", exchange_name, :durable => false, :type => "fanout")
```

Contributed by Jake Davis (Simple).


## Changes Between 0.9.0 and 1.0.0

### Hashi Upgrade

The library now depends on `hashie ~> 2.0.5`.

### Faraday Upgrade

The library now depends on `faraday ~> 0.8.9`.


### MultiJSON Upgrade

The library now depends on `multi_json ~> 1.8.4`.


## Changes Between 0.8.0 and 0.9.0

### New Queue Binding Methods

`RabbitMQ::HTTP::Client#queue_binding_info`,
`RabbitMQ::HTTP::Client#bind_queue`, and
`RabbitMQ::HTTP::Client#delete_queue_binding`
are new methods that operate on queue bindings:

``` ruby
c = RabbitMQ::HTTP::Client.new("http://guest:guest@127.0.0.1:15672")

c.bind_queue("/", "a.queue", "an.exchange", "routing.key")
c.queue_binding_info("/", "a.queue", "an.exchange", "properties.key")
c.delete_queue_binding("/", "a.queue", "an.exchange", "properties.key")
```

Contributed by Noah Magram.


## Changes Between 0.7.0 and 0.8.0

### Client#protocol_ports

`RabbitMQ::HTTP::Client#enabled_protocols` is a new method that returns
a hash of enabled protocols to their ports. The keys are the same as
returned by `Client#enabled_protocols`:

``` ruby
# when TLS and MQTT plugin is enabled
c.protocol_ports # => {"amqp" => 5672, "amqp/ssl" => 5671, "mqtt" => 1883}
```

### Client#enabled_protocols

`RabbitMQ::HTTP::Client#enabled_protocols` is a new method that returns
a list of enabled protocols. Some common values are:

 * `amqp` (AMQP 0-9-1)
 * `amqp/ssl` (AMQP 0-9-1 with TLS enabled)
 * `mqtt`
 * `stomp`

``` ruby
# when TLS and MQTT plugin is enabled
c.enabled_protocols # => ["amqp", "amqp/ssl", "mqtt"]
```



## Changes Between 0.6.0 and 0.7.0

### Support for Basic HTTP Auth Credentials in URI

It is now possible to pass credentials in the endpoint URI:

``` ruby
c = RabbitMQ::HTTP::Client.new("https://guest:guest@127.0.0.1:15672/")
```


## Changes Between 0.5.0 and 0.6.0

### Support for Advanced Connection Options

It is now possible to pass more options to Faraday connection,
for example, HTTPS related ones:

``` ruby
c = RabbitMQ::HTTP::Client.new("https://127.0.0.1:15672/", username: "guest", password: "guest", ssl: {
  client_cer: ...,
  client_key: ...,
  ca_file:    ...,
  ca_path:    ...,
  cert_store: ...
})
```

Any options other than `username` and `password` will be passed on to
`Faraday::Connection`.



## Changes Between 0.4.0 and 0.5.0

### Endpoint Reader

`RabbitMQ::HTTP::Client#endpoint` is a new reader (getter) that makes
it possible to access the URI a client instance uses.


## Changes Between 0.3.0 and 0.4.0

### Meaningful Exceptions for 4xx and 5xx Responses

`4xx` and `5xx` responses now will result in meaningful exceptions
being raised. For example, `404` responses will raise `Faraday::Error::ResourceNotFound`.


## Changes Between 0.2.0 and 0.3.0

### MultiJSON Upgrade

The library now depends on `multi_json ~> 1.7.0`.


## Changes Between 0.1.0 and 0.2.0

### Support for more HTTP API operations

 * Operations on queues
 * Operations on users
 * Operations on permissions
 * Operations on parameters
 * Operations on policies


## Original Release: 0.1.0

### Support for many HTTP API operations

 * Status overview
 * Cluster nodes information
 * Operations on exchanges, queues, bindings
 * Operations on connections
