class Divulgence::Subscription
  attr_reader :id, :publisher, :created_at

  def initialize(args)
    @id = args.fetch(:id) { SecureRandom.uuid }
    @publisher = {
      url: args.fetch(:url),
      token: args.fetch(:token),
      peer: args.fetch(:peer)
    }
    store.insert(id: id,
                 publisher: publisher,
                 created_at: Time.now
                 )
    @created_at = Time.now
  end

  def self.all(criteria = {})
    store.find(criteria).map do |rec|
      subscription = allocate
      rec.each do |k,v|
        subscription.instance_variable_set("@#{k}", v)
      end
      subscription
    end
  end

  def history
    Divulgence::History.find(pulled: id)
  end

  def latest
    history.first
  end

  def data
    latest && latest.data
  end

  def set(changes)
    store.update({id: id}, changes.merge(id: id, publisher: publisher, created_at: created_at))
  end

  def update(payload)
    now = Time.now
    Divulgence::History.new(pulled: id, data: payload)
  end

  def refresh
    self.class.remote_get("#{publisher[:url]}/#{publisher[:token]}") do |response|
      update(response)
    end
  end

  def summary
    {
      id: id,
      publisher: publisher[:peer],
      last_update_ts: latest.ts
    }
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
    RestClient.post(url, payload.to_json, {content_type: :json, accept: :json}) do |response, request, result|
      if response.code == 200
        yield JSON.parse(response.body, symbolize_names: true)
      else
        raise "remote node rejected request: #{response.body}"
      end
    end
  end

  def self.subscribe(opts)
    code = opts.fetch(:code)
    peerdata = opts.fetch(:peer)

    registry_url = "#{registry_base}/shares/ready/#{code}"
    remote_get(registry_url) do |response|
      share_url = response[:url]
      remote_post(share_url, peerdata) do |response|
        new(url: share_url,
            token: response[:token],
            peer: response[:peer]
            )
      end
    end
  end

  private

  def self.store; Divulgence.config.subscription_store; end
  def store; self.class.store; end
end
