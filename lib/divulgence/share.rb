class Divulgence::Share
  attr_reader :id, :data, :created_at, :context

  def initialize(params = {})
    @context = params.delete(:context)
    @id = params.fetch(:id) { SecureRandom.uuid }
    @data = params.reject { |k,v| k == :id }
    @created_at = Time.now
    store.insert(id: @id,
                 created_at: @created_at,
                 data: @data
                 )
  end

  def self.find(context, criteria = {})
    context.share_store.find(criteria).map do |rec|
      share = allocate
      share.instance_variable_set("@context", context)
      rec.each do |k,v|
        share.instance_variable_set("@#{k}", rec[k])
      end
      share
    end
  end

  def subscribers(criteria = {})
    Divulgence::Subscriber.find(context.subscriber_store, criteria.merge(share_id: id))
  end

  def onboard(peerdata)
    Divulgence::Subscriber.new(context.subscriber_store, {share_id: id, peer: peerdata})
  end

  def subscriber_for_token(token)
    this_guy = subscribers(token: token, active: true).first
    raise SecurityError, "invalid token" unless this_guy
    this_guy
  end

  def reject(token)
    subscriber_for_token(token).reject!
  end

  def history
    Divulgence::History.find(context.history_store, pushed: id)
  end

  def refresh(token)
    now = Time.now
    subscriber_for_token(token).ping(now)
    Divulgence::History.new(context.history_store, {pushed: id, token: token, ts: now})

    yield if block_given?
  end

  def set(changes)
    store.update({id: id}, {id: id, created_at: created_at, data: changes})
    @data = changes
  end

  # private

  # def self.store; Divulgence.config.share_store; end
  def store; context.share_store; end
end
