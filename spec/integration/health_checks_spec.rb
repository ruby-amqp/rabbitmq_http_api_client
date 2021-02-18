# -*- coding: utf-8 -*-
require "spec_helper"

describe RabbitMQ::HTTP::HealthChecks do
  let(:endpoint) { "http://127.0.0.1:15672" }

  subject do
    RabbitMQ::HTTP::Client.connect(endpoint, username: "guest", password: "guest")
  end

  #
  # Examples
  #

  describe "cluster-wide alarms check" do
    it "succeeds under regular conditions" do
      succeeded, _ = subject.health.check_alarms
      expect(succeeded).to be(true)
    end
  end

  describe "node-local alarms check" do
    it "succeeds under regular conditions" do
      succeeded, _ = subject.health.check_local_alarms
      expect(succeeded).to be(true)
    end
  end
end
