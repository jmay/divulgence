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

  def history
    @history ||= []
  end

  def update(payload)
    event = {ts: Time.now, data: payload}
    history << event
    @store.update({_id: id},
                  {
                    '$set' => {object: payload},
                    '$push' => {history: event}
                  })
    @data = payload
  end

  def self.registry_base
    ENV['OTHERBASE_REG']
  end

  def self.remote_get(url)
    # $logger.info "GET #{url}"
    RestClient.get(url, {accept: :json}) do |response, request, result|
      if response.code == 200
        yield response.body
      else
        raise
      end
    end
  end

  def self.subscribe(code)
    registry_url = "#{registry_base}/shares/ready/#{code}"
    remote_get(registry_url) do |response|
      share_url = response[:url]
      remote_get(share_url) do |response|
        new(url: share_url, payload: response, id: 123)
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
