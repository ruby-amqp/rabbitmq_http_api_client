# RabbitMQ HTTP API Client for Ruby

This gem is a [RabbitMQ HTTP API](http://hg.rabbitmq.com/rabbitmq-management/raw-file/450b7ea22cfd/priv/www/api/index.html) client for Ruby. It supports

 * Getting cluster overview information
 * Getting cluster nodes status (# file descriptors used, RAM consumption and so on)
 * Getting information about exchanges, queues, bindings
 * Closing client connections
 * Getting information about vhosts, users, permissions
 * Getting information about enabled plugins, protocols, their ports, etc
 * Managing vhosts, users, permissions

and will support more HTTP API features in the future

 * Publishing messages via HTTP
 * Operations on components/extensions
 * Operations on federation policies

## Supported Ruby Versions

 * CRuby 2.5 through 3.x
 * JRuby 9K

## Supported RabbitMQ Versions

All [supported RabbitMQ release series](https://www.rabbitmq.com/versions.html).

All versions require [RabbitMQ Management UI plugin](http://www.rabbitmq.com/management.html) to be installed and enabled.

## Installation

Add this line to your application's Gemfile:

``` ruby
gem 'rabbitmq_http_api_client', '>= 2.2.0'
```

And then execute:

    bundle install

Or install it yourself as:

    gem install rabbitmq_http_api_client

## Usage

To require the client:

``` ruby
require "rabbitmq/http/client"
```

### Specifying Endpoint and Credentials

Use `RabbitMQ::HTTP::Client#connect` to specify RabbitMQ HTTP API endpoint (e.g. `http://127.0.0.1:15672`) and credentials:

``` ruby
require "rabbitmq/http/client"

endpoint = "http://127.0.0.1:15672"
client = RabbitMQ::HTTP::Client.new(endpoint, username: "guest", password: "guest")
```

Alternatively, credentials can be specified in the endpoint URI:

``` ruby
require "rabbitmq/http/client"

client = RabbitMQ::HTTP::Client.new("http://guest:guest@127.0.0.1:15672")
```

### Client API Design Overview

All client methods return arrays or hash-like structures that can be used
like JSON, via `Hash#[]` or regular method access:

``` ruby
r = client.overview

puts r[:rabbitmq_version]
puts r.erlang_version
```

### Accessing Management API with HTTPS

All additional options other than `:username` and `:password` are passed
to [Faraday::Connection](https://github.com/lostisland/faraday). So, it is possible to use HTTPS
like so:

``` ruby
c = RabbitMQ::HTTP::Client.new("https://127.0.0.1:15672/", username: "guest", password: "guest", ssl: {
  client_cer: ...,
  client_key: ...,
  ca_file:    ...,
  ca_path:    ...,
  cert_store: ...
})
```

Or, if you have good reasons to do so, disable peer verification:

``` ruby
c = RabbitMQ::HTTP::Client.new("https://127.0.0.1:15672/", username: "guest", password: "guest", ssl: {
  verify: false
})
```


### Node and Cluster Status

``` ruby
# Get cluster information overview
h     = client.overview

# List cluster nodes with detailed status info for each one of them
nodes = client.list_nodes
n     = nodes.first
puts n.sockets_used
puts n.mem_used
puts n.run_queue

# Get detailed status of a node
n     = client.node_info("rabbit@localhost")
puts n.disk_free
puts n.proc_used
puts n.fd_total

# Get Management Plugin extension list
xs    = client.list_extensions

# List all the entities (vhosts, queues, exchanges, bindings, users, etc)
defs  = client.list_definitions
```

### Operations on Connections

``` ruby
# List all connections to a node
conns = client.list_connections
conn  = conns.first
puts conn.name
puts conn.client_properties.product

# Get a connection information by name
conns = client.list_connections
conn  = client.connection_info(conns.first.name)
puts conn.name
puts conn.client_properties.product

# Forcefully close a connection
conns = client.list_connections
client.close_connection(conns.first.name)
```

### Operations on Channels

``` ruby
# List all channels
channs = client.list_channels
ch     = channs.first
puts ch.number
puts ch.prefetch_count
puts ch.name


# Get a channel information by name
conns = client.list_channels
conn  = client.channel_info(conns.first.name)
puts conn.name
```

### Operations on Exchanges

``` ruby
# List all exchanges in the cluster
xs = client.list_exchanges
x  = xs.first

puts x.type
puts x.name
puts x.vhost
puts x.durable
puts x.auto_delete

# List all exchanges in a vhost
xs = client.list_exchanges("myapp.production")
x  = xs.first

puts x.type
puts x.name
puts x.vhost

# Get information about an exchange in a vhost
x  = client.exchange_info("/", "log.events")

puts x.type
puts x.name
puts x.vhost

# List all exchanges in a vhost for which an exchange is the source
client.list_bindings_by_source("/", "log.events")

# List all exchanges in a vhost for which an exchange is the destination
client.list_bindings_by_destination("/", "command.handlers.email")
```

### Operations on Queues

``` ruby
# List all queues in a node
qs = client.list_queues
q  = qs.first

puts q.name
puts q.auto_delete
puts q.durable
puts q.backing_queue_status
puts q.active_consumers


# Get information about a queue
client.queue_info("/", "collector1.megacorp.local")

# Declare a queue
client.declare_queue("/", "collector1.megacorp.local", :durable => false, :auto_delete => true)

# Delete a queue
client.delete_queue("/", "collector1.megacorp.local")

# List bindings for a queue
bs = client.list_queue_bindings("/", "collector1.megacorp.local")

# Purge a queue
client.purge_queue("/", "collector1.megacorp.local")

# Fetch messages from a queue
ms = client.get_messages("/", "collector1.megacorp.local", :count => 10, :requeue => false, :encoding => "auto")
m  = ms.first

puts m.properties.content_type
puts m.payload
puts m.payload_encoding
```

### Operations on Bindings

``` ruby
# List all bindings
bs = client.list_bindings
b  = bs.first

puts b.destination
puts b.destination_type
puts b.source
puts b.routing_key
puts b.vhost

# List all bindings in a vhost
bs = client.list_bindings("/")

# List all bindings between an exchange and a queue
bs = client.list_bindings_between_queue_and_exchange("/", "collector1.megacorp.local", "log.events")
```

### Operations on Vhosts

``` ruby
# List all vhosts
vs = client.list_vhosts
v  = vs.first

puts v.name
puts v.tracing

# Get information about a vhost
v  = client.vhost_info("/")

puts v.name
puts v.tracing

# Create a vhost
client.create_vhost("myapp.staging")

# Delete a vhost
client.delete_vhost("myapp.staging")
```

### Managing Users

``` ruby
# List all users
us = client.list_users
u  = us.first

puts u.name
puts u.password_hash
puts u.tags

# Get information about a user
u  = client.user_info("guest")

puts u.name
puts u.password_hash
puts u.tags

# Update information about a user
client.update_user("myapp", :tags => "services,policymaker,management", :password => "t0ps3krEt")

# Delete a user
client.delete_user("myapp")
```

### Managing Permissions

``` ruby
# List all permissions
ps = client.list_permissions

puts p.user
puts p.read
puts p.write
puts p.configure
puts p.vhost

# List all permissions in a vhost
ps = client.list_permissions("/")

puts p.user
puts p.read
puts p.write
puts p.configure
puts p.vhost

# List permissions of a user
ps = client.user_permissions("guest")

# List permissions of a user in a vhost
ps = client.list_permissions_of("/", "guest")

# Update permissions of a user in a vhost
ps = client.update_permissions_of("/", "guest", :write => ".*", :read => ".*", :configure => ".*")

# Clear permissions of a user in a vhost
ps = client.clear_permissions_of("/", "guest")
```

## Running Tests

    bundle install
    bundle exec rspec -cfd spec

The test suite assumes that RabbitMQ is running locally with stock settings
and rabbitmq-management plugin enabled.

## Continuous Integration

[![Build Status](https://travis-ci.org/ruby-amqp/rabbitmq_http_api_client.svg?branch=master)](https://travis-ci.org/ruby-amqp/rabbitmq_http_api_client)


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new pull request


## License & Copyright

Double-licensed under the MIT and Mozilla Public License (same as RabbitMQ).

(c) Michael S. Klishin, 2012-2020.
