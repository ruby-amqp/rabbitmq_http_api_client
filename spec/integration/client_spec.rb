# -*- coding: utf-8 -*-
require "spec_helper"

describe RabbitMQ::HTTP::Client do
  let(:endpoint) { "http://127.0.0.1:15672" }

  subject do
    described_class.connect(endpoint, :username => "guest", :password => "guest")
  end

  before :each do
    @conn = Bunny.new
    @conn.start
  end

  after :each do
    @conn.close
  end

  #
  # Default endpoint path
  #
  describe "default endpoint path" do
    it "does NOT append '/api' if the endpoint provides a path" do
      c = described_class.connect("http://guest:guest@127.0.0.1:15672/api")

      r = c.overview
      expect(r.rabbitmq_version).to_not be_nil
      expect(r.erlang_version).to_not be_nil
    end
  end


  #
  # URI-only access
  #

  describe "URI-only access" do
    it "authenticates successfully" do
      c = described_class.connect("http://guest:guest@127.0.0.1:15672")

      r = c.overview
      expect(r.rabbitmq_version).to_not be_nil
      expect(r.erlang_version).to_not be_nil
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
        expect(ts).to include(t)
      end

      expect(r.rabbitmq_version).to_not be_nil
      expect(r.erlang_version).to_not be_nil
    end
  end

  describe "#enabled_protocols" do
    it "returns a list of enabled protocols" do
      xs = subject.enabled_protocols

      expect(xs).to include("amqp")
    end
  end

  describe "#enabled_protocols" do
    it "returns a list of enabled protocols" do
      xs = subject.protocol_ports

      # hash of protocol => port
      expect(xs["amqp"]).to eq(5672)
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
      expect(rabbit.description).to eq("RabbitMQ")

      expect(n.name).to match(/^rabbit/)
    end
  end

  describe "GET /api/node/:name" do
    it "returns status information for a single cluster node" do
      ns = subject.list_nodes
      n  = subject.node_info(ns.first.name)

      rabbit = n.applications.detect { |app| app.name == "rabbit" }
      expect(rabbit.description).to eq("RabbitMQ")

      expect(n.name).to match(/^rabbit/)
    end
  end

  #
  # Extensions
  #

  describe "GET /api/extensions" do
    it "returns a list of enabled management plugin extensions" do
      xs = subject.list_extensions

      expect(xs).to be_kind_of(Array)
    end
  end

  #
  # Definitions
  #

  describe "GET /api/definitions" do
    it "returns a list of all resources/definitions (vhosts, users, permissions, queues, exchanges, bindings, etc)" do
      xs = subject.list_definitions

      expect(xs.bindings).to be_instance_of(Array)
      expect(xs.queues).to be_instance_of(Array)
      expect(xs.exchanges).to be_instance_of(Array)
      expect(xs.users).to be_instance_of(Array)
      expect(xs.vhosts).to be_instance_of(Array)
    end
  end

  describe "POST /api/definitions" do
    let(:definition) do
      {
        :queues => [{
          :name => 'my-definition-queue',
          :vhost => '/',
          :durable => true,
          :auto_delete =>  false,
          :arguments => {
             "x-dead-letter-exchange" => 'dead'
          }
        }]
      }.to_json
    end

    it "returns true when successful" do
      r = subject.upload_definitions(definition)
      expect(r).to eq(true)
    end

    it "stores the uploaded definitions" do
      subject.upload_definitions(definition)
      xs = subject.list_definitions
      uploaded_queue = xs.queues.detect { |q| q.name = 'my-definition-queue' }
      expect(uploaded_queue).not_to eq(nil)
    end
  end

  #
  # Connections
  #

  describe "GET /api/connections" do
    before :each do
      @conn = Bunny.new
      @conn.start
    end

    it "returns a list of all active connections" do
      xs = subject.list_connections
      f  = xs.first

      expect(f.name).to match(/127.0.0.1/)
      expect(f.client_properties.product).to eq("Bunny")
    end
  end

  describe "GET /api/connections/:name" do
    it "returns information about the connection" do
      xs = subject.list_connections
      c  = subject.connection_info(xs.first.name)

      expect(c.name).to match(/127.0.0.1/)
      expect(c.client_properties.product).to eq("Bunny")
    end
  end

  unless ENV["CI"]
    describe "DELETE /api/connections/:name" do
      it "closes the connection" do
        pending "Needs investigation, DELETE does not seem to close the connection"
        xs = subject.list_connections
        c  = subject.close_connection(xs.first.name)

        expect(c.name).to match(/127.0.0.1/)
        expect(c.client_properties.product).to eq("Bunny")

        expect(@conn).to_not be_open
      end
    end
  end


  #
  # Channels
  #

  describe "GET /api/channels" do
    it "returns a list of all active channels" do
      conn = Bunny.new; conn.start
      ch   = conn.create_channel
      xs   = subject.list_channels
      f    = xs.first

      expect(f.number).to be >= 1
      expect(f.prefetch_count).to be >= 0

      ch.close
      conn.close
    end
  end

  describe "GET /api/channels/:name" do
    it "returns information about the channel" do
      conn = Bunny.new; conn.start
      ch   = conn.create_channel

      xs   = subject.list_channels
      c    = subject.channel_info(xs.first.name)

      expect(c.number).to be >= 1
      expect(c.prefetch_count).to be >= 0

      ch.close
      conn.close
    end
  end

  #
  # Exchanges
  #

  describe "GET /api/exchanges" do
    it "returns a list of all exchanges in the cluster" do
      xs = subject.list_exchanges
      f  = xs.first

      expect(f.type).to_not be_nil
      expect(f.name).to_not be_nil
      expect(f.vhost).to_not be_nil
      expect(f.durable).to_not be_nil
      expect(f.auto_delete).to_not be_nil
    end
  end

  describe "GET /api/exchanges/:vhost" do
    it "returns a list of all exchanges in a vhost" do
      xs = subject.list_exchanges("/")
      f  = xs.first

      expect(f.vhost).to eq("/")
    end
  end

  describe "GET /api/exchanges/:vhost/:name" do
    it "returns information about the exchange" do
      e = subject.exchange_info("/", "amq.fanout")

      expect(e.type).to eq("fanout")
      expect(e.name).to eq("amq.fanout")
      expect(e.durable).to eq(true)
      expect(e.vhost).to eq("/")
    end
  end

  describe "PUT /api/exchanges/:vhost/:name" do
    before :each do
      @channel    = @conn.create_channel
    end

    after :each do
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
    before :each do
      @channel    = @conn.create_channel
    end

    after :each do
      @channel.close
    end

    let(:exchange_name) { "httpdeclared" }

    it "deletes an exchange" do
      x = @channel.fanout(exchange_name, :durable => false)
      subject.delete_exchange("/", exchange_name)
    end

    # HTTP client tries to uncompress an empty response :( MK
    xit "doesn't delete used exchange" do
      q = @channel.queue("")
      e = @channel.fanout(exchange_name, :durable => false)
      q.bind(e)
      expect do
        subject.delete_exchange("/", exchange_name, true)
      end.to raise_error(Faraday::ClientError)
    end
  end


  describe "GET /api/exchanges/:vhost/:name/bindings/source" do
    before :each do
      @channel    = @conn.create_channel
    end
    after :each do
      @channel.close
    end

    it "returns a list of all bindings in which the given exchange is the source" do
      e  = @channel.fanout("http.api.tests.fanout", :durable => true)
      q  = @channel.queue("http.api.tests.queue1",  :durable => true)
      q.bind(e)

      xs = subject.list_bindings_by_source("/", "http.api.tests.fanout")
      f  = xs.first

      expect(f.destination).to eq(q.name)
      expect(f.destination_type).to eq("queue")
      expect(f.routing_key).to eq("")
      expect(f.source).to eq(e.name)
      expect(f.vhost).to eq("/")

      e.delete
      q.delete
    end
  end


  describe "GET /api/exchanges/:vhost/:name/bindings/destination" do
    before :each do
      @channel    = @conn.create_channel
    end
    after :each do
      @channel.close
    end

    it "returns a list of all bindings in which the given exchange is the destination" do
      e1  = @channel.fanout("http.api.tests.fanout1", :durable => true)
      e2  = @channel.fanout("http.api.tests.fanout2", :durable => true)
      e1.bind(e2)

      xs = subject.list_bindings_by_destination("/", "http.api.tests.fanout1")
      f  = xs.first

      expect(f.destination).to eq(e1.name)
      expect(f.destination_type).to eq("exchange")
      expect(f.routing_key).to eq("")
      expect(f.source).to eq(e2.name)
      expect(f.vhost).to eq("/")

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
    before :each do
      @channel    = @conn.create_channel
    end
    after :each do
      @channel.close
    end

    it "returns a list of all queues" do
      q  = @channel.queue("", :exclusive => true)

      xs = subject.list_queues
      expect(xs.detect { |x| x.name == q.name }).to_not be_empty
    end
  end

  describe "GET /api/queues/:vhost" do
    before :each do
      @channel    = @conn.create_channel
    end
    after :each do
      @channel.close
    end

    it "returns a list of all queues" do
      q  = @channel.queue("", :exclusive => true)

      xs = subject.list_queues("/")
      expect(xs.detect { |x| x.name == q.name }).to_not be_empty
    end
  end

  describe "GET /api/queues/:vhost/:name" do
    context "when queue exists" do
      before :each do
        @channel    = @conn.create_channel
      end
      after :each do
        @channel.close
      end

      it "returns information about a queue" do
        q  = @channel.queue("", :exclusive => true, :durable => false)
        i  = subject.queue_info("/", q.name)

        expect(i.durable).to eq(false)
        expect(i.durable).to eq(q.durable?)

        expect(i.name).to eq(q.name)
        expect(i.auto_delete).to eq(q.auto_delete?)
        expect(i.active_consumers).to be_nil
        expect(i.backing_queue_status.avg_ack_egress_rate).to eq(0.0)
      end
    end

    context "when queue DOES NOT exist" do
      it "raises NotFound" do
        expect do
          subject.queue_info("/", Time.now.to_i.to_s)
        end.to raise_error(Faraday::Error::ResourceNotFound)
      end
    end
  end

  describe "PUT /api/queues/:vhost/:name" do
    before :each do
      @channel    = @conn.create_channel
    end

    let(:queue_name) { "httpdeclared" }

    it "declares a queue" do
      subject.declare_queue("/", queue_name, :durable => false, :auto_delete => true)

      q = @channel.queue(queue_name, :durable => false, :auto_delete => true)
      q.delete
    end
  end

  describe "DELETE /api/queues/:vhost/:name" do
    before :each do
      @channel    = @conn.create_channel
    end

    let(:queue_name) { "httpdeclared" }

    it "deletes a queue" do
      q = @channel.queue(queue_name, :durable => false)
      subject.delete_queue("/", queue_name)
    end
  end

  describe "GET /api/queues/:vhost/:name/bindings" do
    before :each do
      @channel    = @conn.create_channel
    end

    it "returns a list of bindings for a queue" do
      q  = @channel.queue("")
      q.bind("amq.fanout")

      xs = subject.list_queue_bindings("/", q.name)
      x  = xs.first

      expect(x.destination).to eq(q.name)
      expect(x.destination_type).to eq("queue")
    end
  end

  describe "DELETE /api/queues/:vhost/:name/contents" do
    before :each do
      @channel    = @conn.create_channel
    end
    after :each do
      @channel.close
    end

    it "purges a queue" do
      q   = @channel.queue("")
      x   = @channel.fanout("amq.fanout", :durable => true, :auto_delete => false)
      q.bind(x)

      10.times do
        x.publish("", :routing_key => q.name)
      end
      sleep 0.7

      expect(q.message_count).to eq(10)
      subject.purge_queue("/", q.name)
      sleep 0.5
      expect(q.message_count).to eq(0)
      q.delete
    end
  end

  # yes, POST, because it potentially modifies the state (ordering) of the queue
  describe "POST /api/queues/:vhost/:name/get" do
    before :each do
      @channel    = @conn.create_channel
    end
    after :each do
      @channel.close
    end

    it "fetches a message from a queue, a la basic.get" do
      q   = @channel.queue("")
      x   = @channel.fanout("amq.fanout", :durable => true, :auto_delete => false)
      q.bind(x)

      10.times do |i|
        x.publish("msg #{i}", :routing_key => q.name, :content_type => "application/xyz")
      end
      sleep 0.7

      expect(q.message_count).to eq(10)
      xs = subject.get_messages("/", q.name, :count => 10, :ackmode => "ack_requeue_false", :encoding => "auto")
      m  = xs.first

      expect(m.properties.content_type).to eq("application/xyz")
      expect(m.payload).to eq("msg 0")
      expect(m.payload_encoding).to eq("string")

      q.delete
    end
  end

  describe "GET /api/bindings" do
    it "returns a list of all bindings" do
      xs = subject.list_bindings
      b  = xs.first

      expect(b.destination).to_not be_nil
      expect(b.destination_type).to_not be_nil
      expect(b.source).to_not be_nil
      expect(b.routing_key).to_not be_nil
      expect(b.vhost).to_not be_nil
    end
  end

  describe "GET /api/bindings/:vhost" do
    it "returns a list of all bindings in a vhost" do
      xs = subject.list_bindings("/")
      b  = xs.first

      expect(b.destination).to_not be_nil
      expect(b.destination_type).to_not be_nil
      expect(b.source).to_not be_nil
      expect(b.routing_key).to_not be_nil
      expect(b.vhost).to_not be_nil
    end
  end

  describe "GET /api/bindings/:vhost/e/:exchange/q/:queue" do
    before :each do
      @channel    = @conn.create_channel
    end

    it "returns a list of all bindings between an exchange and a queue" do
      q = @channel.queue("")
      x = @channel.fanout("http.client.fanout")
      q.bind(x)

      xs = subject.list_bindings_between_queue_and_exchange("/", q.name, x.name)
      b  = xs.first
      expect(b.destination).to eq(q.name)
      expect(b.destination_type).to eq("queue")
      expect(b.source).to eq(x.name)
      expect(b.routing_key).to_not be_nil
      expect(b.properties_key).to_not be_nil
      expect(b.vhost).to eq("/")

      q.delete
      x.delete
    end
  end

  describe "POST /api/bindings/:vhost/e/:exchange/q/:queue" do
    before :each do
      @channel    = @conn.create_channel
    end
    after :each do
      @channel.close
    end

    it "creates a binding between an exchange and a queue" do
      routing_key = 'test.key'
      q = @channel.queue("")
      x = @channel.fanout("http.client.fanout")
      q.bind(x)

      b = subject.bind_queue("/", q.name, x.name, routing_key)

      expect(b).to eq(q.name + "/" + routing_key)

      q.delete
      x.delete
    end
  end

  describe "GET /api/bindings/:vhost/e/:exchange/q/:queue/props" do
    before :each do
      @channel    = @conn.create_channel
    end
    after :each do
      @channel.close
    end

    it "returns an individual binding between an exchange and a queue" do
      routing_key = 'test.key'
      q = @channel.queue("")
      x = @channel.fanout("http.client.fanout")
      q.bind(x)

      xs = subject.list_bindings_between_queue_and_exchange("/", q.name, x.name)
      b1 = xs.first

      b2 = subject.queue_binding_info("/", q.name, x.name, b1.properties_key)

      expect(b1).to eq(b2)

    end
  end

  describe "DELETE /api/bindings/:vhost/e/:exchange/q/:queue/props" do
    before :each do
      @channel    = @conn.create_channel
    end
    after :each do
      @channel.close
    end

    it "deletes an individual binding between an exchange and a queue" do
      routing_key = 'test.key'
      q = @channel.queue("")
      x = @channel.fanout("http.client.fanout")
      q.bind(x)

      xs = subject.list_bindings_between_queue_and_exchange("/", q.name, x.name)
      b  = xs.first

      expect(subject.delete_queue_binding("/", q.name, x.name, b.properties_key)).to eq(true)

      xs = subject.list_bindings_between_queue_and_exchange("/", q.name, x.name)

      expect(xs.size).to eq(0)

      q.delete
      x.delete
    end
  end

  describe "POST /api/bindings/:vhost/e/:source_exchange/e/:destination_exchange" do
    before :each do
      @channel    = @conn.create_channel
    end
    after :each do
      @channel.close
    end

    it "creates a binding between two exchanges" do
      routing_key = 'test.key'
      sx = @channel.fanout("http.client.fanout_source")
      dx = @channel.fanout("http.client.fanout_destination")

      xs = subject.list_bindings_between_exchanges("/", dx.name, sx.name)
      expect(xs).to be_empty

      dx.bind(sx)

      b = subject.bind_exchange("/", dx.name, sx.name, routing_key)
      xs = subject.list_bindings_between_exchanges("/", dx.name, sx.name)
      expect(xs).to_not be_empty

      dx.delete
      sx.delete
    end
  end

  describe "GET /api/bindings/:vhost/e/:exchange/q/:queue/props" do
    before :each do
      @channel    = @conn.create_channel
    end
    after :each do
      @channel.close
    end

    it "returns an individual binding between two exchanges" do
      routing_key = 'test.key'
      sx = @channel.fanout("http.client.fanout_source")
      dx = @channel.fanout("http.client.fanout_destination")
      dx.bind(sx)

      xs = subject.list_bindings_between_exchanges("/", dx.name, sx.name)
      b1 = xs.first

      b2 = subject.exchange_binding_info("/", dx.name, sx.name, b1.properties_key)

      expect(b1).to eq(b2)

    end
  end

  describe "DELETE /api/bindings/:vhost/e/:exchange/q/:queue/props" do
    before :each do
      @channel    = @conn.create_channel
    end
    after :each do
      @channel.close
    end

    it "deletes an individual binding between two exchanges" do
      routing_key = 'test.key'
      sx = @channel.fanout("http.client.fanout_source")
      dx = @channel.fanout("http.client.fanout_destination")
      dx.bind(sx)

      xs = subject.list_bindings_between_exchanges("/", dx.name, sx.name)
      b  = xs.first

      expect(subject.delete_exchange_binding("/", dx.name, sx.name, b.properties_key)).to eq(true)

      xs = subject.list_bindings_between_exchanges("/", dx.name, sx.name)

      expect(xs.size).to eq(0)

      dx.delete
      sx.delete
    end
  end

  describe "GET /api/vhosts" do
    it "returns a list of vhosts" do
      xs = subject.list_vhosts
      v  = xs.first

      expect(v.name).to_not be_nil
      expect(v.tracing).to eq(false)
    end
  end

  describe "GET /api/vhosts/:name" do
    context "when vhost exists" do
      it "returns infomation about a vhost" do
        v = subject.vhost_info("/")

        expect(v.name).to_not be_nil
        expect(v.tracing).to eq(false)
      end
    end

    context "when vhost DOES NOT exist" do
      it "raises NotFound" do
        expect do
          subject.vhost_info(Time.now.to_i.to_s)
        end.to raise_error(Faraday::Error::ResourceNotFound)
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
          expect(v.name).to eq(vhost)

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
          expect(v.name).to eq(vhost)

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

      expect(p.read).to eq(".*")
    end
  end

  describe "GET /api/users" do
    it "returns a list of all users" do
      xs = subject.list_users
      u  = xs.first

      expect(u.name).to_not be_nil
      expect(u.password_hash).to_not be_nil
      expect(u.tags).to_not be_nil
    end
  end

  describe "GET /api/users/:name" do
    it "returns information about a user" do
      u = subject.user_info("guest")
      expect(u.name).to eq("guest")
      expect(u.tags).to eq("administrator")
    end
  end

  describe "PUT /api/users/:name" do
    context "with tags provided explicitly" do
      it "updates information about a user" do
        subject.update_user("alt", :tags => "http, policymaker, management", :password => "alt")

        u = subject.user_info("alt")
        expect(u.tags).to eq("http,policymaker,management")
      end
    end

    context "without tags provided" do
      it "uses blank tag list" do
        subject.update_user("alt", :password => "alt")

        u = subject.user_info("alt")
        expect(u.tags).to eq("")
      end
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

      expect(p.read).to eq(".*")
    end
  end

  describe "GET /api/whoami" do
    it "returns information about the current user" do
      u = subject.whoami
      expect(u.name).to eq("guest")
    end
  end

  describe "GET /api/permissions" do
    it "lists all permissions" do
      xs = subject.list_permissions
      expect(xs.first.read).to_not be_nil
    end
  end

  describe "GET /api/permissions/:vhost/:user" do
    it "returns a list of permissions of a user in a vhost" do
      p = subject.list_permissions_of("/", "guest")

      expect(p.read).to eq(".*")
      expect(p.write).to eq(".*")
      expect(p.configure).to eq(".*")
    end
  end

  describe "PUT /api/permissions/:vhost/:user" do
    it "updates permissions of a user in a vhost" do
      subject.update_permissions_of("/", "guest", :write => ".*", :read => ".*", :configure => ".*")

      p = subject.list_permissions_of("/", "guest")

      expect(p.read).to eq(".*")
      expect(p.write).to eq(".*")
      expect(p.configure).to eq(".*")
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
      expect(xs).to be_kind_of(Array)
    end
  end


  #
  # Policies
  #

  describe "GET /api/policies" do
    it "returns a list of all policies" do
      xs = subject.list_policies
      expect(xs).to be_kind_of(Array)
    end
  end

  describe "GET /api/policies/:vhost" do
    it "returns a list of all policies in a vhost" do
      xs = subject.list_policies("/")
      expect(xs).to be_kind_of(Array)
    end
  end


  #
  # Aliveness Test
  #

  describe "GET /api/aliveness-test/:vhost" do
    it "performs aliveness check" do
      r = subject.aliveness_test("/")

      expect(r).to eq(true)
    end
  end
end
