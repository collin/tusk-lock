steps to reproduce

Boot redis on default port

Boot rails app with puma

```
puma
```

Startup rails console

`curl -i localhost:9292/works` and see it works

`curl -i localhost:9292/broken`

in rails console:

```ruby
require "channel"
bbc = Channel.new(:bbc)
bbc.instance_eval{changed and notify_observers}
```

see that curl to broken sends no messages

Channel implementation

```ruby
require 'tusk/observable/redis'
require 'redis'

class Channel
  include Tusk::Observable::Redis

  # takes a channel name so Channel objects can be 
  # instantiated without any knowledge of each other.
  # and still be used to pass messages.
  # ( verified this works fine outside of Rails)
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
```

And in the controller:

```ruby
  # just a simple stream helper
  def with_stream(&block)
    begin 
      yield response.stream
    rescue IOError

    ensure
      response.stream.close
    end
  end

  # This works as expected.
  def works
    with_stream do |stream|
      loop do
        stream.write "hello world!\n"
        sleep 1
      end
    end
  end

  # This does not.
  def broken
    with_stream do |stream|
      channel = Channel.new(:bbc)
      listener = Object.new
      def listener.update
        stream.write "channel message!\n"
        # This never happens.
        # looking into things it looks like
        # this is executed from a thread spawned
        # by Tusk. Digging into that it looks
        # like any access to the response (response.stream)
        # object of the controller hangs.
        #
        # I was able to verify through print statements that Tusk
        # is doing it's thing up until the point we try to call stream.write
        #
        # Deadlocked?
      end
      channel.add_observer listener
      sleep
    end
  end


```