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
  # Helpers
  #

  # Statistics tables in the server are updated asynchronously,
  # in particular starting with rabbitmq/rabbitmq-management#236,
  # so in some cases we need to wait before GET'ing e.g. a newly opened connection.
  def await_event_propagation
    # same number as used in rabbit-hole test suite. Works OK.
    sleep 1
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

    200.times do
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

    gen = Rantly.new
    200.times do
      vhost = gen.string

      context "when vhost #{vhost} is deleted immediately after being created" do
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
end