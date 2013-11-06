class Divulgence::Share
  attr_reader :id, :store

  def initialize(args)
    @store = args.fetch(:store) { Divulgence::NullStore }
    @id = args.fetch(:id)
    store.insert({
                   _id: id,
                   created_at: Time.now,
                   published: false,
                   subscribers: {}
                 })
  end

  def self.all(store)
    store.find.map do |rec|
      share = allocate
      rec.each do |k,v|
        share.instance_variable_set(k, rec[k])
      end
    end
  end

  def published?
    false
  end
  def subscribers
    store.find(_id: /^#{id}.subscribers./).map { |rec| OpenStruct.new(rec) }
  end

  def onboard(peerdata)
    token = SecureRandom.uuid

    subscriber = {
      _id: "#{id}.subscribers.#{token}",
      token: token,
      peer: peerdata,
      active: true,
      subscribed_at: Time.now,
      last_sync_ts: nil
    }

    store.insert(subscriber)

    OpenStruct.new(subscriber)
  end

  # revoking a share means that further refresh attempts will be refused
  def revoke!
  end

  def subscriber_for_token(token)
    subscriber = subscribers.find { |s| s.token == token && s.active }
    raise unless subscriber
    subscriber
  end

  def reject(token)
    subscriber = subscriber_for_token(token)

    subscriber.active = false
    store.update({_id: subscriber._id}, subscriber.to_h)
  end

  def history
    store.find(_id: /^#{id}.history./).map { |rec| OpenStruct.new(rec) }
  end

  def to_hash
    {
      _id: id,
      created_at: created_at,
      published: published?,
      subscribers: subscribers.map(&:to_hash)
    }
  end

  def refresh(token)
    subscriber = subscriber_for_token(token)

    now = Time.now
    subscriber.last_sync_ts = now
    store.update({_id: subscriber._id}, subscriber.to_h)

    store.insert({
                   _id: "#{id}.history.#{token}.#{now.to_i}",
                   token: token,
                   ts: now
                 })

    yield if block_given?
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
