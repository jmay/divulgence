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
    store.find(criteria.merge(obj: 'subscriber', share_id: id)).map { |rec| OpenStruct.new(rec) }
  end

  def subscriber(criteria = {})
    if rec = store.find_one(criteria.merge(obj: 'subscriber', share_id: id))
      OpenStruct.new(rec)
    end
  end

  def onboard(peerdata)
    token = SecureRandom.uuid

    subscriber_data = {
      obj: 'subscriber',
      share_id: id,
      token: token,
      peer: peerdata,
      active: true,
      subscribed_at: Time.now,
      last_sync_ts: nil
    }

    store.insert(subscriber_data)

    OpenStruct.new(subscriber_data)
  end

  def subscriber_for_token(token)
    this_guy = subscriber(token: token, active: true)
    raise SecurityError, "invalid token" unless this_guy
    this_guy
  end

  def reject(token)
    subscriber = subscriber_for_token(token)

    store.update({obj: 'subscriber', share_id: id, token: token}, {active: false})
  end

  def history
    store.find({obj: 'history', share_id: id}, {sort: {ts: -1}})
  end

  def refresh(token)
    subscriber = subscriber_for_token(token)

    now = Time.now
    store.update({obj: 'subscriber', share_id: id, token: token}, {last_sync_ts: now})

    store.insert({
                   obj: 'history',
                   share_id: id,
                   token: token,
                   ts: now
                 })

    yield if block_given?
  end

  private

  def store
    Divulgence.config.share_store
  end
end
