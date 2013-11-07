require "spec_helper"

describe Divulgence::Subscription do

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
      Divulgence::Subscription.all(Divulgence::NullStore).should be_empty
    end
  end

  context "a new subscription" do
    before do
      @share_url = "node.otherbase.dev/nodenodenode/dummy/dummy"
      @stub1 = stub_request(:get, %r{/shares/ready/CODE}).to_return(body: {url: @share_url}.to_json)
      @stub2 = stub_request(:post, @share_url).with(body: {name: 'Susie Subscriber'}).to_return(body: {token: 'NewToken'}.to_json)
      @stub3 = stub_request(:get, "#{@share_url}/NewToken").to_return(body: SharedData.to_json)

      @subscription = Divulgence::Subscription.subscribe(store: Divulgence::MemoryStore.new,
                                                         code: "CODE",
                                                         peer: {name: "Susie Subscriber"})
      @subscription.refresh
    end

    it "should have corresponded with registry and node" do
      @stub1.should have_been_requested # located publisher
      @stub2.should have_been_requested # onboarded
      @stub3.should have_been_requested # refreshed
    end

    it "should know the publisher" do
      @subscription.publisher.should_not be_nil
      @subscription.publisher[:url].should == @share_url
      @subscription.publisher[:token].should == "NewToken"
    end

    it "should have a current payload" do
      @subscription.data.should_not be_empty
      @subscription.history.should_not be_empty
      @subscription.history.first[:data].should == @subscription.data
    end

    it "should define objects" do
      @subscription.entities.count.should == 3
      entlist = [
                 {id: "Group1", name: "Friends", contacts: ["Contact1", "Contact2"]},
                 {id: "Contact1", name: {full: "Bob Brown"}, emails: [{label: "work", email: "bob@work.com"}]},
                 {id: "Contact2", name: {full: "Carol Cowing"}, emails: [{label: "work", email: "carolc@gmail.com"}]}
                ]
      entlist.each do |ent|
        @subscription.entities.should include(ent)
      end
    end

    context "after refreshing unchanged" do
      before do
        @subscription.refresh
      end

      it "should have more history" do
        @subscription.history.count.should == 2
      end

      it "should be unchanged" do
        @subscription.entities.count.should == 3
        @subscription.history.first[:data].should == @subscription.history.last[:data]
      end
    end

    context "after refreshing with changes" do
      before do
        stub_request(:get, "#{@share_url}/NewToken").to_return(body: RevisedData.to_json)
        @subscription.refresh
      end

      it "should have more history" do
        @subscription.history.count.should == 2
      end

      it "should have changes" do
        @subscription.entities.count.should == 4
        @subscription.history.first[:data].should_not == @subscription.history.last[:data]
      end
    end
end

  context "an invalid subscription code" do
    before do
      @stub = stub_request(:get, %r{/shares/ready/BADCODE}).to_return(status: 401)
    end

    it "should raise" do
      expect { Divulgence.subscribe("BADCODE") }.to raise_error
    end
  end

  context "a subscription to an unavailable share" do
    before do
      share_url = "node.otherbase.dev/nodenodenode/dummy/dummy"
      @stub1 = stub_request(:get, %r{/shares/ready/GOODCODE}).to_return(body: {url: share_url})

      @stub2 = stub_request(:get, share_url).to_raise(StandardError)
    end

    it "should fail" do
      expect { Divulgence.subscribe("GOODCODE") }.to raise_error(StandardError)
    end
  end
end

# TODO: test registry timeout
# TODO: test node timeout
