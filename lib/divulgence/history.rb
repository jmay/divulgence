class Divulgence::History
  def initialize(store, args)
    @data = args
    @data[:ts] ||= Time.now
    store.insert(@data)
  end

  # always retrieve history most-recent-first
  def self.find(store, criteria)
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

  # private
  #
  # def self.store
  #   Divulgence.config.history_store
  # end
end
