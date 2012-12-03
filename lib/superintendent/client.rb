require "hashie"
require "faraday"
require "faraday_middleware"
require "multi_json"

# for URI encoding
require "cgi"

module Superintendent
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
      response = @connection.get("/api/overview")
      Hashie::Mash.new(response.body)
    end

    def list_nodes
      response = @connection.get("/api/nodes")
      response.body.map { |i| Hashie::Mash.new(i) }
    end

    def node_info(name)
      response = @connection.get("/api/nodes/#{uri_encode(name)}")
      Hashie::Mash.new(response.body)
    end

    def list_extensions
      response = @connection.get("/api/extensions")
      response.body.map { |i| Hashie::Mash.new(i) }
    end

    def list_definitions
      response = @connection.get("/api/definitions")
      response.body.map { |i| Hashie::Mash.new(i) }
    end

    def upload_definitions(defs)
      raise NotImplementedError.new
    end

    def list_connections
      response = @connection.get("/api/connections")
      response.body.map { |i| Hashie::Mash.new(i) }
    end

    def connection_info(name)
      response = @connection.get("/api/connections/#{uri_encode(name)}")
      Hashie::Mash.new(response.body)
    end

    def close_connection(name)
      response = @connection.delete("/api/connections/#{uri_encode(name)}")
      Hashie::Mash.new(response.body)
    end

    def list_channels
      response = @connection.get("/api/channels")
      response.body.map { |i| Hashie::Mash.new(i) }
    end

    def channel_info(name)
      response = @connection.get("/api/channels/#{uri_encode(name)}")
      Hashie::Mash.new(response.body)
    end

    def list_exchanges(vhost = nil)
      path = if vhost.nil?
               "/api/exchanges"
             else
               "/api/exchanges/#{uri_encode(vhost)}"
             end

      response = @connection.get(path)
      response.body.map { |i| Hashie::Mash.new(i) }
    end

    def exchange_info(vhost, name)
      response = @connection.get("/api/exchanges/#{uri_encode(vhost)}/#{uri_encode(name)}")
      Hashie::Mash.new(response.body)
    end

    def list_bindings_by_source(vhost, exchange)
      response = @connection.get("/api/exchanges/#{uri_encode(vhost)}/#{uri_encode(exchange)}/bindings/source")
      response.body.map { |i| Hashie::Mash.new(i) }
    end

    def list_bindings_by_destination(vhost, exchange)
      response = @connection.get("/api/exchanges/#{uri_encode(vhost)}/#{uri_encode(exchange)}/bindings/destination")
      response.body.map { |i| Hashie::Mash.new(i) }
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

  end # Client
end # Superintendent
