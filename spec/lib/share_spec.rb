require "spec_helper"

describe Divulgence::Share do
  Divulgence.config do |config|
    config.share_store = Divulgence::MemoryStore.new
    config.history_store = Divulgence::MemoryStore.new
    config.subscriber_store = Divulgence::MemoryStore.new
  end

  describe "null state" do
    it "should have no shares" do
      Divulgence.shares.should be_empty
    end
  end

  context "a fresh share" do
    let(:share) do
      Divulgence.share(info: 'stuff here')
    end

    it "should be idle" do
      share.subscribers.should be_empty
      share.history.should be_none
    end

    it "should appear in collection" do
      this_id = share.id
      Divulgence.shares.map(&:id).should include(this_id)
    end

    context "with new subscribers" do
      let(:peer1) { share.onboard(url: "peer1.url") }
      let(:peer2) { share.onboard(url: "peer2.url") }

      before(:each) do
        peer1; peer2
      end

      it "should assign unique tokens to subscribers" do
        peer1.token.should_not be_nil
        peer1.token.should_not == peer2.token
      end

      it "should see unsynced subscribers" do
        share.subscribers.count.should == 2
        share.subscribers.each do |subscriber|
          subscriber.should_not be_synced
        end
      end

      it "should have no activity" do
        share.history.should be_none
      end

      context "after syncing" do
        before do
          share.refresh(peer1.token)
          share.refresh(peer2.token)
        end

        it "should see synced subscribers" do
          share.subscribers.count.should == 2
          share.subscribers.each do |subscriber|
            subscriber.active.should be_true
            expect(subscriber.last_sync_ts).to be_within(1).of(Time.now)
          end
        end

        it "should have activity" do
          share.history.count.should == 2
        end
      end

      context "rejected subscriber" do
        before do
          share.reject(peer1.token)
        end

        it "should refuse to refresh" do
          expect {share.refresh(peer1.token)}.to raise_error
        end
      end
    end
  end

  describe "share with custom data" do
    before(:all) do
      Divulgence::Share.new(id: "MYSHARE", color: 'purple')
    end

    it "should be findable by id" do
      sh = Divulgence::Share.find(id: "MYSHARE").first
      sh.id.should == 'MYSHARE'
      sh.data[:color].should == 'purple'
    end

    it "should be findable by attribute" do
      Divulgence::Share.find(data: {color: 'purple'}).count.should == 1
    end

    it "can update custom data" do
      sh = Divulgence::Share.find(id: "MYSHARE").first
      sh.set(color: 'green')
      sh.data[:color].should == 'green'
    end
  end
end

# TODO: test registry timeout
# TODO: test node timeout
