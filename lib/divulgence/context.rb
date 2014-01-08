require "ostruct"

class Divulgence::Context
  attr_reader :config

  def initialize
    @config ||= OpenStruct.new
    yield @config if block_given?
  end

  def shares(criteria = {})
    Divulgence::Share.find(config, criteria)
  end

  def share(args)
    Divulgence::Share.new(args.merge(context: config))
  end

  def subscriptions(criteria = {})
    Divulgence::Subscription.find(config, criteria)
  end

  def subscribe(args = {})
    Divulgence::Subscription.subscribe(config, args)
  end
end
