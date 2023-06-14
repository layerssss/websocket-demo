# frozen_string_literal: false

require 'em-websocket'

EventMachine.run do
  EM::WebSocket.start(host: '0.0.0.0', port: '3001') do |ws|
    ws.onopen do |handshake|
      puts 'WebSocket connection open'

      # Access properties on the EM::WebSocket::Handshake object, e.g.
      # path, query_string, origin, headers

      # Publish message to the client
      ws.send "Hello Client, you connected to #{handshake.path}"
    end

    ws.onmessage do |message|
      puts "message received: #{message.inspect}"
      case message
      when 'hello'
        ws.send('hi')
      when 'how are you'
        ws.send('i am fine')
      when 'give me a file'
        # !!! This is not working
        # ws.send(File.binread('avatar_small.jpg'))
      else
        ws.send('what?')
      end
    end

    ws.onclose { puts 'Connection closed' }
  end
end
