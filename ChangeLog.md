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
