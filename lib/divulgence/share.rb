class Divulgence::Share
  attr_reader :id, :data

  def initialize(customdata = {})
    @id = SecureRandom.uuid
    @data = customdata
    store.insert({
                   obj: 'share',
                   id: @id,
                   created_at: Time.now,
                   data: @data
                 })
  end

  def self.all(store)
    store.find(obj: 'share').map do |rec|
      share = allocate
      rec.each do |k,v|
        share.instance_variable_set("@#{k}", rec[k])
      end
      share
    end
  end

  def subscribers(criteria = {})
    Divulgence::Subscriber.find(criteria.merge(share_id: id))
  end

  def onboard(peerdata)
    Divulgence::Subscriber.new(share_id: id, peer: peerdata)
  end

  def subscriber_for_token(token)
    this_guy = subscribers(token: token, active: true).first
    raise SecurityError, "invalid token" unless this_guy
    this_guy
  end

  def reject(token)
    subscriber_for_token(token).reject!
  end

  def history
    Divulgence::History.find(pushed: id)
  end

  def refresh(token)
    now = Time.now
    subscriber_for_token(token).ping(now)
    Divulgence::History.new(pushed: id, token: token, ts: now)

    yield if block_given?
  end

  private

  def store
    Divulgence.config.share_store
  end
end
