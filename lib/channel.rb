require 'tusk/observable/redis'
require 'redis'

class Channel
  include Tusk::Observable::Redis

  def initialize(channel)
    @channel = channel
    super()
  end
  
  def connection
    Thread.current[:redis] ||= ::Redis.new
  end

  private

  def channel
    "a" + Digest::MD5.hexdigest("#{self.class.name}#{@channel}")
  end

end