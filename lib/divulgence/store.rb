module Divulgence
  class MemoryStore
    def initialize
      @store = []
    end

    def find(args = {})
      @store.find_all do |rec|
        args.all? { |k, v| v === rec[k] }
      end
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
