# frozen_string_literal: true

require 'websocket'
require 'socket'

tcp_server = TCPServer.new 3001
puts 'Listening on port 3001'

client = tcp_server.accept

handshake = WebSocket::Handshake::Server.new
until handshake.finished?
  byte = client.read(1)
  handshake << byte
end

unless handshake.valid?
  client.close
  exit 1
end

puts "Client connected: #{handshake.version}"
client.write handshake.to_s
client.write WebSocket::Frame::Outgoing::Server.new(
  data: "Hello Client, you connected to #{handshake.path}", type: :text
).to_s

incoming_frame = WebSocket::Frame::Incoming::Server.new(version: handshake.version)
loop do
  byte = client.read(1)
  incoming_frame << byte
  message = incoming_frame.next
  next unless message

  puts "type: #{message.type} data: #{message.data}"
  if message.type == :close
    client.close
    break
  end
  next unless message.type == :text

  case message.data
  when 'hello'
    client.write WebSocket::Frame::Outgoing::Server.new(data: 'hi', type: :text).to_s
  when 'how are you'
    client.write WebSocket::Frame::Outgoing::Server.new(data: 'i am fine', type: :text).to_s
  when 'give me a file'
    client.write WebSocket::Frame::Outgoing::Server.new(data: File.read('avatar_small.jpg'), type: :binary).to_s
  else
    client.write WebSocket::Frame::Outgoing::Server.new(data: 'what?', type: :text).to_s
  end
end
