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
