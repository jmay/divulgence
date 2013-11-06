class Divulgence::Share
  def initialize(args)
  end

  def published?
    false
  end
  def subscribers
    @subscribers ||= []
  end
  def object
    {foo: 1}
  end
  def onboard(peerdata)
    subscriber = Divulgence::Subscriber.new(peerdata)
    subscribers << subscriber
    subscriber
  end

  # revoking a share means that further refresh attempts will be refused
  def revoke!
  end



  def self.registry_url
    ENV['OTHERBASE_REG']
  end

  def self.registry_get(url)
    RestClient.get(url, {accept: :json}) do |response, request, result|
      # $logger.info "REMOTE RESPONDED WITH #{response.code} #{response.class} #{response.body} RESULT #{result}"
      yield response
    end
  end
end
