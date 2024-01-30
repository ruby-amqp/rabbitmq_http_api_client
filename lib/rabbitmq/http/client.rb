require "addressable/uri"
require "hashie"
require "faraday"
require "faraday/follow_redirects"
require "multi_json"
require "uri"

require_relative "client/request_helper"
require_relative "client/response_helper"
require_relative "client/health_checks"

module RabbitMQ
  module HTTP
    class Client

      #
      # API
      #

      attr_reader :endpoint, :health
      attr_reader :connection, :request_helper, :response_helper

      def self.connect(endpoint, options = {})
        new(endpoint, options)
      end

      def initialize(endpoint, options = {})
        @endpoint = endpoint
        @options  = options

        @request_helper = RequestHelper.new()
        @response_helper = ResponseHelper.new(self)
        @health = HealthChecks.new(self)

        initialize_connection(endpoint, options)
      end

      def overview
        decode_resource(@connection.get("overview"))
      end

      # Returns a list of messaging protocols supported by
      # the node (or cluster).
      #
      # Common values are:
      #
      # * amqp
      # * amqp/ssl
      # * mqtt
      # * stomp
      #
      # The exact value depends on RabbitMQ configuration and enabled
      # plugins.
      #
      # @return [Array<String>] Enabled protocols
      def enabled_protocols
        self.overview.listeners.
          map { |lnr| lnr.protocol }.
          uniq
      end

      # Returns a hash of protocol => port.
      #
      # @return [Hash<String, Integer>] Hash of protocol => port
      def protocol_ports
        (self.overview.listeners || []).
          reduce(Hash.new) { |acc, lnr| acc[lnr.protocol] = lnr.port; acc }
      end

      def list_nodes(query = {})
        decode_resource_collection(@connection.get("nodes", query))
      end

      def node_info(name)
        decode_resource(@connection.get("nodes/#{encode_uri_path_segment(name)}"))
      end

      def list_extensions(query = {})
        decode_resource_collection(@connection.get("extensions", query))
      end

      def list_definitions
        decode_resource(@connection.get("definitions"))
      end

      def upload_definitions(defs)
        response = @connection.post("definitions") do |req|
          req.headers['Content-Type'] = "application/json"
          req.body = defs
        end
        response.success?
      end

      def list_connections(query = {})
        decode_resource_collection(@connection.get("connections", query))
      end

      def connection_info(name)
        decode_resource(@connection.get("connections/#{encode_uri_path_segment(name)}"))
      end

      def close_connection(name)
        decode_resource(@connection.delete("connections/#{encode_uri_path_segment(name)}"))
      end

      def list_channels(query = {})
        decode_resource_collection(@connection.get("channels", query))
      end

      def channel_info(name)
        decode_resource(@connection.get("channels/#{encode_uri_path_segment(name)}"))
      end

      def list_exchanges(vhost = nil, query = {})
        path = if vhost.nil?
                 "exchanges"
               else
                 "exchanges/#{encode_uri_path_segment(vhost)}"
               end

        decode_resource_collection(@connection.get(path, query))
      end

      def declare_exchange(vhost, name, attributes = {})
        opts = {
          type: "direct",
          auto_delete: false,
          durable: true,
          arguments: {}
        }.merge(attributes)

        response = @connection.put("exchanges/#{encode_uri_path_segment(vhost)}/#{encode_uri_path_segment(name)}") do |req|
          req.headers['Content-Type'] = 'application/json'
          req.body = MultiJson.dump(opts)
        end
        decode_resource(response)
      end

      def delete_exchange(vhost, name, if_unused = false)
        response = @connection.delete("exchanges/#{encode_uri_path_segment(vhost)}/#{encode_uri_path_segment(name)}") do |req|
          req.params["if-unused"] = true if if_unused
        end
        decode_resource(response)
      end

      def exchange_info(vhost, name)
        decode_resource(@connection.get("exchanges/#{encode_uri_path_segment(vhost)}/#{encode_uri_path_segment(name)}"))
      end

      def list_bindings_by_source(vhost, exchange, query = {})
        decode_resource_collection(@connection.get("exchanges/#{encode_uri_path_segment(vhost)}/#{encode_uri_path_segment(exchange)}/bindings/source", query))
      end

      def list_bindings_by_destination(vhost, exchange, query = {})
        decode_resource_collection(@connection.get("exchanges/#{encode_uri_path_segment(vhost)}/#{encode_uri_path_segment(exchange)}/bindings/destination", query))
      end

      def list_queues(vhost = nil, query = {})
        path = if vhost.nil?
                 "queues"
               else
                 "queues/#{encode_uri_path_segment(vhost)}"
               end

        decode_resource_collection(@connection.get(path, query))
      end

      def queue_info(vhost, name)
        decode_resource(@connection.get("queues/#{encode_uri_path_segment(vhost)}/#{encode_uri_path_segment(name)}"))
      end

      def declare_queue(vhost, name, attributes)
        response = @connection.put("queues/#{encode_uri_path_segment(vhost)}/#{encode_uri_path_segment(name)}") do |req|
          req.headers['Content-Type'] = "application/json"
          req.body = MultiJson.dump(attributes)
        end
        decode_resource(response)
      end

      def delete_queue(vhost, name, if_unused = false, if_empty = false)
        response = @connection.delete("queues/#{encode_uri_path_segment(vhost)}/#{encode_uri_path_segment(name)}") do |req|
          req.params["if-unused"] = true if if_unused
          req.params["if-empty"] = true if if_empty
        end
        decode_resource(response)
      end

      def list_queue_bindings(vhost, queue, query = {})
        decode_resource_collection(@connection.get("queues/#{encode_uri_path_segment(vhost)}/#{encode_uri_path_segment(queue)}/bindings", query))
      end

      def purge_queue(vhost, name)
        @connection.delete("queues/#{encode_uri_path_segment(vhost)}/#{encode_uri_path_segment(name)}/contents")
        Hashie::Mash.new
      end

      def get_messages(vhost, name, options)
        response = @connection.post("queues/#{encode_uri_path_segment(vhost)}/#{encode_uri_path_segment(name)}/get") do |req|
          req.headers['Content-Type'] = "application/json"
          req.body = MultiJson.dump(options)
        end
        decode_resource_collection(response)
      end

      def list_bindings(vhost = nil, query = {})
        path = if vhost.nil?
                 "bindings"
               else
                 "bindings/#{encode_uri_path_segment(vhost)}"
               end

        decode_resource_collection(@connection.get(path, query))
      end

      def list_bindings_between_queue_and_exchange(vhost, queue, exchange, query = {})
        decode_resource_collection(@connection.get("bindings/#{encode_uri_path_segment(vhost)}/e/#{encode_uri_path_segment(exchange)}/q/#{encode_uri_path_segment(queue)}", query))
      end

      def queue_binding_info(vhost, queue, exchange, properties_key)
        decode_resource(@connection.get("bindings/#{encode_uri_path_segment(vhost)}/e/#{encode_uri_path_segment(exchange)}/q/#{encode_uri_path_segment(queue)}/#{encode_uri_path_segment(properties_key)}"))
      end

      def bind_queue(vhost, queue, exchange, routing_key, arguments = [])
        resp = @connection.post("bindings/#{encode_uri_path_segment(vhost)}/e/#{encode_uri_path_segment(exchange)}/q/#{encode_uri_path_segment(queue)}") do |req|
          req.headers['Content-Type'] = 'application/json'
          req.body = MultiJson.dump({:routing_key => routing_key, :arguments => arguments})
        end
        resp.headers['location']
      end

      def delete_queue_binding(vhost, queue, exchange, properties_key)
        resp = @connection.delete("bindings/#{encode_uri_path_segment(vhost)}/e/#{encode_uri_path_segment(exchange)}/q/#{encode_uri_path_segment(queue)}/#{encode_uri_path_segment(properties_key)}")
        resp.success?
      end

      def list_bindings_between_exchanges(vhost, destination_exchange, source_exchange, query = {})
        decode_resource_collection(@connection.get("bindings/#{encode_uri_path_segment(vhost)}/e/#{encode_uri_path_segment(source_exchange)}/e/#{encode_uri_path_segment(destination_exchange)}", query))
      end

      def exchange_binding_info(vhost, destination_exchange, source_exchange, properties_key)
        decode_resource(@connection.get("bindings/#{encode_uri_path_segment(vhost)}/e/#{encode_uri_path_segment(source_exchange)}/e/#{encode_uri_path_segment(destination_exchange)}/#{encode_uri_path_segment(properties_key)}"))
      end


      def bind_exchange(vhost, destination_exchange, source_exchange, routing_key, arguments = [])
        resp = @connection.post("bindings/#{encode_uri_path_segment(vhost)}/e/#{encode_uri_path_segment(source_exchange)}/e/#{encode_uri_path_segment(destination_exchange)}") do |req|
          req.headers['Content-Type'] = 'application/json'
          req.body = MultiJson.dump({:routing_key => routing_key, :arguments => arguments})
        end
        resp.headers['location']
      end

      def delete_exchange_binding(vhost, destination_exchange, source_exchange, properties_key)
        resp = @connection.delete("bindings/#{encode_uri_path_segment(vhost)}/e/#{encode_uri_path_segment(source_exchange)}/e/#{encode_uri_path_segment(destination_exchange)}/#{encode_uri_path_segment(properties_key)}")
        resp.success?
      end


      def list_vhosts(query = {})
        decode_resource_collection(@connection.get("vhosts", query))
      end

      def vhost_info(name)
        decode_resource(@connection.get("vhosts/#{encode_uri_path_segment(name)}"))
      end

      def create_vhost(name)
        response = @connection.put("vhosts/#{encode_uri_path_segment(name)}") do |req|
          req.headers['Content-Type'] = "application/json"
        end
        decode_resource(response)
      end

      def delete_vhost(name)
        decode_resource(@connection.delete("vhosts/#{encode_uri_path_segment(name)}"))
      end



      def list_permissions(vhost = nil, query = {})
        path = if vhost
                 "vhosts/#{encode_uri_path_segment(vhost)}/permissions"
               else
                 "permissions"
               end

        decode_resource_collection(@connection.get(path, query))
      end

      def list_permissions_of(vhost, user)
        decode_resource(@connection.get("permissions/#{encode_uri_path_segment(vhost)}/#{encode_uri_path_segment(user)}"))
      end

      def update_permissions_of(vhost, user, attributes)
        response = @connection.put("permissions/#{encode_uri_path_segment(vhost)}/#{encode_uri_path_segment(user)}") do |req|
          req.headers['Content-Type'] = "application/json"
          req.body = MultiJson.dump(attributes)
        end
        decode_resource(response)
      end

      def clear_permissions_of(vhost, user)
        decode_resource(@connection.delete("permissions/#{encode_uri_path_segment(vhost)}/#{encode_uri_path_segment(user)}"))
      end

      def list_topic_permissions(vhost = nil, query = {})
        path = if vhost
                 "vhosts/#{encode_uri_path_segment(vhost)}/topic-permissions"
                else
                  "topic-permissions"
                end

        decode_resource_collection(@connection.get(path, query))
      end

      def list_topic_permissions_of(vhost, user)
        path = "topic-permissions/#{encode_uri_path_segment(vhost)}/#{encode_uri_path_segment(user)}"
        decode_resource_collection(@connection.get(path))
      end

      def update_topic_permissions_of(vhost, user, attributes)
        response = @connection.put("topic-permissions/#{encode_uri_path_segment(vhost)}/#{encode_uri_path_segment(user)}") do |req|
          req.headers['Content-Type'] = "application/json"
          req.body = MultiJson.dump(attributes)
        end

        nil
      end

      def delete_topic_permissions_of(vhost, user)
        decode_resource(@connection.delete("topic-permissions/#{encode_uri_path_segment(vhost)}/#{encode_uri_path_segment(user)}"))
      end

      def list_users(query = {})
        results = decode_resource_collection(@connection.get("users", query))

        # HTTP API will return tags as an array starting with RabbitMQ 3.9
        results.map do |u|
          u.tags = u.tags.split(",") if u.tags.is_a?(String)
          u
        end
      end

      def user_info(name)
        result = decode_resource(@connection.get("users/#{encode_uri_path_segment(name)}"))

        # HTTP API will return tags as an array starting with RabbitMQ 3.9
        result.tags = result.tags.split(",") if result.tags.is_a?(String)

        result
      end

      def update_user(name, attributes)
        attributes[:tags] ||= ""

        response = @connection.put("users/#{encode_uri_path_segment(name)}") do |req|
          req.headers['Content-Type'] = "application/json"
          req.body = MultiJson.dump(attributes)
        end
        decode_resource(response)
      end
      alias create_user update_user

      def delete_user(name)
        decode_resource(@connection.delete("users/#{encode_uri_path_segment(name)}"))
      end

      def user_permissions(name, query = {})
        decode_resource_collection(@connection.get("users/#{encode_uri_path_segment(name)}/permissions", query))
      end

      def whoami
        decode_resource(@connection.get("whoami"))
      end



      def list_policies(vhost = nil, query = {})
        path = if vhost
                 "policies/#{encode_uri_path_segment(vhost)}"
               else
                 "policies"
               end

        decode_resource_collection(@connection.get(path, query))
      end

      def list_policies_of(vhost, name = nil, query = {})
        path = if name
                 "policies/#{encode_uri_path_segment(vhost)}/#{encode_uri_path_segment(name)}"
               else
                 "policies/#{encode_uri_path_segment(vhost)}"
               end
        decode_resource_collection(@connection.get(path, query))
      end

      def update_policies_of(vhost, name, attributes)
        response = @connection.put("policies/#{encode_uri_path_segment(vhost)}/#{encode_uri_path_segment(name)}") do |req|
          req.headers['Content-Type'] = "application/json"
          req.body = MultiJson.dump(attributes)
        end
        decode_resource(response)
      end

      def clear_policies_of(vhost, name)
        decode_resource(@connection.delete("policies/#{encode_uri_path_segment(vhost)}/#{encode_uri_path_segment(name)}"))
      end




      def list_parameters(component = nil, query = {})
        path = if component
                 "parameters/#{encode_uri_path_segment(component)}"
               else
                 "parameters"
               end
        decode_resource_collection(@connection.get(path, query))
      end

      def list_parameters_of(component, vhost, name = nil, query = {})
        path = if name
                 "parameters/#{encode_uri_path_segment(component)}/#{encode_uri_path_segment(vhost)}/#{encode_uri_path_segment(name)}"
               else
                 "parameters/#{encode_uri_path_segment(component)}/#{encode_uri_path_segment(vhost)}"
               end
        decode_resource_collection(@connection.get(path, query))
      end

      def update_parameters_of(component, vhost, name, attributes)
        response = @connection.put("parameters/#{encode_uri_path_segment(component)}/#{encode_uri_path_segment(vhost)}/#{encode_uri_path_segment(name)}") do |req|
          req.headers['Content-Type'] = "application/json"
          req.body = MultiJson.dump(attributes)
        end
        decode_resource(response)
      end

      def clear_parameters_of(component, vhost, name)
        decode_resource(@connection.delete("parameters/#{encode_uri_path_segment(component)}/#{encode_uri_path_segment(vhost)}/#{encode_uri_path_segment(name)}"))
      end

      protected

      def initialize_connection(endpoint, options = {})
        uri     = URI.parse(endpoint)
        uri.path = "/api" if ["","/"].include?(uri.path)
        user     = uri.user     || options.delete(:username) || "guest"
        password = uri.password || options.delete(:password) || "guest"
        options = options.merge(:url => uri.to_s)
        adapter = options.delete(:adapter) || Faraday.default_adapter

        @connection = Faraday.new(options) do |conn|
          if Gem::Version.new(Faraday::VERSION) < Gem::Version.new("2.0")
            conn.request :basic_auth, user, password
          else
            conn.request :authorization, :basic, user, password
          end

          conn.use        Faraday::FollowRedirects::Middleware, :limit => 3
          conn.use        Faraday::Response::RaiseError
          conn.response   :json, :content_type => /\bjson$/

          conn.adapter    adapter
        end
      end

      def encode_uri_path_segment(segment)
        @request_helper.encode_uri_path_segment(segment)
      end

      def decode_resource(response)
        @response_helper.decode_resource(response)
      end

      def decode_response_body(body)
        @response_helper.decode_response_body(body)
      end

      def decode_resource_collection(response)
        @response_helper.decode_resource_collection(response)
      end
    end # Client
  end # HTTP
end # RabbitMQ
