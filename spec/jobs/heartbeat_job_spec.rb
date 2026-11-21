require "rails_helper"

RSpec.describe HeartbeatJob do
  subject(:job) { described_class.new }

  let(:heartbeat_url) { "https://uptime.betterstack.com/api/v1/heartbeat/exemple" }

  before do
    allow(Rails.application.credentials).to receive(:dig).and_call_original
    allow(Rails.application.credentials).to receive(:dig).with(:better_stack, :heartbeat_url).and_return(heartbeat_url)
    allow(Net::HTTP).to receive(:get)
  end

  describe "#perform" do
    it "pings the Better Stack heartbeat" do
      job.perform

      expect(Net::HTTP).to have_received(:get).with(URI(heartbeat_url))
    end

    context "without a heartbeat URL in the credentials" do
      let(:heartbeat_url) { nil }

      it "pings nothing" do
        job.perform

        expect(Net::HTTP).not_to have_received(:get)
      end
    end
  end
end
