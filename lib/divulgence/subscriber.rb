class Divulgence::Subscriber
  def initialize(args)
    @data = args.merge(
                       token: SecureRandom.uuid,
                       subscribed_at: Time.now,
                       active: true,
                       last_sync_ts: nil
                       )
    store.insert(@data)
  end

  def self.find(criteria)
    store.find(criteria).map do |rec|
      subscriber = allocate
      subscriber.instance_variable_set(:@data, rec)
      subscriber
    end
  end

  def reject!
    store.update(@data, {active: false})
    @data[:active] = false
  end

  def ping(ts = Time.now)
    store.update(@data, {last_sync_ts: ts})
    @data[:last_sync_ts] = ts
  end

  def synced?
    !last_sync_ts.nil?
  end

  def method_missing(meth)
    @data.has_key?(meth) ? @data[meth] : super
  end

  def to_s
    "SUBSCRIBER: #{@data}"
  end

  private

  def store
    self.class.store
  end
  def self.store
    Divulgence.config.subscriber_store
  end
end
