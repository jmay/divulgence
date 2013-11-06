require "spec_helper"

describe Divulgence::Share do
  context "a fresh share" do
    before do
      @share = Divulgence.share(double)
    end

    it "should be idle" do
      @share.should_not be_published
      @share.subscribers.should be_empty
    end

    context "with subscribers" do
      before do
        @peer1 = @share.onboard(double)
        @peer2 = @share.onboard(double)
      end

      it "should see unsynced subscribers" do
        @share.subscribers.count.should == 2
        @share.subscribers.each do |subscriber|
          subscriber.should_not be_synced
        end
      end

      context "after syncing" do
        before do
          @peer1.sync
          @peer2.sync
        end

        it "should see synced subscribers" do
          @share.subscribers.each do |subscriber|
            subscriber.should be_synced
            expect(subscriber.last_sync_ts).to be_within(1).of(Time.now)
          end
        end
      end
    end
  end
end

# TODO: test registry timeout
# TODO: test node timeout
