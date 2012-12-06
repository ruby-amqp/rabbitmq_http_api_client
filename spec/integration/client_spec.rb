require "spec_helper"

describe RabbitMQ::HTTP::Client do
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


  describe "GET /api/exchanges/:vhost/:name/bindings/destination" do
    before :all do
      @connection = Bunny.new
      @connection.start
      @channel    = @connection.create_channel
    end
    after :all do
      @connection.close
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

  describe "GET /api/queues" do
    before :all do
      @connection = Bunny.new
      @connection.start
      @channel    = @connection.create_channel
    end
    after :all do
      @connection.close
    end

    it "returns a list of all queues" do
      q  = @channel.queue("", :exclusive => true)

      xs = subject.list_queues
      xs.detect { |x| x.name == q.name }.should_not be_empty
    end
  end

  describe "GET /api/queues/:vhost" do
    before :all do
      @connection = Bunny.new
      @connection.start
      @channel    = @connection.create_channel
    end
    after :all do
      @connection.close
    end

    it "returns a list of all queues" do
      q  = @channel.queue("", :exclusive => true)

      xs = subject.list_queues("/")
      xs.detect { |x| x.name == q.name }.should_not be_empty
    end
  end

  describe "GET /api/queues/:vhost/:name" do
    before :all do
      @connection = Bunny.new
      @connection.start
      @channel    = @connection.create_channel
    end
    after :all do
      @connection.close
    end

    it "returns information about a queue" do
      q  = @channel.queue("", :exclusive => true, :durable => false)
      i  = subject.queue_info("/", q.name)

      i.durable.should be_false
      i.durable.should == q.durable?

      i.name.should == q.name
      i.auto_delete.should == q.auto_delete?
      i.active_consumers.should == 0
      i.backing_queue_status.avg_ack_egress_rate.should == 0.0
    end
  end

  describe "PUT /api/queues/:vhost/:name" do
    before :all do
      @connection = Bunny.new
      @connection.start
      @channel    = @connection.create_channel
    end
    after :all do
      @connection.close
    end

    it "declares a queue"
  end

  describe "DELETE /api/queues/:vhost/:name" do
    it "deletes a queue"
  end

  describe "GET /api/queues/:vhost/:name/bindings" do
    it "returns a list of bindings for a queue"
  end

  describe "DELETE /api/queues/:vhost/:name/contents" do
    it "purges a queue"
  end

  describe "GET /api/queues/:vhost/:name/get" do
    it "fetches a message from a queue, a la basic.get"
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
    it "returns a list of all bindings between an exchange and a queue"
  end

  describe "POST /api/bindings/:vhost/e/:exchange/q/:queue" do
    it "creates a binding between an exchange and a queue"
  end

  describe "GET /api/bindings/:vhost/e/:exchange/q/:queue/props" do
    it "returns an individual binding between an exchange and a queue"
  end

  describe "DELETE /api/bindings/:vhost/e/:exchange/q/:queue/props" do
    it "deletes an individual binding between an exchange and a queue"
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
    it "returns infomation about a vhost" do
      v = subject.vhost_info("/")

      v.name.should_not be_nil
      v.tracing.should be_false
    end
  end

  describe "POST /api/vhosts/:name" do
    it "creates a vhost"
  end

  describe "PUT /api/vhosts/:name" do
    it "updates a vhost"
  end

  describe "GET /api/vhosts/:name/permissions" do
    it "returns a list of permissions in a vhost"
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
    it "returns information about a user"
  end

  describe "PUT /api/users/:name" do
    it "updates information about a user"
  end

  describe "POST /api/users/:name" do
    it "creates a user"
  end

  describe "GET /api/users/:name/permissions" do
    it "returns a list of permissions for a user"
  end

  describe "GET /api/whoami" do
    it "returns information about the current user"
  end

  describe "GET /api/permissions" do
    it "lists all permissions"
  end

  describe "GET /api/permissions/:vhost/:user" do
    it "returns a list of permissions of a user in a vhost"
  end

  describe "PUT /api/permissions/:vhost/:user" do
    it "updates permissions of a user in a vhost"
  end

  describe "DELETE /api/permissions/:vhost/:user" do
    it "clears permissions of a user in a vhost"
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

  describe "GET /api/parameters/:component" do
    it "returns a list of all parameters for a component"
  end

  describe "GET /api/parameters/:component/:vhost" do
    it "returns a list of all parameters for a component in a vhost"
  end

  describe "GET /api/parameters/:component/:vhost/:name" do
    it "returns information about a specific parameter"
  end

  describe "PUT /api/parameters/:component/:vhost/:name" do
    it "updates information about a specific parameter"
  end

  describe "DELETE /api/parameters/:component/:vhost/:name" do
    it "clears information about a specific parameter"
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
    it "returns a list of all policies in a vhost"
  end

  describe "GET /api/policies/:vhost/:name" do
    it "returns information about a policy in a vhost"
  end

  describe "PUT /api/policies/:vhost/:name" do
    it "updates information about a policy in a vhost"
  end

  describe "DELETE /api/policies/:vhost/:name" do
    it "clears information about a policy in a vhost"
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
