# RabbitMQ HTTP API Client for Ruby

This gem is a RabbitMQ HTTP API Client for Ruby. It supports

 * Getting cluster overview information
 * Getting cluster nodes status (# file descriptors used, RAM consumption and so on)
 * Getting information about exchanges, queues, bindings
 * Closing client connections
 * Getting information about vhosts, users, permissions

and will support more HTTP API features in the future

 * Publishing messages via HTTP
 * Operations on components/extensions
 * Operations on federation policies

## Supported Ruby Versions

 * MRI 1.9.3
 * JRuby 1.7+
 * Rubinius 2.0+
 * MRI 1.9.2
 * MRI 1.8.7

## Supported RabbitMQ Versions

 * RabbitMQ 3.x
 * RabbitMQ 2.x

All versions require [RabbitMQ Management UI plugin](http://www.rabbitmq.com/management.html) to be installed and enabled.

## Installation

Add this line to your application's Gemfile:

    gem 'veterinarian'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install veterinarian

## Usage

TODO: Write usage instructions here

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request


## License & Copyright

Double-licensed under the MIT and Mozilla Public License (same as RabbitMQ).

(c) Michael S. Klishin, 2012-2013.
