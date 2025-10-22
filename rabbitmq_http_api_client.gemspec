# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rabbitmq/http/client/version'

Gem::Specification.new do |gem|
  gem.name          = "rabbitmq_http_api_client"
  gem.version       = RabbitMQ::HTTP::Client::VERSION
  gem.authors       = ["Michael Klishin"]
  gem.email         = ["michael@clojurewerkz.org"]
  gem.description   = %q{RabbitMQ HTTP API client for Ruby}
  gem.summary       = %q{RabbitMQ HTTP API client for Ruby}
  gem.homepage      = "http://github.com/ruby-amqp/rabbitmq_http_api_client"
  gem.licenses      = ["MIT", "MPL-2.0"]

  gem.files         = Dir["ChangeLog.md", "LICENSE.txt", "README.md", "lib/**/*"]
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency    'addressable', '~> 2.8'
  gem.add_dependency    'hashie', '~> 5.0'
  gem.add_dependency    'multi_json', '~> 1.17'
  gem.add_dependency    'faraday', '~> 2.14'
  gem.add_dependency    'faraday-follow_redirects', '~> 0.4'
end
