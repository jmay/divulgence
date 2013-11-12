module Divulgence
  class MemoryStore
    def initialize
      @store = []
    end

    # NOTE: doesn't implement sorting

    def find(criteria, options = {})
      @store.find_all do |rec|
        criteria.all? { |k, v| v === rec[k] }
      end
    end

    def find_one(criteria, options = {})
      find(criteria, options = {}).last
    end

    def insert(data)
      @store << data
    end

    def update(match, data)
      find(match).each do |rec|
        rec.replace(data)
      end
    end
  end

  class NullStore
    def self.find(args = {})
      []
    end
    def self.method_missing(*args)
      # no-op
    end
  end
end
