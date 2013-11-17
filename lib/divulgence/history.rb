class Divulgence::History
  def initialize(args)
    @data = args.merge(ts: Time.now)
    store.insert(@data)
  end

  # always retrieve history most-recent-first
  def self.find(criteria)
    Enumerator.new do |yielder|
      store.find(criteria, {sort: {ts: -1}}).map do |rec|
        event = allocate
        event.instance_variable_set(:@data, rec)
        yielder.yield event
      end
    end
  end

  def method_missing(meth)
    @data.has_key?(meth) ? @data[meth] : super
  end

  private

  def store
    self.class.store
  end
  def self.store
    Divulgence.config.history_store
  end
end
