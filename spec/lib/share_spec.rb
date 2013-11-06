require "spec_helper"

describe Divulgence::Share do
  TempStore = Divulgence::MemoryStore.new

  context "a fresh share" do
    before do
      @share = Divulgence::Share.new(store: TempStore, id: SecureRandom.uuid)
    end

    it "should be idle" do
      @share.should_not be_published
      @share.subscribers.should be_empty
      @share.history.should be_empty
    end

    context "with new subscribers" do
      before do
        @peer1 = @share.onboard(url: "peer1.url")
        @peer2 = @share.onboard(url: "peer2.url")
      end

      it "should assign unique tokens to subscribers" do
        @peer1.token.should_not == @peer2.token
      end

      it "should see unsynced subscribers" do
        @share.subscribers.count.should == 2
        @share.subscribers.each do |subscriber|
          subscriber.should_not be_synced
        end
      end

      it "should have no activity" do
        @share.history.should be_empty
      end

      context "after syncing" do
        before do
          @share.refresh(@peer1.token)
          @share.refresh(@peer2.token)
        end

        it "should see synced subscribers" do
          @share.subscribers.count.should == 2
          @share.subscribers.each do |subscriber|
            subscriber.active.should be_true
            expect(subscriber.last_sync_ts).to be_within(1).of(Time.now)
          end
        end

        it "should have activity" do
          @share.history.count.should == 2
        end
      end

      context "rejected subscriber" do
        before do
          @share.reject(@peer1.token)
        end

        it "should refuse to refresh" do
          expect {@share.refresh(@peer1.token)}.to raise_error
        end
      end
    end
  end
end

# TODO: test registry timeout
# TODO: test node timeout
