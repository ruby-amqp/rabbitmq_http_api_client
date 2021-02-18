require "hashie"
require "faraday"
require "faraday_middleware"
require "multi_json"
require "uri"

module RabbitMQ
  module HTTP
    class HealthChecks

      def initialize(client)
        @client = client
        @request_helper  = @client.request_helper
        @response_helper = @client.response_helper
      end

      def check_alarms
        health_check_for("health/checks/alarms")
      end

      def check_local_alarms
        health_check_for("health/checks/local-alarms")
      end

      def check_virtual_hosts
        health_check_for("health/checks/virtual-hosts")
      end

      def check_if_node_is_quorum_critical
        health_check_for("health/checks/node-is-quorum-critical")
      end

      def check_if_node_is_mirror_sync_critical
        health_check_for("health/checks/node-is-mirror-sync-critical")
      end

      def check_port_listener(port)
        health_check_for("health/checks/port-listener/#{encode_uri_path_segment(port)}")
      end

      def check_protocol_listener(proto)
        health_check_for("health/checks/protocol-listener/#{encode_uri_path_segment(proto)}")
      end

      TIME_UNITS = %w(days weeks months years)

      def check_certificate_expiration(within, unit)
        raise ArgumentError.new("supported time units are #{TIME_UNITS.join(', ')}, given: #{unit}") if !TIME_UNITS.include?(unit)
        raise ArgumentError.new("the number of time units must be a positive integer") if within <= 0

        health_check_for("health/checks/certificate-expiration/#{@request_helper.encode_uri_path_segment(within)}/#{@request_helper.encode_uri_path_segment(unit)}")
      end


      def health_check_for(path)
        begin
            _ = @response_helper.decode_resource(@client.connection.get(path))
            [true, nil]
          rescue Faraday::ServerError => se
            # health check endpoints respond with a 503 if the server fails
            if se.response_status == 503
              [false, @response_helper.decode_response_body(se.response[:body])]
            else
              raise se
            end
        end
      end
    end
  end
end
