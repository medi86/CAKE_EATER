$LOAD_PATH.unshift File.expand_path('lib', __dir__)
require 'network_games/cake_eater_app'

host = ENV.fetch('HOST', 'localhost')
port = ENV.fetch('PORT', '3000').to_i

users = [
  {username: 'team1', password: 'secret'},
  {username: 'team2', password: 'secrets'},
]

cake_eater = NetworkGames::CakeEaterApp.new users: users, registration_time: 5*60

Thread.new do
  loop do
    sleep 1
    cake_eater.timer.check
  end
end

require 'websocket_parser'
require 'celluloid/autostart'
require 'reel'
require 'rack'

Reel::Server::HTTP.supervise(host, port) do |connection|
  connection.each_request do |request|
    if request.websocket?
      # var ws=new WebSocket('ws://localhost:3000'); ws.onmessage = function(arg) { console.log(arg.data) };
      puts "Client made a WebSocket request to: #{request.url}"
      websocket = request.websocket
      websocket << "Hello everyone out there in WebSocket land"
      websocket.close
    else
      # Mostly stolen from https://github.com/celluloid/reel-rack/blob/2edd5ff371a94eca79791d5312aae8065b42b714/lib/reel/rack/server.rb#L71
      options = { :method => request.method, :input => request.body.to_s, "REMOTE_ADDR" => request.remote_addr }
      request.headers.each { |key, value|
        header = key.upcase.gsub('-','_')
        header = "HTTP_#{header}" unless header == 'CONTENT_TYPE' || header == 'CONTENT_LENGTH'
        options[header] = value
      }
      env = ::Rack::MockRequest.env_for(request.url, options)
      status, headers, body = cake_eater.call(env)
      request.respond status, headers, body.join("\n")
    end
  end
end

sleep
