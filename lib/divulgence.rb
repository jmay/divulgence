unless Kernel.respond_to?(:require_relative)
  module Kernel
    def require_relative(path)
      require File.join(File.dirname(caller[0]), path.to_str)
    end
  end
end

%w(
  share
  subscription
  store
  ).each do |f|
  require_relative "divulgence/#{f}"
end

module Divulgence
  def self.share(args)
    Divulgence::Share.new(args)
  end

  def self.shares
    Divulgence::Share.all(config.share_store)
  end

  def self.subscriptions(criteria = {})
    Divulgence::Subscription.all(config.subscription_store, criteria)
  end

  def self.subscribe(args = {})
    Divulgence::Subscription.subscribe(args)
  end

  def self.config
    @@config ||= OpenStruct.new
    yield @@config if block_given?
    @@config
  end
end
