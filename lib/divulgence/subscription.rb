class Divulgence::Subscription
  attr_reader :data, :publisher, :id

  def initialize(args)
    @store = args.fetch(:store) { NullStore }

    @id = args.fetch(:id)
    @publisher = {
      url: args.fetch(:url)
    }
    @data = args.fetch(:payload)

    @store.insert({
                    _id: id,
                    publisher: publisher,
                    created_at: Time.now
                  })
    update(data)
  end

  def self.all(store)
    store.find.map do |rec|
      subscription = allocate
      subscription.instance_variable_set(:id, rec[:_id])
      subscription.instance_variable_set(:publisher, rec[:_publisher])
      subscription.instance_variable_set(:data, rec[:_data])
      subscription
    end
  end

  # def current_state
  #   {
  #     publisher: publisher,
  #     object: object,
  #     history: history
  #   }
  # end

  def history
    @history ||= []
  end

  def update(payload)
    event = {ts: Time.now, payload: payload}
    history << event
    @store.update({_id: id},
                  {
                    '$set' => {object: payload},
                    '$push' => {history: event}
                  })
    @data = payload
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
        new(url: url, payload: response.body, id: 123)
      end
    end
  end
end

class NullStore
  def self.find
    []
  end
  def self.method_missing(*args)
    # no-op
  end
end
