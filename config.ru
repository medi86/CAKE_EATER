$LOAD_PATH.unshift File.expand_path('lib', __dir__)
require 'network_games/cake_eater_app'


users = [
  {username: 'team1', password: 'secret'},
  {username: 'team2', password: 'secrets'},
]

app = NetworkGames::CakeEaterApp.new users: users, registration_time: 5*60

Thread.new do
  loop do
    sleep 1
    app.timer.check
  end
end

run app
