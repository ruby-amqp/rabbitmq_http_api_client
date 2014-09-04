## Changes Between 1.3.0 and 1.4.0

### Protocol Ports for Non-Administrators

`Client#protocol_ports` no longer fails with a nil pointer exception
for non-administrators.

### Hashi Upgrade

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
