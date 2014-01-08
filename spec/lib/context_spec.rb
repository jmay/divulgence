require "spec_helper"

# test multiple collections

describe Divulgence::Context do
  before(:each) do
    @d1 = Divulgence::Context.new do |config|
      config.share_store = Divulgence::MemoryStore.new
      config.history_store = Divulgence::MemoryStore.new
      config.subscriber_store = Divulgence::MemoryStore.new
      config.subscription_store = Divulgence::MemoryStore.new
    end

    @d2 = Divulgence::Context.new do |config|
      config.share_store = Divulgence::MemoryStore.new
      config.history_store = Divulgence::MemoryStore.new
      config.subscriber_store = Divulgence::MemoryStore.new
      config.subscription_store = Divulgence::MemoryStore.new
    end
  end

  it "should start empty" do
    @d1.shares.should be_empty
    @d1.subscriptions.should be_empty
    @d2.shares.should be_empty
    @d2.subscriptions.should be_empty
  end

  it "should live in a namespace" do
    s1 = @d1.share(info: 'stuff here')
    @d1.shares.should_not be_empty
    @d2.shares.should be_empty
  end
end
