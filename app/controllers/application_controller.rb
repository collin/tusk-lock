require "channel"

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  include ActionController::Live

  def works
    with_stream do |stream|
      loop do
        stream.write "hello world!\n"
        sleep 1
      end
    end
  end

  def broken
    with_stream do |stream|
      channel = Channel.new(:bbc)
      listener = Object.new
      def listener.update
        stream.write "channel message!\n"
      end
      channel.add_observer listener
      sleep
    end
  end

  def with_stream(&block)
    begin 
      yield response.stream
    rescue IOError

    ensure
      response.stream.close
    end
  end
end
