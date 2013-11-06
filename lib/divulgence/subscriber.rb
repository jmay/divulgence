class Divulgence::Subscriber
  def initialize(hash)
    @data = hash
  end

  def subscribed?
    @data[:subscribed]
  end

  def synced?
    !@last_sync_ts.nil?
  end

  def sync
    @last_sync_ts = Time.now
  end

  def last_sync_ts
    @last_sync_ts
  end

  def name
    @data[:name]
  end

  def url
    @data[:url]
  end

  def to_s
    "#<#{self.class}:#{id}: #{name} at #{url}>"
  end
end
