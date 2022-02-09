require "hashie"
require "faraday"
require "faraday_middleware"
require "multi_json"
require "uri"

module RabbitMQ
  module HTTP
    class ResponseHelper

      def initialize(client)
        @client = client
      end

      def decode_resource(response)
        if response.nil? || response.body.empty?
          Hashie::Mash.new
        else
          decode_response_body(response.body)
        end
      end

      def decode_response_body(body)
        if body.empty?
          Hashie::Mash.new
        else
          Hashie::Mash.new(body)
        end
      end

      def decode_resource_collection(response)
        collection = response.body.is_a?(Array) ? response.body : response.body.fetch('items')

        collection.map { |i| Hashie::Mash.new(i) }
      end
    end
  end
end
