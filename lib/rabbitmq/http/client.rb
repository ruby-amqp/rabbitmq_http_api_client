require "hashie"
require "faraday"
require "faraday_middleware"
require "multi_json"

# for URI encoding
require "cgi"

module RabbitMQ
  module HTTP
    class Client

      #
      # API
      #

      def self.connect(endpoint, options = {})
        new(endpoint, options)
      end

      def initialize(endpoint, options = {})
        @endpoint = endpoint
        @options  = options

        initialize_connection(endpoint, options)
      end

      def overview
        decode_resource(@connection.get("/api/overview"))
      end

      def list_nodes
        decode_resource_collection(@connection.get("/api/nodes"))
      end

      def node_info(name)
        decode_resource(@connection.get("/api/nodes/#{uri_encode(name)}"))
      end

      def list_extensions
        decode_resource_collection(@connection.get("/api/extensions"))
      end

      def list_definitions
        decode_resource(@connection.get("/api/definitions"))
      end

      def upload_definitions(defs)
        raise NotImplementedError.new
      end

      def list_connections
        decode_resource_collection(@connection.get("/api/connections"))
      end

      def connection_info(name)
        decode_resource(@connection.get("/api/connections/#{uri_encode(name)}"))
      end

      def close_connection(name)
        decode_resource(@connection.delete("/api/connections/#{uri_encode(name)}"))
      end

      def list_channels
        decode_resource_collection(@connection.get("/api/channels"))
      end

      def channel_info(name)
        decode_resource(@connection.get("/api/channels/#{uri_encode(name)}"))
      end

      def list_exchanges(vhost = nil)
        path = if vhost.nil?
                 "/api/exchanges"
               else
                 "/api/exchanges/#{uri_encode(vhost)}"
               end

        decode_resource_collection(@connection.get(path))
      end

      def exchange_info(vhost, name)
        decode_resource(@connection.get("/api/exchanges/#{uri_encode(vhost)}/#{uri_encode(name)}"))
      end

      def list_bindings_by_source(vhost, exchange)
        decode_resource_collection(@connection.get("/api/exchanges/#{uri_encode(vhost)}/#{uri_encode(exchange)}/bindings/source"))
      end

      def list_bindings_by_destination(vhost, exchange)
        decode_resource_collection(@connection.get("/api/exchanges/#{uri_encode(vhost)}/#{uri_encode(exchange)}/bindings/destination"))
      end

      def list_queues(vhost = nil)
        path = if vhost.nil?
                 "/api/queues"
               else
                 "/api/queues/#{uri_encode(vhost)}"
               end

        decode_resource_collection(@connection.get(path))
      end

      def queue_info(vhost, name)
        decode_resource(@connection.get("/api/queues/#{uri_encode(vhost)}/#{uri_encode(name)}"))
      end

      def declare_queue(vhost, name, attributes)
        raise NotImplementedError.new
      end

      def delete_queue(vhost, name)
        raise NotImplementedError.new
      end

      def purge_queue(vhost, name)
        raise NotImplementedError.new
      end


      def list_bindings(vhost = nil)
        path = if vhost.nil?
                 "/api/bindings"
               else
                 "/api/bindings/#{uri_encode(vhost)}"
               end

        decode_resource_collection(@connection.get(path))
      end

      def list_vhosts
        decode_resource_collection(@connection.get("/api/vhosts"))
      end

      def vhost_info(name)
        decode_resource(@connection.get("/api/vhosts/#{uri_encode(name)}"))
      end



      def list_users
        decode_resource_collection(@connection.get("/api/users"))
      end



      def list_policies
        decode_resource_collection(@connection.get("/api/policies"))
      end


      def list_parameters
        decode_resource_collection(@connection.get("/api/parameters"))
      end



      def aliveness_test(vhost)
        r = @connection.get("/api/aliveness-test/#{uri_encode(vhost)}")
        r.body["status"] == "ok"
      end


      protected

      def initialize_connection(endpoint, options = {})
        @connection = Faraday.new(:url => endpoint) do |conn|
          conn.basic_auth options.fetch(:username, "guest"), options.fetch(:password, "guest")
          conn.use        FaradayMiddleware::FollowRedirects, :limit => 3
          conn.response   :json, :content_type => /\bjson$/

          conn.adapter    options.fetch(:adapter, Faraday.default_adapter)
        end
      end

      def uri_encode(s)
        CGI.escape(s)
      end

      def decode_resource(response)
        Hashie::Mash.new(response.body)
      end

      def decode_resource_collection(response)
        response.body.map { |i| Hashie::Mash.new(i) }
      end
    end # Client
  end # HTTP
end # RabbitMQ
