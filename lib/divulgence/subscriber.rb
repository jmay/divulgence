class Divulgence::Subscriber
  def initialize(store, args)
    @store = store
    @data = args.merge(
                       token: SecureRandom.uuid,
                       subscribed_at: Time.now,
                       active: true,
                       last_sync_ts: nil
                       )
    @store.insert(@data)
  end

  def self.find(store, criteria)
    store.find(criteria).map do |rec|
      subscriber = allocate
      subscriber.instance_variable_set(:@store, store)
      subscriber.instance_variable_set(:@data, rec)
      subscriber
    end
  end

  def reject!
    @store.update(@data, @data.merge(active: false))
    @data[:active] = false
  end

  def ping(ts = Time.now)
    @store.update(@data, @data.merge(last_sync_ts: ts))
    @data[:last_sync_ts] = ts
  end

  def synced?
    !last_sync_ts.nil?
  end

  def method_missing(meth)
    @data.has_key?(meth) ? @data[meth] : super
  end

  # private
  #
  # def self.store
  #   Divulgence.config.subscriber_store
  # end
end
