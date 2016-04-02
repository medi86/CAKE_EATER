require 'rest-client'
require 'io/console'
require 'json'
require 'pp'

loop do
  char = $stdin.raw { $stdin.getc }
  case char
  when 3.chr then break
  when 'h'   then action = 'move_west'
  when 'j'   then action = 'move_south'
  when 'k'   then action = 'move_north'
  when 'l'   then action = 'move_east'
  when 'c'   then action = 'eat_cake'
  end

  begin
    user   = 'team1'
    result = RestClient::Request.new(
      method:   :put,
      url:      "localhost:3000/cake_eater/robots/#{user}",
      user:     user,
      password: 'secret',
      payload:  {'action' => action}.to_json
    ).execute
    puts "\e[H\e[2J#{JSON.parse(result).pretty_inspect}"
  rescue RestClient::BadRequest
  end
end
