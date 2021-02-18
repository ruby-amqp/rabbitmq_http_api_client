require "hashie"
require "faraday"
require "faraday_middleware"
require "multi_json"
require "uri"

module RabbitMQ
  module HTTP
    class RequestHelper
      def encode_uri_path_segment(segment)
        # Correctly escapes spaces, see ruby-amqp/rabbitmq_http_api_client#28.
        #
        # Note that slashes also must be escaped since this is a single URI path segment,
        # not an entire path.
        Addressable::URI.encode_component(segment, Addressable::URI::CharacterClasses::UNRESERVED)
      end
    end
  end
end