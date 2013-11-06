require "spec_helper"

describe Divulgence::Subscription do

  SharedData = {
    name: "Friends",
    contacts: [
               {name: {full: "Bob Brown"}, emails: [{label: "work", email: "bob@work.com"}]},
               {name: {full: "Carol Cowing"}, emails: [{label: "work", email: "carolc@gmail.com"}]},
              ]
  }

  context "a new subscription" do
    before do
      registry_url = %r{#{ENV['OTHERBASE_REG']}/shares/ready/}
      @share_url = "node.otherbase.dev/nodenodenode/dummy/dummy"
      @stub1 = stub_request(:get, registry_url).to_return(body: {url: @share_url})

      @stub2 = stub_request(:get, @share_url).to_return(body: SharedData)

      @subscription = Divulgence.subscribe("CODE")
    end

    it "should talk to registry" do
      @stub1.should have_been_requested
    end

    it "should talk to node" do
      @stub2.should have_been_requested
    end

    it "should know the publisher" do
      @subscription.publisher.should_not be_nil
      @subscription.publisher.url.should == @share_url
    end

    it "should have a current payload" do
      @subscription.object.should_not be_empty
      @subscription.history.should_not be_empty
    end
  end

  context "an invalid subscription code" do
    before do
      url_re = %r{#{ENV['OTHERBASE_REG']}/shares/ready/}
      @stub = stub_request(:get, url_re).to_return(status: 401)
    end

    it "should raise" do
      expect { Divulgence.subscribe("BADCODE") }.to raise_error
    end
  end

  context "a subscription to an unavailable share" do
    before do
      registry_url = %r{#{ENV['OTHERBASE_REG']}/shares/ready/}
      share_url = "node.otherbase.dev/nodenodenode/dummy/dummy"
      @stub1 = stub_request(:get, registry_url).to_return(body: {url: share_url})

      @stub2 = stub_request(:get, share_url).to_raise(StandardError)
    end

    it "should fail" do
      expect { Divulgence.subscribe("GOODCODE") }.to raise_error(StandardError)
    end
  end
end

# TODO: test registry timeout
# TODO: test node timeout
