class Divulgence::Subscription
  attr_reader :publisher, :id

  def initialize(args)
    @store = args.fetch(:store) { Divulgence::NullStore }

    @id = args.fetch(:id) { SecureRandom.uuid }
    @publisher = {
      url: args.fetch(:url),
      token: args.fetch(:token),
      peer: args.fetch(:peer)
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
      subscription.instance_variable_set(:@store, store)
      subscription.instance_variable_set(:@id, rec[:_id])
      subscription.instance_variable_set(:@publisher, rec[:_publisher])
      subscription.instance_variable_set(:@data, rec[:_data])
      subscription
    end
  end

  def history
    @store.find({_id: /^#{id}.history./}, {sort: {ts: -1}}).map { |rec| OpenStruct.new(rec) }
  end

  def latest
    if rec = @store.find_one({_id: /^#{id}.history./}, {sort: {ts: -1}})
      OpenStruct.new(rec)
    end
  end

  def update(payload)
    now = Time.now
    @store.insert({
                    _id: "#{id}.history.#{now.to_i}",
                    ts: now,
                    data: payload
                  })
  end

  def data
    latest.data
  end

  def refresh
    self.class.remote_get("#{publisher[:url]}/#{publisher[:token]}") do |response|
      update(response)
    end
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
        new(store: store,
            url: share_url,
            token: response[:token],
            peer: response[:peer]
            )
      end
    end
  end
end
