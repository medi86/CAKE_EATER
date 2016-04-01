require 'network_games/time_control'
require 'network_games/cake_eater'
require 'json'

class NetworkGames
  class CakeEaterApp
    attr_reader :board, :game, :timer, :status
    def initialize(registration_time: 5*60, timer: TimeControl.new, users:[], ascii_board: nil)
      ascii_board ||= 30.times.map { Array.new(40, ' ').join }.join("\n")
      @board = NetworkGames::Board.from_ascii ascii_board, tiles: {
        ' ' => nil,
        '#' => NetworkGames::Board::Wall,
        'C' => NetworkGames::CakeEater::Cake,
      }

      @game = NetworkGames::CakeEater.new(board)

      users.each { |credentials| @game.join name: credentials.fetch(:username) }

      @users  = users
      @timer  = timer
      @status = :registration
      timer.register :game_start, registration_time do
        @status = :in_progress
        countdown
      end
    end

    def countdown
      timer.register(:game_tick, 1) {
        countdown
        game.tick
        File.write 'board.json', as_json.to_json
      }
    end

    def as_json
      { status:         status,
        board:          game.board.as_json,
        cake_remaining: game.cake_remaining,
        leaderboard:    game.leaderboard,
        users:          @users.map { |h| {username: h[:username]} },
      }
    end

    def call(env)
      status, headers, body = 404, {}, []
      case env['PATH_INFO']
      when '/cake_eater'
        json = {status: self.status, cake_remaining: game.cake_remaining, leaderboard: game.leaderboard}
        body << JSON.dump(json)
        status = 200
      when %r(^/cake_eater/robots/(.+))
        team_name = $1
        username  = authenticate(env['HTTP_AUTHORIZATION'])
        if @users.none? { |credentials| credentials[:username] == team_name }
          json = {error: "There is no robot named #{team_name.inspect}, known names: #{@users.map { |credentials| credentials[:username] }.inspect}"}
          body << JSON.dump(json)
          status = 404
        elsif !username
          json = {error: "You need to provide your username and password, eg #{env['rack.url_scheme']}://#{team_name}:SecretPassword@#{env['HTTP_HOST']}#{env['PATH_INFO']}"}
          body << JSON.dump(json)
          status = 401
        elsif username != team_name
          json = {error: "Your credentials do not allow you to see the requested robot" }
          body << JSON.dump(json)
          status = 403
          team_name == username
        else
          valid_actions = {
            'eat_cake'   => lambda { game.eat_cake   team_name },
            'move_north' => lambda { game.move_north team_name },
            'move_east'  => lambda { game.move_east  team_name },
            'move_south' => lambda { game.move_south team_name },
            'move_west'  => lambda { game.move_west  team_name },
          }
          if env['REQUEST_METHOD'] == 'PUT'
            input = JSON.parse(env['rack.input'].read)
            if valid_actions.key? input['action']
              valid_actions[input['action']].call
              status = 200
            else
              status = 400
            end
          elsif env['REQUEST_METHOD'] == 'GET'
            status = 200
          end
          if status == 400
            input = {error: "#{input['action'].inspect} is not a valid action."}
            body << JSON.dump(input)
          elsif env['REQUEST_METHOD'] == 'GET' || env['REQUEST_METHOD'] == 'PUT'
            json = game.look team_name
            json[:actions] = valid_actions.keys
            body << JSON.dump(json)
          end
        end
      else raise "UNHANDLED PATH: #{env['PATH_INFO']}"
      end

      [status, headers, body]
    end

    private

    def authenticate(auth_header)
      username, password = username_and_password(auth_header)
      username &&
        password &&
        @users.find { |credentials| credentials[:username] == username && credentials[:password] == password } &&
        username
    end

    def username_and_password(auth_header)
      authorization = auth_header.to_s.chomp.split.last
      return unless authorization
      username, password = authorization.unpack("m").first.split(":")
    end
  end
end
