require "spec_helper"

describe Veterinarian::Client do
  let(:endpoint) { "http://127.0.0.1:55672" }

  subject do
    described_class.connect(endpoint, :username => "guest", :password => "guest")
  end


  #
  # Overview
  #

  describe "GET /api/overview" do
    it "returns an overview" do
      r = subject.overview

      r.exchange_types.map { |h| h.name }.
        sort.should == ["direct", "fanout", "headers", "topic"]

      r.rabbitmq_version.should_not be_nil
      r.erlang_version.should_not be_nil
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

      n.name.should == "rabbit@localhost"
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
      n = subject.node_info("rabbit@localhost")

      rabbit = n.applications.detect { |app| app.name == "rabbit" }
      rabbit.description.should == "RabbitMQ"

      n.name.should == "rabbit@localhost"
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

      f.javascript.should == "dispatcher.js"
    end
  end

  #
  # Definitions
  #

  describe "GET /api/definitions" do

  end

  describe "POST /api/definitions" do

  end

  #
  # Connections
  #

  describe "GET /api/connections" do
    before :all do
      @connection = Bunny.new
      @connection.start
    end
    after :all do
      @connection.close
    end

    it "returns a list of all active connections" do
      xs = subject.list_connections
      f  = xs.first

      f.name.should =~ /127.0.0.1/
      f.client_properties.product.should == "Bunny"
    end
  end

  describe "GET /api/connections/:name" do
    before :all do
      @connection = Bunny.new
      @connection.start
    end
    after :all do
      @connection.close
    end

    it "returns information about the connection" do
      xs = subject.list_connections
      c  = subject.connection_info(xs.first.name)

      c.name.should =~ /127.0.0.1/
      c.client_properties.product.should == "Bunny"
    end
  end

  describe "DELETE /api/connections/:name" do
    before :all do
      @connection = Bunny.new
      @connection.start
    end
    after :all do
      @connection.close if @connection.open?
    end


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
      @connection = Bunny.new
      @connection.start
      @channel    = @connection.create_channel
    end
    after :all do
      @connection.close
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
      @connection = Bunny.new
      @connection.start
      @channel    = @connection.create_channel
    end
    after :all do
      @connection.close
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
    it "returns a list of all exchanges in the vhost" do
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

  describe "GET /api/exchanges/:vhost/:name/bindings/source" do
    before :all do
      @connection = Bunny.new
      @connection.start
      @channel    = @connection.create_channel
    end
    after :all do
      @connection.close
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
end
