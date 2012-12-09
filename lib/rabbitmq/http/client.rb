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
        response = @connection.put("/api/queues/#{uri_encode(vhost)}/#{uri_encode(name)}") do |req|
          req.headers['Content-Type'] = "application/json"
          req.body = MultiJson.dump(attributes)
        end
        decode_resource(response)
      end

      def delete_queue(vhost, name)
        decode_resource(@connection.delete("/api/queues/#{uri_encode(vhost)}/#{uri_encode(name)}"))
      end

      def list_queue_bindings(vhost, queue)
        decode_resource_collection(@connection.get("/api/queues/#{uri_encode(vhost)}/#{uri_encode(queue)}/bindings"))
      end

      def purge_queue(vhost, name)
        decode_resource(@connection.delete("/api/queues/#{uri_encode(vhost)}/#{uri_encode(name)}/contents"))
      end

      def get_messages(vhost, name, options)
        response = @connection.post("/api/queues/#{uri_encode(vhost)}/#{uri_encode(name)}/get") do |req|
          req.headers['Content-Type'] = "application/json"
          req.body = MultiJson.dump(options)
        end
        decode_resource_collection(response)
      end


      def list_bindings(vhost = nil)
        path = if vhost.nil?
                 "/api/bindings"
               else
                 "/api/bindings/#{uri_encode(vhost)}"
               end

        decode_resource_collection(@connection.get(path))
      end

      def list_bindings_between_queue_and_exchange(vhost, queue, exchange)
        decode_resource_collection(@connection.get("/api/bindings/#{uri_encode(vhost)}/e/#{uri_encode(exchange)}/q/#{uri_encode(queue)}"))
      end




      def list_vhosts
        decode_resource_collection(@connection.get("/api/vhosts"))
      end

      def vhost_info(name)
        decode_resource(@connection.get("/api/vhosts/#{uri_encode(name)}"))
      end

      def create_vhost(name)
        response = @connection.put("/api/vhosts/#{uri_encode(name)}") do |req|
          req.headers['Content-Type'] = "application/json"
        end
        decode_resource(response)
      end

      def delete_vhost(name)
        decode_resource(@connection.delete("/api/vhosts/#{uri_encode(name)}"))
      end



      def list_permissions(vhost = nil)
        path = if vhost
                 "/api/vhosts/#{uri_encode(vhost)}/permissions"
               else
                 "/api/permissions"
               end

        decode_resource_collection(@connection.get(path))
      end

      def list_permissions_of(vhost, user)
        decode_resource(@connection.get("/api/permissions/#{uri_encode(vhost)}/#{uri_encode(user)}"))
      end

      def update_permissions_of(vhost, user, attributes)
        response = @connection.put("/api/permissions/#{uri_encode(vhost)}/#{uri_encode(user)}") do |req|
          req.headers['Content-Type'] = "application/json"
          req.body = MultiJson.dump(attributes)
        end
        decode_resource(response)
      end

      def clear_permissions_of(vhost, user)
        decode_resource(@connection.delete("/api/permissions/#{uri_encode(vhost)}/#{uri_encode(user)}"))
      end



      def list_users
        decode_resource_collection(@connection.get("/api/users"))
      end

      def user_info(name)
        decode_resource(@connection.get("/api/users/#{uri_encode(name)}"))
      end

      def update_user(name, attributes)
        response = @connection.put("/api/users/#{uri_encode(name)}") do |req|
          req.headers['Content-Type'] = "application/json"
          req.body = MultiJson.dump(attributes)
        end
        decode_resource(response)
      end
      alias create_user update_user

      def delete_user(name)
        decode_resource(@connection.delete("/api/users/#{uri_encode(name)}"))
      end

      def user_permissions(name)
        decode_resource_collection(@connection.get("/api/users/#{uri_encode(name)}/permissions"))
      end

      def whoami
        decode_resource(@connection.get("/api/whoami"))
      end



      def list_policies(vhost = nil)
        path = if vhost
                 "/api/policies/#{uri_encode(vhost)}"
               else
                 "/api/policies"
               end

        decode_resource_collection(@connection.get(path))
      end

      def list_policies_of(vhost, name = nil)
        path = if name
                 "/api/policies/#{uri_encode(vhost)}/#{uri_encode(name)}"
               else
                 "/api/policies/#{uri_encode(vhost)}"
               end
        decode_resource_collection(@connection.get(path))
      end

      def update_policies_of(vhost, name, attributes)
        response = @connection.put("/api/policies/#{uri_encode(vhost)}/#{uri_encode(name)}") do |req|
          req.headers['Content-Type'] = "application/json"
          req.body = MultiJson.dump(attributes)
        end
        decode_resource(response)
      end

      def clear_policies_of(vhost, name)
        decode_resource(@connection.delete("/api/policies/#{uri_encode(vhost)}/#{uri_encode(name)}"))
      end




      def list_parameters(component = nil)
        path = if component
                 "/api/parameters/#{uri_encode(component)}"
               else
                 "/api/parameters"
               end
        decode_resource_collection(@connection.get(path))
      end

      def list_parameters_of(component, vhost, name = nil)
        path = if name
                 "/api/parameters/#{uri_encode(component)}/#{uri_encode(vhost)}/#{uri_encode(name)}"
               else
                 "/api/parameters/#{uri_encode(component)}/#{uri_encode(vhost)}"
               end
        decode_resource_collection(@connection.get(path))
      end

      def update_parameters_of(component, vhost, name, attributes)
        response = @connection.put("/api/parameters/#{uri_encode(component)}/#{uri_encode(vhost)}/#{uri_encode(name)}") do |req|
          req.headers['Content-Type'] = "application/json"
          req.body = MultiJson.dump(attributes)
        end
        decode_resource(response)
      end

      def clear_parameters_of(component, vhost, name)
        decode_resource(@connection.delete("/api/parameters/#{uri_encode(component)}/#{uri_encode(vhost)}/#{uri_encode(name)}"))
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
