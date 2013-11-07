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

  def self.subscribe(code, peerdata)
    Divulgence::Subscription.subscribe(code, peerdata)
  end
end
