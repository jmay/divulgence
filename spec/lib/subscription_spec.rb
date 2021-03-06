require "spec_helper"

describe Divulgence::Subscription do
  before(:all) do
    @context = Divulgence::Context.new do |config|
      config.subscription_store = Divulgence::MemoryStore.new
      config.history_store = Divulgence::MemoryStore.new
    end
  end

  SharedData = {
    id: "Group1",
    name: "Friends",
    contacts: [
               {id: "Contact1", name: {full: "Bob Brown"}, emails: [{label: "work", email: "bob@work.com"}]},
               {id: "Contact2", name: {full: "Carol Cowing"}, emails: [{label: "work", email: "carolc@gmail.com"}]},
              ]
  }
  RevisedData = {
    id: "Group1",
    name: "Friends",
    contacts: [
               {id: "Contact1", name: {full: "Robert Brown"}, emails: [{label: "work", email: "bob@work.com"}]},
               {id: "Contact2", name: {full: "Carol Cowing"}, emails: [{label: "work", email: "carolc@gmail.com"}]},
               {id: "Contact3", name: {full: "Donna Dolittle"}, emails: [{label: "work", email: "donnado@yahoo.com"}]},
              ]
  }

  context "null state" do
    it "should have no subscriptions" do
      @context.subscriptions.should be_empty
    end
  end

  context "a new subscription" do
    before(:all) do
      @share_url = "node.otherbase.dev/nodenodenode/dummy/dummy"
      @stub1 = stub_request(:get, %r{/shares/ready/CODE}).to_return(body: {url: @share_url}.to_json)
      @stub2 = stub_request(:post, @share_url).with(body: {name: 'Susie Subscriber'}).to_return(body: {token: 'NewToken', peer: {name: 'Paul Publisher'}}.to_json)
      @stub3 = stub_request(:get, "#{@share_url}/NewToken").to_return(body: SharedData.to_json)

      @subscription = @context.subscribe(code: "CODE",
                                           peer: {name: "Susie Subscriber"})
      @subscription.refresh
    end

    it "should have corresponded with registry and node" do
      @stub1.should have_been_requested # located publisher
      @stub2.should have_been_requested # onboarded
      @stub3.should have_been_requested # refreshed
      @subscription.created_at.should_not be_nil
    end

    it "should know the publisher" do
      @subscription.publisher.should_not be_nil
      @subscription.publisher[:url].should eq @share_url
      @subscription.publisher[:peer].should eq({name: 'Paul Publisher'})
      @subscription.publisher[:token].should == "NewToken"
    end

    it "should have a current payload" do
      @subscription.data.should_not be_empty
      @subscription.history.to_a.should_not be_empty
      @subscription.history.first.data.should == @subscription.data
    end

    it "should appear in list of subscriptions" do
      sublist = @context.subscriptions
      sublist.map(&:id).should == [@subscription.id]
      expected_summary = {id: @subscription.id, last_update_ts: Time.now, publisher: {name: 'Paul Publisher'}}
      sublist.first.summary[:id].should == expected_summary[:id]
      sublist.first.summary[:publisher].should == expected_summary[:publisher]
      sublist.first.summary[:last_update_ts].to_s.should == expected_summary[:last_update_ts].to_s
    end

    it "should support custom annotation" do
      @subscription.set(color: "purple")
      @old_pub = @subscription.publisher
      s = @context.subscriptions(color: "purple").first
      s.should_not be_nil
      s.instance_variable_get(:@color).should == "purple"
      s.publisher.should == @old_pub
    end

    context "after refreshing" do
      before do
        stub_request(:get, "#{@share_url}/NewToken").to_return(body: RevisedData.to_json)
        @subscription.refresh
      end

      it "should have more history" do
        @subscription.history.count.should == 2
      end

      it "should have the new data" do
        expect(@subscription.data).to eq(RevisedData)
      end

      it "should still be the only subscription" do
        @context.subscriptions.count.should == 1
      end
    end
end

  context "an invalid subscription code" do
    before do
      @stub = stub_request(:get, %r{/shares/ready/BADCODE}).to_return(status: 401)
    end

    it "should raise" do
      expect { @context.subscribe("BADCODE") }.to raise_error
    end
  end

  context "a subscription to an unavailable share" do
    before do
      share_url = "node.otherbase.dev/nodenodenode/dummy/dummy"
      @stub1 = stub_request(:get, %r{/shares/ready/GOODCODE}).to_return(body: {url: share_url})

      @stub2 = stub_request(:get, share_url).to_raise(StandardError)
    end

    it "should fail" do
      expect { @context.subscribe("GOODCODE") }.to raise_error(StandardError)
    end
  end
end

# TODO: test registry timeout
# TODO: test node timeout
