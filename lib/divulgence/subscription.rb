class Divulgence::Subscription
  attr_reader :data, :publisher, :id

  def initialize(args)
    @store = args.fetch(:store) { Divulgence::NullStore }

    @id = args.fetch(:id)
    @publisher = {
      url: args.fetch(:url),
      token: args.fetch(:token)
    }
    @store.insert({
                    _id: id,
                    publisher: publisher,
                    created_at: Time.now
                  })
    # update(data)
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

  def refresh
    self.class.remote_get("#{publisher[:url]}/#{publisher[:token]}") do |response|
      update(response)
    end
  end

  def entities
    return [] unless data

    primary = {}
    ents = [primary]
    data.each do |k,v|
      Array(v).each do |x|
        if x.respond_to?(:fetch) && x[:id]
          primary[k] ||= []
          primary[k] << x[:id]
          ents << x
        else
          primary[k] = x
        end
      end
    end
    ents
  end

  def self.registry_base
    ENV['OTHERBASE_REG']
  end

  def self.remote_get(url)
    RestClient.get(url, {accept: :json}) do |response, request, result|
      if response.code == 200
        yield JSON.parse(response.body, symbolize_names: true)
      else
        raise
      end
    end
  end

  def self.remote_post(url, payload)
    RestClient.post(url, payload, {accept: :json}) do |response, request, result|
      if response.code == 200
        yield JSON.parse(response.body, symbolize_names: true)
      else
        raise
      end
    end
  end

  def self.subscribe(opts)
    store = opts.fetch(:store) { Divulgence::NullStore }
    code = opts.fetch(:code)
    peerdata = opts.fetch(:peer)

    registry_url = "#{registry_base}/shares/ready/#{code}"
    remote_get(registry_url) do |response|
      share_url = response[:url]
      remote_post(share_url, peerdata) do |response|
        new(store: store, url: share_url, token: response[:token], id: SecureRandom.uuid)
      end
    end
  end
end
