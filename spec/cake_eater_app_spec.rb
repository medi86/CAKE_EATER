require 'spec_helper'
require 'network_games/cake_eater_app'

RSpec.describe 'NetworkGames::CakeEaterApp' do
  it 'chooses a random board on an a 40x30 grid' do
    app = NetworkGames::CakeEaterApp.new
    expect(app.board.width).to eq 40
    expect(app.board.height).to eq 30
  end

  it 'starts once the registration time is up (defaulting to 5 min)' do
    timer = NetworkGames::TimeControl.new
    app   = NetworkGames::CakeEaterApp.new timer: timer
    expect(timer.remaining :game_start).to eq 5*60
    expect(app.status).to eq :registration
    timer.call :game_start
    expect(app.status).to eq :in_progress
  end

  it 'adds a robot for each user' do
    app = NetworkGames::CakeEaterApp.new users: [{username: 'team1', password: 'secret'}]
    expect(app.game.look 'team1').to be_a_kind_of Hash
    expect(app.game.look 'team2').to be_nil
  end

  describe 'GET /cake_eater' do
    specify '200 OK with contents of the leaderboard, status, and the amount of cake remaining' do
      timer = NetworkGames::TimeControl.new
      app   = NetworkGames::CakeEaterApp.new timer: timer, users: [{username: 'team1', password: 'secret'}]

      response = get '/cake_eater'
      expect(response.status).to eq 200
      expect(JSON.parse response, symbolize_names: true).to eq \
        status: :in_progress,
        cake_remaining: :not_sure_What_This_should_be,
        leaderboard: [{name: 'team1', score: 0}]

      timer.call :game_start

      response = get '/cake_eater'
      expect(response.status).to eq 200
      expect(JSON.parse response, symbolize_names: true).to eq \
        status: :in_progress,
        cake_remaining: :not_sure_What_This_should_be,
        leaderboard: [{name: 'team1', score: 0}]
    end
  end


  describe 'GET /cake_eater/robots/:robot_name' do
    specify '401 Unauthorized unless there is a header with the token' do
      app = NetworkGames::CakeEaterApp.new users: [{username: 'team1', password: 'secret'}]

      response = get '/cake_eater/robots/team1' # FIXME: no credentials
      expect(response.status).to eq 401
      expect(JSON.parse response, symbolize_names: true).to eq \
        error: "You need to provide your username and password, eg http://Aladdin:OpenSesame@www.example.com/cake_eater"

      response = get '/cake_eater/robots/team1' # FIXME: with credentials
      expect(response.status).to eq 401
      expect(JSON.parse response, symbolize_names: true).to eq \
        error: "You need to provide your username and password, eg http://Aladdin:OpenSesame@www.example.com/cake_eater"
    end

    specify '403 Forbidden if the username/password do not match the robot they are requesting' do
      app = NetworkGames::CakeEaterApp.new users: [{username: 'team1', password: 'secret', username: 'team2', password: 'othersecret'}]

      response = get '/cake_eater/robots/team1' # FIXME: team1 credentials
      expect(response.status).to eq 200

      response = get '/cake_eater/robots/team1' # FIXME: team2 credentials
      expect(response.status).to eq 403
      expect(JSON.parse response, symbolize_names: true).to eq error: "Your credentials do not allow you to see the requested robot"
    end

    specify '404 Not Found if the robot has not been registered' do
      app = NetworkGames::CakeEaterApp.new users: [{username: 'team1', password: 'secret'}]
      response = get '/cake_eater/robots/team2' # FIXME: team1 credentials
      expect(response.status).to eq 404
      expect(JSON.parse response, symbolize_names: true).to eq error: "There is no robot named \"team2\", known names: [\"team1\"]"
    end

    specify '200 OK if the robot can look around, body includes name, score, coords, plan, a grid of nearby tiles, and available actions' do
      app = NetworkGames::CakeEaterApp.new users: [{username: 'team1', password: 'secret'}]
      response = get '/cake_eater/robots/team1' # FIXME: team1 credentials
      expect(response.status).to eq 200
      expect(JSON.parse response, symbolize_names: true).to eq \
        name: 'team1', score: 0, x: :fixme, y: :fixme, plan: nil,
        grid: [:fixme],
        actions: [:eat_cake, :move_north, :move_east, :move_south, :move_west]

    end
  end


  describe 'PUTS /cake_eater/robots/:robot_name' do
    specify '401 Unauthorized unless there is a header with the token'
    specify '404 Not Found if the robot has not been registered'
    describe '200 OK' do
      specify 'when the move is technically valid, body is the same as the get request'
      specify 'plans the move'
      specify 'performs the move once the move time is hit'
      specify 'overwrites the old move if the move time hasn\'t been hit yet'
      specify 'valid moves: eat_cake move_north move_east move_south move_west'
    end
  end
end
