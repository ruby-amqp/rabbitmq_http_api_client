# -*- coding: utf-8 -*-
require "spec_helper"

describe RabbitMQ::HTTP::Client do
  let(:endpoint) { "http://127.0.0.1:15672" }

  subject do
    described_class.connect(endpoint, :username => "guest", :password => "guest")
  end

  before :all do
    @connection = Bunny.new
    @connection.start
  end

  after :all do
    @connection.close
  end


  #
  # URI-only access
  #

  describe "URI-only access" do
    it "authenticates successfully" do
      c = described_class.connect("http://guest:guest@127.0.0.1:15672")

      r = c.overview
      r.rabbitmq_version.should_not be_nil
      r.erlang_version.should_not be_nil
    end
  end


  #
  # Overview
  #

  describe "GET /api/overview" do
    it "returns an overview" do
      r = subject.overview

      ts = r.exchange_types.map { |h| h.name }.
        sort
      ["direct", "fanout", "headers", "topic"].each do |t|
        ts.should include(t)
      end

      r.rabbitmq_version.should_not be_nil
      r.erlang_version.should_not be_nil
    end
  end

  describe "#enabled_protocols" do
    it "returns a list of enabled protocols" do
      xs = subject.enabled_protocols

      xs.should include("amqp")
    end
  end

  describe "#enabled_protocols" do
    it "returns a list of enabled protocols" do
      xs = subject.protocol_ports

      # hash of protocol => port
      xs["amqp"].should == 5672
    end
  end

  #
  # Nodes
  #

  describe "GET /api/nodes" do
    it "lists cluster nodes with detailed status information for each one of them" do
      nodes  = subject.list_nodes
      n      = nodes.first

      rabbit = n.applications.detect { |app| app.name == "rabbit" }
      rabbit.description.should == "RabbitMQ"

      n.name.should =~ /^rabbit/
      n.partitions.should == []
      n.fd_used.should_not be_nil
      n.fd_total.should_not be_nil
      n.sockets_used.should_not be_nil
      n.sockets_total.should_not be_nil
      n.mem_used.should_not be_nil
      n.mem_limit.should_not be_nil
      n.disk_free_limit.should_not be_nil
      n.disk_free.should_not be_nil
      n.proc_used.should_not be_nil
      n.proc_total.should_not be_nil
      n.run_queue.should_not be_nil
    end
  end

  describe "GET /api/node/:name" do
    it "returns status information for a single cluster node" do
      ns = subject.list_nodes
      n  = subject.node_info(ns.first.name)

      rabbit = n.applications.detect { |app| app.name == "rabbit" }
      rabbit.description.should == "RabbitMQ"

      n.name.should =~ /^rabbit/
      n.partitions.should == []
      n.fd_used.should_not be_nil
      n.fd_total.should_not be_nil
      n.sockets_used.should_not be_nil
      n.sockets_total.should_not be_nil
      n.mem_used.should_not be_nil
      n.mem_limit.should_not be_nil
      n.disk_free_limit.should_not be_nil
      n.disk_free.should_not be_nil
      n.proc_used.should_not be_nil
      n.proc_total.should_not be_nil
      n.run_queue.should_not be_nil
      n.running.should be_true
    end
  end

  #
  # Extensions
  #

  describe "GET /api/extensions" do
    it "returns a list of enabled management plugin extensions" do
      xs = subject.list_extensions
      f  = xs.first

      ["dispatcher.js", "shovel.js"].should include(f.javascript)
    end
  end

  #
  # Definitions
  #

  describe "GET /api/definitions" do
    it "returns a list of all resources/definitions (vhosts, users, permissions, queues, exchanges, bindings, etc)" do
      xs = subject.list_definitions

      xs.bindings.should be_instance_of(Array)
      xs.queues.should be_instance_of(Array)
      xs.exchanges.should be_instance_of(Array)
      xs.users.should be_instance_of(Array)
      xs.vhosts.should be_instance_of(Array)
    end
  end

  describe "POST /api/definitions" do
    it "uploads definitions to RabbitMQ"
  end

  #
  # Connections
  #

  describe "GET /api/connections" do
    before :all do
      @connection = Bunny.new
      @connection.start
    end

    it "returns a list of all active connections" do
      xs = subject.list_connections
      f  = xs.first

      f.name.should =~ /127.0.0.1/
      f.client_properties.product.should == "Bunny"
    end
  end

  describe "GET /api/connections/:name" do
    it "returns information about the connection" do
      xs = subject.list_connections
      c  = subject.connection_info(xs.first.name)

      c.name.should =~ /127.0.0.1/
      c.client_properties.product.should == "Bunny"
    end
  end

  describe "DELETE /api/connections/:name" do
    it "closes the connection" do
      pending "Needs investigation, DELETE does not seem to close the connection"
      xs = subject.list_connections
      c  = subject.close_connection(xs.first.name)

      c.name.should =~ /127.0.0.1/
      c.client_properties.product.should == "Bunny"

      @connection.should_not be_open
    end
  end


  #
  # Channels
  #

  describe "GET /api/channels" do
    before :all do
      @channel    = @connection.create_channel
    end

    it "returns a list of all active channels" do
      xs = subject.list_channels
      f  = xs.first

      f.number.should be >= 1
      f.prefetch_count.should be >= 0
    end
  end

  describe "GET /api/channels/:name" do
    before :all do
      @channel    = @connection.create_channel
    end

    it "returns information about the channel" do
      xs = subject.list_channels
      c  = subject.channel_info(xs.first.name)

      c.number.should be >= 1
      c.prefetch_count.should be >= 0
    end
  end

  #
  # Exchanges
  #

  describe "GET /api/exchanges" do
    it "returns a list of all exchanges in the cluster" do
      xs = subject.list_exchanges
      f  = xs.first

      f.type.should_not be_nil
      f.name.should_not be_nil
      f.vhost.should_not be_nil
      f.durable.should_not be_nil
      f.auto_delete.should_not be_nil
    end
  end

  describe "GET /api/exchanges/:vhost" do
    it "returns a list of all exchanges in a vhost" do
      xs = subject.list_exchanges("/")
      f  = xs.first

      f.vhost.should == "/"
    end
  end

  describe "GET /api/exchanges/:vhost/:name" do
    it "returns information about the exchange" do
      e = subject.exchange_info("/", "amq.fanout")

      e.type.should == "fanout"
      e.name.should == "amq.fanout"
      e.durable.should be_true
      e.vhost.should == "/"
      e.internal.should be_false
      e.auto_delete.should be_false
    end
  end

  describe "PUT /api/exchanges/:vhost/:name" do
    before :all do
      @channel    = @connection.create_channel
    end

    after :all do
      @channel.close
    end

    let(:exchange_name) { "httpdeclared" }

    it "declares an exchange" do
      subject.declare_exchange("/", exchange_name, :durable => false, :type => "fanout")

      x = @channel.fanout(exchange_name, :durable => false, :auto_delete => false)
      x.delete
    end
  end

  describe "DELETE /api/exchanges/:vhost/:name" do
    before :all do
      @channel    = @connection.create_channel
    end

    after :all do
      @channel.close
    end

    let(:exchange_name) { "httpdeclared" }

    it "deletes an exchange" do
      x = @channel.fanout(exchange_name, :durable => false)
      subject.delete_exchange("/", exchange_name)
    end
  end


  describe "GET /api/exchanges/:vhost/:name/bindings/source" do
    before :all do
      @channel    = @connection.create_channel
    end

    after :all do
      @channel.close
    end

    it "returns a list of all bindings in which the given exchange is the source" do
      e  = @channel.fanout("http.api.tests.fanout", :durable => true)
      q  = @channel.queue("http.api.tests.queue1",  :durable => true)
      q.bind(e)

      xs = subject.list_bindings_by_source("/", "http.api.tests.fanout")
      f  = xs.first

      f.destination.should == q.name
      f.destination_type.should == "queue"
      f.routing_key.should == ""
      f.source.should == e.name
      f.vhost.should == "/"

      e.delete
      q.delete
    end
  end


  describe "GET /api/exchanges/:vhost/:name/bindings/destination" do
    before :all do
      @channel    = @connection.create_channel
    end

    it "returns a list of all bindings in which the given exchange is the source" do
      e1  = @channel.fanout("http.api.tests.fanout1", :durable => true)
      e2  = @channel.fanout("http.api.tests.fanout2", :durable => true)
      e1.bind(e2)

      xs = subject.list_bindings_by_destination("/", "http.api.tests.fanout1")
      f  = xs.first

      f.destination.should == e1.name
      f.destination_type.should == "exchange"
      f.routing_key.should == ""
      f.source.should == e2.name
      f.vhost.should == "/"

      e1.delete
      e2.delete
    end
  end



  describe "POST /api/exchanges/:vhost/:name/publish" do
    it "publishes a messages to the exchange"
  end


  #
  # Queues
  #

  describe "GET /api/queues" do
    before :all do
      @channel    = @connection.create_channel
    end

    it "returns a list of all queues" do
      q  = @channel.queue("", :exclusive => true)

      xs = subject.list_queues
      xs.detect { |x| x.name == q.name }.should_not be_empty
    end
  end

  describe "GET /api/queues/:vhost" do
    before :all do
      @channel    = @connection.create_channel
    end

    it "returns a list of all queues" do
      q  = @channel.queue("", :exclusive => true)

      xs = subject.list_queues("/")
      xs.detect { |x| x.name == q.name }.should_not be_empty
    end
  end

  describe "GET /api/queues/:vhost/:name" do
    context "when queue exists" do
      before :all do
        @channel    = @connection.create_channel
      end

      it "returns information about a queue" do
        q  = @channel.queue("", :exclusive => true, :durable => false)
        i  = subject.queue_info("/", q.name)

        i.durable.should be_false
        i.durable.should == q.durable?

        i.name.should == q.name
        i.auto_delete.should == q.auto_delete?
        i.active_consumers.should be_nil
        i.backing_queue_status.avg_ack_egress_rate.should == 0.0
      end
    end

    context "when queue DOES NOT exist" do
      it "raises NotFound" do
        lambda do
          subject.queue_info("/", Time.now.to_i.to_s)
        end.should raise_error(Faraday::Error::ResourceNotFound)
      end
    end
  end

  describe "PUT /api/queues/:vhost/:name" do
    before :all do
      @channel    = @connection.create_channel
    end

    let(:queue_name) { "httpdeclared" }

    it "declares a queue" do
      subject.declare_queue("/", queue_name, :durable => false, :auto_delete => true)

      q = @channel.queue(queue_name, :durable => false, :auto_delete => true)
      q.delete
    end
  end

  describe "DELETE /api/queues/:vhost/:name" do
    before :all do
      @channel    = @connection.create_channel
    end

    let(:queue_name) { "httpdeclared" }

    it "deletes a queue" do
      q = @channel.queue(queue_name, :durable => false)
      subject.delete_queue("/", queue_name)
    end
  end

  describe "GET /api/queues/:vhost/:name/bindings" do
    before :all do
      @channel    = @connection.create_channel
    end

    it "returns a list of bindings for a queue" do
      q  = @channel.queue("")
      q.bind("amq.fanout")

      xs = subject.list_queue_bindings("/", q.name)
      x  = xs.first

      x.destination.should == q.name
      x.destination_type.should == "queue"
    end
  end

  describe "DELETE /api/queues/:vhost/:name/contents" do
    before :all do
      @channel    = @connection.create_channel
    end

    it "purges a queue" do
      q   = @channel.queue("")
      x   = @channel.fanout("amq.fanout", :durable => true, :auto_delete => false)
      q.bind(x)

      10.times do
        x.publish("", :routing_key => q.name)
      end
      sleep 0.7

      q.message_count.should == 10
      subject.purge_queue("/", q.name)
      sleep 0.5
      q.message_count.should == 0
      q.delete
    end
  end

  # yes, POST, because it potentially modifies the state (ordering) of the queue
  describe "POST /api/queues/:vhost/:name/get" do
    before :all do
      @channel    = @connection.create_channel
    end

    it "fetches a message from a queue, a la basic.get" do
      q   = @channel.queue("")
      x   = @channel.fanout("amq.fanout", :durable => true, :auto_delete => false)
      q.bind(x)

      10.times do |i|
        x.publish("msg #{i}", :routing_key => q.name, :content_type => "application/xyz")
      end
      sleep 0.7

      q.message_count.should == 10
      xs = subject.get_messages("/", q.name, :count => 10, :requeue => false, :encoding => "auto")
      m  = xs.first

      m.properties.content_type.should == "application/xyz"
      m.payload.should == "msg 0"
      m.payload_encoding.should == "string"

      q.delete
    end
  end

  describe "GET /api/bindings" do
    it "returns a list of all bindings" do
      xs = subject.list_bindings
      b  = xs.first

      b.destination.should_not be_nil
      b.destination_type.should_not be_nil
      b.source.should_not be_nil
      b.routing_key.should_not be_nil
      b.vhost.should_not be_nil
    end
  end

  describe "GET /api/bindings/:vhost" do
    it "returns a list of all bindings in a vhost" do
      xs = subject.list_bindings("/")
      b  = xs.first

      b.destination.should_not be_nil
      b.destination_type.should_not be_nil
      b.source.should_not be_nil
      b.routing_key.should_not be_nil
      b.vhost.should_not be_nil
    end
  end

  describe "GET /api/bindings/:vhost/e/:exchange/q/:queue" do
    before :all do
      @channel    = @connection.create_channel
    end

    it "returns a list of all bindings between an exchange and a queue" do
      q = @channel.queue("")
      x = @channel.fanout("http.client.fanout")
      q.bind(x)

      xs = subject.list_bindings_between_queue_and_exchange("/", q.name, x.name)
      b  = xs.first
      b.destination.should == q.name
      b.destination_type.should == "queue"
      b.source.should == x.name
      b.routing_key.should_not be_nil
      b.properties_key.should_not be_nil
      b.vhost.should == "/"

      q.delete
      x.delete
    end
  end

  describe "POST /api/bindings/:vhost/e/:exchange/q/:queue" do
    before :all do
      @channel    = @connection.create_channel
    end

    it "creates a binding between an exchange and a queue" do
      routing_key = 'test.key'
      q = @channel.queue("")
      x = @channel.fanout("http.client.fanout")
      q.bind(x)

      b = subject.bind_queue("/", q.name, x.name, routing_key)

      b.should == q.name + "/" + routing_key

      q.delete
      x.delete
    end
  end

  describe "GET /api/bindings/:vhost/e/:exchange/q/:queue/props" do
    before :all do
      @channel    = @connection.create_channel
    end

    it "returns an individual binding between an exchange and a queue" do
      routing_key = 'test.key'
      q = @channel.queue("")
      x = @channel.fanout("http.client.fanout")
      q.bind(x)

      xs = subject.list_bindings_between_queue_and_exchange("/", q.name, x.name)
      b1 = xs.first

      b2 = subject.queue_binding_info("/", q.name, x.name, b1.properties_key)

      b1.should == b2

    end
  end

  describe "DELETE /api/bindings/:vhost/e/:exchange/q/:queue/props" do
    before :all do
      @channel    = @connection.create_channel
    end

    it "deletes an individual binding between an exchange and a queue" do
      routing_key = 'test.key'
      q = @channel.queue("")
      x = @channel.fanout("http.client.fanout")
      q.bind(x)

      xs = subject.list_bindings_between_queue_and_exchange("/", q.name, x.name)
      b  = xs.first

      subject.delete_queue_binding("/", q.name, x.name, b.properties_key).should be_true

      xs = subject.list_bindings_between_queue_and_exchange("/", q.name, x.name)

      xs.size.should == 0

      q.delete
      x.delete
    end
  end

  describe "GET /api/vhosts" do
    it "returns a list of vhosts" do
      xs = subject.list_vhosts
      v  = xs.first

      v.name.should_not be_nil
      v.tracing.should be_false
    end
  end

  describe "GET /api/vhosts/:name" do
    context "when vhost exists" do
      it "returns infomation about a vhost" do
        v = subject.vhost_info("/")

        v.name.should_not be_nil
        v.tracing.should be_false
      end
    end

    context "when vhost DOES NOT exist" do
      it "raises NotFound" do
        lambda do
          subject.vhost_info(Time.now.to_i.to_s)
        end.should raise_error(Faraday::Error::ResourceNotFound)
      end
    end

  end

  describe "PUT /api/vhosts/:name" do
    gen = Rantly.new

    [
      "http-created",
      "http_created",
      "http created",
      "создан по хатэтэпэ",
      "creado a través de HTTP",
      "通过http",
      "HTTP를 통해 생성",
      "HTTPを介して作成",
      "created over http?",
      "created @ http API",
      "erstellt über http",
      "http पर बनाया",
      "ถูกสร้างขึ้นผ่าน HTTP",
      "±!@^&#*"
    ].each do |vhost|
      context "when vhost name is #{vhost}" do
        it "creates a vhost" do
          subject.create_vhost(vhost)
          subject.create_vhost(vhost)

          v = subject.vhost_info(vhost)
          v.name.should == vhost

          subject.delete_vhost(v.name)
        end
      end
    end

    1000.times do
      vhost = gen.string

      context "when vhost name is #{vhost}" do
        it "creates a vhost" do
          subject.create_vhost(vhost)
          subject.create_vhost(vhost)

          v = subject.vhost_info(vhost)
          v.name.should == vhost

          subject.delete_vhost(v.name)
        end
      end
    end
  end

  describe "DELETE /api/vhosts/:name" do
    let(:vhost) { "http-created2" }

    it "deletes a vhost" do
      subject.create_vhost(vhost)
      subject.delete_vhost(vhost)
    end
  end

  describe "GET /api/vhosts/:name/permissions" do
    it "returns a list of permissions in a vhost" do
      xs = subject.list_permissions("/")
      p  = xs.detect { |x| x.user == "guest" }

      p.read.should == ".*"
    end
  end

  describe "GET /api/users" do
    it "returns a list of all users" do
      xs = subject.list_users
      u  = xs.first

      u.name.should_not be_nil
      u.password_hash.should_not be_nil
      u.tags.should_not be_nil
    end
  end

  describe "GET /api/users/:name" do
    it "returns information about a user" do
      u = subject.user_info("guest")
      u.name.should == "guest"
      u.tags.should == "administrator"
    end
  end

  describe "PUT /api/users/:name" do
    it "updates information about a user" do
      subject.update_user("alt", :tags => "http, policymaker, management", :password => "alt")

      u = subject.user_info("alt")
      u.tags.should == "http,policymaker,management"
    end
  end

  describe "DELETE /api/users/:name" do
    it "deletes a user" do
      subject.update_user("alt2", :tags => "http", :password => "alt")
      subject.delete_user("alt2")
    end
  end

  describe "GET /api/users/:name/permissions" do
    it "returns a list of permissions for a user" do
      xs = subject.user_permissions("guest")
      p  = xs.first

      p.read.should == ".*"
    end
  end

  describe "GET /api/whoami" do
    it "returns information about the current user" do
      u = subject.whoami
      u.name.should == "guest"
    end
  end

  describe "GET /api/permissions" do
    it "lists all permissions" do
      xs = subject.list_permissions
      xs.first.read.should_not be_nil
    end
  end

  describe "GET /api/permissions/:vhost/:user" do
    it "returns a list of permissions of a user in a vhost" do
      p = subject.list_permissions_of("/", "guest")

      p.read.should == ".*"
      p.write.should == ".*"
      p.configure.should == ".*"
    end
  end

  describe "PUT /api/permissions/:vhost/:user" do
    it "updates permissions of a user in a vhost" do
      subject.update_permissions_of("/", "guest", :write => ".*", :read => ".*", :configure => ".*")

      p = subject.list_permissions_of("/", "guest")

      p.read.should == ".*"
      p.write.should == ".*"
      p.configure.should == ".*"
    end
  end

  describe "DELETE /api/permissions/:vhost/:user" do
    it "clears permissions of a user in a vhost" do
      pending
      subject.create_user("/", "alt3")
      subject.update_permissions_of("/", "alt3", :write => ".*", :read => ".*", :configure => ".*")
      subject.clear_permissions_of("/", "alt3")

      p = subject.list_permissions_of("/", "alt3")

      puts p.inspect
    end
  end

  #
  # Parameters
  #

  describe "GET /api/parameters" do
    it "returns a list of all parameters" do
      xs = subject.list_parameters
      xs.should be_kind_of(Array)
    end
  end


  #
  # Policies
  #

  describe "GET /api/policies" do
    it "returns a list of all policies" do
      xs = subject.list_policies
      xs.should be_kind_of(Array)
    end
  end

  describe "GET /api/policies/:vhost" do
    it "returns a list of all policies in a vhost" do
      xs = subject.list_policies("/")
      xs.should be_kind_of(Array)
    end
  end


  #
  # Aliveness Test
  #

  describe "GET /api/aliveness-test/:vhost" do
    it "performs aliveness check" do
      r = subject.aliveness_test("/")

      r.should be_true
    end
  end
end
