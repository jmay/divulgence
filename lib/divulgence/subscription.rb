class Divulgence::Subscription
  def initialize(args)
    @subscription_url = args.fetch(:url)
    update(args.fetch(:payload))
  end

  def publisher
    OpenStruct.new(url: @subscription_url)
  end
  def object
    @data
  end
  def history
    @history ||= []
  end

  def update(payload)
    history << {ts: Time.now, payload: payload}
    @data = payload
  end

  # cancelling a subscription means to stop refreshing from the publisher
  # we don't need to inform the publisher that there will be no further refresh attempts
  def cancel!
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

  def self.retrieve_disclosure(code)
    url = "#{registry_url}/shares/ready/#{code}"
    # $logger.info "GET #{url}"
    registry_get(url) do |payload|
      payload[:url]
    end
  # rescue Exception => e
  #   $logger.info "REGISTRY BARF: #{e.}"
  #   nil
  end

  def self.subscribe(code)
    url = retrieve_disclosure(code)
    registry_get(url) do |response|
      if response.code == 200
        # sharespec = JSON.parse(response, { symbolize_names: true })
        new(url: url, payload: response.body)
      end
    end
  end
end
