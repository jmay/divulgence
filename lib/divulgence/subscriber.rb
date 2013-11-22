class Divulgence::Subscriber
  def initialize(args)
    @data = args.merge(
                       token: SecureRandom.uuid,
                       subscribed_at: Time.now,
                       active: true,
                       last_sync_ts: nil
                       )
    self.class.store.insert(@data)
  end

  def self.find(criteria)
    store.find(criteria).map do |rec|
      subscriber = allocate
      subscriber.instance_variable_set(:@data, rec)
      subscriber
    end
  end

  def reject!
    self.class.store.update(@data, @data.merge(active: false))
    @data[:active] = false
  end

  def ping(ts = Time.now)
    self.class.store.update(@data, @data.merge(last_sync_ts: ts))
    @data[:last_sync_ts] = ts
  end

  def synced?
    !last_sync_ts.nil?
  end

  def method_missing(meth)
    @data.has_key?(meth) ? @data[meth] : super
  end

  private

  def self.store
    Divulgence.config.subscriber_store
  end
end
